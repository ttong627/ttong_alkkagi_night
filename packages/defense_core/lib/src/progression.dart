import 'dart:convert';
import 'dart:math';

import 'allies.dart';
import 'campaign.dart';
import 'daily_quests_codex.dart';
import 'launchers.dart';
import 'materials.dart';
import 'mutants.dart';

/// 초간단 기명 심법 수련 — 3대 원터치 핵심 능력치.
enum CoreStatType {
  firepower('단전 화력', '모든 자동 발사대 · 중앙 보호 장치 · 동료 타격력 +3.5%/단'),
  fortitude('호신 강기', '외곽 기공 방어막 · 중앙 보호 장치 최대 내구도 및 자동 회복 +4.5%/단'),
  precision('영안 정밀', '자동 발사 예측 조준 정확도 및 회심 피해 배율 +3.5%/단');

  const CoreStatType(this.label, this.description);
  final String label;
  final String description;
}

/// 십대 경맥 개통 (수련 1/10 ~ 10/10) — 알까기 조작 0%, 빛나는 혈자리 톡톡 점등만으로 100% 개통!
class MeridianStepSpec {
  const MeridianStepSpec({
    required this.stepNumber,
    required this.name,
    required this.acupointNames,
    required this.acupointCoords,
    required this.reqNaegong,
    required this.effectSummary,
    required this.rewardTokens,
    required this.rewardElixirs,
    required this.rewardSupportTokens,
  });

  final int stepNumber;
  final String name;
  final List<String> acupointNames;
  /// 0.0~1.0 정규화 인체 수묵 기맥도 좌표 (크고 누르기 쉬운 혈자리 구슬).
  final List<Vec2> acupointCoords;
  final int reqNaegong;
  final String effectSummary;
  final int rewardTokens;
  final int rewardElixirs;
  final int rewardSupportTokens;

  static const List<MeridianStepSpec> steps = [
    MeridianStepSpec(
      stepNumber: 1,
      name: '양유맥 개통',
      acupointNames: ['금문혈', '양교혈', '견정혈'],
      acupointCoords: [Vec2(0.32, 0.78), Vec2(0.36, 0.56), Vec2(0.40, 0.34)],
      reqNaegong: 0,
      effectSummary: '길목 자동 알 발사대 전체 공격력 +6%',
      rewardTokens: 45,
      rewardElixirs: 1,
      rewardSupportTokens: 0,
    ),
    MeridianStepSpec(
      stepNumber: 2,
      name: '음유맥 개통',
      acupointNames: ['축빈혈', '부사혈', '천돌혈'],
      acupointCoords: [Vec2(0.66, 0.76), Vec2(0.60, 0.54), Vec2(0.50, 0.30)],
      reqNaegong: 40,
      effectSummary: '외곽 기공 방어막 최대 내구도 +10%',
      rewardTokens: 50,
      rewardElixirs: 2,
      rewardSupportTokens: 0,
    ),
    MeridianStepSpec(
      stepNumber: 3,
      name: '양교맥 개통',
      acupointNames: ['신맥혈', '거료혈', '풍지혈'],
      acupointCoords: [Vec2(0.28, 0.82), Vec2(0.30, 0.50), Vec2(0.42, 0.22)],
      reqNaegong: 110,
      effectSummary: '중앙 자동 보호 장치 장전 속도 +8%',
      rewardTokens: 70,
      rewardElixirs: 2,
      rewardSupportTokens: 0,
    ),
    MeridianStepSpec(
      stepNumber: 4,
      name: '음교맥 개통',
      acupointNames: ['조해혈', '교신혈', '결분혈', '정명혈'],
      acupointCoords: [Vec2(0.68, 0.82), Vec2(0.64, 0.60), Vec2(0.56, 0.36), Vec2(0.50, 0.20)],
      reqNaegong: 210,
      effectSummary: '동료 · 영수 자동 출격 재사용 대기 −8%',
      rewardTokens: 90,
      rewardElixirs: 3,
      rewardSupportTokens: 0,
    ),
    MeridianStepSpec(
      stepNumber: 5,
      name: '대맥 개통',
      acupointNames: ['대맥혈', '오추혈', '유도혈', '장문혈'],
      acupointCoords: [Vec2(0.30, 0.56), Vec2(0.43, 0.58), Vec2(0.57, 0.58), Vec2(0.70, 0.56)],
      reqNaegong: 350,
      effectSummary: '돌연변이 처치 시 증표 획득량 +10%',
      rewardTokens: 120,
      rewardElixirs: 3,
      rewardSupportTokens: 1,
    ),
    MeridianStepSpec(
      stepNumber: 6,
      name: '충맥 개통',
      acupointNames: ['기충혈', '황유혈', '유문혈', '전중혈'],
      acupointCoords: [Vec2(0.50, 0.74), Vec2(0.50, 0.60), Vec2(0.50, 0.46), Vec2(0.50, 0.34)],
      reqNaegong: 520,
      effectSummary: '모든 자동 발사 수호 알 회심(크리티컬) 확률 +6%',
      rewardTokens: 150,
      rewardElixirs: 4,
      rewardSupportTokens: 0,
    ),
    MeridianStepSpec(
      stepNumber: 7,
      name: '임맥 개통',
      acupointNames: ['관원혈', '기해혈', '중완혈', '승장혈'],
      acupointCoords: [Vec2(0.50, 0.78), Vec2(0.50, 0.66), Vec2(0.50, 0.50), Vec2(0.50, 0.25)],
      reqNaegong: 750,
      effectSummary: '전투 시작 시 기본 내공 +0.6칸 즉시 충전',
      rewardTokens: 190,
      rewardElixirs: 4,
      rewardSupportTokens: 0,
    ),
    MeridianStepSpec(
      stepNumber: 8,
      name: '독맥 개통',
      acupointNames: ['명문혈', '지양혈', '신주혈', '대추혈', '아문혈'],
      acupointCoords: [
        Vec2(0.50, 0.72),
        Vec2(0.50, 0.58),
        Vec2(0.50, 0.45),
        Vec2(0.50, 0.32),
        Vec2(0.50, 0.20),
      ],
      reqNaegong: 1050,
      effectSummary: '설렘 기연(크리티컬 · 한 번 더!) 발동 확률 +6%',
      rewardTokens: 240,
      rewardElixirs: 5,
      rewardSupportTokens: 0,
    ),
    MeridianStepSpec(
      stepNumber: 9,
      name: '기경팔맥 합일',
      acupointNames: ['동방청룡혈', '서방백호혈', '남방주작혈', '북방현무혈', '중앙기명혈'],
      acupointCoords: [
        Vec2(0.26, 0.48),
        Vec2(0.74, 0.48),
        Vec2(0.50, 0.72),
        Vec2(0.50, 0.26),
        Vec2(0.50, 0.48),
      ],
      reqNaegong: 1450,
      effectSummary: '모든 수호 알의 밀침 충격량 +12%',
      rewardTokens: 300,
      rewardElixirs: 6,
      rewardSupportTokens: 1,
    ),
    MeridianStepSpec(
      stepNumber: 10,
      name: '생사현관 대개통',
      acupointNames: ['하단전', '중단전', '상단전 백회혈'],
      acupointCoords: [Vec2(0.50, 0.68), Vec2(0.50, 0.44), Vec2(0.50, 0.16)],
      reqNaegong: 1950,
      effectSummary: '단전 최대 내공 4칸 확장 & 시작 내공 +1.0칸 & 전 아군 화력 +14% & 황금 광륜!',
      rewardTokens: 420,
      rewardElixirs: 8,
      rewardSupportTokens: 2,
    ),
  ];
}

/// 단전 운기 1회 결과 보고.
class MeditationResult {
  const MeditationResult({
    required this.gainedNaegong,
    required this.gainedSeals,
    required this.wasEnlightenmentBonus,
    required this.wasCriticalSerendipity,
    required this.wasOneMoreSerendipity,
    required this.remainingDailyBonusCount,
  });

  final int gainedNaegong;
  final int gainedSeals;
  final bool wasEnlightenmentBonus;
  final bool wasCriticalSerendipity;
  final bool wasOneMoreSerendipity;
  final int remainingDailyBonusCount;
}

/// 물자 호송 또는 심야 탐색 수령 결과.
class DispatchClaimResult {
  const DispatchClaimResult({
    required this.title,
    required this.gainedTokens,
    required this.gainedElixirs,
    required this.gainedSupportTokens,
    required this.gainedShards,
    required this.wasCritical,
    required this.wasEncoreOneMore,
  });

  final String title;
  final int gainedTokens;
  final int gainedElixirs;
  final int gainedSupportTokens;
  final int gainedShards;
  final bool wasCritical;
  final bool wasEncoreOneMore;
}

/// 진법 편성 프리셋 (3슬롯 저장 지원).
class LoadoutPreset {
  LoadoutPreset({
    required this.name,
    required this.primaryStone,
    required this.primaryShape,
    required this.sectTechnique,
    required this.mountTypes,
    required this.equippedBeast,
    required this.beastCondition,
    required this.companions,
    required this.companionConditions,
    required this.supportSlotCount,
    required this.supportTriggerShieldRatio,
    required this.autoUpgradeInBattle,
  });

  String name;
  StoneMaterial primaryStone;
  StoneShape primaryShape;
  SectTechnique sectTechnique;
  List<LauncherType> mountTypes;
  SpiritBeast equippedBeast;
  AutoTriggerCondition beastCondition;
  List<CompanionHero> companions;
  Map<CompanionHero, AutoTriggerCondition> companionConditions;
  int supportSlotCount;
  double supportTriggerShieldRatio;
  bool autoUpgradeInBattle;

  factory LoadoutPreset.starter({String name = '1번 수호 진법'}) {
    return LoadoutPreset(
      name: name,
      primaryStone: StoneMaterial.cheongok,
      primaryShape: StoneShape.round,
      sectTechnique: SectTechnique.swordQi,
      mountTypes: [
        LauncherType.rapid,
        LauncherType.heavy,
        LauncherType.curveSpin,
        LauncherType.frostField,
        LauncherType.qiAmplifier,
        LauncherType.heavy,
        LauncherType.rapid,
        LauncherType.frostField,
        LauncherType.curveSpin,
        LauncherType.heavy,
        LauncherType.rapid,
        LauncherType.qiAmplifier,
        LauncherType.frostField,
        LauncherType.curveSpin,
      ],
      equippedBeast: SpiritBeast.nalssaendol,
      beastCondition: SpiritBeast.nalssaendol.defaultCondition,
      companions: [
        CompanionHero.seokdu,
      ],
      companionConditions: {
        for (final h in CompanionHero.values) h: h.defaultCondition,
      },
      supportSlotCount: 3,
      supportTriggerShieldRatio: 0.45,
      autoUpgradeInBattle: false,
    );
  }

  LoadoutPreset copyWithName(String newName) => LoadoutPreset(
        name: newName,
        primaryStone: primaryStone,
        primaryShape: primaryShape,
        sectTechnique: sectTechnique,
        mountTypes: List<LauncherType>.from(mountTypes),
        equippedBeast: equippedBeast,
        beastCondition: beastCondition,
        companions: List<CompanionHero>.from(companions),
        companionConditions: Map<CompanionHero, AutoTriggerCondition>.from(companionConditions),
        supportSlotCount: supportSlotCount,
        supportTriggerShieldRatio: supportTriggerShieldRatio,
        autoUpgradeInBattle: autoUpgradeInBattle,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'stone': primaryStone.id,
        'shape': primaryShape.id,
        'sect': sectTechnique.id,
        'mounts': mountTypes.map((e) => e.id).toList(),
        'beast': equippedBeast.id,
        'beastCond': beastCondition.name,
        'companions': companions.map((e) => e.id).toList(),
        'compConds': companionConditions.map((k, v) => MapEntry(k.id, v.name)),
        'supportSlots': supportSlotCount,
        'supportRatio': supportTriggerShieldRatio,
        'autoUpg': autoUpgradeInBattle,
      };

