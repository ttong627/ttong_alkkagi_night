import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:defense_core/defense_core.dart';

void configureOptimalLoadout(PlayerProgress p, StageSpec stage) {
  final preset = p.activePreset;
  final stones = p.unlockedStones.toList()..sort((a, b) => b.grade.compareTo(a.grade));
  if (stones.isNotEmpty) {
    preset.primaryStone = stones.first;
  }
  preset.primaryShape = (stage.isBossStage && stage.chapterNumber >= 4)
      ? StoneShape.sphere
      : StoneShape.round;
  preset.sectTechnique = stage.isReincarnationBossStage
      ? SectTechnique.taiji
      : SectTechnique.values[stage.globalIndex % SectTechnique.values.length];

  final chSpec = CampaignCatalog.chapterOf(stage.chapterNumber);
  for (int i = 0; i < chSpec.mounts.length && i < preset.mountTypes.length; i++) {
    final rec = chSpec.mounts[i].recommendedType;
    if (rec.unlockChapter <= p.effectiveArsenalChapter) {
      preset.mountTypes[i] = rec;
    }
  }

  final beasts = SpiritBeast.values.where((b) => (p.beastLevels[b] ?? 0) > 0).toList()
    ..sort((a, b) {
      final sa = (p.beastLevels[a] ?? 0) * 2 + a.index * 3;
      final sb = (p.beastLevels[b] ?? 0) * 2 + b.index * 3;
      return sb.compareTo(sa);
    });
  if (beasts.isNotEmpty) {
    preset.equippedBeast = beasts.first;
    preset.beastCondition = beasts.first.defaultCondition;
  }

  final heroes = CompanionHero.values.where((h) => (p.companionLevels[h] ?? 0) > 0).toList()
    ..sort((a, b) {
      final am = a == CompanionHero.mukhyeon ? 1 : 0;
      final bm = b == CompanionHero.mukhyeon ? 1 : 0;
      if (am != bm) return am.compareTo(bm);
      final lv = (p.companionLevels[b] ?? 0).compareTo(p.companionLevels[a] ?? 0);
      if (lv != 0) return lv;
      return b.index.compareTo(a.index);
    });
  if (heroes.isNotEmpty) {
    preset.companions = heroes.take(3).toList();
  }
  preset.supportSlotCount = 3;
  preset.supportTriggerShieldRatio = 0.42;
  preset.autoUpgradeInBattle = true;
}

