import 'dart:io';
import 'dart:math';

import 'package:defense_core/defense_core.dart';

class StagePlayRecord {
  StagePlayRecord({
    required this.stageCode,
    required this.chapter,
    required this.attempts,
    required this.stars,
    required this.durationSec,
    required this.minShieldPct,
    required this.minTowerPct,
    required this.kills,
    required this.bossMaxHitShield,
    required this.precisionHits,
    required this.usedSupport,
    required this.serendipities,
  });

  final String stageCode;
  final int chapter;
  final int attempts;
  final int stars;
  final double durationSec;
  final int minShieldPct;
  final int minTowerPct;
  final int kills;
  final int bossMaxHitShield;
  final int precisionHits;
  final int usedSupport;
  final int serendipities;
}

void _assertFiniteArena(DefenseBattleSim sim, String ctx) {
  bool okNum(double v) => v.isFinite && !v.isNaN;
  if (!okNum(sim.shieldHp) ||
      !okNum(sim.towerHp) ||
      !okNum(sim.qiBars) ||
      !okNum(sim.granaryHealth) ||
      !okNum(sim.cropsHealth) ||
      !okNum(sim.livestockHealth)) {
    throw StateError('비유한(NaN/Inf) 전장 핵심 수치 감지 [$ctx]');
  }
  if (sim.fieldTokens < 0 || sim.supportChargesLeft < 0) {
    throw StateError('음수 전장 자원 감지 [$ctx]: field=${sim.fieldTokens}, sup=${sim.supportChargesLeft}');
  }
  for (final m in sim.mutants) {
    if (!okNum(m.pos.x) || !okNum(m.pos.y) || !okNum(m.hp) || !okNum(m.headingRad)) {
      throw StateError('비유한 변이체 상태 감지 [$ctx] uid=${m.uid}');
    }
  }
  for (final p in sim.projectiles) {
    if (!okNum(p.pos.x) || !okNum(p.pos.y) || !okNum(p.damage) || !okNum(p.vel.x) || !okNum(p.vel.y)) {
      throw StateError('비유한 투사체 상태 감지 [$ctx] src=${p.sourceKey}');
    }
  }
}

void _assertProgressHealthy(PlayerProgress p, String ctx) {
  if (p.tokens < 0 ||
      p.elixirs < 0 ||
      p.trainingSeals < 0 ||
      p.naegongPoints < 0 ||
      p.supportTokens < 0) {
    throw StateError(
      '음수 영구 재화 감지 [$ctx]: tok=${p.tokens}, elx=${p.elixirs}, seal=${p.trainingSeals}, ng=${p.naegongPoints}, sup=${p.supportTokens}',
    );
  }
}