  factory LoadoutPreset.fromJson(Map<String, dynamic> j) {
    final rawName = j['name'];
    final safeName = (rawName is String && rawName.trim().isNotEmpty) ? rawName.trim() : '수호 진법';
    final base = LoadoutPreset.starter(name: safeName);
    base.primaryStone = StoneMaterial.values.firstWhere(
      (e) => e.id == j['stone'] || e.name == j['stone'],
      orElse: () => StoneMaterial.cheongok,
    );
    base.primaryShape = StoneShape.values.firstWhere(
      (e) => e.id == j['shape'] || e.name == j['shape'],
      orElse: () => StoneShape.round,
    );
    base.sectTechnique = SectTechnique.values.firstWhere(
      (e) => e.id == j['sect'] || e.name == j['sect'],
      orElse: () => SectTechnique.swordQi,
    );
    if (j['mounts'] is List) {
      final parsed = (j['mounts'] as List)
          .map((id) => LauncherType.values.firstWhere(
                (e) => e.id == id || e.name == id,
                orElse: () => LauncherType.rapid,
              ))
          .toList();
      if (parsed.isNotEmpty) {
        while (parsed.length < 14) {
          parsed.add(LauncherType.values[parsed.length % LauncherType.values.length]);
        }
        base.mountTypes = parsed.take(14).toList();
      }
    }
    base.equippedBeast = SpiritBeast.values.firstWhere(
      (e) => e.id == j['beast'] || e.name == j['beast'],
      orElse: () => SpiritBeast.nalssaendol,
    );
    base.beastCondition = AutoTriggerCondition.values.firstWhere(
      (e) => e.name == j['beastCond'],
      orElse: () => base.equippedBeast.defaultCondition,
    );
    if (j['companions'] is List) {
      final parsed = (j['companions'] as List)
          .map((id) => CompanionHero.values.firstWhere(
                (e) => e.id == id || e.name == id,
                orElse: () => CompanionHero.seokdu,
              ))
          .toSet()
          .toList();
      if (parsed.isNotEmpty) {
        base.companions = parsed.take(3).toList();
      }
    }
    if (j['compConds'] is Map) {
      (j['compConds'] as Map).forEach((k, v) {
        final hero = CompanionHero.values.where((e) => e.id == k || e.name == k).firstOrNull;
        final cond = AutoTriggerCondition.values.where((e) => e.name == v).firstOrNull;
        if (hero != null && cond != null) {
          base.companionConditions[hero] = cond;
        }
      });
    }
    base.supportSlotCount = PlayerProgress._safeInt(j['supportSlots'], 3).clamp(0, 3);
    base.supportTriggerShieldRatio =
        PlayerProgress._safeDouble(j['supportRatio'], 0.45).clamp(0.20, 0.80);
    base.autoUpgradeInBattle = PlayerProgress._safeBool(j['autoUpg'], true);
    return base;
  }
}

/// 원터치 일괄 보상 수령 및 자동 재파견 요약 결과.
class BatchClaimSummary {
  const BatchClaimSummary({
    required this.claimedCount,
    required this.gainedTokens,
    required this.gainedElixirs,
    required this.gainedSupportTokens,
    required this.gainedSeals,
    required this.gainedShards,
    required this.redispatchedConvoy,
    required this.redispatchedExplore,
    required this.sources,
  });

  final int claimedCount;
  final int gainedTokens;
  final int gainedElixirs;
  final int gainedSupportTokens;
  final int gainedSeals;
  final int gainedShards;
  final bool redispatchedConvoy;
  final bool redispatchedExplore;
  final List<String> sources;

  bool get hasAnyAction =>
      claimedCount > 0 || redispatchedConvoy || redispatchedExplore;
}

/// 플레이어 전체 영구 진행 상태 (증표·영약·수련·기연·호송·탐색·지원패 통합).
class PlayerProgress {
  PlayerProgress({
    this.tokens = 120,
    this.elixirs = 4,
    this.trainingSeals = 15,
    this.naegongPoints = 20,
    this.realmIndex = 0,
    this.centralGuardianLevel = 1,
    this.supportTokens = 2,
    this.moonOmenGauge = 35,
    int highestClearedGlobalStage = 0,
    this.openedMeridianStep = 0,
    this.dailyEnlightenmentUsed = 0,
    this.lastMeditationDayKey = '',
    this.convoyActive = false,
    this.convoyBattlesRemaining = 0,
    this.convoySupplyBuffBattles = 0,
    this.convoyCompletedCount = 0,
    this.exploreActive = false,
    this.exploreBattlesRemaining = 0,
    this.activePresetIndex = 0,
    this.attendanceDayKey = '',
    this.attendanceStepCount = 0,
    this.dailyQuestDayKey = '',
    this.weeklyQuestKey = '',
    this.monthlyQuestKey = '',
    this.dailyAllClearClaimed = false,
    this.totalMutantKills = 0,
    this.totalPporokCount = 0,
    this.totalBankShotCount = 0,
    this.totalChainShatterCount = 0,
    this.bestEndlessWave = 0,
    this.forgeMasteryLevel = 0,
    this.elixirResonanceLevel = 0,
    this.reincarnationCount = 0,
    this.nightmareChapter10Cleared = false,
    this.reincarnationBossCleared = false,
    this.reincarnationBossAttempts = 0,
    this.reincarnationBossWins = 0,
    this.transcendenceLevel = 0,
    this.tutorialSeen = false,
    this.bgmVolume = 0.38,
    this.sfxVolume = 0.72,
    this.vibrationEnabled = true,
    this.vibrationStrength = 2,
    this.preferredDifficultyId = 'normal',
    this.preferredBattleSpeed = 1,
    this.preferredAutoPerk = false,
    this.preferredContinuousMarch = true,
    Map<String, int>? bestEndlessByDifficulty,
    Map<LauncherType, int>? launcherPermanentLevels,
    Set<StoneMaterial>? unlockedStones,
    Map<StoneMaterial, int>? stoneShards,
    Map<SpiritBeast, int>? beastLevels,
    Map<CompanionHero, int>? companionLevels,
    Map<CoreStatType, int>? coreStatLevels,
    Map<String, int>? stageStars,
    List<LoadoutPreset>? presets,
    Map<CraftMaterial, int>? materials,
    Map<TacticalConsumable, int>? consumables,
    Map<NightDeed, int>? dailyDeeds,
    Map<NightDeed, int>? weeklyDeeds,
    Map<NightDeed, int>? monthlyDeeds,
    Set<String>? claimedQuestIds,
    Set<String>? claimedAchievements,
    Set<MutantKind>? seenMutants,
  })  : highestClearedGlobalStage = highestClearedGlobalStage.clamp(
          0,
          CampaignCatalog.allStages.length,
        ),
        bestEndlessByDifficulty = bestEndlessByDifficulty ?? <String, int>{},
        launcherPermanentLevels = launcherPermanentLevels ??
            {for (final t in LauncherType.values) t: 1},
        unlockedStones = unlockedStones ?? {StoneMaterial.cheongok},
        stoneShards = stoneShards ??
            {
              StoneMaterial.onok: 0,
              StoneMaterial.yongrin: 0,
              StoneMaterial.taegeuk: 0,
            },
        beastLevels = beastLevels ??
            {
              for (final b in SpiritBeast.values)
                b: b == SpiritBeast.nalssaendol ? 1 : 0,
            },
        companionLevels = companionLevels ??
            {
              for (final c in CompanionHero.values)
                c: c == CompanionHero.seokdu ? 1 : 0,
            },
        coreStatLevels = coreStatLevels ??
            {for (final s in CoreStatType.values) s: 0},
        stageStars = stageStars ?? {},
        presets = presets ??
            [
              LoadoutPreset.starter(name: '1번 균형 진법'),
              LoadoutPreset.starter(name: '2번 중갑 파쇄 진법')
                ..sectTechnique = SectTechnique.ironFist
                ..primaryShape = StoneShape.sphere,
              LoadoutPreset.starter(name: '3번 빙결 도탄 진법')
                ..sectTechnique = SectTechnique.taiji
                ..primaryShape = StoneShape.flat,
            ],
        materials = materials ??
            {
              CraftMaterial.hyeoncheolOre: 2,
              CraftMaterial.moonHerb: 2,
              CraftMaterial.frostJade: 1,
              CraftMaterial.thunderPowder: 1,
            },
        consumables = consumables ??
            {
              TacticalConsumable.qiSurgePill: 1,
              TacticalConsumable.guardianRepairSeal: 1,
              TacticalConsumable.auroraCritCharm: 1,
            },
        dailyDeeds = dailyDeeds ?? {},
        weeklyDeeds = weeklyDeeds ?? {},
        monthlyDeeds = monthlyDeeds ?? {},
        claimedQuestIds = claimedQuestIds ?? {},
        claimedAchievements = claimedAchievements ?? {},
        seenMutants = seenMutants ?? {MutantKind.swarmRat};

  /// 돌연변이 처치 드롭 「증표」 — 발사대 및 중앙 보호 장치 강화·업그레이드 전용.
  int tokens;

  /// 「영약」 — 영수·동료 강화 및 내공 8경지 승급 전용.
  int elixirs;

  /// 초간단 수련으로 얻는 「수련 인장」 — 3대 능력치 원터치 단련용.
  int trainingSeals;

  /// 누적 내공 수치.
  int naegongPoints;

  /// 현재 내공 경지 인덱스 (0=삼류 ~ 7=생사경).
  int realmIndex;

  /// 중앙 자동 알 발사 보호 장치 영구 강화 등급.
  int centralGuardianLevel;

  /// 보유 「지원패(무림수호단 출두야~~!!)」 개수.
  int supportTokens;

  /// 보름달 길조 게이지 (0~100, 100 도달 시 확정 특급 기연 발동!).
  int moonOmenGauge;

  /// 클리어한 최고 전체 스테이지 번호 (0 ~ 100 · 10현 × 각 10판).
  int highestClearedGlobalStage;

  /// 개통 완료한 십대 경맥 단계 (0 ~ 10).
  int openedMeridianStep;

  /// 오늘 사용한 일일 깨달음(6배 보너스) 횟수 (최대 10회).
  int dailyEnlightenmentUsed;
  String lastMeditationDayKey;

  /// 물자 호송 상태 (방어 판 수 기반 시계 조작 방지).
  bool convoyActive;
  int convoyBattlesRemaining;
  int convoySupplyBuffBattles;
  int convoyCompletedCount;

  /// 심야 탐색 상태.
  bool exploreActive;
  int exploreBattlesRemaining;

  int activePresetIndex;

  /// 출석 · 임무 · 누적 통계 · 도감 · 환경 설정 상태.
  String attendanceDayKey;
  int attendanceStepCount;
  String dailyQuestDayKey;
  String weeklyQuestKey;
  String monthlyQuestKey;
  bool dailyAllClearClaimed;
  int totalMutantKills;
  int totalPporokCount;
  int totalBankShotCount;
  int totalChainShatterCount;
  int bestEndlessWave;
  int forgeMasteryLevel;
  int elixirResonanceLevel;

  /// 누적 환생(윤회 등선) 횟수 (0 = 초회차, 1 = 제1환생 ×3배, 2 = 제2환생 ×9배, k = ×3^k배 무한 상승!).
  int reincarnationCount;

  /// 현재 회차에서 [악몽] 난이도 제10현 최종 결전(10-10)을 정화했는지 여부.
  bool nightmareChapter10Cleared;

  /// 현재 회차에서 【윤회 최종 보스전】(성공 확률 <5%)을 격파해 환생 자격이 열렸는지 여부.
  bool reincarnationBossCleared;

  /// 누적 윤회 최종 보스전 도전 및 토벌 횟수.
  int reincarnationBossAttempts;
  int reincarnationBossWins;

  /// 환생자(reincarnationCount > 0) 전용 「윤회 초월 단련」 단계 — 환생 직후 능력치는 기존과 100% 동일하게 유지되며,
  /// 환생 후 높아진 3^k배 전장에서 획득한 증표·영약으로 초월 단련을 쌓아 다음 환생까지 무한 성장한다!
  int transcendenceLevel;