BattleSummary playAsActiveHuman({
  required PlayerProgress p,
  required StageSpec stage,
  required DefenseDifficulty difficulty,
  required int seed,
  int? lazyPadCap,
  double maxSimSec = 420.0,
}) {
  final sim = DefenseBattleSim(
    stage: stage,
    difficulty: difficulty,
    progress: p,
    seed: seed,
    allowSupportTokens: lazyPadCap == null,
    allowSerendipity: true,
    autoBuildForSimVerify: false,
  );

  const dt = 1.0 / 30.0;
  const decisionStride = 15; // 2Hz 인간 조작 주기
  final maxSteps = (maxSimSec / dt).round();
  final usedPills = <TacticalConsumable>{};

  for (int step = 0; step < maxSteps && !sim.isFinished; step++) {
    if (step % decisionStride == 0) {
      if (sim.pendingPerkChoices.isNotEmpty) {
        final pick = sim.recommendedPerkChoice() ?? sim.pendingPerkChoices.first;
        sim.chooseRoguePerk(pick);
      }

      if (lazyPadCap != null) {
        if (sim.launchers.length < lazyPadCap) {
          final nextSlot = sim.nextRecommendedSlotIndex();
          if (nextSlot != null) {
            final slot = sim.mountSlotByIndex(nextSlot)!;
            if (!sim.isSlotExcavated(nextSlot)) {
              if (sim.fieldTokens >= sim.excavationCostForSlot(slot)) {
                sim.excavateSlotInBattle(nextSlot);
              }
            } else {
              sim.quickDirectBuildNextPad();
            }
          }
        }
      } else {
        for (final l in sim.launchers) {
          if (l.isCorrupted) {
            sim.cleanseLauncherAtSlot(l.slotIndex);
            break;
          }
        }
        if (sim.rouletteSpinsAvailable > 0 && sim.mutants.length >= 3) {
          sim.spinDestinyRoulette();
        }
        final nextSlot = sim.nextRecommendedSlotIndex();
        if (nextSlot != null) {
          final slot = sim.mountSlotByIndex(nextSlot)!;
          if (!sim.isSlotExcavated(nextSlot)) {
            if (sim.fieldTokens >= sim.excavationCostForSlot(slot)) {
              sim.excavateSlotInBattle(nextSlot);
            }
          } else {
            sim.quickDirectBuildNextPad();
          }
        } else {
          sim.upgradeLiveFirepower();
          sim.upgradeLiveReload();
          sim.upgradeLiveRange();
          if (sim.shieldHp < sim.shieldMaxHpDynamic * 0.80) {
            sim.upgradeLiveBarrier();
          }
          for (final l in sim.launchers) {
            if (l.tier < 4 && !l.isConstructing && sim.fieldTokens >= sim.upgradeCostForLauncher(l)) {
              sim.upgradeLauncherAtSlot(l.slotIndex);
              break;
            }
          }
          final mergePair = sim.findAnyMergePair();
          if (mergePair != null && sim.fieldTokens >= sim.mergeCostForSlot(mergePair.$1) + 90) {
            final lA = sim.launcherAtSlot(mergePair.$1);
            if (lA != null && lA.tier >= 3) {
              sim.mergeLauncherAtSlot(mergePair.$1);
            }
          }
        }

        if (sim.isPrecisionStrikeReady) {
          final boss = sim.activeMultiPhaseBoss;
          if (boss != null && boss.hasActiveWeakPoint) {
            sim.firePrecisionStrikeAt(boss.weakSpotWorldPos, targetBossUid: boss.uid);
          }
        }

        if (sim.qiBars < sim.maxQiBars - 0.5 &&
            stage.isBossStage &&
            !usedPills.contains(TacticalConsumable.qiSurgePill)) {
          if (sim.activateConsumable(TacticalConsumable.qiSurgePill)) {
            usedPills.add(TacticalConsumable.qiSurgePill);
          }
        }
        if (sim.shieldHp < sim.shieldMaxHpDynamic * 0.72 &&
            !usedPills.contains(TacticalConsumable.guardianRepairSeal)) {
          if (sim.activateConsumable(TacticalConsumable.guardianRepairSeal)) {
            usedPills.add(TacticalConsumable.guardianRepairSeal);
          }
        }
        if (sim.activeMultiPhaseBoss != null &&
            !usedPills.contains(TacticalConsumable.auroraCritCharm)) {
          if (sim.activateConsumable(TacticalConsumable.auroraCritCharm)) {
            usedPills.add(TacticalConsumable.auroraCritCharm);
          }
        }
        if (sim.supportChargesLeft > 0 &&
            (sim.shieldHp <= sim.shieldMaxHpDynamic * 0.36 ||
                (sim.shieldHp <= 0 && sim.towerHp <= sim.centralSpec.coreMaxHp * 0.72))) {
          sim.triggerSupportChuldu();
        }
      }
    }

    if (lazyPadCap == null && step % 240 == 60 && sim.launchers.isNotEmpty && sim.isCentralReadyToFire) {
      Vec2 aimPt = sim.powerTarget.center;
      if (sim.treasureGoblin != null && sim.treasureGoblin!.alive) {
        aimPt = sim.treasureGoblin!.pos;
      } else {
        final keg = sim.powderKegs.where((k) => k.intact).firstOrNull;
        if (keg != null && keg.pos.distanceTo(sim.towerPos) <= sim.effectiveCentralManualRange) {
          aimPt = keg.pos;
        } else if (step % 480 == 60) {
          aimPt = sim.cloneGate.center;
        }
      }
      if (!sim.centralManualMode) sim.toggleCentralManualMode();
      sim.fireCentralManualAt(aimPt);
      if (sim.centralManualMode) sim.toggleCentralManualMode();
    }

    sim.step(dt);
  }
  return sim.buildSummary();
}

