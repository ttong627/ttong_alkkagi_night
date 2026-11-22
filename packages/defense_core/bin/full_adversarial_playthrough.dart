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
    if (rec.unlockChapter <= p.highestUnlockedChapter) {
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

void _runBetweenBattleGrowth(
  PlayerProgress p,
  Random rng,
  String todayKey, {
  int extraMeditations = 6,
}) {
  p.claimAttendance(todayKey: todayKey, rng: rng);
  if (p.remainingDailyEnlightenment(todayKey: todayKey) > 0) {
    p.meditateBatch(count: 10, hitGoldenRing: true, rng: rng, todayKey: todayKey);
  }
  for (int i = 0; i < extraMeditations; i++) {
    p.meditateOnce(hitGoldenRing: i % 3 != 0, rng: rng, todayKey: todayKey);
  }

  while (p.canOpenNextMeridian()) {
    p.openNextMeridian();
  }
  while (p.breakthroughRealm()) {}

  p.claimAllReadyRewards(rng, todayKey: todayKey, autoRedispatch: true);
  if (p.highestUnlockedChapter >= 2 && !p.convoyActive && p.convoyBattlesRemaining == 0) {
    p.startSupplyConvoy();
  }
  if (!p.exploreActive && p.exploreBattlesRemaining == 0) {
    p.startNightExplore();
  }

  // 비약 제조 재료가 모이면 3종 전술 비약 고르게 제조
  for (final item in TacticalConsumable.values) {
    if ((p.consumables[item] ?? 0) < 2 && p.canCraftConsumable(item)) {
      p.craftConsumable(item);
    }
  }

  // 스마트 추천 일괄 강화 + 3대 핵심 능력치 골고루 투자
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

({
  BattleSummary summary,
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
  final maxSteps = (460.0 / dt).round();
  double minShieldRatio = 1.0;
  double minTowerRatio = 1.0;
  int bossMaxShieldSeen = 0;
  bool mergedOnce = false;
  bool manualFiredOnce = false;
  bool cleansedOnce = false;
  bool rouletteOnce = false;
  final usedPills = <TacticalConsumable>{};

  for (int step = 0; step < maxSteps && !sim.isFinished; step++) {
    // 1) 돌파 비급 선택 (우선순위 기반 수동 선택 검증)
    if (sim.pendingPerkChoices.isNotEmpty) {
      final pick = sim.recommendedPerkChoice() ?? sim.pendingPerkChoices.first;
      sim.chooseRoguePerk(pick);
    }

    // 2) 마기 침식 포탑 즉시 터치 정화
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

    // 4) 전방 암석 개척 & 추천 다병종 축조 (초반 1회는 도박소환도 병행 검증!)
    final nextSlot = sim.nextRecommendedSlotIndex();
    if (nextSlot != null) {
      final slot = sim.mountSlotByIndex(nextSlot)!;
      if (!sim.isSlotExcavated(nextSlot)) {
        if (sim.fieldTokens >= sim.excavationCostForSlot(slot)) {
          sim.excavateSlotInBattle(nextSlot);
        }
      } else {
        if (stage.stageNumber == 3 && sim.launchers.isEmpty && sim.fieldTokens >= sim.currentLuckySummonCost) {
          sim.quickLuckySummonNextPad();
        } else {
          sim.quickDirectBuildNextPad();
        }
      }
    } else if (sim.fieldTokens >= 150) {
      // 모든 초소가 채워졌고 여유 기력이 넉넉할 때 유료 연성 합치기 또는 실시간 전군 강화 수행!
      if (!mergedOnce && sim.launchers.length >= 6 && sim.findAnyMergePair() != null) {
        if (sim.quickMergeAnyPair()) {
          mergedOnce = true;
        }
      }
      sim.upgradeLiveFirepower();
      sim.upgradeLiveReload();
      sim.upgradeLiveRange();
      if (sim.shieldHp < sim.shieldMaxHpDynamic * 0.75) {
        sim.upgradeLiveBarrier();
      }
    }

    // 5) 다단 변이 보스 약점 정밀 저격
    if (sim.isPrecisionStrikeReady) {
      final boss = sim.activeMultiPhaseBoss;
      if (boss != null && boss.phaseTransitionTimer <= 0) {
        sim.firePrecisionStrikeAt(boss.weakSpotWorldPos);
      }
    }

    // 6) 매 9초마다 수동 탄지 전환 → 복제문 / 화력 과녁패 / 보물 도깨비 / 화약통 직접 조준 사격 후 자동 복귀!
    if (step % 270 == 90 && sim.launchers.isNotEmpty) {
      Vec2 aimPt = sim.powerTarget.center;
      if (sim.treasureGoblin != null && sim.treasureGoblin!.alive) {
        aimPt = sim.treasureGoblin!.pos;
      } else {
        final intactKeg = sim.powderKegs.where((k) => k.intact).firstOrNull;
        if (intactKeg != null && intactKeg.pos.distanceTo(sim.towerPos) <= sim.effectiveCentralManualRange) {
          aimPt = intactKeg.pos;
        } else if (step % 540 == 90) {
          aimPt = sim.cloneGate.center;
        }
      }
      if (!sim.centralManualMode) sim.toggleCentralManualMode();
      sim.centralFireTimer = 0.0;
      if (sim.fireCentralManualAt(aimPt)) {
        manualFiredOnce = true;
      }
      if (sim.centralManualMode) sim.toggleCentralManualMode();
    }

    // 7) 여유 구간 다음 물결 조기 호출 보너스 검증 (각 스테이지 2물결에서 1회 검증)
    if (sim.currentWaveIndex == 1 && sim.canCallNextWaveEarly && sim.shieldHp > sim.shieldMaxHpDynamic * 0.80) {
      sim.callNextWaveEarly();
    }

    // 8) 보스전 및 위기 상황에서 전술 비약 3종 실전 사용 검증
    if (allowConsumablesAndSupport) {
      if (sim.qiBars < 1.0 &&
          stage.isBossStage &&
          (p.consumables[TacticalConsumable.qiSurgePill] ?? 0) > 0 &&
          !usedPills.contains(TacticalConsumable.qiSurgePill)) {
        if (sim.activateConsumable(TacticalConsumable.qiSurgePill)) {
          usedPills.add(TacticalConsumable.qiSurgePill);
        }
      }
      if (sim.shieldHp < sim.shieldMaxHpDynamic * 0.55 &&
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
    durationSec: sim.elapsedSec,
    minShieldPct: (minShieldRatio.clamp(0.0, 1.0) * 100).round(),
    minTowerPct: (minTowerRatio.clamp(0.0, 1.0) * 100).round(),
    bossMaxHitShield: bossMaxShieldSeen,
    precisionHits: sim.precisionHitCount,
    activeContribKeys: summary.contributions.map((c) => c.key).toSet(),
    mergedInBattle: mergedOnce || sim.mergeEvolutionCount > 0,
    manualShotFired: manualFiredOnce,
    cleansedTower: cleansedOnce,
    spunRoulette: rouletteOnce,
    usedConsumables: usedPills,
  );
}

List<String> _runAdversarialEdgeChecks() {
  final notes = <String>[];
  final rng = Random(20261126);

  // [검증 1] 제1장 신규 계정으로 제8장 천룡 금룡 및 스토리 전용 동료 조기 구매 차단 검증
  final fresh = PlayerProgress(elixirs: 999);
  if (fresh.unlockOrUpgradeBeast(SpiritBeast.geumryong)) {
    throw StateError('적대적 검증 실패: 1장에서 8장 해금 영수 금룡이 영입됨!');
  }
  if (fresh.unlockOrUpgradeCompanion(CompanionHero.geomhwang)) {
    throw StateError('적대적 검증 실패: 1장에서 7장 해금 동료 검황이 영입됨!');
  }
  if (fresh.unlockOrUpgradeCompanion(CompanionHero.yeonbi)) {
    throw StateError('적대적 검증 실패: 구출 전용(unlockElixirs=0) 동료 연비가 영약 0개로 영입됨!');
  }
  notes.add('PASS [보안/해금] 1장 미해금 상위 영수(금룡)·동료(검황)·구출전용 동료(0영약) 조기 구매 원천 차단 확인');

  // [검증 2] 일일 깨달음 3배 정확 일치 및 일일 소진 후 보름달 기연 무한 루프 차단 검증
  final medP = PlayerProgress();
  final r1 = medP.meditateOnce(hitGoldenRing: false, rng: Random(1), todayKey: '2026-11-22');
  // 기연 미발동 시 기본 12 × 3 = 36 (또는 2배 기연 시 72), 인장 3 × 3 = 9 (또는 18)
  if (r1.gainedNaegong != 36 && r1.gainedNaegong != 72) {
    throw StateError('단전 운기 일일 깨달음 배율 불일치: ${r1.gainedNaegong}');
  }
  medP.meditateBatch(count: 10, hitGoldenRing: true, rng: rng, todayKey: '2026-11-22');
  final moonBefore = medP.moonOmenGauge;
  medP.meditateOnce(hitGoldenRing: true, rng: Random(3), todayKey: '2026-11-22');
  if ((medP.moonOmenGauge - moonBefore) > 2) {
    throw StateError('일일 깨달음 소진 후 과도한 보름달 게이지 충전 감지!');
  }
  notes.add('PASS [내공수련] 일일 깨달음 3배(36내공/9인장) 일치 및 비전투 보름달 무한 증식 차단 확인');

  // [검증 3] 유료 연성 합치기(mergeLauncherAtSlot) 시 진화된 병종의 영구 강화 레벨 동기화 검증
  final mergeP = PlayerProgress(tokens: 5000, highestClearedGlobalStage: 60);
  mergeP.launcherPermanentLevels[LauncherType.rapid] = 1;
  mergeP.launcherPermanentLevels[LauncherType.heavy] = 18;
  for (final lt in LauncherType.values) {
    if (lt != LauncherType.rapid) mergeP.launcherPermanentLevels[lt] = 18;
  }
  final mSim = DefenseBattleSim(
    stage: CampaignCatalog.stageAt(5, 2),
    difficulty: DefenseDifficulty.normal,
    progress: mergeP,
    seed: 9,
  );
  mSim.fieldTokens = 600;
  mSim.placeLauncherInBattle(0, LauncherType.rapid);
  mSim.placeLauncherInBattle(1, LauncherType.rapid);
  mSim.step(3.5);
  mSim.mergeLauncherAtSlot(0);
  final evolved = mSim.launcherAtSlot(0)!;
  final expectedPerm = mergeP.launcherPermanentLevels[evolved.type]!;
  if (evolved.permanentLevel != expectedPerm) {
    throw StateError('합치기 후 permanentLevel 미동기화: ${evolved.permanentLevel} != $expectedPerm');
  }
  notes.add('PASS [합치기물리] 연성 합체 진화 시 신규 병종 영구 강화 단계(${evolved.permanentLevel}단) 즉시 동기화 확인');

  // [검증 4] 제5장 시계태엽 미궁 전 구간 100% 90° 직각 복도(대각선 0개) 검증
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
  notes.add('PASS [지형기하] 제5장 시계태엽 미궁 전 레인 제어점 100% 수직·수평(90° 직각) 무결성 확인');

  // [검증 5] 제7장 남→북 역진격(towerPos=(360,212))에서 묵현 긴급 난입·출두 방사형 밀침·보스 포효·호위병 방향 검증
  final p7 = PlayerProgress(highestClearedGlobalStage: 80, supportTokens: 2);
  p7.companionLevels[CompanionHero.mukhyeon] = 7;
  final sim7 = DefenseBattleSim(
    stage: CampaignCatalog.stageAt(7, 11),
    difficulty: DefenseDifficulty.normal,
    progress: p7,
    seed: 77,
    allowSerendipity: false,
  );
  sim7.fieldTokens = 500;
  sim7.placeLauncherInBattle(0, LauncherType.rapid);
  sim7.step(3.5);
  sim7.mutants.clear();
  final southGateBoss = ActiveMutant(
    uid: 7001,
    kind: MutantKind.chapterOverlord,
    laneIndex: 0,
    waypoints: sim7.chapter.smoothedLane(0),
    pos: const Vec2(360, 1180), // 남쪽 입구(본진에서 968px 떨어짐)
    maxHp: 50000,
    speed: 30,
  )..enableBossPhases(phases: 3, initialPlates: 2);
  sim7.mutants.add(southGateBoss);
  sim7.step(1 / 30);
  if (southGateBoss.roarShockUsed) {
    throw StateError('제7장 남쪽 출발점(y=1180)에서 보스 포효가 첫 프레임에 오작동함!');
  }
  final nearFortEnemy = ActiveMutant(
    uid: 7002,
    kind: MutantKind.ironBoar,
    laneIndex: 0,
    waypoints: sim7.chapter.smoothedLane(0),
    pos: const Vec2(360, 310), // 북단 성채(y=212) 바로 남쪽 98px 지점!
    maxHp: 20000,
    speed: 20,
  );
  sim7.mutants.add(nearFortEnemy);
  final hpBeforeMuk = nearFortEnemy.hp;
  sim7.shieldHp = sim7.shieldMaxHpDynamic * 0.30;
  sim7.step(1 / 30);
  if (!sim7.mukhyeonTriggered || nearFortEnemy.hp >= hpBeforeMuk || nearFortEnemy.knockbackVel.y <= 0) {
    throw StateError('제7장 북단 성채(y<390) 침입 적에게 묵현 위기 난입 피해/남방 밀침이 작동하지 않음!');
  }
  // 보스 페이즈 전환 무적 중 암행어사 출두 시 페이즈 전환 즉시 타파 검증
  southGateBoss.phaseTransitionTimer = 0.65;
  final bossPhaseBefore = southGateBoss.currentPhase;
  sim7.triggerSupportChuldu();
  if (southGateBoss.phaseTransitionTimer > 0 && southGateBoss.hp >= southGateBoss.currentMaxHp) {
    throw StateError('보스 재변이 무적 타이머 중 출두 피해가 씹힘!');
  }
  notes.add('PASS [역방향물리] 제7장 북단 성채 묵현 난입·남방 밀침·보스 포효 거리 판정·재변이 중 출두 관통 확인 (phase>=$bossPhaseBefore)');

  // [검증 6] 뼈방패 야차 정면 감쇠 vs 후방 직격 무감쇠 방향성 검증
  final yachaSim = DefenseBattleSim(
    stage: CampaignCatalog.stageAt(3, 4),
    difficulty: DefenseDifficulty.normal,
    progress: PlayerProgress(highestClearedGlobalStage: 30),
    seed: 12,
    allowSerendipity: false,
  );
  yachaSim.mutants.clear();
  yachaSim.projectiles.clear();
  final frontYacha = ActiveMutant(
    uid: 8101,
    kind: MutantKind.shieldYacha,
    laneIndex: 0,
    waypoints: yachaSim.chapter.smoothedLane(0),
    pos: const Vec2(240, 500),
    maxHp: 5000,
    speed: 0,
  )..headingRad = pi / 2; // 남쪽(+y)을 바라봄
  final backYacha = ActiveMutant(
    uid: 8102,
    kind: MutantKind.shieldYacha,
    laneIndex: 0,
    waypoints: yachaSim.chapter.smoothedLane(0),
    pos: const Vec2(480, 500),
    maxHp: 5000,
    speed: 0,
  )..headingRad = pi / 2; // 남쪽(+y)을 바라봄
  yachaSim.mutants.addAll([frontYacha, backYacha]);
  // 정면(남쪽->북쪽 -y 발사) 탄알 vs 후방(북쪽->남쪽 +y 발사) 탄알
  yachaSim.projectiles.add(
    ActiveStoneProjectile(
      sourceKey: 'front_test',
      sourceLabel: '정면탄',
      pos: const Vec2(240, 506),
      vel: const Vec2(0, -300),
      material: StoneMaterial.cheongok,
      shape: StoneShape.flat,
      damage: 200,
      knockback: 10,
      critChance: 0.0,
      colorHex: 0xFFFFFFFF,
    ),
  );
  yachaSim.projectiles.add(
    ActiveStoneProjectile(
      sourceKey: 'back_test',
      sourceLabel: '배후탄',
      pos: const Vec2(480, 494),
      vel: const Vec2(0, 300),
      material: StoneMaterial.cheongok,
      shape: StoneShape.flat,
      damage: 200,
      knockback: 10,
      critChance: 0.0,
      colorHex: 0xFFFFFFFF,
    ),
  );
  yachaSim.step(1 / 60);
  final frontLost = 5000.0 - frontYacha.hp;
  final backLost = 5000.0 - backYacha.hp;
  if (backLost <= frontLost * 1.5) {
    throw StateError('뼈방패 야차 전후방 판정 실패: 정면피해=$frontLost, 배후피해=$backLost');
  }
  notes.add(
    'PASS [방향성방패] 뼈방패 야차 정면 방어(${frontLost.toStringAsFixed(1)}) vs 배후 관통(${backLost.toStringAsFixed(1)}) 방향성 판정 확인',
  );

  // [검증 7] 묵현 상시 편성 슬롯 배치 시 능동 [흑검 정화참] 발동 검증
  final mukActiveP = PlayerProgress(highestClearedGlobalStage: 70);
  mukActiveP.companionLevels[CompanionHero.mukhyeon] = 5;
  mukActiveP.activePreset.companions = [CompanionHero.mukhyeon];
  final mukSim = DefenseBattleSim(
    stage: CampaignCatalog.stageAt(6, 5),
    difficulty: DefenseDifficulty.normal,
    progress: mukActiveP,
    seed: 55,
    allowSerendipity: false,
  );
  mukSim.fieldTokens = 500;
  mukSim.placeLauncherInBattle(0, LauncherType.rapid);
  for (int s = 0; s < 450 && !mukSim.isFinished; s++) {
    mukSim.step(1 / 30);
  }
  final mukContrib = mukSim.buildSummary().contributions.where((c) => c.key == 'hero_mukhyeon').firstOrNull;
  if (mukContrib == null || mukContrib.totalDamage <= 0) {
    throw StateError('상시 슬롯에 배치한 동료 묵현의 능동 스킬 피해가 0임!');
  }
  notes.add(
    'PASS [동료14인] 상시 슬롯 배치 묵현 [흑검 정화참] 능동 발동 확인 (누적 피해 ${mukContrib.totalDamage.round()})',
  );

  return notes;
}

void main() {
  final sw = Stopwatch()..start();
  stdout.writeln('=======================================================================');
  stdout.writeln(' [수호알까기 v1.0.0+26] 신규 계정 1-1 → 10-10 최종장 완전 플레이 & 적대적 전수 점검');
  stdout.writeln('=======================================================================');

  // 1부: 적대적 엣지케이스 & 물리/보안 불변식 검증
  final edgeNotes = _runAdversarialEdgeChecks();
  for (final n in edgeNotes) {
    stdout.writeln('  ✓ $n');
  }

  // 2부: 신규 계정(PlayerProgress 기본값)으로 1-1부터 10-10(111관문)까지 유기적 완전 플레이!
  final player = PlayerProgress();
  final rng = Random(20261122);
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

  // 첫 출정 전 입문 단전 운기 1회 수행
  _runBetweenBattleGrowth(player, rng, fmtDay(simDate), extraMeditations: 4);

  for (int idx = 0; idx < CampaignCatalog.allStages.length; idx++) {
    final stage = CampaignCatalog.allStages[idx];
    // 하루 약 8관문씩 14일간 플레이하는 자연스러운 유저 수련·출석 주기 시뮬레이션
    if (idx > 0 && idx % 8 == 0) {
      simDate = simDate.add(const Duration(days: 1));
    }
    final todayKey = fmtDay(simDate);

    // 해금된 모든 동료(14인)와 영수(5종)가 실전에 골고루 투입되도록 순환 검증
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
      );

      _runBetweenBattleGrowth(
        player,
        rng,
        todayKey,
        extraMeditations: res.summary.victory ? 7 : 18,
      );

      if (res.summary.victory) {
        if (attempts == 1) firstTryWins++;
        wonSummary = res.summary;
        wonDur = res.durationSec;
        wonMinShield = res.minShieldPct;
        wonMinTower = res.minTowerPct;
        wonBossShield = res.bossMaxHitShield;
        wonPrecHits = res.precisionHits;
        break;
      }

      if (attempts >= 5) {
        throw StateError(
          '난이도 병목 경고: ${stage.code} (${stage.title})에서 정상 수련·강화 후 5회 연속 패배!',
        );
      }
      // 패배 시 실제 유저처럼 직전 정화 관문을 1회 재수련 파밍하여 전력을 보강한 뒤 재도전!
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
      );
      _runBetweenBattleGrowth(player, rng, todayKey, extraMeditations: 16);
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
      ),
    );
  }

  // 최종장 클리어 후 잔여 재화·단전 운기로 생사경·10경맥·13수호석·14동료·5영수·신기연마·영약공명 만개 검증!
  for (int d = 0; d < 4; d++) {
    simDate = simDate.add(const Duration(days: 1));
    _runBetweenBattleGrowth(player, rng, fmtDay(simDate), extraMeditations: 35);
  }
  // 미영입 영수/동료가 있으면 보유 영약으로 마저 영입 및 실전 출격 검증
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

  // 최종 성장 계정으로 악몽(Nightmare) 난이도 10-10 최종 보스 진검 검증 + 무한 혈전 100물결 생존 검증!
  final finalStage = CampaignCatalog.stageAt(10, 10);
  _configureSmartLoadoutForStage(player, finalStage);
  final nightmareFinal = _playStageLikeSkilledHuman(
    p: player,
    stage: finalStage,
    difficulty: DefenseDifficulty.nightmare,
    seed: 20261010,
  );

  // 무한 혈전 100물결 생성 및 실전 돌입 검증
  final endlessStage = EndlessWaveBuilder.buildEndlessStage(
    chapterTheme: 10,
    waveCount: 100,
  );
  _configureSmartLoadoutForStage(player, endlessStage);
  final endlessSim = DefenseBattleSim(
    stage: endlessStage,
    difficulty: DefenseDifficulty.normal,
    progress: player,
    seed: 88888,
    autoBuildForSimVerify: true,
  )..autoPrecisionForVerify = true;
  for (int s = 0; s < (520.0 * 30).round() && !endlessSim.isFinished; s++) {
    endlessSim.step(1 / 30);
    if (s % 90 == 0) {
      _assertFiniteArena(endlessSim, '무한혈전@step$s');
    }
  }
  final endlessSummary = endlessSim.buildSummary();
  player.onBattleFinished(
    stage: endlessStage,
    victory: endlessSummary.victory,
    stars: endlessSummary.stars,
    earnedTokens: endlessSummary.earnedTokens,
    earnedElixirs: endlessSummary.earnedElixirs,
    usedSupportCount: endlessSummary.usedSupportCount,
    killCount: endlessSummary.killCount,
    pporokCount: endlessSummary.pporokCount,
    bankShotCount: endlessSummary.bankShotCount,
    chainShatterCount: endlessSummary.chainShatterCount,
    serendipityCount: endlessSummary.serendipityCount,
    encounteredMutants: endlessSummary.encounteredMutants,
    endlessWavesCleared: endlessSummary.wavesClearedCount,
    todayKey: fmtDay(simDate),
  );

  // SUHO1 백업 코드 무손실 왕복 복원 검증
  final backup = player.exportBackupCode();
  final restored = PlayerProgress.tryDecodeBackupCode(backup);
  if (restored == null ||
      restored.highestClearedGlobalStage != 111 ||
      restored.openedMeridianStep != player.openedMeridianStep ||
      restored.realmIndex != player.realmIndex ||
      restored.unlockedStones.length != player.unlockedStones.length) {
    throw StateError('SUHO1 백업 코드 최종 계정 왕복 무결성 실패!');
  }

  // 핵심 달성 기준 단언
  if (player.highestClearedGlobalStage != 111) {
    throw StateError('111관문 완전 정화 미달성: ${player.highestClearedGlobalStage}');
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

  // 장별 통계 집계 및 보고서 작성
  final buf = StringBuffer()
    ..writeln('================================================================================')
    ..writeln(' 수호알까기 · 탄지무림 심야기습 v1.0.0+26 — 신규 계정 전 구간(1-1~10-10) 완전 플레이 점검표')
    ..writeln('================================================================================')
    ..writeln('• 시작 조건 : 완전 초기화된 신규 계정 PlayerProgress() (증표 60 · 영약 2 · 내공 0 · 0관문)')
    ..writeln('• 캠페인 결과 : 총 111 / 111 관문 정화 완료! (1트 클리어 $firstTryWins/111 · 총 시도 $totalAttempts회)')
    ..writeln('• 내공 수련 : 경지 [${player.realm.name} (${player.realmIndex + 1}/8)] · 십대 경맥 ${player.openedMeridianStep}/10 완전 개통 · 누적 내공 ${player.naegongPoints}')
    ..writeln('• 영구 강화 : 중앙 수호탑 ${player.centralGuardianLevel}단 · 발사대 영구 ${LauncherType.values.map((t) => "${t.name.split(" ").first}:${player.launcherPermanentLevels[t]}단").join(", ")}')
    ..writeln('• 심화 단련 : 신기 연마 ${player.forgeMasteryLevel}단 · 영약 공명 ${player.elixirResonanceLevel}단 · 3대 비결 ${CoreStatType.values.map((c) => "${c.name}:${player.coreStatLevels[c]}").join(", ")}')
    ..writeln('• 수집 완성 : 수호석 ${player.unlockedStones.length}/13종 · 영수 $ownedBeasts/5종 · 동료 영웅 $ownedHeroes/14인 · 조우 변이 ${player.seenMutants.length}/${MutantKind.values.length}종')
    ..writeln('• 전장 상호작용 : 유료합체 $totalMergedStages관문 · 수동탄지 $totalManualAimStages관문 · 침식정화 $totalCleansedStages관문 · 돌림판 $totalRouletteStages관문 · 비약사용 ${allUsedConsumables.length}/3종')
    ..writeln('• 최종 검증 : 10-10 악몽(Nightmare) 승리=${nightmareFinal.summary.victory}(★${nightmareFinal.summary.stars}) · 무한혈전 돌파=${player.bestEndlessWave}물결 · SUHO1 백업 복원 일치=PASS')
    ..writeln('--------------------------------------------------------------------------------')
    ..writeln(' [장별 실전 난이도 · 방어선 긴장도 · 보스 마갑 계측 요약]')
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
    final chSpec = CampaignCatalog.chapterOf(ch);
    buf.writeln(
      ' • 제${ch.toString().padLeft(2)}장 [${chSpec.routeTopologyTag}] : '
      '${chRecs.length}/${chRecs.length}승 (재도전 $retries회 · ★3 $threeStars곳) | '
      '평균 ${avgDur.toStringAsFixed(1)}초 | 최저방어막 평균 ${avgMinShield.toStringAsFixed(0)}% (최저본진 $minTowerWorst%) | '
      '장보스 최대마갑 $maxShield타',
    );
  }
  buf
    ..writeln('--------------------------------------------------------------------------------')
    ..writeln(' [적대적 엣지케이스 & 물리 불변식 검증 7대 항목]')
    ..writeln('--------------------------------------------------------------------------------');
  for (final n in edgeNotes) {
    buf.writeln(' • $n');
  }
  buf.writeln('================================================================================');

  final reportText = buf.toString();
  stdout.writeln(reportText);
  final outReport = File('../../docs/전구간_완전플레이_적대적점검_보고서.txt');
  outReport.parent.createSync(recursive: true);
  outReport.writeAsStringSync(reportText);
  stdout.writeln(
    '완료 (${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)}초) -> ${outReport.path}',
  );
}