  bool tutorialSeen;
  double bgmVolume;
  double sfxVolume;
  bool vibrationEnabled;
  int vibrationStrength;
  String preferredDifficultyId;
  int preferredBattleSpeed;
  bool preferredAutoPerk;
  bool preferredContinuousMarch;
  final Map<String, int> bestEndlessByDifficulty;

  final Map<LauncherType, int> launcherPermanentLevels;
  final Set<StoneMaterial> unlockedStones;
  final Map<StoneMaterial, int> stoneShards;
  final Map<SpiritBeast, int> beastLevels;
  final Map<CompanionHero, int> companionLevels;
  final Map<CoreStatType, int> coreStatLevels;
  final Map<String, int> stageStars;
  final List<LoadoutPreset> presets;
  final Map<CraftMaterial, int> materials;
  final Map<TacticalConsumable, int> consumables;
  final Map<NightDeed, int> dailyDeeds;
  final Map<NightDeed, int> weeklyDeeds;
  final Map<NightDeed, int> monthlyDeeds;
  final Set<String> claimedQuestIds;
  final Set<String> claimedAchievements;
  final Set<MutantKind> seenMutants;

  /// 가장 최근 관문 첫 정화 시 구출 합류한 동료·영수 축하 알림 (일시 표시용).
  String? lastRescueBanner;
  CompanionHero? lastRescuedCompanion;
  SpiritBeast? lastRescuedBeast;

  NaegongRealm get realm => NaegongRealm.values[realmIndex.clamp(0, 7)];
  LoadoutPreset get activePreset => presets[activePresetIndex.clamp(0, presets.length - 1)];

  /// 앞으로 구출을 기다리는 가장 가까운 관문 (모두 구출 시 null).
  StageSpec? get nextRescueStage =>
      CampaignCatalog.nextRescueStageAfter(highestClearedGlobalStage);

  int get highestUnlockedChapter {
    if (highestClearedGlobalStage <= 0) return 1;
    final nextGlobal = (highestClearedGlobalStage + 1).clamp(1, CampaignCatalog.allStages.length);
    return CampaignCatalog.allStages[nextGlobal - 1].chapterNumber;
  }

  /// 무구·발사대·수호석·동료·영수·호송·탐색 개방 기준 장 번호:
  /// 환생(reincarnationCount > 0) 후 1-1부터 새로 행군할 때도 기존에 열었던 전 10현 무구·동료·영수·호송을 100% 그대로 사용할 수 있다!
  int get effectiveArsenalChapter =>
      reincarnationCount > 0 ? 10 : highestUnlockedChapter;

  /// 영수·동료 최대 단련 상한 (초회차 10단, 환생마다 +10단씩 확장되어 다회차 환생에서도 영약 성장이 계속 이어짐!).
  int get maxAllyLevel => (10 + reincarnationCount * 10).clamp(10, 999);

  /// 누적 환생 횟수에 따른 전 난이도 배율 (1환생 = 3배, 2환생 = 9배, 3환생 = 27배, k환생 = 3^k배!).
  double get reincarnationDifficultyMultiplier =>
      reincarnationCount <= 0 ? 1.0 : pow(3.0, reincarnationCount).toDouble();

  /// 환생 회차에 비례하는 영구 재화(증표·영약·내공·수련인장) 획득 배율.
  double get reincarnationRewardMultiplier =>
      reincarnationCount <= 0 ? 1.0 : pow(3.0, reincarnationCount).toDouble();

  /// 환생 후 「윤회 초월 단련」에 의한 총 공격력·호신강기 증폭 배율 (환생 직후 0단일 때는 1.0배로 기존 능력치 100% 그대로 유지!).
  double get transcendenceMultiplier =>
      transcendenceLevel <= 0 ? 1.0 : pow(1.12, transcendenceLevel).toDouble();

  int get transcendenceTokenCost {
    final tier = transcendenceLevel ~/ 10;
    final stepInTier = transcendenceLevel % 10;
    final raw = (360 + stepInTier * 90) * pow(3.0, tier);
    return raw.isFinite ? raw.round().clamp(360, 900000000) : 900000000;
  }

  int get transcendenceElixirCost {
    final tier = transcendenceLevel ~/ 10;
    final stepInTier = transcendenceLevel % 10;
    final raw = (10 + stepInTier * 3) * pow(2.6, tier);
    return raw.isFinite ? raw.round().clamp(10, 90000000) : 90000000;
  }

  bool upgradeTranscendence() {
    if (reincarnationCount <= 0 || transcendenceLevel >= 9999) return false;
    final tCost = transcendenceTokenCost;
    final eCost = transcendenceElixirCost;
    if (tokens < tCost || elixirs < eCost) return false;
    tokens -= tCost;
    elixirs -= eCost;
    transcendenceLevel++;
    return true;
  }

  /// 현재 회차에서 윤회 최종 보스전에 도전할 수 있는지 여부 (악몽 10-10 클리어 완료 & 아직 보스 미격파, 또는 격파 후에도 재도전 가능하도록 별도 안내).
  bool get canChallengeReincarnationBoss => nightmareChapter10Cleared;

  /// 현재 회차에서 윤회 최종 보스전까지 정복해 즉시 환생 의식을 거행할 수 있는지 여부.
  bool get canPerformReincarnation =>
      nightmareChapter10Cleared && reincarnationBossCleared && reincarnationCount < 999;

  /// 【윤회 환생】 실행:
  /// - 모든 영구 능력치(경지·경맥·내공·수련3대능력·중앙탑·5발사대·신기연마·영기공명·초월단련·13수호석·14동료·5영수·재화·지원패·비약·프리셋) 100% 유지!
  /// - 캠페인 진행도만 1-1(0판)로 초기화하고 `reincarnationCount`를 +1 올려 전 난이도를 기존 대비 3배(누적 3^k배) 격상한다!
  bool performReincarnation() {
    if (!canPerformReincarnation) return false;
    reincarnationCount = (reincarnationCount + 1).clamp(1, 999);
    highestClearedGlobalStage = 0;
    stageStars.clear();
    nightmareChapter10Cleared = false;
    reincarnationBossCleared = false;
    lastRescueBanner = null;
    lastRescuedCompanion = null;
    lastRescuedBeast = null;

    // 등선 축하 군수 보급: 새 회차 3배 혈전에 대비해 지원패 +3 및 전술 비약 3종 각 +2 수여
    supportTokens = (supportTokens + 3).clamp(0, 999999);
    for (final item in TacticalConsumable.values) {
      consumables[item] = ((consumables[item] ?? 0) + 2).clamp(0, 999999);
    }
    return true;
  }

  bool isStageUnlocked(StageSpec stage) {
    if (stage.isReincarnationBossStage) {
      return nightmareChapter10Cleared;
    }
    return stage.globalIndex <= highestClearedGlobalStage + 1;
  }

  // --- 수호 도감 수집률 및 세트 가산치 (최대 +12% 화력·방어막 보너스) ---
  int get unlockedLauncherCount =>
      LauncherType.values.where((t) => t.unlockChapter <= effectiveArsenalChapter).length;
  int get unlockedBeastCount => beastLevels.values.where((v) => v > 0).length;
  int get unlockedCompanionCount => companionLevels.values.where((v) => v > 0).length;

  int get codexCollectedCount =>
      1 + // 중앙 기명 수호탑 기본 보유
      unlockedStones.length +
      unlockedLauncherCount +
      unlockedBeastCount +
      unlockedCompanionCount +
      seenMutants.length;

  int get codexTotalCount =>
      1 + // 중앙 기명 수호탑 포함
      StoneMaterial.values.length +
      LauncherType.values.length +
      SpiritBeast.values.length +
      CompanionHero.values.length +
      MutantKind.values.length;

  double get codexPowerBonus => (codexCollectedCount / codexTotalCount).clamp(0.0, 1.0) * 0.12;

  // --- 경맥 & 3대 수련 능력치 누적 보너스 ---
  double get maxQiBars => openedMeridianStep >= 10 ? 4.0 : 3.0;
  double get meridianLauncherDmgBonus =>
      (openedMeridianStep >= 1 ? 0.06 : 0.0) + (openedMeridianStep >= 10 ? 0.14 : 0.0);
  double get meridianShieldHpBonus => openedMeridianStep >= 2 ? 0.10 : 0.0;
  double get meridianCentralReloadBonus => openedMeridianStep >= 3 ? 0.08 : 0.0;
  double get meridianAllyCooldownReduction => openedMeridianStep >= 4 ? 0.08 : 0.0;
  double get meridianTokenDropBonus => openedMeridianStep >= 5 ? 0.10 : 0.0;
  double get meridianCritBonus => openedMeridianStep >= 6 ? 0.06 : 0.0;
  double get meridianStartQiBonus =>
      (openedMeridianStep >= 7 ? 0.6 : 0.0) + (openedMeridianStep >= 10 ? 1.0 : 0.0);
  double get meridianSerendipityBonus =>
      (openedMeridianStep >= 8 ? 0.06 : 0.0) + (openedMeridianStep >= 10 ? 0.04 : 0.0);
  double get meridianKnockbackBonus => openedMeridianStep >= 9 ? 0.12 : 0.0;

  double get coreFirepowerBonus => (coreStatLevels[CoreStatType.firepower] ?? 0) * 0.035;
  double get coreFortitudeBonus => (coreStatLevels[CoreStatType.fortitude] ?? 0) * 0.045;
  double get corePrecisionBonus => (coreStatLevels[CoreStatType.precision] ?? 0) * 0.035;

  static bool _isFarFutureClockDrift(String storedDay, String currentDay) {
    final a = DateTime.tryParse(storedDay);
    final b = DateTime.tryParse(currentDay);
    if (a == null || b == null) return false;
    return a.difference(b).inDays > 180;
  }

  /// 오늘 남은 일일 깨달음(고배율 운기) 횟수 조회 (새로운 날 진입 시 즉시 10회 반환).
  int remainingDailyEnlightenment({String? todayKey}) {
    final day = todayKey ?? _todayString();
    if (_isFarFutureClockDrift(lastMeditationDayKey, day)) {
      return 0;
    }
    if (lastMeditationDayKey.isEmpty || day.compareTo(lastMeditationDayKey) > 0) {
      return 10;
    }
    return (10 - dailyEnlightenmentUsed).clamp(0, 10);
  }

  /// 1) 초간단 단전 운기 호흡 (아무 때나 눌러도 100% 성공 · 실패 0%!).
  MeditationResult meditateOnce({
    required bool hitGoldenRing,
    required Random rng,
    String? todayKey,
  }) {
    final day = todayKey ?? _todayString();
    if (_isFarFutureClockDrift(lastMeditationDayKey, day)) {
      // 잘못된 먼 미래 시계(180일 초과)에서 정상 날짜로 복귀한 경우 당일 중복 보상은 막되 내일부터 정상 회복!
      lastMeditationDayKey = day;
      dailyEnlightenmentUsed = 10;
    } else if (lastMeditationDayKey.isEmpty || day.compareTo(lastMeditationDayKey) > 0) {
      lastMeditationDayKey = day;
      dailyEnlightenmentUsed = 0;
    }

    final hasDailyBonus = dailyEnlightenmentUsed < 10;
    if (hasDailyBonus) {
      dailyEnlightenmentUsed++;
    }

    int baseNaegong = hasDailyBonus ? 36 : 12;
    int baseSeals = hasDailyBonus ? 9 : 3;

    final serendipityChance = (hitGoldenRing ? 0.45 : 0.16) + meridianSerendipityBonus;
    final isCrit = hitGoldenRing || rng.nextDouble() < serendipityChance * 0.5;
    final isOneMore = rng.nextDouble() < (0.20 + meridianSerendipityBonus);

    if (isCrit) {
      baseNaegong *= 2;
      baseSeals *= 2;
    }
    if (isOneMore) {
      baseNaegong = (baseNaegong * 1.6).round();
      baseSeals += 4;
    }

    naegongPoints += baseNaegong;
    trainingSeals += baseSeals;
    // 오늘의 깨달음(하루 첫 10회) 수련 중에만 보름달 길조 게이지가 차오르며, 이후에는 실전 수호로 충전된다(전투 0회 무한 수령 악용 차단!).
    if (hasDailyBonus) {
      moonOmenGauge = (moonOmenGauge + 4).clamp(0, 100);
    }
    recordDeed(NightDeed.meditate, 1, todayKey: day);
    if (isCrit || isOneMore) {
      recordDeed(NightDeed.serendipityHit, 1, todayKey: day);
    }

    return MeditationResult(
      gainedNaegong: baseNaegong,
      gainedSeals: baseSeals,
      wasEnlightenmentBonus: hasDailyBonus,
      wasCriticalSerendipity: isCrit,
      wasOneMoreSerendipity: isOneMore,
      remainingDailyBonusCount: (10 - dailyEnlightenmentUsed).clamp(0, 10),
    );
  }