Future<(int wins, int? firstWinSeed, int unfinished)> _evaluateBossMonteCarloParallel({
  required String progressJson,
  required int reincarnationCount,
  required int totalSeeds,
  required int baseSeed,
}) async {
  const workers = 8;
  final futures = <Future<(int, int?, int)>>[];
  for (int w = 0; w < workers; w++) {
    futures.add(Isolate.run(() {
      final bossStage =
          CampaignCatalog.buildReincarnationFinalBossStage(reincarnationCount: reincarnationCount);
      final snap = PlayerProgress.decodeJson(progressJson);
      final supBefore = snap.supportTokens;
      int wins = 0;
      int? firstWin;
      int unfin = 0;
      for (int s = w; s < totalSeeds; s += workers) {
        final trialP = PlayerProgress.decodeJson(progressJson);
        configureOptimalLoadout(trialP, bossStage);
        final sum = playAsActiveHuman(
          p: trialP,
          stage: bossStage,
          difficulty: DefenseDifficulty.nightmare,
          seed: baseSeed + s * 97,
        );
        if (trialP.supportTokens != supBefore) {
          throw StateError('윤회 보스전 도중 원본 지원패가 차감됨!');
        }
        if (sum.victory) {
          wins++;
          firstWin ??= baseSeed + s * 97;
        }
      }
      return (wins, firstWin, unfin);
    }));
  }
  final results = await Future.wait(futures);
  int totalWins = 0;
  int? earliestWin;
  int totalUnfin = 0;
  for (final r in results) {
    totalWins += r.$1;
    if (r.$2 != null && (earliestWin == null || r.$2! < earliestWin)) {
      earliestWin = r.$2;
    }
    totalUnfin += r.$3;
  }
  return (totalWins, earliestWin, totalUnfin);
}

PlayerProgress _buildCycle0EndgameProfile() {
  final p = PlayerProgress(
    tokens: 4800,
    elixirs: 65,
    trainingSeals: 220,
    naegongPoints: 3400,
    realmIndex: 7,
    centralGuardianLevel: 21,
    supportTokens: 8,
    highestClearedGlobalStage: 99,
    openedMeridianStep: 10,
    forgeMasteryLevel: 8,
    elixirResonanceLevel: 8,
    preferredDifficultyId: 'nightmare',
    preferredBattleSpeed: 4,
    preferredAutoPerk: true,
  );
  for (final lt in LauncherType.values) {
    p.launcherPermanentLevels[lt] = 18;
  }
  for (final cs in CoreStatType.values) {
    p.coreStatLevels[cs] = 14;
  }
  p.unlockedStones.addAll(StoneMaterial.values);
  for (final b in SpiritBeast.values) {
    p.beastLevels[b] = 9;
  }
  for (final h in CompanionHero.values) {
    p.companionLevels[h] = 9;
  }
  for (final c in TacticalConsumable.values) {
    p.consumables[c] = 5;
  }
  return p;
}

void _investBetweenBattles(PlayerProgress p, Random rng, String dayKey) {
  p.claimAttendance(todayKey: dayKey, rng: rng);
  if (p.remainingDailyEnlightenment(todayKey: dayKey) > 0) {
    p.meditateBatch(count: 10, hitGoldenRing: true, rng: rng, todayKey: dayKey);
  }
  p.claimAllReadyRewards(rng, todayKey: dayKey, autoRedispatch: true);
  p.upgradeRecommendedBatch(maxSteps: 18);
  for (final cs in CoreStatType.values) {
    while (p.trainingSeals >= p.coreStatUpgradeCost(cs)) {
      p.upgradeCoreStat(cs);
    }
  }
  for (final c in TacticalConsumable.values) {
    while ((p.consumables[c] ?? 0) < 3 && p.canCraftConsumable(c)) {
      p.craftConsumable(c);
    }
  }
}