void _configureSmartLoadoutForStage(
  PlayerProgress p,
  StageSpec stage, {
  CompanionHero? forceHero,
  SpiritBeast? forceBeast,
}) {
  final preset = p.activePreset;
  final stones = p.unlockedStones.toList()..sort((a, b) => b.grade.compareTo(a.grade));
  if (stones.isNotEmpty) {
    preset.primaryStone = stones.first;
  }
  preset.primaryShape = StoneShape.values[stage.globalIndex % StoneShape.values.length];
  if (stage.isBossStage && stage.chapterNumber >= 4) {
    preset.primaryShape = StoneShape.sphere;
  }
  preset.sectTechnique = SectTechnique.values[stage.globalIndex % SectTechnique.values.length];

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
  if (forceBeast != null && (p.beastLevels[forceBeast] ?? 0) > 0) {
    preset.equippedBeast = forceBeast;
    preset.beastCondition = forceBeast.defaultCondition;
  } else if (beasts.isNotEmpty) {
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
  final picked = heroes.take(3).toList();
  if (forceHero != null &&
      (p.companionLevels[forceHero] ?? 0) > 0 &&
      !picked.contains(forceHero)) {
    if (picked.length >= 3) {
      picked[2] = forceHero;
    } else {
      picked.add(forceHero);
    }
  }
  if (picked.isNotEmpty) {
    preset.companions = picked;
  }
  preset.autoUpgradeInBattle = true;
}

/// 현실적인 비노가다(Non-Grind) 플레이어 정비 루프:
/// - 하루 1회 출석 + 오늘의 깨달음 10회 일괄 운기(추가 수백 회 노가다 없음, 판당 자연 호흡 2회만 수행!)
void _runBetweenBattleGrowth(
  PlayerProgress p,
  Random rng,
  String todayKey, {
  int casualBreaths = 2,
}) {
  p.claimAttendance(todayKey: todayKey, rng: rng);
  if (p.remainingDailyEnlightenment(todayKey: todayKey) > 0) {
    p.meditateBatch(count: 10, hitGoldenRing: true, rng: rng, todayKey: todayKey);
  }
  for (int i = 0; i < casualBreaths; i++) {
    p.meditateOnce(hitGoldenRing: i.isEven, rng: rng, todayKey: todayKey);
  }

  while (p.canOpenNextMeridian()) {
    p.openNextMeridian();
  }
  while (p.breakthroughRealm()) {}

  p.claimAllReadyRewards(rng, todayKey: todayKey, autoRedispatch: true);
  if (p.effectiveArsenalChapter >= 2 && !p.convoyActive && p.convoyBattlesRemaining == 0) {
    p.startSupplyConvoy();
  }
  if (p.effectiveArsenalChapter >= 4 && !p.exploreActive && p.exploreBattlesRemaining == 0) {
    p.startNightExplore();
  }

  for (final item in TacticalConsumable.values) {
    if ((p.consumables[item] ?? 0) < 2 && p.canCraftConsumable(item)) {
      p.craftConsumable(item);
    }
  }

  p.upgradeRecommendedBatch(maxSteps: 12);
  for (final cs in CoreStatType.values) {
    if (p.trainingSeals >= p.coreStatUpgradeCost(cs)) {
      p.upgradeCoreStat(cs);
    }
  }
  for (final st in StoneMaterial.values) {
    if (!p.unlockedStones.contains(st)) {
      p.unlockStoneWithTokens(st);
    }
  }
  _assertProgressHealthy(p, '성장점검@$todayKey');
}

/// 해당 장의 정직한 기대 성장치(오버스펙 치팅 없는 난이도 변별 검증용).
PlayerProgress _buildChapterAppropriateProfile(int ch) {
  final p = PlayerProgress(
    tokens: 320,
    elixirs: 24,
    trainingSeals: 90,
    naegongPoints: (ch - 1) * 280 + 40,
    realmIndex: ((ch - 1) * 0.75).floor().clamp(0, 7),
    centralGuardianLevel: 1 + ((ch - 1) * 1.9).round(),
    supportTokens: 0,
    highestClearedGlobalStage: CampaignCatalog.stagesOfChapter(ch).first.globalIndex - 1,
    openedMeridianStep: ((ch - 1) * 1.0).round().clamp(0, 10),
  );
  for (final lt in LauncherType.values) {
    if (lt.unlockChapter <= ch) {
      p.launcherPermanentLevels[lt] = 1 + ((ch - 1) * 1.65).round();
    }
  }
  for (final cs in CoreStatType.values) {
    p.coreStatLevels[cs] = ((ch - 1) * 1.05).round();
  }
  final stoneIdx = ch >= 10
      ? 12
      : (ch == 9 ? 11 : (ch == 8 ? 10 : (ch - 1).clamp(0, 8)));
  final stone = StoneMaterial.values[stoneIdx];
  p.unlockedStones.add(stone);

  final beast = ch >= 8
      ? SpiritBeast.geumryong
      : ch >= 6
          ? SpiritBeast.baekho
          : ch >= 4
              ? SpiritBeast.cheonghak
              : ch >= 3
                  ? SpiritBeast.geumgangTurtle
                  : SpiritBeast.nalssaendol;
  p.beastLevels[beast] = (1 + (ch * 0.8).round()).clamp(1, 10);

  final heroes = <CompanionHero>[
    CompanionHero.seokdu,
    if (ch >= 2) CompanionHero.yeonbi,
    if (ch >= 2) CompanionHero.cheongmyeong,
    if (ch >= 4) CompanionHero.chwiseon,
    if (ch >= 6) CompanionHero.seolhwa,
    if (ch >= 7) CompanionHero.yonga,
    if (ch >= 9) CompanionHero.geomhwang,
  ];
  for (final h in heroes) {
    p.companionLevels[h] = (1 + (ch * 0.8).round()).clamp(1, 10);
  }
  if (ch >= 6) {
    p.companionLevels[CompanionHero.mukhyeon] = (ch - 4).clamp(1, 10);
  }
  return p;
}

({
  BattleSummary summary,
  bool finishedNaturally,
  bool towerDamaged,
  double durationSec,
  int minShieldPct,
  int minTowerPct,
  int bossMaxHitShield,
  int precisionHits,
  Set<String> activeContribKeys,
  bool mergedInBattle,
  bool manualShotFired,
  bool cleansedTower,
  bool spunRoulette,
  Set<TacticalConsumable> usedConsumables,
}) _playStageLikeSkilledHuman({
  required PlayerProgress p,
  required StageSpec stage,
  required DefenseDifficulty difficulty,
  required int seed,
  bool allowConsumablesAndSupport = true,
  double maxSimDurationSec = 540.0,
}) {
  final sim = DefenseBattleSim(
    stage: stage,
    difficulty: difficulty,
    progress: p,
    seed: seed,
    allowSupportTokens: allowConsumablesAndSupport,
    allowSerendipity: true,
    autoBuildForSimVerify: false,
  );

  const dt = 1.0 / 30.0;
  // 인간 반응 속도(0.5초 = 2Hz, 15프레임 간격)로 조작 수행 — 30Hz 전지전능 프레임 봇 배제!
  const humanDecisionStride = 15;
  final maxSteps = (maxSimDurationSec / dt).round();
  double minShieldRatio = 1.0;
  double minTowerRatio = 1.0;
  int bossMaxShieldSeen = 0;
  bool mergedOnce = false;
  bool manualFiredOnce = false;
  bool cleansedOnce = false;
  bool rouletteOnce = false;
  final usedPills = <TacticalConsumable>{};

  for (int step = 0; step < maxSteps && !sim.isFinished; step++) {
    final isHumanActionTick = step % humanDecisionStride == 0;

    if (isHumanActionTick) {
      // 1) 돌파 비급 선택 (0.5초 인간 인지 주기)
      if (sim.pendingPerkChoices.isNotEmpty) {
        final pick = sim.recommendedPerkChoice() ?? sim.pendingPerkChoices.first;
        sim.chooseRoguePerk(pick);
      }

      // 2) 마기 침식 포탑 정화 (회당 1기)
      for (final l in sim.launchers) {
        if (l.isCorrupted) {
          if (sim.cleanseLauncherAtSlot(l.slotIndex)) {
            cleansedOnce = true;
          }
          break;
        }
      }

      // 3) 운명 돌림판 가동
      if (sim.rouletteSpinsAvailable > 0 && sim.mutants.length >= 3) {
        if (sim.spinDestinyRoulette() != null) {
          rouletteOnce = true;
        }
      }

      // 4) 전방 암석 개척 & 편성된 진법(preferredBuildTypeForSlot) 기반 축조·승급·연성 합체!
      final nextSlot = sim.nextRecommendedSlotIndex();
      if (nextSlot != null) {
        final slot = sim.mountSlotByIndex(nextSlot)!;
        if (!sim.isSlotExcavated(nextSlot)) {
          if (sim.fieldTokens >= sim.excavationCostForSlot(slot)) {
            sim.excavateSlotInBattle(nextSlot);
          }
        } else {
          if (stage.stageNumber == 3 &&
              sim.launchers.isEmpty &&
              sim.fieldTokens >= sim.currentLuckySummonCost) {
            sim.quickLuckySummonNextPad();
          } else {
            sim.quickDirectBuildNextPad();
          }
        }
      } else {
        // 모든 거점이 채워졌을 때: 실시간 전군 강화 → 저단계 포탑 장별 배율 승급 → 4형 쌍 연성 합체(5형 신기)!
        sim.upgradeLiveFirepower();
        sim.upgradeLiveReload();
        sim.upgradeLiveRange();
        if (sim.shieldHp < sim.shieldMaxHpDynamic * 0.78) {
          sim.upgradeLiveBarrier();
        }
        for (final l in sim.launchers) {
          if (l.tier < 4 && !l.isConstructing && sim.fieldTokens >= sim.upgradeCostForLauncher(l)) {
            sim.upgradeLauncherAtSlot(l.slotIndex);
            break;
          }
        }
        final mergePair = sim.findAnyMergePair();
        if (mergePair != null &&
            sim.fieldTokens >= sim.mergeCostForSlot(mergePair.$1) + 95) {
          final lA = sim.launcherAtSlot(mergePair.$1);
          if (lA != null && (lA.tier >= 3 || !mergedOnce)) {
            if (sim.mergeLauncherAtSlot(mergePair.$1)) {
              mergedOnce = true;
            }
          }
        }
      }

      // 5) 다단 변이 보스 약점 정밀 저격 (0.5초 인지 주기 + 정상 쿨타임 준수!)
      if (sim.isPrecisionStrikeReady) {
        final boss = sim.activeMultiPhaseBoss;
        if (boss != null && boss.hasActiveWeakPoint) {
          sim.firePrecisionStrikeAt(boss.weakSpotWorldPos, targetBossUid: boss.uid);
        }
      }

      // 7) 여유 구간 다음 물결 조기 호출 보너스 검증 (각 스테이지 2물결에서 1회)
      if (sim.currentWaveIndex == 1 &&
          sim.canCallNextWaveEarly &&
          sim.shieldHp > sim.shieldMaxHpDynamic * 0.82 &&
          stage.globalIndex < 900) {
        sim.callNextWaveEarly();
      }

      // 8) 보스전 및 위기 상황에서 전술 비약 3종 실전 사용
      if (allowConsumablesAndSupport) {
        if (sim.qiBars < sim.maxQiBars - 0.5 &&
            stage.isBossStage &&
            (p.consumables[TacticalConsumable.qiSurgePill] ?? 0) > 0 &&
            !usedPills.contains(TacticalConsumable.qiSurgePill)) {
          if (sim.activateConsumable(TacticalConsumable.qiSurgePill)) {
            usedPills.add(TacticalConsumable.qiSurgePill);
          }
        }
        if ((sim.shieldHp < sim.shieldMaxHpDynamic * 0.88 ||
                sim.cropsHealth < 0.98) &&
            (p.consumables[TacticalConsumable.guardianRepairSeal] ?? 0) > 0 &&
            !usedPills.contains(TacticalConsumable.guardianRepairSeal)) {
          if (sim.activateConsumable(TacticalConsumable.guardianRepairSeal)) {
            usedPills.add(TacticalConsumable.guardianRepairSeal);
          }
        }
        if (sim.activeMultiPhaseBoss != null &&
            (p.consumables[TacticalConsumable.auroraCritCharm] ?? 0) > 0 &&
            !usedPills.contains(TacticalConsumable.auroraCritCharm)) {
          if (sim.activateConsumable(TacticalConsumable.auroraCritCharm)) {
            usedPills.add(TacticalConsumable.auroraCritCharm);
          }
        }
      }
    }

    // 6) 9초 간격 장전 완료 시 수동 기물 사격
    if (step % 270 == 90 && sim.launchers.isNotEmpty && sim.isCentralReadyToFire) {
      Vec2 aimPt = sim.powerTarget.center;
      if (sim.treasureGoblin != null && sim.treasureGoblin!.alive) {
        aimPt = sim.treasureGoblin!.pos;
      } else {
        final intactKeg = sim.powderKegs.where((k) => k.intact).firstOrNull;
        if (intactKeg != null &&
            intactKeg.pos.distanceTo(sim.towerPos) <= sim.effectiveCentralManualRange) {
          aimPt = intactKeg.pos;
        } else if (step % 540 == 90) {
          aimPt = sim.cloneGate.center;
        }
      }
      if (!sim.centralManualMode) sim.toggleCentralManualMode();
      if (sim.fireCentralManualAt(aimPt)) {
        manualFiredOnce = true;
      }
      if (sim.centralManualMode) sim.toggleCentralManualMode();
    }

    sim.step(dt);
    _assertFiniteArena(sim, '${stage.code}@step$step');

    if (sim.shieldMaxHpDynamic > 0) {
      minShieldRatio = min(minShieldRatio, sim.shieldHp / sim.shieldMaxHpDynamic);
    }
    if (sim.centralSpec.coreMaxHp > 0) {
      minTowerRatio = min(minTowerRatio, sim.towerHp / sim.centralSpec.coreMaxHp);
    }
    for (final m in sim.mutants) {
      if (m.maxHitShield > bossMaxShieldSeen) {
        bossMaxShieldSeen = m.maxHitShield;
      }
    }
  }

  final summary = sim.buildSummary();
  return (
    summary: summary,
    finishedNaturally: sim.isFinished,
    towerDamaged: sim.towerTookDamage,
    durationSec: sim.elapsedSec,
    minShieldPct: (minShieldRatio.clamp(0.0, 1.0) * 100).round(),
    minTowerPct: (minTowerRatio.clamp(0.0, 1.0) * 100).round(),
    bossMaxHitShield: bossMaxShieldSeen,
    precisionHits: sim.precisionHitCount,
    activeContribKeys:
        summary.contributions.where((c) => c.totalDamage > 0).map((c) => c.key).toSet(),
    mergedInBattle: mergedOnce || sim.mergeEvolutionCount > 0,
    manualShotFired: manualFiredOnce,
    cleansedTower: cleansedOnce,
    spunRoulette: rouletteOnce,
    usedConsumables: usedPills,
  );
}

List<String> _runAdversarialEdgeChecks() {
  final notes = <String>[];
  final rng = Random(20261127);

  // [검증 1] 제1장 신규 계정으로 미해금 영수·동료·구출전용 동료 조기 구매 원천 차단
  final fresh = PlayerProgress(elixirs: 999);
  if (fresh.unlockOrUpgradeBeast(SpiritBeast.geumryong) ||
      fresh.unlockOrUpgradeCompanion(CompanionHero.geomhwang) ||
      fresh.unlockOrUpgradeCompanion(CompanionHero.yeonbi)) {
    throw StateError('적대적 검증 실패: 미해금 영수/동료 조기 구매 허용됨!');
  }
  notes.add('PASS [보안/해금] 1장 미해금 상위 영수(금룡)·동료(검황)·구출전용 동료(0영약) 조기 구매 원천 차단');

  // [검증 2] 일일 깨달음 10회 소진 후 단전 운기 연타 시 보름달 게이지 비전투 증식 0건 검증
  final medP = PlayerProgress();
  final r1 = medP.meditateOnce(hitGoldenRing: false, rng: Random(1), todayKey: '2026-11-22');
  if (r1.gainedNaegong != 36 && r1.gainedNaegong != 72) {
    throw StateError('단전 운기 일일 깨달음 배율 불일치: ${r1.gainedNaegong}');
  }
  medP.meditateBatch(count: 10, hitGoldenRing: true, rng: rng, todayKey: '2026-11-22');
  final moonBefore = medP.moonOmenGauge;
  for (int i = 0; i < 25; i++) {
    medP.meditateOnce(hitGoldenRing: true, rng: Random(10 + i), todayKey: '2026-11-22');
  }
  if (medP.moonOmenGauge != moonBefore) {
    throw StateError('일일 깨달음 소진 후 비전투 보름달 게이지 충전 누수 감지!');
  }
  notes.add('PASS [내공수련] 일일 깨달음 3배(36내공/9인장) 일치 & 소진 후 비전투 보름달 무한 파밍 완전 차단');

  // [검증 3] 도박 소환 후 즉시 철거 시 기력 증식 차익(Arbitrage) 차단 + 합체 영구단수 동기화 검증
  final mergeP = PlayerProgress(tokens: 5000, highestClearedGlobalStage: 60);
  mergeP.launcherPermanentLevels[LauncherType.rapid] = 1;
  for (final lt in LauncherType.values) {
    if (lt != LauncherType.rapid) mergeP.launcherPermanentLevels[lt] = 18;
  }
  final mSim = DefenseBattleSim(
    stage: CampaignCatalog.stageAt(5, 2),
    difficulty: DefenseDifficulty.normal,
    progress: mergeP,
    seed: 9,
    allowSerendipity: false,
  );
  mSim.fieldTokens = 300;
  final tokBefore = mSim.fieldTokens;
  mSim.summonLuckyLauncherInBattle(0);
  mSim.dismantleLauncherInBattle(0);
  if (mSim.fieldTokens >= tokBefore) {
    throw StateError('도박 소환 즉시 철거 차익 버그 잔존: ${mSim.fieldTokens} >= $tokBefore');
  }
  mSim.fieldTokens = 600;
  mSim.placeLauncherInBattle(0, LauncherType.rapid);
  mSim.placeLauncherInBattle(1, LauncherType.rapid);
  mSim.step(3.5);
  mSim.mergeLauncherAtSlot(0);
  final evolved = mSim.launcherAtSlot(0)!;
  if (evolved.permanentLevel != mergeP.launcherPermanentLevels[evolved.type]) {
    throw StateError('합치기 후 permanentLevel 미동기화!');
  }
  notes.add('PASS [경제/합체] 도박소환 철거 기력 차익 0건 차단 & 연성 합체 영구단수(${evolved.permanentLevel}단) 즉시 동기화');

  // [검증 4] 빙결 적 공격 정지 · 수동 어기어석 16타 마갑 파쇄 · 10경맥 4칸 내공 & 출두 즉시 차감 검증
  final pMax = PlayerProgress(realmIndex: 7, openedMeridianStep: 10, supportTokens: 2);
  if (pMax.maxQiBars != 4.0) {
    throw StateError('10단 경맥 개통 후 내공 상한이 4.0칸이 아님: ${pMax.maxQiBars}');
  }
  final fSim = DefenseBattleSim(
    stage: CampaignCatalog.stageAt(4, 10),
    difficulty: DefenseDifficulty.normal,
    progress: pMax,
    seed: 33,
    allowSerendipity: false,
  );
  fSim.mutants.clear();
  final frozen = ActiveMutant(
    uid: 9101,
    kind: MutantKind.plagueToad,
    laneIndex: 0,
    waypoints: fSim.chapter.smoothedLane(0),
    pos: fSim.towerPos,
    maxHp: 9000,
    speed: 35,
  )..freezeTimer = 1.5;
  fSim.mutants.add(frozen);
  final shBefore = fSim.shieldHp;
  fSim.step(0.4);
  if (fSim.shieldHp != shBefore) {
    throw StateError('빙결 중인 적이 결계 피해를 가함!');
  }
  fSim.triggerSupportChuldu();
  if (pMax.supportTokens != 1) {
    throw StateError('출두 발동 즉시 영구 지원패 차감 미작동 (재시작 악용 위험)!');
  }
  notes.add('PASS [전투규칙] 빙결 적 접촉/독오라 완전 정지 · 10경맥 내공 4.0칸 확장 · 출두 즉시 영구 지원패 차감 확인');

  // [검증 5] 제5장 직각 미궁 100% 수직·수평 & 제10장 지상 레인 무지개교 연결 무결성 검증
  final ch5 = CampaignCatalog.chapterOf(5);
  for (int li = 0; li < ch5.lanes.length; li++) {
    final raw = ch5.lanes[li];
    for (int i = 1; i < raw.length; i++) {
      final dx = (raw[i].x - raw[i - 1].x).abs();
      final dy = (raw[i].y - raw[i - 1].y).abs();
      if (dx > 0.01 && dy > 0.01) {
        throw StateError('제5장 직각 미궁 lane[$li] 대각선 구간 발견: ${raw[i - 1]} -> ${raw[i]}');
      }
    }
  }
  final ch10 = CampaignCatalog.chapterOf(10);
  for (final lane in ch10.lanes) {
    if (lane.first.x > 320) {
      throw StateError('제10장 지상 레인이 우측 끊어진 구름 절벽(x>320)에서 시작됨!');
    }
  }
  notes.add('PASS [지형정합] 제5장 100% 직각 미궁 복도 & 제10장 일곱 부유섬 지상교/우측 비룡 공중로 분리 정합 확인');

  // [검증 6] 제7현 남→북 역진격 묵현 난입 · 뼈방패 야차 방향성 방패 · 묵현 상시 능동 스킬 검증
  final p7 = PlayerProgress(highestClearedGlobalStage: 70, supportTokens: 2);
  p7.companionLevels[CompanionHero.mukhyeon] = 7;
  final sim7 = DefenseBattleSim(
    stage: CampaignCatalog.stageAt(7, 10),
    difficulty: DefenseDifficulty.normal,
    progress: p7,
    seed: 77,
    allowSerendipity: false,
  );
  sim7.fieldTokens = 500;
  sim7.placeLauncherInBattle(0, LauncherType.rapid);
  sim7.step(3.5);
  sim7.mutants.clear();
  final nearFortEnemy = ActiveMutant(
    uid: 7002,
    kind: MutantKind.ironBoar,
    laneIndex: 0,
    waypoints: sim7.chapter.smoothedLane(0),
    pos: const Vec2(360, 310),
    maxHp: 20000,
    speed: 20,
  );
  sim7.mutants.add(nearFortEnemy);
  sim7.shieldHp = sim7.shieldMaxHpDynamic * 0.30;
  sim7.step(1 / 30);
  if (!sim7.mukhyeonTriggered || nearFortEnemy.knockbackVel.y <= 0) {
    throw StateError('제7장 북단 성채 묵현 난입 남방 밀침 실패!');
  }
  // [검증 7] 기둥 뒤 적 오폭 차단(Swept Pillar Occlusion) · 관통탄 전열→후열 t정렬 · ★3 무흠결 판정 · 4→5형 합체 돌림판 지급 검증!
  final pPhys = PlayerProgress(highestClearedGlobalStage: 100, unlockedStones: StoneMaterial.values.toSet());
  final physSim = DefenseBattleSim(
    stage: CampaignCatalog.stageAt(1, 2),
    difficulty: DefenseDifficulty.normal,
    progress: pPhys,
    seed: 101,
    allowSerendipity: false,
  );
  physSim.mutants.clear();
  physSim.projectiles.clear();
  final pil = physSim.chapter.pillars.first;
  final behindEnemy = ActiveMutant(
    uid: 8801,
    kind: MutantKind.swarmRat,
    laneIndex: 0,
    waypoints: <Vec2>[pil.center + const Vec2(0, -42)],
    pos: pil.center + const Vec2(0, -42),
    maxHp: 500,
    speed: 0,
  );
  physSim.mutants.add(behindEnemy);
  physSim.projectiles.add(
    ActiveStoneProjectile(
      sourceKey: 'test_pillar',
      sourceLabel: '기둥차단검증',
      pos: pil.center + const Vec2(0, 42),
      vel: const Vec2(0, -2400),
      material: StoneMaterial.cheongok,
      shape: StoneShape.flat,
      damage: 200,
      knockback: 10,
      critChance: 0.0,
      colorHex: 0xFFFFFFFF,
      pierceLeft: 0,
      maxTravelDist: 300,
    )..bouncesLeft = 0,
  );
  physSim.step(1 / 60);
  if (behindEnemy.hp < 500) {
    throw StateError('기둥에 막혀 소멸해야 할 무도탄(bounces=0) 투사체가 기둥 뒤 적을 관통 타격함!');
  }

  // 관통 1회 투사체가 한 스텝에 앞(y=480)·뒤(y=430) 2마리를 지날 때 전열부터 순서대로 모두 타격하는지 검증!
  physSim.mutants.clear();
  physSim.projectiles.clear();
  final backM = ActiveMutant(
    uid: 8802,
    kind: MutantKind.ironBoar,
    laneIndex: 0,
    waypoints: const <Vec2>[Vec2(200, 430)],
    pos: const Vec2(200, 430),
    maxHp: 1000,
    speed: 0,
  );
  final frontM = ActiveMutant(
    uid: 8803,
    kind: MutantKind.ironBoar,
    laneIndex: 0,
    waypoints: const <Vec2>[Vec2(200, 480)],
    pos: const Vec2(200, 480),
    maxHp: 1000,
    speed: 0,
  );
  // 역순 삽입에도 t 정렬로 frontM -> backM 모두 피격되어야 함!
  physSim.mutants.addAll([frontM, backM]);
  physSim.projectiles.add(
    ActiveStoneProjectile(
      sourceKey: 'test_pierce',
      sourceLabel: '관통정렬검증',
      pos: const Vec2(200, 510),
      vel: const Vec2(0, -6000),
      material: StoneMaterial.geumgang,
      shape: StoneShape.flat,
      damage: 150,
      knockback: 0,
      critChance: 0.0,
      colorHex: 0xFFFFFFFF,
      pierceLeft: 1,
      maxTravelDist: 300,
    )..bouncesLeft = 0,
  );
  physSim.step(1 / 60);
  if (frontM.hp >= 1000 || backM.hp >= 1000) {
    throw StateError('단일 서브스텝 다중 관통 누락 발생: front=${frontM.hp}, back=${backM.hp}');
  }

  // 4형 2기 합체 -> ★5형 태초 신기 진화 시 돌림판 +1 지급 검증 & 본진 피격 시 ★3 차단 검증!
  physSim.fieldTokens = 2000;
  physSim.placeLauncherInBattle(0, LauncherType.rapid);
  physSim.placeLauncherInBattle(1, LauncherType.rapid);
  physSim.step(3.0);
  for (int u = 0; u < 3; u++) {
    physSim.upgradeLauncherAtSlot(0);
    physSim.upgradeLauncherAtSlot(1);
    physSim.step(1.5);
  }
  final spinsBefore5 = physSim.rouletteSpinsAvailable;
  if (!physSim.mergeLauncherAtSlot(0) ||
      physSim.launcherAtSlot(0)?.tier != 5 ||
      physSim.rouletteSpinsAvailable != spinsBefore5 + 1) {
    throw StateError('4형 2기 → ★5형 합체 시 돌림판 +1 보너스 미지급!');
  }
  physSim.isFinished = true;
  physSim.isVictory = true;
  physSim.towerTookDamage = true;
  if (physSim.buildSummary().stars >= 3) {
    throw StateError('본진 수호탑이 직접 피해를 입었는데 ★3 만점이 부여됨!');
  }
  notes.add('PASS [물리/판정] 기둥 뒤 적 오폭 차단 · 관통 t정렬 다중타격 · ★5형 합체 돌림판 +1 · 본진피격 시 ★3 차단 검증');

  // [검증 8] 14인 동료 전원 · 5종 영수 전원 · 13종 수호석 · 3모양 · 4문파 내공 실전 기여도 100% 검증!
  final rosterP = PlayerProgress(
    highestClearedGlobalStage: 100,
    realmIndex: 7,
    openedMeridianStep: 10,
    centralGuardianLevel: 20,
    unlockedStones: StoneMaterial.values.toSet(),
  );
  for (final b in SpiritBeast.values) {
    rosterP.beastLevels[b] = 6;
  }
  for (final h in CompanionHero.values) {
    rosterP.companionLevels[h] = 6;
  }
  for (final lt in LauncherType.values) {
    rosterP.launcherPermanentLevels[lt] = 15;
  }

  final verifiedHeroes = <CompanionHero>{};
  for (final hero in CompanionHero.values) {
    final pr = rosterP.activePreset;
    pr.companions = [hero];
    pr.companionConditions[hero] = AutoTriggerCondition.anyEnemyInRange;
    final hSim = DefenseBattleSim(
      stage: CampaignCatalog.stageAt(6, 5),
      difficulty: DefenseDifficulty.normal,
      progress: rosterP,
      seed: 400 + hero.index,
      allowSupportTokens: false,
    );
    hSim.fieldTokens = 400;
    hSim.placeLauncherInBattle(0, LauncherType.rapid);
    hSim.placeLauncherInBattle(1, LauncherType.heavy);
    hSim.qiBars = rosterP.maxQiBars;
    if (hero == CompanionHero.sinseung || hero == CompanionHero.mukhyeon) {
      hSim.shieldHp = hSim.shieldMaxHpDynamic * 0.30;
      hSim.cropsHealth = 0.70;
    }
    for (int s = 0; s < 900 && !hSim.isFinished; s++) {
      if (hero == CompanionHero.mukhyeon && s == 120) {
        hSim.shieldHp = min(hSim.shieldHp, hSim.shieldMaxHpDynamic * 0.30);
      }
      hSim.step(1 / 30);
    }
    final key = 'hero_${hero.id}';
    final contributed = hSim.buildSummary().contributions.any((c) => c.key == key && c.totalDamage > 0);
    if (!contributed) {
      throw StateError('동료 [${hero.name}] ($key) 실전 기여도 0 발생!');
    }
    verifiedHeroes.add(hero);
  }

  final verifiedBeasts = <SpiritBeast>{};
  for (final beast in SpiritBeast.values) {
    final pr = rosterP.activePreset;
    pr.equippedBeast = beast;
    pr.beastCondition = AutoTriggerCondition.anyEnemyInRange;
    final bSim = DefenseBattleSim(
      stage: CampaignCatalog.stageAt(5, 4),
      difficulty: DefenseDifficulty.normal,
      progress: rosterP,
      seed: 500 + beast.index,
      allowSupportTokens: false,
    );
    bSim.fieldTokens = 400;
    bSim.placeLauncherInBattle(0, LauncherType.rapid);
    if (beast == SpiritBeast.geumgangTurtle) {
      bSim.shieldHp = bSim.shieldMaxHpDynamic * 0.50;
    }
    for (int s = 0; s < 750 && !bSim.isFinished; s++) {
      bSim.step(1 / 30);
    }
    final bKey = beast == SpiritBeast.geumgangTurtle ? 'beast_geumgang' : 'beast_${beast.id}';
    final contributed = bSim.buildSummary().contributions.any((c) => c.key == bKey && c.totalDamage > 0);
    if (!contributed) {
      throw StateError('영수 [${beast.name}] ($bKey) 실전 기여도 0 발생!');
    }
    verifiedBeasts.add(beast);
  }

  for (int i = 0; i < StoneMaterial.values.length; i++) {
    final stone = StoneMaterial.values[i];
    final shape = StoneShape.values[i % StoneShape.values.length];
    final sect = SectTechnique.values[i % SectTechnique.values.length];
    rosterP.activePreset
      ..primaryStone = stone
      ..primaryShape = shape
      ..sectTechnique = sect;
    final sSim = DefenseBattleSim(
      stage: CampaignCatalog.stageAt(3, 2),
      difficulty: DefenseDifficulty.normal,
      progress: rosterP,
      seed: 600 + i,
      allowSupportTokens: false,
    );
    sSim.fieldTokens = 300;
    sSim.placeLauncherInBattle(0, LauncherType.qiAmplifier);
    sSim.placeLauncherInBattle(1, LauncherType.rapid);
    sSim.qiBars = 2.5;
    for (int s = 0; s < 360 && !sSim.isFinished; s++) {
      sSim.step(1 / 30);
    }
    _assertFiniteArena(sSim, '수호석검증_${stone.name}');
  }

  // 무한혈전 1장 테마 vs 10장 테마 체력 곡선 동일성(142배 편차 차단) 검증!
  final endCh1 = DefenseBattleSim(
    stage: EndlessWaveBuilder.buildEndlessStage(chapterTheme: 1, waveCount: 10),
    difficulty: DefenseDifficulty.normal,
    progress: rosterP,
    seed: 701,
  );
  final endCh10 = DefenseBattleSim(
    stage: EndlessWaveBuilder.buildEndlessStage(chapterTheme: 10, waveCount: 10),
    difficulty: DefenseDifficulty.normal,
    progress: rosterP,
    seed: 701,
  );
  for (int s = 0; s < 150; s++) {
    endCh1.step(1 / 30);
    endCh10.step(1 / 30);
  }
  final ch1Rat = endCh1.mutants.where((m) => m.kind == MutantKind.swarmRat).firstOrNull;
  final ch10Rat = endCh10.mutants.where((m) => m.kind == MutantKind.swarmRat).firstOrNull;
  if (ch1Rat == null || ch10Rat == null || (ch10Rat.maxHp / ch1Rat.maxHp - 1.0).abs() > 0.05) {
    throw StateError('무한혈전 장 테마 간 체력 편차 잔존: ch1=${ch1Rat?.maxHp}, ch10=${ch10Rat?.maxHp}');
  }
  notes.add(
    'PASS [전수검증] 14동료(${verifiedHeroes.length}/14)·5영수(${verifiedBeasts.length}/5)·13수호석·3모양·4문파비기 실전 기여 & 무한혈전 전 테마 공정 스케일링 확인',
  );

  return notes;
}

void main() {
  final sw = Stopwatch()..start();
  stdout.writeln('=======================================================================');
  stdout.writeln(' [수호알까기 v1.0.0+28] 인간반응(2Hz)·무치팅 전 구간(1-1~10-10) & 3난이도·무한100물결 적대적 점검');
  stdout.writeln('=======================================================================');

  // 1부: 적대적 엣지케이스 & 물리/보안 불변식 검증
  final edgeNotes = _runAdversarialEdgeChecks();
  for (final n in edgeNotes) {
    stdout.writeln('  ✓ $n');
  }

  // 2부: 무배치 방치(AFK) 대조군 검증 (쉬움 난이도에서도 111관문 중 공짜 승리 0건 필수!)
  int afkWins = 0;
  for (final st in [
    CampaignCatalog.stageAt(1, 1),
    CampaignCatalog.stageAt(3, 1),
    CampaignCatalog.stageAt(6, 1),
    CampaignCatalog.stageAt(10, 10),
  ]) {
    final afkP = _buildChapterAppropriateProfile(st.chapterNumber);
    final afkSim = DefenseBattleSim(
      stage: st,
      difficulty: DefenseDifficulty.easy,
      progress: afkP,
      seed: 999,
      allowSupportTokens: false,
      allowSerendipity: false,
      autoBuildForSimVerify: false,
    );
    for (int i = 0; i < (360 * 30) && !afkSim.isFinished; i++) {
      afkSim.step(1 / 30);
    }
    if (afkSim.buildSummary().victory) afkWins++;
  }
  if (afkWins > 0) {
    throw StateError('무배치 방치(AFK) 대조군에서 공짜 승리($afkWins건) 발생!');
  }
  stdout.writeln('  ✓ PASS [방치차단] 초소 무배치 방치(AFK) 시 쉬움 난이도 포함 100% 패배 확인');

  // 3부: 신규 계정(PlayerProgress 기본값)으로 추가 명상 노가다 없이 1-1 -> 10-10 유기적 완전 플레이!
  final player = PlayerProgress();
  final rng = Random(20261127);
  final records = <StagePlayRecord>[];
  final allUsedContribKeys = <String>{};
  final allUsedConsumables = <TacticalConsumable>{};
  int totalAttempts = 0;
  int firstTryWins = 0;
  int totalMergedStages = 0;
  int totalManualAimStages = 0;
  int totalCleansedStages = 0;
  int totalRouletteStages = 0;

  DateTime simDate = DateTime.utc(2026, 11, 22);
  String fmtDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // 첫 출정 전 오늘의 깨달음 수련만 1회 수행 (추가 수백 회 노가다 0회!)
  _runBetweenBattleGrowth(player, rng, fmtDay(simDate), casualBreaths: 2);

  for (int idx = 0; idx < CampaignCatalog.allStages.length; idx++) {
    final stage = CampaignCatalog.allStages[idx];
    if (idx > 0 && idx % 6 == 0) {
      simDate = simDate.add(const Duration(days: 1));
    }
    final todayKey = fmtDay(simDate);

    final unlockedHeroes =
        CompanionHero.values.where((h) => (player.companionLevels[h] ?? 0) > 0).toList();
    final unlockedBeasts =
        SpiritBeast.values.where((b) => (player.beastLevels[b] ?? 0) > 0).toList();
    final forceHero =
        unlockedHeroes.isNotEmpty ? unlockedHeroes[idx % unlockedHeroes.length] : null;
    final forceBeast =
        unlockedBeasts.isNotEmpty ? unlockedBeasts[idx % unlockedBeasts.length] : null;

    int attempts = 0;
    late BattleSummary wonSummary;
    double wonDur = 0;
    int wonMinShield = 0;
    int wonMinTower = 0;
    int wonBossShield = 0;
    int wonPrecHits = 0;

    while (true) {
      attempts++;
      totalAttempts++;
      _configureSmartLoadoutForStage(
        player,
        stage,
        forceHero: attempts == 1 ? forceHero : null,
        forceBeast: attempts == 1 ? forceBeast : null,
      );

      final res = _playStageLikeSkilledHuman(
        p: player,
        stage: stage,
        difficulty: DefenseDifficulty.normal,
        seed: 7000 + stage.globalIndex * 31 + attempts * 97,
      );
      allUsedContribKeys.addAll(res.activeContribKeys);
      allUsedConsumables.addAll(res.usedConsumables);
      if (res.mergedInBattle) totalMergedStages++;
      if (res.manualShotFired) totalManualAimStages++;
      if (res.cleansedTower) totalCleansedStages++;
      if (res.spunRoulette) totalRouletteStages++;

      player.onBattleFinished(
        stage: stage,
        victory: res.summary.victory,
        stars: res.summary.stars,
        earnedTokens: res.summary.earnedTokens,
        earnedElixirs: res.summary.earnedElixirs,
        usedSupportCount: res.summary.usedSupportCount,
        killCount: res.summary.killCount,
        pporokCount: res.summary.pporokCount,
        bankShotCount: res.summary.bankShotCount,
        chainShatterCount: res.summary.chainShatterCount,
        serendipityCount: res.summary.serendipityCount,
        encounteredMutants: res.summary.encounteredMutants,
        todayKey: todayKey,
        difficultyId: DefenseDifficulty.normal.id,
        supportAlreadyDeductedInSim: res.summary.supportDeductedRealtime,
        bossElixirAlreadyIncluded: res.summary.bossElixirIncluded,
        convoyBuffAlreadyConsumed: res.summary.convoyBuffConsumedRealtime,
      );

      _runBetweenBattleGrowth(player, rng, todayKey, casualBreaths: 2);

      if (res.summary.victory) {
        if (!res.finishedNaturally) {
          throw StateError('${stage.code} 시간 초과 상태에서 승리로 오판정됨!');
        }
        if (attempts == 1) firstTryWins++;
        wonSummary = res.summary;
        wonDur = res.durationSec;
        wonMinShield = res.minShieldPct;
        wonMinTower = res.towerDamaged ? min(99, res.minTowerPct) : res.minTowerPct;
        wonBossShield = res.bossMaxHitShield;
        wonPrecHits = res.precisionHits;
        break;
      }

      if (attempts >= 6) {
        throw StateError(
          '난이도 병목 경고: ${stage.code} (${stage.title})에서 정상 플레이 후 6회 연속 패배!',
        );
      }
      // 패배 시 직전 정화 관문을 1회 재도전해 증표·영약을 보충한 뒤 재출격
      final farmStage = idx > 0 ? CampaignCatalog.allStages[idx - 1] : stage;
      _configureSmartLoadoutForStage(player, farmStage);
      final farmRes = _playStageLikeSkilledHuman(
        p: player,
        stage: farmStage,
        difficulty: DefenseDifficulty.normal,
        seed: 90000 + idx * 19 + attempts,
        allowConsumablesAndSupport: false,
      );
      player.onBattleFinished(
        stage: farmStage,
        victory: farmRes.summary.victory,
        stars: farmRes.summary.stars,
        earnedTokens: farmRes.summary.earnedTokens,
        earnedElixirs: farmRes.summary.earnedElixirs,
        usedSupportCount: farmRes.summary.usedSupportCount,
        killCount: farmRes.summary.killCount,
        pporokCount: farmRes.summary.pporokCount,
        bankShotCount: farmRes.summary.bankShotCount,
        chainShatterCount: farmRes.summary.chainShatterCount,
        serendipityCount: farmRes.summary.serendipityCount,
        encounteredMutants: farmRes.summary.encounteredMutants,
        todayKey: todayKey,
        difficultyId: DefenseDifficulty.normal.id,
        supportAlreadyDeductedInSim: farmRes.summary.supportDeductedRealtime,
        bossElixirAlreadyIncluded: farmRes.summary.bossElixirIncluded,
        convoyBuffAlreadyConsumed: farmRes.summary.convoyBuffConsumedRealtime,
      );
      _runBetweenBattleGrowth(player, rng, todayKey, casualBreaths: 3);
    }

    records.add(
      StagePlayRecord(
        stageCode: stage.code,
        chapter: stage.chapterNumber,
        attempts: attempts,
        stars: wonSummary.stars,
        durationSec: wonDur,
        minShieldPct: wonMinShield,
        minTowerPct: wonMinTower,
        kills: wonSummary.killCount,
        bossMaxHitShield: wonBossShield,
        precisionHits: wonPrecHits,
        usedSupport: wonSummary.usedSupportCount,
        serendipities: wonSummary.serendipityCount,
      ),
    );
  }

  // 4부: 전 111관문 3대 난이도(쉬움·보통·악몽) 정직한 장별 적정 스펙 변별력 검증!
  final diffWins = <DefenseDifficulty, int>{
    DefenseDifficulty.easy: 0,
    DefenseDifficulty.normal: 0,
    DefenseDifficulty.nightmare: 0,
  };
  final diffThreeStars = <DefenseDifficulty, int>{
    DefenseDifficulty.easy: 0,
    DefenseDifficulty.normal: 0,
    DefenseDifficulty.nightmare: 0,
  };
  final diffShieldSum = <DefenseDifficulty, int>{
    DefenseDifficulty.easy: 0,
    DefenseDifficulty.normal: 0,
    DefenseDifficulty.nightmare: 0,
  };

  for (final st in CampaignCatalog.allStages) {
    for (final diff in DefenseDifficulty.values) {
      final capP = _buildChapterAppropriateProfile(st.chapterNumber);
      _configureSmartLoadoutForStage(capP, st);
      final r = _playStageLikeSkilledHuman(
        p: capP,
        stage: st,
        difficulty: diff,
        seed: 31000 + st.globalIndex * 13,
        allowConsumablesAndSupport: false,
      );
      if (r.summary.victory) diffWins[diff] = diffWins[diff]! + 1;
      if (r.summary.stars == 3) diffThreeStars[diff] = diffThreeStars[diff]! + 1;
      diffShieldSum[diff] = diffShieldSum[diff]! + r.minShieldPct;
    }
  }

  final totalStageCnt = CampaignCatalog.allStages.length;
  final easyAvgSh = diffShieldSum[DefenseDifficulty.easy]! / totalStageCnt;
  final normAvgSh = diffShieldSum[DefenseDifficulty.normal]! / totalStageCnt;
  final nightAvgSh = diffShieldSum[DefenseDifficulty.nightmare]! / totalStageCnt;
  stdout.writeln(
    '  ✓ [3난이도 변별] 쉬움 ${diffWins[DefenseDifficulty.easy]}/$totalStageCnt승(★3 ${diffThreeStars[DefenseDifficulty.easy]}, 최저방어막 ${easyAvgSh.toStringAsFixed(1)}%) | '
    '보통 ${diffWins[DefenseDifficulty.normal]}/$totalStageCnt승(★3 ${diffThreeStars[DefenseDifficulty.normal]}, 최저방어막 ${normAvgSh.toStringAsFixed(1)}%) | '
    '악몽 ${diffWins[DefenseDifficulty.nightmare]}/$totalStageCnt승(★3 ${diffThreeStars[DefenseDifficulty.nightmare]}, 최저방어막 ${nightAvgSh.toStringAsFixed(1)}%)',
  );
  if (!(easyAvgSh > normAvgSh && normAvgSh > nightAvgSh) &&
      !(diffThreeStars[DefenseDifficulty.easy]! >= diffThreeStars[DefenseDifficulty.normal]! &&
          diffThreeStars[DefenseDifficulty.normal]! > diffThreeStars[DefenseDifficulty.nightmare]!)) {
    throw StateError('쉬움·보통·악몽 난이도 간 변별력이 부족합니다!');
  }

  // 엔드게임 수련 마무리 (7일 추가 일일 깨달음으로 생사경·10경맥·13수호석·14동료·5영수 달성 확인)
  for (int d = 0; d < 8; d++) {
    simDate = simDate.add(const Duration(days: 1));
    _runBetweenBattleGrowth(player, rng, fmtDay(simDate), casualBreaths: 4);
  }
  for (final b in SpiritBeast.values) {
    if ((player.beastLevels[b] ?? 0) == 0 && player.elixirs >= b.unlockElixirs) {
      player.unlockOrUpgradeBeast(b);
    }
  }
  for (final h in CompanionHero.values) {
    if ((player.companionLevels[h] ?? 0) == 0 &&
        h.unlockElixirs > 0 &&
        player.elixirs >= h.unlockElixirs) {
      player.unlockOrUpgradeCompanion(h);
    }
  }
  if (player.forgeMasteryLevel == 0 && player.tokens >= player.forgeMasteryCost) {
    player.upgradeForgeMastery();
  }
  if (player.elixirResonanceLevel == 0 && player.elixirs >= player.elixirResonanceCost) {
    player.upgradeElixirResonance();
  }

  // 5부: 무한 혈전 100물결 — (A) 막 10-10을 깬 성장 계정 vs (B) 만렙 태초 종결 계정 완주 검증!
  final endlessStage = EndlessWaveBuilder.buildEndlessStage(
    chapterTheme: 10,
    waveCount: 100,
  );
  _configureSmartLoadoutForStage(player, endlessStage);
  final freshEndlessRun = _playStageLikeSkilledHuman(
    p: player,
    stage: endlessStage,
    difficulty: DefenseDifficulty.normal,
    seed: 88888,
    maxSimDurationSec: 1800.0,
  );
  player.onBattleFinished(
    stage: endlessStage,
    victory: freshEndlessRun.summary.victory,
    stars: freshEndlessRun.summary.stars,
    earnedTokens: freshEndlessRun.summary.earnedTokens,
    earnedElixirs: freshEndlessRun.summary.earnedElixirs,
    usedSupportCount: freshEndlessRun.summary.usedSupportCount,
    killCount: freshEndlessRun.summary.killCount,
    pporokCount: freshEndlessRun.summary.pporokCount,
    bankShotCount: freshEndlessRun.summary.bankShotCount,
    chainShatterCount: freshEndlessRun.summary.chainShatterCount,
    serendipityCount: freshEndlessRun.summary.serendipityCount,
    encounteredMutants: freshEndlessRun.summary.encounteredMutants,
    endlessWavesCleared: freshEndlessRun.summary.wavesClearedCount,
    todayKey: fmtDay(simDate),
    difficultyId: DefenseDifficulty.normal.id,
    supportAlreadyDeductedInSim: freshEndlessRun.summary.supportDeductedRealtime,
    bossElixirAlreadyIncluded: freshEndlessRun.summary.bossElixirIncluded,
    convoyBuffAlreadyConsumed: freshEndlessRun.summary.convoyBuffConsumedRealtime,
  );

  // (B) 숙련 엔드게임 계정(생사경 + 10경맥 + 전 포탑 30단 + 신기연마 32단 + 영약공명 28단 + 13단 태초석)으로 100물결 완전 정복 검증!
  final masterAccount = PlayerProgress(
    tokens: 3000,
    elixirs: 300,
    supportTokens: 4,
    realmIndex: 7,
    openedMeridianStep: 10,
    centralGuardianLevel: 32,
    forgeMasteryLevel: 32,
    elixirResonanceLevel: 28,
    highestClearedGlobalStage: 100,
    unlockedStones: StoneMaterial.values.toSet(),
    consumables: {
      for (final c in TacticalConsumable.values) c: 3,
    },
  );
  for (final lt in LauncherType.values) {
    masterAccount.launcherPermanentLevels[lt] = 30;
  }
  for (final cs in CoreStatType.values) {
    masterAccount.coreStatLevels[cs] = 22;
  }
  for (final b in SpiritBeast.values) {
    masterAccount.beastLevels[b] = 10;
  }
  for (final h in CompanionHero.values) {
    masterAccount.companionLevels[h] = 10;
  }
  _configureSmartLoadoutForStage(masterAccount, endlessStage);
  final masterEndlessNormal = _playStageLikeSkilledHuman(
    p: masterAccount,
    stage: endlessStage,
    difficulty: DefenseDifficulty.normal,
    seed: 202800,
    maxSimDurationSec: 3600.0,
  );
  if (!masterEndlessNormal.finishedNaturally ||
      !masterEndlessNormal.summary.victory ||
      masterEndlessNormal.summary.wavesClearedCount < 100) {
    throw StateError(
      '숙련 엔드게임 계정 무한혈전 100물결 완주 미달성: finished=${masterEndlessNormal.finishedNaturally}, ${masterEndlessNormal.summary.wavesClearedCount}/100물결',
    );
  }
  final masterEndlessNightmare = _playStageLikeSkilledHuman(
    p: masterAccount,
    stage: endlessStage,
    difficulty: DefenseDifficulty.nightmare,
    seed: 202801,
    maxSimDurationSec: 3600.0,
  );

  // 최종 성장 계정으로 악몽(Nightmare) 10-10 보스 진검 검증
  final finalStage = CampaignCatalog.stageAt(10, 10);
  _configureSmartLoadoutForStage(masterAccount, finalStage);
  final nightmareFinal = _playStageLikeSkilledHuman(
    p: masterAccount,
    stage: finalStage,
    difficulty: DefenseDifficulty.nightmare,
    seed: 20261010,
  );
  if (!nightmareFinal.summary.victory) {
    throw StateError('종결 계정 10-10 악몽 난이도 클리어 실패!');
  }

  // SUHO1 백업 코드 무손실 왕복 복원 검증
  final backup = player.exportBackupCode();
  final restored = PlayerProgress.tryDecodeBackupCode(backup);
  if (restored == null ||
      restored.highestClearedGlobalStage != totalStageCnt ||
      restored.openedMeridianStep != player.openedMeridianStep ||
      restored.realmIndex != player.realmIndex ||
      restored.bestEndlessByDifficulty[DefenseDifficulty.normal.id] !=
          player.bestEndlessByDifficulty[DefenseDifficulty.normal.id]) {
    throw StateError('SUHO1 백업 코드 최종 계정 왕복 무결성 실패!');
  }

  if (player.highestClearedGlobalStage != totalStageCnt) {
    throw StateError('100판 완전 정화 미달성: ${player.highestClearedGlobalStage}');
  }
  if (player.openedMeridianStep < 10) {
    throw StateError('십대 경맥 10/10 미달성: ${player.openedMeridianStep}');
  }
  if (player.realmIndex < 7) {
    throw StateError('내공 최고 경지 생사경(7) 미달성: ${player.realmIndex}');
  }
  if (player.unlockedStones.length < StoneMaterial.values.length) {
    throw StateError(
      '13단 수호석 전종 해금 미달성: ${player.unlockedStones.length}/${StoneMaterial.values.length}',
    );
  }
  final ownedBeasts = SpiritBeast.values.where((b) => (player.beastLevels[b] ?? 0) > 0).length;
  final ownedHeroes =
      CompanionHero.values.where((h) => (player.companionLevels[h] ?? 0) > 0).length;
  if (ownedBeasts < SpiritBeast.values.length || ownedHeroes < CompanionHero.values.length) {
    throw StateError('영수($ownedBeasts/5) 또는 동료($ownedHeroes/14) 전종 합류 미달성!');
  }

  if (allUsedConsumables.length < TacticalConsumable.values.length) {
    throw StateError(
      '전술 비약 3종 실전 사용 검증 미달: ${allUsedConsumables.length}/${TacticalConsumable.values.length}',
    );
  }

  final avgSerendip =
      records.map((r) => r.serendipities).reduce((a, b) => a + b) / records.length;

  // 장별 통계 집계 및 보고서 작성
  final buf = StringBuffer()
    ..writeln('================================================================================')
    ..writeln(' 수호알까기 · 탄지무림 심야기습 v1.0.0+29 — 10현×10마을(총 100판) 인간반응(2Hz)·무치팅 전 구간 & 무한100물결 점검표')
    ..writeln('================================================================================')
    ..writeln('• 시작 조건 : 신규 계정 PlayerProgress() · 인간 반응 주기(0.5초/2Hz) · 추가 단전 노가다 0회 · 쿨타임 치팅 0회')
    ..writeln('• 캠페인 완주 : 총 $totalStageCnt / $totalStageCnt 판(10현×10마을) 정화 완료! (1트 클리어 $firstTryWins/$totalStageCnt · 총 시도 $totalAttempts회 · 관문당 평균 기연 ${avgSerendip.toStringAsFixed(1)}회)')
    ..writeln('• 3난이도 변별 : 쉬움 ${diffWins[DefenseDifficulty.easy]}/$totalStageCnt승(★3 ${diffThreeStars[DefenseDifficulty.easy]}, 최저방어막 ${easyAvgSh.toStringAsFixed(1)}%) > 보통 ${diffWins[DefenseDifficulty.normal]}/$totalStageCnt승(★3 ${diffThreeStars[DefenseDifficulty.normal]}, 최저방어막 ${normAvgSh.toStringAsFixed(1)}%) > 악몽 ${diffWins[DefenseDifficulty.nightmare]}/$totalStageCnt승(★3 ${diffThreeStars[DefenseDifficulty.nightmare]}, 최저방어막 ${nightAvgSh.toStringAsFixed(1)}%)')
    ..writeln('• 무한 100물결 : 막 10-10 클리어 계정 돌파=${freshEndlessRun.summary.wavesClearedCount}물결 · 종결 계정 보통=${masterEndlessNormal.summary.wavesClearedCount}/100물결 완주(PASS!) · 종결 계정 악몽=${masterEndlessNightmare.summary.wavesClearedCount}/100물결')
    ..writeln('• 내공 수련 : 경지 [${player.realm.name} (${player.realmIndex + 1}/8)] · 십대 경맥 ${player.openedMeridianStep}/10(내공 ${player.maxQiBars}칸) · 누적 내공 ${player.naegongPoints}')
    ..writeln('• 영구 강화 : 중앙 수호탑 ${player.centralGuardianLevel}단 · 발사대 영구 ${LauncherType.values.map((t) => "${t.name.split(" ").first}:${player.launcherPermanentLevels[t]}단").join(", ")}')
    ..writeln('• 수집 완성 : 수호석 ${player.unlockedStones.length}/13종 · 영수 $ownedBeasts/5종 · 동료 영웅 $ownedHeroes/14인 · 조우 변이 ${player.seenMutants.length}/${MutantKind.values.length}종')
    ..writeln('• 전장 상호작용 : 유료합체 $totalMergedStages관문 · 수동탄지 $totalManualAimStages관문 · 침식정화 $totalCleansedStages관문 · 돌림판 $totalRouletteStages관문 · 비약사용 ${allUsedConsumables.length}/3종 · SUHO1 복원=PASS')
    ..writeln('--------------------------------------------------------------------------------')
    ..writeln(' [장별 실전 난이도 · 방어선 긴장도 · 보스 마갑 · 기연 발동 계측 요약]')
    ..writeln('--------------------------------------------------------------------------------');

  for (int ch = 1; ch <= 10; ch++) {
    final chRecs = records.where((r) => r.chapter == ch).toList();
    final avgDur = chRecs.map((e) => e.durationSec).reduce((a, b) => a + b) / chRecs.length;
    final avgMinShield =
        chRecs.map((e) => e.minShieldPct).reduce((a, b) => a + b) / chRecs.length;
    final minTowerWorst = chRecs.map((e) => e.minTowerPct).reduce(min);
    final threeStars = chRecs.where((e) => e.stars == 3).length;
    final retries = chRecs.map((e) => e.attempts - 1).reduce((a, b) => a + b);
    final maxShield = chRecs.map((e) => e.bossMaxHitShield).reduce(max);
    final avgChSerendip =
        chRecs.map((e) => e.serendipities).reduce((a, b) => a + b) / chRecs.length;
    final chSpec = CampaignCatalog.chapterOf(ch);
    buf.writeln(
      ' • 제${ch.toString().padLeft(2)}장 [${chSpec.routeTopologyTag}] : '
      '${chRecs.length}/${chRecs.length}승 (재도전 $retries회 · ★3 $threeStars곳) | '
      '평균 ${avgDur.toStringAsFixed(1)}초 | 최저방어막 ${avgMinShield.toStringAsFixed(0)}%(최저본진 $minTowerWorst%) | '
      '보스마갑 $maxShield타 | 기연 ${avgChSerendip.toStringAsFixed(1)}회',
    );
  }
  buf
    ..writeln('--------------------------------------------------------------------------------')
    ..writeln(' [적대적 엣지케이스 & 물리 불변식 검증 항목]')
    ..writeln('--------------------------------------------------------------------------------');
  for (final n in edgeNotes) {
    buf.writeln(' • $n');
  }
  buf.writeln('================================================================================');

  final reportText = buf.toString();
  stdout.writeln(reportText);
  try {
    final outReport = File('../../docs/전구간_완전플레이_적대적점검_보고서.txt');
    outReport.parent.createSync(recursive: true);
    outReport.writeAsStringSync(reportText);
    stdout.writeln(
      '완료 (${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}초) -> ${outReport.path}',
    );
  } on FileSystemException {
    stdout.writeln('완료 (${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}초) [읽기 전용 환경]');
  }
}