  /// 10회 연속 단전 운기 편의 실행 (손가락 피로 없이 한 번에 10회 수련!).
  MeditationResult meditateBatch({
    required int count,
    required bool hitGoldenRing,
    required Random rng,
    String? todayKey,
  }) {
    final safeCount = count.clamp(1, 20);
    int totNaegong = 0;
    int totSeals = 0;
    bool anyBonus = false;
    bool anyCrit = false;
    bool anyOneMore = false;
    int lastRemain = 0;
    for (int i = 0; i < safeCount; i++) {
      final r = meditateOnce(hitGoldenRing: hitGoldenRing, rng: rng, todayKey: todayKey);
      totNaegong += r.gainedNaegong;
      totSeals += r.gainedSeals;
      if (r.wasEnlightenmentBonus) anyBonus = true;
      if (r.wasCriticalSerendipity) anyCrit = true;
      if (r.wasOneMoreSerendipity) anyOneMore = true;
      lastRemain = r.remainingDailyBonusCount;
    }
    return MeditationResult(
      gainedNaegong: totNaegong,
      gainedSeals: totSeals,
      wasEnlightenmentBonus: anyBonus,
      wasCriticalSerendipity: anyCrit,
      wasOneMoreSerendipity: anyOneMore,
      remainingDailyBonusCount: lastRemain,
    );
  }

  /// 2) 십대 경맥 개통 (혈자리 구슬만 다 누르면 실패 0% 즉시 개통!).
  bool canOpenNextMeridian() {
    if (openedMeridianStep < 0 || openedMeridianStep >= MeridianStepSpec.steps.length) {
      return false;
    }
    final nextSpec = MeridianStepSpec.steps[openedMeridianStep];
    return naegongPoints >= nextSpec.reqNaegong;
  }

  MeridianStepSpec? openNextMeridian() {
    if (!canOpenNextMeridian()) return null;
    final spec = MeridianStepSpec.steps[openedMeridianStep];
    openedMeridianStep++;
    tokens += spec.rewardTokens;
    elixirs += spec.rewardElixirs;
    supportTokens += spec.rewardSupportTokens;
    return spec;
  }

  /// 3) 3대 능력치 원터치 단련.
  int coreStatUpgradeCost(CoreStatType type) {
    final lv = coreStatLevels[type] ?? 0;
    return 6 + lv * 5;
  }

  bool upgradeCoreStat(CoreStatType type) {
    final cur = coreStatLevels[type] ?? 0;
    if (cur >= 999) return false;
    final cost = coreStatUpgradeCost(type);
    if (trainingSeals < cost) return false;
    trainingSeals -= cost;
    coreStatLevels[type] = cur + 1;
    return true;
  }

  /// 4) 대장간 — 증표로 중앙 보호 장치 / 길목 발사대 영구 강화 및 알 해금.
  bool upgradeCentralGuardian() {
    if (centralGuardianLevel >= 999) return false;
    final cost = CentralGuardianSpec.permanentUpgradeCost(centralGuardianLevel);
    if (tokens < cost) return false;
    tokens -= cost;
    centralGuardianLevel++;
    return true;
  }

  bool upgradeLauncherPermanent(LauncherType type) {
    final lv = launcherPermanentLevels[type] ?? 1;
    if (lv >= 999) return false;
    final cost = type.permanentUpgradeCost(lv);
    if (tokens < cost) return false;
    tokens -= cost;
    launcherPermanentLevels[type] = lv + 1;
    return true;
  }

  int get forgeMasteryCost => 260 + forgeMasteryLevel * 95;
  double get forgeMasteryPowerBonus => forgeMasteryLevel * 0.045;

  bool upgradeForgeMastery() {
    if (forgeMasteryLevel >= 9999) return false;
    final cost = forgeMasteryCost;
    if (tokens < cost) return false;
    tokens -= cost;
    forgeMasteryLevel++;
    return true;
  }

  bool canUnlockStone(StoneMaterial stone) {
    if (unlockedStones.contains(stone)) return false;
    if (effectiveArsenalChapter < stone.minChapter) return false;
    if (stone.isShardStone) {
      return (stoneShards[stone] ?? 0) >= stone.shardRequired;
    }
    return tokens >= stone.unlockTokens;
  }

  bool unlockStoneWithTokens(StoneMaterial stone) {
    if (unlockedStones.contains(stone)) return false;
    if (effectiveArsenalChapter < stone.minChapter) return false;
    if (stone.isShardStone) {
      final have = stoneShards[stone] ?? 0;
      if (have < stone.shardRequired) return false;
      stoneShards[stone] = have - stone.shardRequired;
      unlockedStones.add(stone);
      return true;
    }
    if (tokens < stone.unlockTokens) return false;
    tokens -= stone.unlockTokens;
    unlockedStones.add(stone);
    return true;
  }

  /// 5) 영약각 — 영약으로 내공 8경지 돌파, 호법 영기 무한 공명, 영수 강화, 동료 강화.
  int get elixirResonanceCost => 10 + elixirResonanceLevel * 4;
  double get elixirResonanceBonus => elixirResonanceLevel * 0.055;

  bool upgradeElixirResonance() {
    if (elixirResonanceLevel >= 9999) return false;
    final cost = elixirResonanceCost;
    if (elixirs < cost) return false;
    elixirs -= cost;
    elixirResonanceLevel++;
    return true;
  }

  bool breakthroughRealm() {
    final next = realm.nextRealm;
    if (next == null) return false;
    if (naegongPoints < next.reqNaegong || elixirs < next.reqElixir) return false;
    elixirs -= next.reqElixir;
    realmIndex = next.indexStep;
    return true;
  }

  bool unlockOrUpgradeBeast(SpiritBeast beast) {
    final cur = beastLevels[beast] ?? 0;
    if (cur == 0 && effectiveArsenalChapter < beast.unlockChapter) return false;
    final cost = cur == 0 ? beast.unlockElixirs : beast.upgradeElixirCost(lvOrZero(cur));
    if (cur >= maxAllyLevel || elixirs < cost) return false;
    elixirs -= cost;
    beastLevels[beast] = cur + 1;
    if (cur == 0 && beast.index > activePreset.equippedBeast.index) {
      activePreset.equippedBeast = beast;
      activePreset.beastCondition = beast.defaultCondition;
    }
    return true;
  }

  static int lvOrZero(int v) => v < 0 ? 0 : v;

  bool unlockOrUpgradeCompanion(CompanionHero hero) {
    final cur = companionLevels[hero] ?? 0;
    if (cur == 0 &&
        (hero.unlockElixirs <= 0 || effectiveArsenalChapter < hero.unlockChapter)) {
      return false;
    }
    final cost = cur == 0 ? hero.unlockElixirs : hero.upgradeElixirCost(lvOrZero(cur));
    if (cur >= maxAllyLevel || elixirs < cost) return false;
    elixirs -= cost;
    companionLevels[hero] = cur + 1;
    if (cur == 0 &&
        hero != CompanionHero.mukhyeon &&
        activePreset.companions.length < 3 &&
        !activePreset.companions.contains(hero)) {
      activePreset.companions.add(hero);
    }
    return true;
  }

  /// 6) 물자 호송 & 심야 탐색 출발 및 수령 (지원패 3대 수급 경로 + 크리티컬·한 번 더 기연!).
  bool startSupplyConvoy() {
    if (effectiveArsenalChapter < 2 || convoyActive) return false;
    convoyActive = true;
    convoyBattlesRemaining = 2;
    return true;
  }

  DispatchClaimResult? claimSupplyConvoy(Random rng, {String? todayKey}) {
    if (!convoyActive || convoyBattlesRemaining > 0) return null;
    convoyActive = false;
    convoyCompletedCount++;
    convoySupplyBuffBattles = 3;

    final chScale = effectiveArsenalChapter;
    final rMult = reincarnationRewardMultiplier;
    int gainTokens = ((55 + chScale * 18) * rMult).round().clamp(1, 90000000);
    int gainElixirs = ((2 + (chScale ~/ 3)) * rMult).round().clamp(1, 9000000);
    // 조건 달성 경로: 호송 완수 시 지원패 확정 1개 지급!
    int gainSupport = 1;
    int gainShards = rng.nextDouble() < 0.45 ? 2 : 1;

    final isCrit = rng.nextDouble() < (0.28 + meridianSerendipityBonus);
    final isEncore = rng.nextDouble() < (0.22 + meridianSerendipityBonus);

    if (isCrit) {
      gainTokens *= 2;
      gainElixirs *= 2;
    }
    if (isEncore) {
      gainTokens = (gainTokens * 1.5).round();
      gainElixirs += 2;
      gainSupport += 1;
    }

    tokens += gainTokens;
    elixirs += gainElixirs;
    supportTokens += gainSupport;
    _grantRandomShards(gainShards, rng);
    final bonusMat = CraftMaterial.values[rng.nextInt(CraftMaterial.values.length)];
    materials[bonusMat] = (materials[bonusMat] ?? 0) + 1;
    if (isCrit || isEncore) {
      recordDeed(NightDeed.serendipityHit, 1, todayKey: todayKey);
    }

    return DispatchClaimResult(
      title: '구출 마을 식량·영약 호송 마차 도착!',
      gainedTokens: gainTokens,
      gainedElixirs: gainElixirs,
      gainedSupportTokens: gainSupport,
      gainedShards: gainShards,
      wasCritical: isCrit,
      wasEncoreOneMore: isEncore,
    );
  }

  bool startNightExplore() {
    if (effectiveArsenalChapter < 4 || exploreActive) return false;
    exploreActive = true;
    exploreBattlesRemaining = 2;
    return true;
  }

  DispatchClaimResult? claimNightExplore(Random rng, {String? todayKey}) {
    if (!exploreActive || exploreBattlesRemaining > 0) return null;
    exploreActive = false;

    final chScale = effectiveArsenalChapter;
    final rMult = reincarnationRewardMultiplier;
    int gainTokens = ((40 + chScale * 14) * rMult).round().clamp(1, 90000000);
    int gainElixirs = ((3 + (chScale ~/ 3)) * rMult).round().clamp(1, 9000000);
    // 탐색 경로: 봉화대 정찰로 지원패 발굴!
    int gainSupport = rng.nextDouble() < 0.70 ? 1 : 0;
    int gainShards = 3;

    final isCrit = rng.nextDouble() < (0.26 + meridianSerendipityBonus);
    final isEncore = rng.nextDouble() < (0.22 + meridianSerendipityBonus);

    if (isCrit) {
      gainElixirs *= 2;
      gainShards *= 2;
    }
    if (isEncore) {
      gainSupport += 1;
      gainTokens += (45 * rMult).round().clamp(45, 45000000);
    }

    tokens += gainTokens;
    elixirs += gainElixirs;
    supportTokens += gainSupport;
    _grantRandomShards(gainShards, rng);
    final bonusMat = CraftMaterial.values[rng.nextInt(CraftMaterial.values.length)];
    materials[bonusMat] = (materials[bonusMat] ?? 0) + 1;
    if (isCrit || isEncore) {
      recordDeed(NightDeed.serendipityHit, 1, todayKey: todayKey);
    }

    return DispatchClaimResult(
      title: '심야 산야 탐색대 귀환!',
      gainedTokens: gainTokens,
      gainedElixirs: gainElixirs,
      gainedSupportTokens: gainSupport,
      gainedShards: gainShards,
      wasCritical: isCrit,
      wasEncoreOneMore: isEncore,
    );
  }