Future<void> main(List<String> args) async {
  final outSavePath = args.isNotEmpty ? args.first : '';
  final savedMilestones = <String, String>{};
  final rng = Random(20261125);

  stdout.writeln('=== [1단계] 초회차(0환생) 악몽 10-10 정화 및 윤회 최종 보스전 <5% 확률 검증 ===');
  final p = _buildCycle0EndgameProfile();
  savedMilestones['cycle0_before_nm10_10'] = p.exportBackupCode();

  final st1010 = CampaignCatalog.allStages.last;
  configureOptimalLoadout(p, st1010);
  bool clearedNm10 = false;
  for (int attempt = 0; attempt < 8 && !clearedNm10; attempt++) {
    final sum = playAsActiveHuman(
      p: p,
      stage: st1010,
      difficulty: DefenseDifficulty.nightmare,
      seed: 10100 + attempt * 37,
    );
    p.onBattleFinished(
      stage: st1010,
      victory: sum.victory,
      stars: sum.stars,
      earnedTokens: sum.earnedTokens,
      earnedElixirs: sum.earnedElixirs,
      usedSupportCount: sum.usedSupportCount,
      killCount: sum.killCount,
      difficultyId: DefenseDifficulty.nightmare.id,
      supportAlreadyDeductedInSim: sum.supportDeductedRealtime,
      bossElixirAlreadyIncluded: sum.bossElixirIncluded,
    );
    if (sum.victory) {
      clearedNm10 = true;
      stdout.writeln('  ✓ 초회차 악몽 10-10 정화 성공! (시도 ${attempt + 1}회 · ★${sum.stars})');
    }
  }
  if (!clearedNm10 || !p.canChallengeReincarnationBoss) {
    stderr.writeln('실패: 초회차 악몽 10-10 클리어 또는 윤회 보스 해금 실패!');
    exit(1);
  }
  savedMilestones['cycle0_boss_unlocked'] = p.exportBackupCode();

  const totalSeeds = 200;
  final sw0 = Stopwatch()..start();
  final (boss0Wins, firstWinningSeed0, _) = await _evaluateBossMonteCarloParallel(
    progressJson: p.encodeJson(),
    reincarnationCount: 0,
    totalSeeds: totalSeeds,
    baseSeed: 888000,
  );
  final winRate0 = boss0Wins * 100.0 / totalSeeds;
  stdout.writeln(
    '  ★ 초회차 【윤회 최종 보스전】 $totalSeeds판 8코어 병렬 시뮬 결과 (${(sw0.elapsedMilliseconds / 1000).toStringAsFixed(1)}s): 승리 $boss0Wins/$totalSeeds판 (승률 ${winRate0.toStringAsFixed(2)}%)',
  );

  final bossStage0 = CampaignCatalog.buildReincarnationFinalBossStage(reincarnationCount: 0);
  int lazyBossWins = 0;
  for (int s = 0; s < 20; s++) {
    final trialP = PlayerProgress.decodeJson(p.encodeJson());
    configureOptimalLoadout(trialP, bossStage0);
    final sum = playAsActiveHuman(
      p: trialP,
      stage: bossStage0,
      difficulty: DefenseDifficulty.nightmare,
      seed: 999000 + s,
      lazyPadCap: 3,
    );
    if (sum.victory) lazyBossWins++;
  }
  stdout.writeln('  ★ 윤회 최종 보스전 소수 설치(3기 방치) 승리: $lazyBossWins/20판');

  if (boss0Wins <= 0 || winRate0 >= 5.0 || lazyBossWins > 0) {
    stderr.writeln(
      '보정 필요: 초회차 최종 보스 승률=${winRate0.toStringAsFixed(2)}% (목표: 0% 초과 ~ 5.0% 미만, 방치 0승)',
    );
    exit(2);
  }

  configureOptimalLoadout(p, bossStage0);
  final winSum0 = playAsActiveHuman(
    p: p,
    stage: bossStage0,
    difficulty: DefenseDifficulty.nightmare,
    seed: firstWinningSeed0!,
  );
  p.onBattleFinished(
    stage: bossStage0,
    victory: winSum0.victory,
    stars: winSum0.stars,
    earnedTokens: winSum0.earnedTokens,
    earnedElixirs: winSum0.earnedElixirs,
    usedSupportCount: winSum0.usedSupportCount,
    killCount: winSum0.killCount,
    difficultyId: DefenseDifficulty.nightmare.id,
    supportAlreadyDeductedInSim: true,
    bossElixirAlreadyIncluded: true,
  );
  savedMilestones['cycle0_ready_to_reincarnate'] = p.exportBackupCode();

  final preCentralLv = p.centralGuardianLevel;
  final preStoneCount = p.unlockedStones.length;
  final preHeroCount = p.unlockedCompanionCount;
  if (!p.performReincarnation()) {
    throw StateError('제1환생 실행 실패!');
  }
  stdout.writeln(
    '=== [2단계] 제1환생 완료! (reincarnationCount=${p.reincarnationCount} · 난이도 ×${p.reincarnationDifficultyMultiplier.toStringAsFixed(0)}배 · 스테이지=${p.highestClearedGlobalStage}/100 · 수호탑Lv=$preCentralLv->${p.centralGuardianLevel} · 수호석=$preStoneCount/${p.unlockedStones.length} · 동료=$preHeroCount/${p.unlockedCompanionCount}) ===',
  );
  savedMilestones['cycle1_just_reincarnated_1_1'] = p.exportBackupCode();

  final st11 = CampaignCatalog.allStages.first;
  configureOptimalLoadout(p, st11);
  final lazy11 = playAsActiveHuman(
    p: p,
    stage: st11,
    difficulty: DefenseDifficulty.nightmare,
    seed: 202601,
    lazyPadCap: 2,
  );
  if (lazy11.victory) {
    throw StateError('제1환생 1-1 악몽이 포대 2기 방치로 클리어됨!');
  }
  stdout.writeln('  ✓ 제1환생 1-1(×3배) 포대 2기 방치 시 패배 확인 완료!');

  int cycle1NightmareClears = 0;
  for (int idx = 0; idx < CampaignCatalog.allStages.length; idx++) {
    final stage = CampaignCatalog.allStages[idx];
    final dayKey = '2026-12-${((idx ~/ 4) % 28 + 1).toString().padLeft(2, '0')}';
    _investBetweenBattles(p, rng, dayKey);
    configureOptimalLoadout(p, stage);

    final targetDiff = (stage.chapterNumber >= 8 || idx < 5)
        ? DefenseDifficulty.nightmare
        : DefenseDifficulty.normal;

    bool won = false;
    for (int tryIdx = 0; tryIdx < 10 && !won; tryIdx++) {
      final sum = playAsActiveHuman(
        p: p,
        stage: stage,
        difficulty: targetDiff,
        seed: 310000 + idx * 131 + tryIdx * 29,
      );
      p.onBattleFinished(
        stage: stage,
        victory: sum.victory,
        stars: sum.stars,
        earnedTokens: sum.earnedTokens,
        earnedElixirs: sum.earnedElixirs,
        usedSupportCount: sum.usedSupportCount,
        killCount: sum.killCount,
        difficultyId: targetDiff.id,
        supportAlreadyDeductedInSim: sum.supportDeductedRealtime,
        bossElixirAlreadyIncluded: sum.bossElixirIncluded,
        todayKey: dayKey,
      );
      if (sum.victory) {
        won = true;
        if (targetDiff == DefenseDifficulty.nightmare) cycle1NightmareClears++;
      } else {
        final farmStage = CampaignCatalog.allStages[max(0, idx - 1)];
        for (int f = 0; f < 2; f++) {
          final fSum = playAsActiveHuman(
            p: p,
            stage: farmStage,
            difficulty: DefenseDifficulty.normal,
            seed: 410000 + idx * 71 + tryIdx * 13 + f,
          );
          p.onBattleFinished(
            stage: farmStage,
            victory: fSum.victory,
            stars: fSum.stars,
            earnedTokens: fSum.earnedTokens,
            earnedElixirs: fSum.earnedElixirs,
            usedSupportCount: fSum.usedSupportCount,
            killCount: fSum.killCount,
            difficultyId: DefenseDifficulty.normal.id,
            supportAlreadyDeductedInSim: fSum.supportDeductedRealtime,
            bossElixirAlreadyIncluded: fSum.bossElixirIncluded,
            todayKey: dayKey,
          );
          _investBetweenBattles(p, rng, dayKey);
        }
        configureOptimalLoadout(p, stage);
      }
    }
    if (!won) {
      stderr.writeln('실패: 제1환생 ${stage.code} (${targetDiff.id}) 돌파 실패! (초월단련=${p.transcendenceLevel})');
      exit(3);
    }
    if (idx == 98) {
      savedMilestones['cycle1_before_nm10_10'] = p.exportBackupCode();
    }
  }
  stdout.writeln(
    '  ✓ 제1환생(×3배) 1~10현 100판 전수 돌파 완료! (악몽 직접 클리어 $cycle1NightmareClears판 · 초월단련 ${p.transcendenceLevel}단 · nightmareChapter10Cleared=${p.nightmareChapter10Cleared})',
  );
  savedMilestones['cycle1_boss_unlocked'] = p.exportBackupCode();

  final sw1 = Stopwatch()..start();
  final (boss1Wins, firstWinningSeed1, _) = await _evaluateBossMonteCarloParallel(
    progressJson: p.encodeJson(),
    reincarnationCount: p.reincarnationCount,
    totalSeeds: totalSeeds,
    baseSeed: 1888000,
  );
  final winRate1 = boss1Wins * 100.0 / totalSeeds;
  stdout.writeln(
    '  ★ 제1환생(×3배) 【윤회 최종 보스전】 $totalSeeds판 8코어 병렬 시뮬 결과 (${(sw1.elapsedMilliseconds / 1000).toStringAsFixed(1)}s): 승리 $boss1Wins/$totalSeeds판 (승률 ${winRate1.toStringAsFixed(2)}%)',
  );
  if (boss1Wins <= 0 || winRate1 >= 5.0) {
    stderr.writeln(
      '보정 필요: 제1환생 최종 보스 승률=${winRate1.toStringAsFixed(2)}% (목표: 0% 초과 ~ 5.0% 미만)',
    );
    exit(4);
  }

  final bossStage1 = CampaignCatalog.buildReincarnationFinalBossStage(
    reincarnationCount: p.reincarnationCount,
  );
  configureOptimalLoadout(p, bossStage1);
  final winSum1 = playAsActiveHuman(
    p: p,
    stage: bossStage1,
    difficulty: DefenseDifficulty.nightmare,
    seed: firstWinningSeed1!,
  );
  p.onBattleFinished(
    stage: bossStage1,
    victory: winSum1.victory,
    stars: winSum1.stars,
    earnedTokens: winSum1.earnedTokens,
    earnedElixirs: winSum1.earnedElixirs,
    usedSupportCount: winSum1.usedSupportCount,
    killCount: winSum1.killCount,
    difficultyId: DefenseDifficulty.nightmare.id,
    supportAlreadyDeductedInSim: true,
    bossElixirAlreadyIncluded: true,
  );
  savedMilestones['cycle1_ready_to_reincarnate'] = p.exportBackupCode();

  if (!p.performReincarnation()) {
    throw StateError('제2환생 실행 실패!');
  }
  stdout.writeln(
    '=== [3단계] 제2환생 완료! (reincarnationCount=${p.reincarnationCount} · 난이도 ×${p.reincarnationDifficultyMultiplier.toStringAsFixed(0)}배 · 스테이지=${p.highestClearedGlobalStage}/100 · 초월단련=${p.transcendenceLevel}단) ===',
  );
  savedMilestones['cycle2_just_reincarnated_1_1'] = p.exportBackupCode();

  configureOptimalLoadout(p, st11);
  final c2s1 = playAsActiveHuman(
    p: p,
    stage: st11,
    difficulty: DefenseDifficulty.normal,
    seed: 299901,
  );
  if (!c2s1.victory) {
    stderr.writeln('실패: 제2환생(×9배) 1-1 보통 개막전 돌파 실패!');
    exit(5);
  }
  final roundTrip = PlayerProgress.tryDecodeBackupCode(p.exportBackupCode());
  if (roundTrip == null ||
      roundTrip.reincarnationCount != 2 ||
      roundTrip.reincarnationDifficultyMultiplier != 9.0) {
    throw StateError('제2환생 SUHO1 백업 복원 무결성 실패!');
  }
  stdout.writeln('  ✓ 제2환생(×9배) 1-1 수호 승리 및 SUHO1 백업 부호 무손실 복원 검증 완료!');

  if (outSavePath.isNotEmpty) {
    File(outSavePath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(savedMilestones),
    );
    stdout.writeln('  ✓ 검증 마일스톤 SUHO1 저장 완료: $outSavePath');
  }
  stdout.writeln('=== 전 구간 다회차 환생 & <5% 최종 보스전 검증 100% 통과! ===');
}