  /// 7) 보름달 길조 게이지 100% 달성 확정 기연 열기 (기연 경로 지원패!).
  DispatchClaimResult? claimFullMoonSerendipity(Random rng, {String? todayKey}) {
    if (moonOmenGauge < 100) return null;
    moonOmenGauge = 0;

    final chScale = effectiveArsenalChapter;
    final rMult = reincarnationRewardMultiplier;
    int gainTokens = ((70 + chScale * 20) * rMult).round().clamp(1, 90000000);
    int gainElixirs = ((3 + (chScale ~/ 2)) * rMult).round().clamp(1, 9000000);
    int gainSupport = 1;
    int gainShards = 4;

    final isCrit = rng.nextDouble() < 0.35;
    final isEncore = rng.nextDouble() < 0.25;
    if (isCrit) {
      gainTokens *= 2;
      gainElixirs += 3;
    }
    if (isEncore) {
      gainSupport += 1;
      gainShards += 3;
    }

    tokens += gainTokens;
    elixirs += gainElixirs;
    supportTokens += gainSupport;
    _grantRandomShards(gainShards, rng);
    recordDeed(NightDeed.serendipityHit, 1, todayKey: todayKey);

    return DispatchClaimResult(
      title: '보름달 대길조 특급 기연 발동!',
      gainedTokens: gainTokens,
      gainedElixirs: gainElixirs,
      gainedSupportTokens: gainSupport,
      gainedShards: gainShards,
      wasCritical: isCrit,
      wasEncoreOneMore: isEncore,
    );
  }

  /// 8) 공통 보상 꾸러미 지급.
  void applyRewardBundle(NightRewardBundle bundle, [Random? rng]) {
    tokens += bundle.tokens;
    elixirs += bundle.elixirs;
    trainingSeals += bundle.trainingSeals;
    supportTokens += bundle.supportTokens;
    if (bundle.shards > 0) {
      _grantRandomShards(bundle.shards, rng ?? Random());
    }
    for (final e in bundle.materials.entries) {
      materials[e.key] = (materials[e.key] ?? 0) + e.value;
    }
    for (final e in bundle.consumables.entries) {
      consumables[e.key] = (consumables[e.key] ?? 0) + e.value;
    }
  }

  /// 9) 7일 순환 출석부 (빠진 날이 있어도 초기화되지 않고 이어짐).
  int get currentAttendanceDayIndex => (attendanceStepCount < 0 ? 0 : attendanceStepCount) % 7;

  bool canClaimAttendance({String? todayKey}) {
    final day = todayKey ?? _todayString();
    final sane = NightAttendance.saneDayKey(attendanceDayKey, day);
    return sane != day;
  }

  NightRewardBundle? claimAttendance({Random? rng, String? todayKey}) {
    final day = todayKey ?? _todayString();
    if (!canClaimAttendance(todayKey: day)) return null;
    final reward = NightAttendance.sevenDayRewards[currentAttendanceDayIndex];
    attendanceDayKey = day;
    attendanceStepCount = (attendanceStepCount < 0 ? 0 : attendanceStepCount) + 1;
    applyRewardBundle(reward, rng);
    return reward;
  }

  /// 10) 일일·주간·월간 수호 임무 기록 및 수령 (기기 시계 역행 남용 차단).
  void syncQuestPeriods({String? todayKey}) {
    final day = todayKey ?? _todayString();
    if (_isFarFutureClockDrift(attendanceDayKey, day)) {
      attendanceDayKey = day;
    }
    if (_isFarFutureClockDrift(dailyQuestDayKey, day)) {
      dailyQuestDayKey = day;
      weeklyQuestKey = NightQuestCatalog.weekKeyOf(day);
      monthlyQuestKey = NightQuestCatalog.monthKeyOf(day);
    }
    final saneDaily = NightAttendance.saneDayKey(dailyQuestDayKey, day);
    if (saneDaily != day) {
      dailyQuestDayKey = day;
      dailyDeeds.clear();
      dailyAllClearClaimed = false;
      claimedQuestIds.removeWhere((id) => id.startsWith('d_'));
    }
    final wk = NightQuestCatalog.weekKeyOf(day);
    if (weeklyQuestKey.isEmpty || wk.compareTo(weeklyQuestKey) > 0) {
      weeklyQuestKey = wk;
      weeklyDeeds.clear();
      claimedQuestIds.removeWhere((id) => id.startsWith('w_'));
    }
    final mk = NightQuestCatalog.monthKeyOf(day);
    if (monthlyQuestKey.isEmpty || mk.compareTo(monthlyQuestKey) > 0) {
      monthlyQuestKey = mk;
      monthlyDeeds.clear();
      claimedQuestIds.removeWhere((id) => id.startsWith('m_'));
    }
  }

  void recordDeed(NightDeed deed, int amount, {String? todayKey}) {
    if (amount <= 0) return;
    syncQuestPeriods(todayKey: todayKey);
    dailyDeeds[deed] = (dailyDeeds[deed] ?? 0) + amount;
    weeklyDeeds[deed] = (weeklyDeeds[deed] ?? 0) + amount;
    monthlyDeeds[deed] = (monthlyDeeds[deed] ?? 0) + amount;
  }

  List<NightMissionSpec> todayDailyMissions({String? todayKey}) {
    final day = todayKey ?? _todayString();
    syncQuestPeriods(todayKey: day);
    return NightQuestCatalog.dailyOf(day);
  }

  int deedProgress(NightMissionSpec m, {String? todayKey}) {
    syncQuestPeriods(todayKey: todayKey);
    return switch (m.period) {
      QuestPeriodKind.daily => dailyDeeds[m.deed] ?? 0,
      QuestPeriodKind.weekly => weeklyDeeds[m.deed] ?? 0,
      QuestPeriodKind.monthly => monthlyDeeds[m.deed] ?? 0,
    };
  }

  bool isMissionClaimed(NightMissionSpec m, {String? todayKey}) {
    syncQuestPeriods(todayKey: todayKey);
    return claimedQuestIds.contains(m.id);
  }

  bool canClaimMission(NightMissionSpec m, {String? todayKey}) {
    final day = todayKey ?? _todayString();
    if (m.period == QuestPeriodKind.daily &&
        !todayDailyMissions(todayKey: day).any((dm) => dm.id == m.id)) {
      return false;
    }
    return !isMissionClaimed(m, todayKey: day) &&
        deedProgress(m, todayKey: day) >= m.goal;
  }

  NightRewardBundle? claimMission(NightMissionSpec m, {Random? rng, String? todayKey}) {
    if (!canClaimMission(m, todayKey: todayKey)) return null;
    claimedQuestIds.add(m.id);
    applyRewardBundle(m.reward, rng);
    return m.reward;
  }

  bool canClaimDailyAllClear({String? todayKey}) {
    final day = todayKey ?? _todayString();
    syncQuestPeriods(todayKey: day);
    if (dailyAllClearClaimed) return false;
    final dailies = NightQuestCatalog.dailyOf(day);
    return dailies.every((m) => claimedQuestIds.contains(m.id));
  }

  NightRewardBundle? claimDailyAllClear({Random? rng, String? todayKey}) {
    if (!canClaimDailyAllClear(todayKey: todayKey)) return null;
    dailyAllClearClaimed = true;
    applyRewardBundle(NightQuestCatalog.dailyAllClearBonus, rng);
    return NightQuestCatalog.dailyAllClearBonus;
  }

  /// 11) 전술 비약 제조 (수호 재료 조합).
  bool canCraftConsumable(TacticalConsumable item) {
    for (final req in item.recipe.entries) {
      if ((materials[req.key] ?? 0) < req.value) return false;
    }
    return true;
  }

  bool craftConsumable(TacticalConsumable item) {
    if (!canCraftConsumable(item)) return false;
    for (final req in item.recipe.entries) {
      materials[req.key] = (materials[req.key] ?? 0) - req.value;
    }
    consumables[item] = (consumables[item] ?? 0) + 1;
    return true;
  }

  /// 12) 영구 업적 달성 확인 및 수령.
  bool isAchievementMet(NightAchievementSpec a) {
    switch (a.id) {
      case 'ach_first_dawn':
        return reincarnationCount > 0 || highestClearedGlobalStage >= 1;
      case 'ach_ch1_clear':
        return reincarnationCount > 0 ||
            highestClearedGlobalStage >= CampaignCatalog.stagesOfChapter(1).last.globalIndex;
      case 'ach_ch3_clear':
        return reincarnationCount > 0 ||
            highestClearedGlobalStage >= CampaignCatalog.stagesOfChapter(3).last.globalIndex;
      case 'ach_ch6_clear':
        return reincarnationCount > 0 ||
            highestClearedGlobalStage >= CampaignCatalog.stagesOfChapter(6).last.globalIndex;
      case 'ach_ch10_clear':
        return reincarnationCount > 0 ||
            highestClearedGlobalStage >= CampaignCatalog.allStages.length;
      case 'ach_meridian_5':
        return openedMeridianStep >= 5;
      case 'ach_meridian_10':
        return openedMeridianStep >= 10;
      case 'ach_pporok_20':
        return totalPporokCount >= 20;
      case 'ach_bank_15':
        return totalBankShotCount >= 15;
      case 'ach_chain_15':
        return totalChainShatterCount >= 15;
      case 'ach_convoy_5':
        return convoyCompletedCount >= 5;
      case 'ach_endless_10':
        return bestEndlessWave >= 10;
      default:
        return false;
    }
  }

  bool canClaimAchievement(NightAchievementSpec a) =>
      !claimedAchievements.contains(a.id) && isAchievementMet(a);

  NightRewardBundle? claimAchievement(NightAchievementSpec a, {Random? rng}) {
    if (!canClaimAchievement(a)) return null;
    claimedAchievements.add(a.id);
    applyRewardBundle(a.reward, rng);
    return a.reward;
  }

  /// 출석·임무·업적 중 즉시 받을 수 있는 보상이 있는지 여부 (홈 알림 배지용).
  bool hasClaimableRewards({String? todayKey}) {
    if (canClaimAttendance(todayKey: todayKey)) return true;
    if (canClaimDailyAllClear(todayKey: todayKey)) return true;
    for (final m in todayDailyMissions(todayKey: todayKey)) {
      if (canClaimMission(m, todayKey: todayKey)) return true;
    }
    for (final m in NightQuestCatalog.weeklyMissions) {
      if (canClaimMission(m, todayKey: todayKey)) return true;
    }
    for (final m in NightQuestCatalog.monthlyMissions) {
      if (canClaimMission(m, todayKey: todayKey)) return true;
    }
    for (final a in NightAchievementSpec.all) {
      if (canClaimAchievement(a)) return true;
    }
    return false;
  }

  /// 보름달 기연·호송·탐색·출석·임무·업적 또는 미출발 호송/탐색까지 포함해 원터치 행동 가능 여부.
  bool hasAnyReadyAction({String? todayKey}) {
    if (moonOmenGauge >= 100) return true;
    if (convoyActive && convoyBattlesRemaining <= 0) return true;
    if (exploreActive && exploreBattlesRemaining <= 0) return true;
    if (effectiveArsenalChapter >= 2 && !convoyActive) return true;
    if (effectiveArsenalChapter >= 4 && !exploreActive) return true;
    return hasClaimableRewards(todayKey: todayKey);
  }

  /// 도착한 모든 보상(보름달·호송·탐색·출석·일일/주간/월간 임무·업적)을 한 번에 수령하고 호송/탐색을 자동 재파견!
  BatchClaimSummary claimAllReadyRewards(
    Random rng, {
    String? todayKey,
    bool autoRedispatch = true,
  }) {
    final beforeTokens = tokens;
    final beforeElixirs = elixirs;
    final beforeSupport = supportTokens;
    final beforeSeals = trainingSeals;
    final beforeShards = stoneShards.values.fold<int>(0, (a, b) => a + b);
    final sources = <String>[];
    int count = 0;

    if (moonOmenGauge >= 100) {
      final r = claimFullMoonSerendipity(rng, todayKey: todayKey);
      if (r != null) {
        count++;
        sources.add('보름달 기연');
      }
    }
    if (convoyActive && convoyBattlesRemaining <= 0) {
      final r = claimSupplyConvoy(rng, todayKey: todayKey);
      if (r != null) {
        count++;
        sources.add('물자 호송');
      }
    }
    if (exploreActive && exploreBattlesRemaining <= 0) {
      final r = claimNightExplore(rng, todayKey: todayKey);
      if (r != null) {
        count++;
        sources.add('심야 탐색');
      }
    }
    if (canClaimAttendance(todayKey: todayKey)) {
      final b = claimAttendance(rng: rng, todayKey: todayKey);
      if (b != null) {
        count++;
        sources.add('출석 보상');
      }
    }

    int missionCnt = 0;
    for (final m in todayDailyMissions(todayKey: todayKey)) {
      if (claimMission(m, rng: rng, todayKey: todayKey) != null) {
        count++;
        missionCnt++;
      }
    }
    if (claimDailyAllClear(rng: rng, todayKey: todayKey) != null) {
      count++;
      missionCnt++;
    }
    for (final m in NightQuestCatalog.weeklyMissions) {
      if (claimMission(m, rng: rng, todayKey: todayKey) != null) {
        count++;
        missionCnt++;
      }
    }
    for (final m in NightQuestCatalog.monthlyMissions) {
      if (claimMission(m, rng: rng, todayKey: todayKey) != null) {
        count++;
        missionCnt++;
      }
    }
    if (missionCnt > 0) {
      sources.add('수호 임무 $missionCnt건');
    }

    int achCnt = 0;
    for (final a in NightAchievementSpec.all) {
      if (claimAchievement(a, rng: rng) != null) {
        count++;
        achCnt++;
      }
    }
    if (achCnt > 0) {
      sources.add('업적 $achCnt건');
    }

    bool sentConvoy = false;
    bool sentExplore = false;
    if (autoRedispatch) {
      if (effectiveArsenalChapter >= 2 && !convoyActive) {
        sentConvoy = startSupplyConvoy();
      }
      if (effectiveArsenalChapter >= 4 && !exploreActive) {
        sentExplore = startNightExplore();
      }
    }

    final afterShards = stoneShards.values.fold<int>(0, (a, b) => a + b);
    return BatchClaimSummary(
      claimedCount: count,
      gainedTokens: max(0, tokens - beforeTokens),
      gainedElixirs: max(0, elixirs - beforeElixirs),
      gainedSupportTokens: max(0, supportTokens - beforeSupport),
      gainedSeals: max(0, trainingSeals - beforeSeals),
      gainedShards: max(0, afterShards - beforeShards),
      redispatchedConvoy: sentConvoy,
      redispatchedExplore: sentExplore,
      sources: sources,
    );
  }

  /// 보유 증표·영약·수련인장으로 가장 효율 높은 항목을 최대 [maxSteps]회 스마트 일괄 강화!
  List<String> upgradeRecommendedBatch({int maxSteps = 5}) {
    if (maxSteps <= 0) return const [];
    final logs = <String>[];
    final limit = maxSteps.clamp(1, 15);

    for (int step = 0; step < limit; step++) {
      // 1순위: 경맥 즉시 개통 가능 시 개통 (무료 내공 조건 + 재화 보상 획득!)
      final opened = openNextMeridian();
      if (opened != null) {
        logs.add('경맥 [${opened.name}] 개통');
        continue;
      }

      // 2순위: 내공 경지 돌파 가능 시 돌파
      if (breakthroughRealm()) {
        logs.add('내공 경지 [${realm.name}] 승급');
        continue;
      }

      // 3순위: 조각 수호석(11~13단) 및 현재 장 해금 가능한 상위 증표 수호석(2~10단) 해금!
      StoneMaterial? unlockedStoneNow;
      for (final st in StoneMaterial.values.reversed) {
        if (st.isShardStone && canUnlockStone(st) && unlockStoneWithTokens(st)) {
          unlockedStoneNow = st;
          if (st.grade > activePreset.primaryStone.grade) {
            activePreset.primaryStone = st;
          }
          break;
        }
      }
      if (unlockedStoneNow == null) {
        for (final st in StoneMaterial.values) {
          if (!st.isShardStone && canUnlockStone(st) && unlockStoneWithTokens(st)) {
            unlockedStoneNow = st;
            if (st.grade > activePreset.primaryStone.grade) {
              activePreset.primaryStone = st;
            }
            break;
          }
        }
      }
      if (unlockedStoneNow != null) {
        logs.add('${unlockedStoneNow.grade}단 [${unlockedStoneNow.name}] 해금');
        continue;
      }

      // 3.5순위: 환생자 전용 「윤회 초월 단련」 가능 시 최우선 돌파 (3^k배 환생 난이도 대응 핵심 승수 성장!)
      if (upgradeTranscendence()) {
        logs.add('윤회 초월 단련 $transcendenceLevel단');
        continue;
      }

      // 4순위: 중앙 수호탑 vs 현재 진법/해금 주력 발사대 중 아직 상한(999단) 미만인 최소 비용 강화
      final unlockedLaunchers = LauncherType.values
          .where(
            (t) =>
                t.unlockChapter <= effectiveArsenalChapter &&
                (launcherPermanentLevels[t] ?? 1) < 999,
          )
          .toList();
      final presetSet = activePreset.mountTypes.toSet();
      final candidateLaunchers = unlockedLaunchers
          .where(presetSet.contains)
          .toList();
      final pool = candidateLaunchers.isNotEmpty
          ? candidateLaunchers
          : unlockedLaunchers;
      LauncherType? cheapestLauncher;
      int cheapestLauncherCost = 1 << 30;
      for (final lt in pool) {
        final c = lt.permanentUpgradeCost(launcherPermanentLevels[lt] ?? 1);
        if (c < cheapestLauncherCost) {
          cheapestLauncherCost = c;
          cheapestLauncher = lt;
        }
      }
      final canUpgCentral = centralGuardianLevel < 999;
      final centralCost = canUpgCentral
          ? CentralGuardianSpec.permanentUpgradeCost(centralGuardianLevel)
          : (1 << 30);
      if (canUpgCentral && centralCost <= cheapestLauncherCost && upgradeCentralGuardian()) {
        logs.add('중앙 수호탑 $centralGuardianLevel단');
        continue;
      }
      if (cheapestLauncher != null && upgradeLauncherPermanent(cheapestLauncher)) {
        logs.add('${cheapestLauncher.name} ${launcherPermanentLevels[cheapestLauncher]}단');
        continue;
      }
      if (canUpgCentral && upgradeCentralGuardian()) {
        logs.add('중앙 수호탑 $centralGuardianLevel단');
        continue;
      }
      if (upgradeForgeMastery()) {
        logs.add('태초 신기 연마 $forgeMasteryLevel단');
        continue;
      }

      // 5순위: 영약으로 상위 영수 영입/강화 · 상위 동료 영입/출전 동료 강화 · 호법 영기 공명 강화
      SpiritBeast? newlyHiredBeast;
      for (final b in SpiritBeast.values.reversed) {
        if ((beastLevels[b] ?? 0) == 0 &&
            b.unlockChapter <= effectiveArsenalChapter &&
            unlockOrUpgradeBeast(b)) {
          newlyHiredBeast = b;
          break;
        }
      }
      if (newlyHiredBeast != null) {
        logs.add('${newlyHiredBeast.name} 영입');
        continue;
      }

      final activeBeast = activePreset.equippedBeast;
      if ((beastLevels[activeBeast] ?? 0) > 0 &&
          (beastLevels[activeBeast] ?? 0) < maxAllyLevel &&
          unlockOrUpgradeBeast(activeBeast)) {
        logs.add('${activeBeast.name} ${beastLevels[activeBeast]}단');
        continue;
      }

      CompanionHero? newlyHiredHero;
      for (final h in CompanionHero.values.reversed) {
        if (h != CompanionHero.mukhyeon &&
            (companionLevels[h] ?? 0) == 0 &&
            h.unlockElixirs > 0 &&
            h.unlockChapter <= effectiveArsenalChapter &&
            unlockOrUpgradeCompanion(h)) {
          newlyHiredHero = h;
          break;
        }
      }
      if (newlyHiredHero != null) {
        logs.add('${newlyHiredHero.name} 영입');
        continue;
      }

      CompanionHero? upgradedHero;
      for (final h in activePreset.companions) {
        final lv = companionLevels[h] ?? 0;
        if (lv > 0 && lv < maxAllyLevel && unlockOrUpgradeCompanion(h)) {
          upgradedHero = h;
          break;
        }
      }
      if (upgradedHero != null) {
        logs.add('${upgradedHero.name} ${companionLevels[upgradedHero]}단');
        continue;
      }
      if (upgradeElixirResonance()) {
        logs.add('호법 영기 공명 $elixirResonanceLevel단');
        continue;
      }

      // 6순위: 수련 인장으로 3대 핵심 능력치 균형 단련
      final sortedStats = CoreStatType.values.toList()
        ..sort((a, b) => (coreStatLevels[a] ?? 0).compareTo(coreStatLevels[b] ?? 0));
      bool statDone = false;
      for (final st in sortedStats) {
        if (upgradeCoreStat(st)) {
          logs.add('${st.label} ${coreStatLevels[st]}단');
          statDone = true;
          break;
        }
      }
      if (statDone) continue;

      break;
    }

    return logs;
  }

  /// 13) 기기 변경용 오프라인 백업 부호 내보내기 / 복원 (위변조 검증 합산값 포함).
  static String _fnv1aHex(String text) {
    int hash = 0x811c9dc5;
    for (final b in utf8.encode(text)) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  String exportBackupCode() {
    final b64 = base64Url.encode(utf8.encode(encodeJson()));
    final checksum = _fnv1aHex(b64);
    return 'SUHO1:$checksum:$b64';
  }

  static PlayerProgress? tryDecodeBackupCode(String rawCode) {
    try {
      final trimmed = rawCode.trim();
      if (!trimmed.startsWith('SUHO1:')) return null;
      final parts = trimmed.split(':');
      if (parts.length != 3) return null;
      final expectedSum = parts[1].toUpperCase();
      final payload = parts[2];
      if (_fnv1aHex(payload) != expectedSum) return null;
      final decodedJson = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      return PlayerProgress.decodeJson(decodedJson);
    } catch (_) {
      return null;
    }
  }

  void onBattleFinished({
    required StageSpec stage,
    required bool victory,
    required int stars,
    required int earnedTokens,
    required int earnedElixirs,
    required int usedSupportCount,
    int killCount = 0,
    int pporokCount = 0,
    int bankShotCount = 0,
    int chainShatterCount = 0,
    int serendipityCount = 0,
    Set<MutantKind> encounteredMutants = const {},
    int endlessWavesCleared = 0,
    String difficultyId = 'normal',
    bool supportAlreadyDeductedInSim = false,
    bool bossElixirAlreadyIncluded = false,
    bool convoyBuffAlreadyConsumed = false,
    String? todayKey,
  }) {
    lastRescueBanner = null;
    lastRescuedCompanion = null;
    lastRescuedBeast = null;

    final safeUsedSupport = max(0, usedSupportCount);
    final rMult = reincarnationRewardMultiplier;
    final safeEarnedTokens =
        (max(0, earnedTokens) * rMult).round().clamp(0, 250000000);
    final safeEarnedElixirs =
        (max(0, earnedElixirs) * rMult).round().clamp(0, 25000000);
    final safeKillCount = max(0, killCount);
    final safePporok = max(0, pporokCount);
    final safeBank = max(0, bankShotCount);
    final safeChain = max(0, chainShatterCount);
    final safeSeren = max(0, serendipityCount);

    if (stage.isReincarnationBossStage) {
      reincarnationBossAttempts = (reincarnationBossAttempts + 1).clamp(1, 999999999);
    }

    if (!supportAlreadyDeductedInSim &&
        !stage.isReincarnationBossStage &&
        safeUsedSupport > 0) {
      supportTokens = (supportTokens - safeUsedSupport).clamp(0, 999999);
    }
    tokens = (tokens + safeEarnedTokens).clamp(0, 999999999);
    elixirs = (elixirs + safeEarnedElixirs).clamp(0, 999999999);
    moonOmenGauge = (moonOmenGauge + (victory ? 28 : 14)).clamp(0, 100);

    totalMutantKills += safeKillCount;
    totalPporokCount += safePporok;
    totalBankShotCount += safeBank;
    totalChainShatterCount += safeChain;
    seenMutants.addAll(encounteredMutants);
    if (endlessWavesCleared > bestEndlessWave) {
      bestEndlessWave = endlessWavesCleared;
    }
    if (endlessWavesCleared > 0) {
      final prevDiffBest = bestEndlessByDifficulty[difficultyId] ?? 0;
      if (endlessWavesCleared > prevDiffBest) {
        bestEndlessByDifficulty[difficultyId] = endlessWavesCleared;
      }
    }

    recordDeed(NightDeed.mutantKills, safeKillCount, todayKey: todayKey);
    recordDeed(NightDeed.cliffPporok, safePporok, todayKey: todayKey);
    recordDeed(NightDeed.serendipityHit, safeSeren, todayKey: todayKey);

    if (!convoyBuffAlreadyConsumed && convoySupplyBuffBattles > 0) {
      convoySupplyBuffBattles--;
    }

    if (victory) {
      recordDeed(NightDeed.battleWin, 1, todayKey: todayKey);
      if (stars >= 3) {
        recordDeed(NightDeed.perfectDefense, 1, todayKey: todayKey);
      }

      // 실전 방어 승리로 단전 내공과 수련 인장이 함께 성장 (전투와 수련의 유기적 선순환!)
      final gainedNaegong =
          ((16 + stage.chapterNumber * 5 + (stage.isBossStage ? 22 : 0)) * rMult)
              .round()
              .clamp(1, 50000000);
      final gainedSeals =
          ((4 + (stage.chapterNumber ~/ 2) + (stage.isBossStage ? 5 : 0)) * rMult)
              .round()
              .clamp(1, 10000000);
      naegongPoints = (naegongPoints + gainedNaegong).clamp(0, 999999999);
      trainingSeals = (trainingSeals + gainedSeals).clamp(0, 999999999);
      if (stage.isBossStage) {
        if (!bossElixirAlreadyIncluded) {
          final extraBossElixirs =
              ((2 + (stage.chapterNumber ~/ 3)) * rMult).round().clamp(1, 5000000);
          elixirs = (elixirs + extraBossElixirs).clamp(0, 999999999);
        }
        _grantRandomShards(
          stage.isReincarnationBossStage ? 6 : (stage.stageNumber >= 10 ? 3 : 1),
          Random(totalMutantKills + stage.globalIndex + 17),
        );
      }

      if (stage.chapterNumber == 10 &&
          stage.stageNumber == 10 &&
          difficultyId == DefenseDifficulty.nightmare.id) {
        nightmareChapter10Cleared = true;
      }
      if (stage.isReincarnationBossStage) {
        reincarnationBossWins = (reincarnationBossWins + 1).clamp(1, 999999999);
        reincarnationBossCleared = true;
        supportTokens = (supportTokens + 3).clamp(0, 999999);
      }

      // 승리 시 수호 재료 1종 확정 획득
      final dropMat = CraftMaterial.values[
          (stage.chapterNumber + totalMutantKills) % CraftMaterial.values.length];
      materials[dropMat] = (materials[dropMat] ?? 0) + 1;

      final countsTowardDispatch = reincarnationCount > 0 ||
          stage.globalIndex >= 800 ||
          stage.chapterNumber >= max(1, highestUnlockedChapter - 2);
      if (countsTowardDispatch) {
        if (convoyActive && convoyBattlesRemaining > 0) {
          convoyBattlesRemaining--;
        }
        if (exploreActive && exploreBattlesRemaining > 0) {
          exploreBattlesRemaining--;
        }
      }

      if (stage.globalIndex <= CampaignCatalog.allStages.length) {
        final prevStars = stageStars[stage.code] ?? 0;
        if (stars > prevStars) {
          stageStars[stage.code] = stars;
          // 조건 달성 경로: 마을 식량/농산물/가축 무피해 ★3 첫 달성 시 지원패 수여!
          if (stars == 3 && prevStars < 3) {
            supportTokens += 1;
          }
        }

        final isFirstClear = stage.globalIndex > highestClearedGlobalStage;
        if (isFirstClear) {
          highestClearedGlobalStage = stage.globalIndex;
        }

        // 관문 진행에 따른 동료(13인) · 영수(4종) 지속 구출 합류!
        // (세이브 이관·경계 재클리어 시에도 아직 미합류(Lv.0) 구출 대상이 있으면 누락 없이 합류 보장!)
        final needMissingCompanion = stage.rescueCompanion != null &&
            (companionLevels[stage.rescueCompanion!] ?? 0) <= 0;
        final needMissingMukhyeon = stage.alsoRescuesMukhyeon &&
            (companionLevels[CompanionHero.mukhyeon] ?? 0) <= 0;
        final needMissingBeast = stage.rescueBeast != null &&
            (beastLevels[stage.rescueBeast!] ?? 0) <= 0;

        if (isFirstClear ||
            needMissingCompanion ||
            needMissingMukhyeon ||
            needMissingBeast) {
          final rescueNotices = <String>[];
          if (stage.rescueCompanion != null &&
              (isFirstClear || needMissingCompanion)) {
            final hero = stage.rescueCompanion!;
            final prevLv = companionLevels[hero] ?? 0;
            companionLevels[hero] =
                prevLv <= 0 ? 1 : (prevLv + 1).clamp(1, maxAllyLevel);
            for (final preset in presets) {
              if (preset.companions.length < 3 && !preset.companions.contains(hero)) {
                preset.companions.add(hero);
              }
            }
            lastRescuedCompanion = hero;
            rescueNotices.add(
              prevLv <= 0
                  ? '🎉 동료 「${hero.name}(${hero.title})」 구출 합류!'
                  : '🎉 동료 「${hero.name}」 구출 감응 (+1단계 승급)!',
            );
          }

          if (stage.alsoRescuesMukhyeon &&
              (isFirstClear || needMissingMukhyeon)) {
            final prevMuk = companionLevels[CompanionHero.mukhyeon] ?? 0;
            companionLevels[CompanionHero.mukhyeon] =
                prevMuk <= 0 ? 1 : (prevMuk + 1).clamp(1, maxAllyLevel);
            if (isFirstClear || prevMuk <= 0) {
              supportTokens = (supportTokens + 2).clamp(0, 999999);
            }
            rescueNotices.add('⚔️ 숙적 「묵현」 귀순 합류 & 지원패 +2!');
          }

          if (stage.rescueBeast != null &&
              (isFirstClear || needMissingBeast)) {
            final beast = stage.rescueBeast!;
            final prevBeastLv = beastLevels[beast] ?? 0;
            beastLevels[beast] =
                prevBeastLv <= 0 ? 1 : (prevBeastLv + 1).clamp(1, maxAllyLevel);
            if (prevBeastLv <= 0 && beast.index > activePreset.equippedBeast.index) {
              activePreset.equippedBeast = beast;
              activePreset.beastCondition = beast.defaultCondition;
            }
            lastRescuedBeast = beast;
            rescueNotices.add(
              prevBeastLv <= 0
                  ? '🐾 영수 「${beast.name}」 구출 계약 완료!'
                  : '🐾 영수 「${beast.name}」 영기 각성 (+1단계 승급)!',
            );
          }

          if (rescueNotices.isNotEmpty) {
            lastRescueBanner = rescueNotices.join(' · ');
          }
        }
      }
    }
  }

  void _grantRandomShards(int amount, Random rng) {
    const targets = [StoneMaterial.onok, StoneMaterial.yongrin, StoneMaterial.taegeuk];
    for (int i = 0; i < amount; i++) {
      final pick = targets[rng.nextInt(targets.length)];
      stoneShards[pick] = (stoneShards[pick] ?? 0) + 1;
    }
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String encodeJson() => jsonEncode({
        'tokens': tokens,
        'elixirs': elixirs,
        'seals': trainingSeals,
        'naegong': naegongPoints,
        'realm': realmIndex,
        'centralLv': centralGuardianLevel,
        'support': supportTokens,
        'moon': moonOmenGauge,
        'cleared': highestClearedGlobalStage,
        'meridian': openedMeridianStep,
        'dailyUsed': dailyEnlightenmentUsed,
        'lastDay': lastMeditationDayKey,
        'convoyOn': convoyActive,
        'convoyRem': convoyBattlesRemaining,
        'convoyBuff': convoySupplyBuffBattles,
        'convoyCnt': convoyCompletedCount,
        'exploreOn': exploreActive,
        'exploreRem': exploreBattlesRemaining,
        'presetIdx': activePresetIndex,
        'attDay': attendanceDayKey,
        'attStep': attendanceStepCount,
        'qDay': dailyQuestDayKey,
        'qWeek': weeklyQuestKey,
        'qMonth': monthlyQuestKey,
        'qAllClear': dailyAllClearClaimed,
        'totKills': totalMutantKills,
        'totPporok': totalPporokCount,
        'totBank': totalBankShotCount,
        'totChain': totalChainShatterCount,
        'bestEndless': bestEndlessWave,
        'forgeMastery': forgeMasteryLevel,
        'elixirResonance': elixirResonanceLevel,
        'reincCnt': reincarnationCount,
        'nmCh10Clear': nightmareChapter10Cleared,
        'reincBossClear': reincarnationBossCleared,
        'reincBossTry': reincarnationBossAttempts,
        'reincBossWin': reincarnationBossWins,
        'transcendLv': transcendenceLevel,
        'tutSeen': tutorialSeen,
        'bgmVol': bgmVolume,
        'sfxVol': sfxVolume,
        'vibOn': vibrationEnabled,
        'vibStr': vibrationStrength,
        'prefDiff': preferredDifficultyId,
        'prefSpeed': preferredBattleSpeed,
        'prefAutoPerk': preferredAutoPerk,
        'prefContMarch': preferredContinuousMarch,
        'bestEndlessMap': bestEndlessByDifficulty,
        'launcherLvs': launcherPermanentLevels.map((k, v) => MapEntry(k.id, v)),
        'stones': unlockedStones.map((e) => e.id).toList(),
        'shards': stoneShards.map((k, v) => MapEntry(k.id, v)),
        'beasts': beastLevels.map((k, v) => MapEntry(k.id, v)),
        'companions': companionLevels.map((k, v) => MapEntry(k.id, v)),
        'coreStats': coreStatLevels.map((k, v) => MapEntry(k.name, v)),
        'stars': stageStars,
        'presets': presets.map((p) => p.toJson()).toList(),
        'materials': materials.map((k, v) => MapEntry(k.name, v)),
        'consumables': consumables.map((k, v) => MapEntry(k.name, v)),
        'dDeeds': dailyDeeds.map((k, v) => MapEntry(k.name, v)),
        'wDeeds': weeklyDeeds.map((k, v) => MapEntry(k.name, v)),
        'mDeeds': monthlyDeeds.map((k, v) => MapEntry(k.name, v)),
        'claimedQ': claimedQuestIds.toList(),
        'claimedAch': claimedAchievements.toList(),
        'seenMutants': seenMutants.map((e) => e.name).toList(),
      });

  static int _safeInt(dynamic v, int fallback) {
    if (v is num && v.isFinite) return v.toInt();
    return fallback;
  }

  static double _safeDouble(dynamic v, double fallback) {
    if (v is num && v.isFinite) return v.toDouble();
    return fallback;
  }

  static bool _safeBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    return fallback;
  }

  static String _safeDayKey(dynamic v) {
    if (v is String) {
      final trimmed = v.trim();
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) return trimmed;
    }
    return '';
  }

  static String _safePeriodKey(dynamic v, String prefixPattern) {
    if (v is String) {
      final trimmed = v.trim();
      if (RegExp(prefixPattern).hasMatch(trimmed)) return trimmed;
    }
    return '';
  }

  factory PlayerProgress.decodeJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Root JSON must be an object');
    }
    final j = Map<String, dynamic>.from(decoded);
    final maxStage = CampaignCatalog.allStages.length;
    final maxMeridian = MeridianStepSpec.steps.length;
    final maxRealm = NaegongRealm.values.length - 1;

    final p = PlayerProgress(
      tokens: _safeInt(j['tokens'], 120).clamp(0, 999999999),
      elixirs: _safeInt(j['elixirs'], 4).clamp(0, 999999999),
      trainingSeals: _safeInt(j['seals'] ?? j['trainingSeals'], 15).clamp(0, 999999999),
      naegongPoints: _safeInt(j['naegong'] ?? j['naegongPoints'], 20).clamp(0, 999999999),
      realmIndex: _safeInt(j['realm'] ?? j['realmIndex'], 0).clamp(0, maxRealm),
      centralGuardianLevel:
          _safeInt(j['centralLv'] ?? j['centralGuardianLevel'], 1).clamp(1, 999),
      supportTokens: _safeInt(j['support'] ?? j['supportTokens'], 2).clamp(0, 999999),
      moonOmenGauge: _safeInt(j['moon'] ?? j['moonOmenGauge'], 35).clamp(0, 100),
      highestClearedGlobalStage: _safeInt(
        j['cleared'] ?? j['highestClearedStage'] ?? j['highestClearedGlobalStage'],
        0,
      ).clamp(0, maxStage),
      openedMeridianStep: _safeInt(
        j['meridian'] ?? j['meridianStep'] ?? j['openedMeridianStep'],
        0,
      ).clamp(0, maxMeridian),
      dailyEnlightenmentUsed: _safeInt(j['dailyUsed'], 0).clamp(0, 10),
      lastMeditationDayKey: _safeDayKey(j['lastDay']),
      convoyActive: _safeBool(j['convoyOn'], false),
      convoyBattlesRemaining: _safeInt(j['convoyRem'], 0).clamp(0, 10),
      convoySupplyBuffBattles: _safeInt(j['convoyBuff'], 0).clamp(0, 99),
      convoyCompletedCount: _safeInt(j['convoyCnt'], 0).clamp(0, 999999),
      exploreActive: _safeBool(j['exploreOn'], false),
      exploreBattlesRemaining: _safeInt(j['exploreRem'], 0).clamp(0, 10),
      activePresetIndex: _safeInt(j['presetIdx'], 0).clamp(0, 99),
      attendanceDayKey: _safeDayKey(j['attDay']),
      attendanceStepCount: _safeInt(j['attStep'], 0).clamp(0, 999999),
      dailyQuestDayKey: _safeDayKey(j['qDay']),
      weeklyQuestKey: _safePeriodKey(j['qWeek'], r'^W\d{4}-\d{2}-\d{2}$'),
      monthlyQuestKey: _safePeriodKey(j['qMonth'], r'^M\d{4}-\d{2}$'),
      dailyAllClearClaimed: _safeBool(j['qAllClear'], false),
      totalMutantKills: _safeInt(j['totKills'], 0).clamp(0, 999999999),
      totalPporokCount: _safeInt(j['totPporok'], 0).clamp(0, 999999999),
      totalBankShotCount: _safeInt(j['totBank'], 0).clamp(0, 999999999),
      totalChainShatterCount: _safeInt(j['totChain'], 0).clamp(0, 999999999),
      bestEndlessWave: _safeInt(j['bestEndless'], 0).clamp(0, 9999),
      forgeMasteryLevel: _safeInt(j['forgeMastery'], 0).clamp(0, 9999),
      elixirResonanceLevel: _safeInt(j['elixirResonance'], 0).clamp(0, 9999),
      reincarnationCount: _safeInt(j['reincCnt'] ?? j['reincarnationCount'], 0).clamp(0, 999),
      nightmareChapter10Cleared: _safeBool(
        j['nmCh10Clear'] ?? j['nightmareChapter10Cleared'],
        false,
      ),
      reincarnationBossCleared: _safeBool(
        j['reincBossClear'] ?? j['reincarnationBossCleared'],
        false,
      ),
      reincarnationBossAttempts:
          _safeInt(j['reincBossTry'] ?? j['reincarnationBossAttempts'], 0).clamp(0, 9999999),
      reincarnationBossWins:
          _safeInt(j['reincBossWin'] ?? j['reincarnationBossWins'], 0).clamp(0, 9999999),
      transcendenceLevel:
          _safeInt(j['transcendLv'] ?? j['transcendenceLevel'], 0).clamp(0, 9999),
      tutorialSeen: _safeBool(j['tutSeen'], false),
      bgmVolume: _safeDouble(j['bgmVol'] ?? j['bgmVolume'], 0.38).clamp(0.0, 1.0),
      sfxVolume: _safeDouble(j['sfxVol'] ?? j['sfxVolume'], 0.72).clamp(0.0, 1.0),
      vibrationEnabled: _safeBool(j['vibOn'], true),
      vibrationStrength: _safeInt(j['vibStr'] ?? j['vibrationStrength'], 2).clamp(1, 3),
      preferredDifficultyId: switch (j['prefDiff']) {
        'easy' => 'easy',
        'nightmare' => 'nightmare',
        _ => 'normal',
      },
      preferredBattleSpeed: _safeInt(j['prefSpeed'], 1).clamp(1, 4),
      preferredAutoPerk: _safeBool(j['prefAutoPerk'], false),
      preferredContinuousMarch: _safeBool(j['prefContMarch'], true),
    );

    if (j['bestEndlessMap'] is Map) {
      (j['bestEndlessMap'] as Map).forEach((k, v) {
        if (k == 'easy' || k == 'normal' || k == 'nightmare') {
          p.bestEndlessByDifficulty[k as String] = _safeInt(v, 0).clamp(0, 9999);
        }
      });
    }

    if (j['launcherLvs'] is Map) {
      (j['launcherLvs'] as Map).forEach((k, v) {
        final lt = LauncherType.values.where((e) => e.id == k || e.name == k).firstOrNull;
        if (lt != null) {
          p.launcherPermanentLevels[lt] = _safeInt(v, 1).clamp(1, 999);
        }
      });
    }
    if (j['stones'] is List) {
      for (final id in (j['stones'] as List)) {
        final sm = StoneMaterial.values.where((e) => e.id == id || e.name == id).firstOrNull;
        if (sm != null) p.unlockedStones.add(sm);
      }
    }
    if (j['shards'] is Map) {
      (j['shards'] as Map).forEach((k, v) {
        final sm = StoneMaterial.values.where((e) => e.id == k || e.name == k).firstOrNull;
        if (sm != null) {
          p.stoneShards[sm] = _safeInt(v, 0).clamp(0, 999999);
        }
      });
    }
    if (j['beasts'] is Map) {
      (j['beasts'] as Map).forEach((k, v) {
        final sb = SpiritBeast.values.where((e) => e.id == k || e.name == k).firstOrNull;
        if (sb != null) {
          final minLv = sb == SpiritBeast.nalssaendol ? 1 : 0;
          p.beastLevels[sb] = _safeInt(v, minLv).clamp(minLv, p.maxAllyLevel);
        }
      });
    }
    if (j['companions'] is Map) {
      (j['companions'] as Map).forEach((k, v) {
        final ch = CompanionHero.values.where((e) => e.id == k || e.name == k).firstOrNull;
        if (ch != null) {
          p.companionLevels[ch] = _safeInt(v, 0).clamp(0, p.maxAllyLevel);
        }
      });
    }
    if (j['coreStats'] is Map) {
      (j['coreStats'] as Map).forEach((k, v) {
        final cs = CoreStatType.values.where((e) => e.name == k).firstOrNull;
        if (cs != null) {
          p.coreStatLevels[cs] = _safeInt(v, 0).clamp(0, 999);
        }
      });
    }
    if (j['stars'] is Map) {
      final legacyStars = <String, int>{};
      (j['stars'] as Map).forEach((k, v) {
        legacyStars[k.toString()] = _safeInt(v, 0).clamp(0, 3);
      });
      // 구버전(111판 체제: 일부 장 11~12판 존재) 세이브의 결전 별점을 10현×10판(총 100판) 체제의 10판으로 무손실 이관!
      final stagePattern = RegExp(r'^(\d+)-(\d+)$');
      legacyStars.forEach((key, stars) {
        final m = stagePattern.firstMatch(key);
        if (m == null) return;
        final ch = int.tryParse(m.group(1)!) ?? 0;
        final st = int.tryParse(m.group(2)!) ?? 0;
        if (ch < 1 || ch > 10 || st < 1) return;
        final mappedCode = '$ch-${st.clamp(1, 10)}';
        final prev = p.stageStars[mappedCode];
        if (prev == null || stars > prev) {
          p.stageStars[mappedCode] = stars;
        }
      });
    }
    if (j['presets'] is List) {
      final list = (j['presets'] as List)
          .whereType<Map>()
          .map((e) => LoadoutPreset.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (list.isNotEmpty) {
        p.presets
          ..clear()
          ..addAll(list);
      }
    }
    p.activePresetIndex = p.activePresetIndex.clamp(0, p.presets.length - 1);
    final bestOwnedStone = (p.unlockedStones.toList()
          ..sort((a, b) => b.grade.compareTo(a.grade)))
        .firstOrNull ??
        StoneMaterial.cheongok;
    for (final pr in p.presets) {
      if (!p.unlockedStones.contains(pr.primaryStone)) {
        pr.primaryStone = bestOwnedStone;
      }
      if ((p.beastLevels[pr.equippedBeast] ?? 0) <= 0) {
        pr.equippedBeast = SpiritBeast.nalssaendol;
        pr.beastCondition = SpiritBeast.nalssaendol.defaultCondition;
      }
      pr.companions = pr.companions
          .where((h) => (p.companionLevels[h] ?? 0) > 0)
          .take(3)
          .toList();
      if (pr.companions.isEmpty && (p.companionLevels[CompanionHero.seokdu] ?? 0) > 0) {
        pr.companions.add(CompanionHero.seokdu);
      }
    }

    if (j['materials'] is Map) {
      (j['materials'] as Map).forEach((k, v) {
        final cm = CraftMaterial.values.where((e) => e.name == k).firstOrNull;
        if (cm != null) {
          p.materials[cm] = _safeInt(v, 0).clamp(0, 999999);
        }
      });
    }
    if (j['consumables'] is Map) {
      (j['consumables'] as Map).forEach((k, v) {
        final tc = TacticalConsumable.values.where((e) => e.name == k).firstOrNull;
        if (tc != null) {
          p.consumables[tc] = _safeInt(v, 0).clamp(0, 999999);
        }
      });
    }
    void readDeeds(dynamic rawMap, Map<NightDeed, int> dest) {
      if (rawMap is Map) {
        rawMap.forEach((k, v) {
          final nd = NightDeed.values.where((e) => e.name == k).firstOrNull;
          if (nd != null) {
            dest[nd] = _safeInt(v, 0).clamp(0, 999999999);
          }
        });
      }
    }
    readDeeds(j['dDeeds'], p.dailyDeeds);
    readDeeds(j['wDeeds'], p.weeklyDeeds);
    readDeeds(j['mDeeds'], p.monthlyDeeds);
    if (j['claimedQ'] is List) {
      for (final item in (j['claimedQ'] as List)) {
        if (item != null) p.claimedQuestIds.add(item.toString());
      }
    }
    if (j['claimedAch'] is List) {
      for (final item in (j['claimedAch'] as List)) {
        if (item != null) p.claimedAchievements.add(item.toString());
      }
    }
    if (j['seenMutants'] is List) {
      for (final item in (j['seenMutants'] as List)) {
        final mk = MutantKind.values
            .where((e) => e.name == item || e.id == item)
            .firstOrNull;
        if (mk != null) p.seenMutants.add(mk);
      }
    }
    return p;
  }
}
