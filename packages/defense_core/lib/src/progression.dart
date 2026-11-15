import 'dart:convert';
import 'dart:math';

import 'allies.dart';
import 'campaign.dart';
import 'launchers.dart';
import 'materials.dart';

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
      effectSummary: '전투 시작 내공 +1.0칸 & 전 아군 화력 +14% & 황금 광륜 해금!',
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
        LauncherType.rapid,
        LauncherType.heavy,
        LauncherType.qiAmplifier,
      ],
      equippedBeast: SpiritBeast.nalssaendol,
      beastCondition: SpiritBeast.nalssaendol.defaultCondition,
      companions: [
        CompanionHero.seokdu,
        CompanionHero.yeonbi,
        CompanionHero.cheongmyeong,
      ],
      companionConditions: {
        for (final h in CompanionHero.values) h: h.defaultCondition,
      },
      supportSlotCount: 3,
      supportTriggerShieldRatio: 0.45,
      autoUpgradeInBattle: true,
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
    final base = LoadoutPreset.starter(name: (j['name'] as String?) ?? '수호 진법');
    base.primaryStone = StoneMaterial.values.firstWhere(
      (e) => e.id == j['stone'],
      orElse: () => StoneMaterial.cheongok,
    );
    base.primaryShape = StoneShape.values.firstWhere(
      (e) => e.id == j['shape'],
      orElse: () => StoneShape.round,
    );
    base.sectTechnique = SectTechnique.values.firstWhere(
      (e) => e.id == j['sect'],
      orElse: () => SectTechnique.swordQi,
    );
    if (j['mounts'] is List) {
      final parsed = (j['mounts'] as List)
          .map((id) => LauncherType.values.firstWhere((e) => e.id == id, orElse: () => LauncherType.rapid))
          .toList();
      if (parsed.isNotEmpty) {
        while (parsed.length < 5) {
          parsed.add(LauncherType.rapid);
        }
        base.mountTypes = parsed.take(5).toList();
      }
    }
    base.equippedBeast = SpiritBeast.values.firstWhere(
      (e) => e.id == j['beast'],
      orElse: () => SpiritBeast.nalssaendol,
    );
    base.beastCondition = AutoTriggerCondition.values.firstWhere(
      (e) => e.name == j['beastCond'],
      orElse: () => base.equippedBeast.defaultCondition,
    );
    if (j['companions'] is List) {
      final parsed = (j['companions'] as List)
          .map((id) => CompanionHero.values.firstWhere((e) => e.id == id, orElse: () => CompanionHero.seokdu))
          .toSet()
          .toList();
      if (parsed.isNotEmpty) {
        base.companions = parsed.take(3).toList();
      }
    }
    if (j['compConds'] is Map) {
      (j['compConds'] as Map).forEach((k, v) {
        final hero = CompanionHero.values.where((e) => e.id == k).firstOrNull;
        final cond = AutoTriggerCondition.values.where((e) => e.name == v).firstOrNull;
        if (hero != null && cond != null) {
          base.companionConditions[hero] = cond;
        }
      });
    }
    base.supportSlotCount = ((j['supportSlots'] as num?)?.toInt() ?? 3).clamp(0, 3);
    base.supportTriggerShieldRatio = ((j['supportRatio'] as num?)?.toDouble() ?? 0.45).clamp(0.20, 0.80);
    base.autoUpgradeInBattle = (j['autoUpg'] as bool?) ?? true;
    return base;
  }
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
    this.highestClearedGlobalStage = 0,
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
    Map<LauncherType, int>? launcherPermanentLevels,
    Set<StoneMaterial>? unlockedStones,
    Map<StoneMaterial, int>? stoneShards,
    Map<SpiritBeast, int>? beastLevels,
    Map<CompanionHero, int>? companionLevels,
    Map<CoreStatType, int>? coreStatLevels,
    Map<String, int>? stageStars,
    List<LoadoutPreset>? presets,
  })  : launcherPermanentLevels = launcherPermanentLevels ??
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
                c: (c == CompanionHero.seokdu ||
                        c == CompanionHero.yeonbi ||
                        c == CompanionHero.cheongmyeong)
                    ? 1
                    : 0,
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
            ];

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

  /// 클리어한 최고 전체 스테이지 번호 (0 ~ 111).
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

  final Map<LauncherType, int> launcherPermanentLevels;
  final Set<StoneMaterial> unlockedStones;
  final Map<StoneMaterial, int> stoneShards;
  final Map<SpiritBeast, int> beastLevels;
  final Map<CompanionHero, int> companionLevels;
  final Map<CoreStatType, int> coreStatLevels;
  final Map<String, int> stageStars;
  final List<LoadoutPreset> presets;

  NaegongRealm get realm => NaegongRealm.values[realmIndex.clamp(0, 7)];
  LoadoutPreset get activePreset => presets[activePresetIndex.clamp(0, presets.length - 1)];

  int get highestUnlockedChapter {
    if (highestClearedGlobalStage <= 0) return 1;
    final nextGlobal = (highestClearedGlobalStage + 1).clamp(1, CampaignCatalog.allStages.length);
    return CampaignCatalog.allStages[nextGlobal - 1].chapterNumber;
  }

  bool isStageUnlocked(StageSpec stage) => stage.globalIndex <= highestClearedGlobalStage + 1;

  // --- 경맥 & 3대 수련 능력치 누적 보너스 ---
  double get meridianLauncherDmgBonus =>
      (openedMeridianStep >= 1 ? 0.06 : 0.0) + (openedMeridianStep >= 10 ? 0.14 : 0.0);
  double get meridianShieldHpBonus => openedMeridianStep >= 2 ? 0.10 : 0.0;
  double get meridianCentralReloadBonus => openedMeridianStep >= 3 ? 0.08 : 0.0;
  double get meridianAllyCooldownReduction => openedMeridianStep >= 4 ? 0.08 : 0.0;
  double get meridianTokenDropBonus => openedMeridianStep >= 5 ? 0.10 : 0.0;
  double get meridianCritBonus => openedMeridianStep >= 6 ? 0.06 : 0.0;
  double get meridianStartQiBonus =>
      (openedMeridianStep >= 7 ? 0.6 : 0.0) + (openedMeridianStep >= 10 ? 1.0 : 0.0);
  double get meridianSerendipityBonus => openedMeridianStep >= 8 ? 0.06 : 0.0;
  double get meridianKnockbackBonus => openedMeridianStep >= 9 ? 0.12 : 0.0;

  double get coreFirepowerBonus => (coreStatLevels[CoreStatType.firepower] ?? 0) * 0.035;
  double get coreFortitudeBonus => (coreStatLevels[CoreStatType.fortitude] ?? 0) * 0.045;
  double get corePrecisionBonus => (coreStatLevels[CoreStatType.precision] ?? 0) * 0.035;

  /// 1) 초간단 단전 운기 호흡 (아무 때나 눌러도 100% 성공 · 실패 0%!).
  MeditationResult meditateOnce({
    required bool hitGoldenRing,
    required Random rng,
    String? todayKey,
  }) {
    final day = todayKey ?? _todayString();
    if (lastMeditationDayKey != day) {
      lastMeditationDayKey = day;
      dailyEnlightenmentUsed = 0;
    }

    final hasDailyBonus = dailyEnlightenmentUsed < 10;
    if (hasDailyBonus) {
      dailyEnlightenmentUsed++;
    }

    int baseNaegong = hasDailyBonus ? 18 : 4;
    int baseSeals = hasDailyBonus ? 6 : 2;

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
    moonOmenGauge = (moonOmenGauge + 4).clamp(0, 100);

    return MeditationResult(
      gainedNaegong: baseNaegong,
      gainedSeals: baseSeals,
      wasEnlightenmentBonus: hasDailyBonus,
      wasCriticalSerendipity: isCrit,
      wasOneMoreSerendipity: isOneMore,
      remainingDailyBonusCount: (10 - dailyEnlightenmentUsed).clamp(0, 10),
    );
  }

  /// 2) 십대 경맥 개통 (혈자리 구슬만 다 누르면 실패 0% 즉시 개통!).
  bool canOpenNextMeridian() {
    if (openedMeridianStep >= MeridianStepSpec.steps.length) return false;
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
    final cost = coreStatUpgradeCost(type);
    if (trainingSeals < cost) return false;
    trainingSeals -= cost;
    coreStatLevels[type] = (coreStatLevels[type] ?? 0) + 1;
    return true;
  }

  /// 4) 대장간 — 증표로 중앙 보호 장치 / 길목 발사대 영구 강화 및 알 해금.
  bool upgradeCentralGuardian() {
    final cost = CentralGuardianSpec.permanentUpgradeCost(centralGuardianLevel);
    if (tokens < cost) return false;
    tokens -= cost;
    centralGuardianLevel++;
    return true;
  }

  bool upgradeLauncherPermanent(LauncherType type) {
    final lv = launcherPermanentLevels[type] ?? 1;
    final cost = type.permanentUpgradeCost(lv);
    if (tokens < cost) return false;
    tokens -= cost;
    launcherPermanentLevels[type] = lv + 1;
    return true;
  }

  bool unlockStoneWithTokens(StoneMaterial stone) {
    if (unlockedStones.contains(stone)) return false;
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

  /// 5) 영약각 — 영약으로 내공 8경지 돌파, 영수 강화, 동료 강화.
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
    final cost = cur == 0 ? beast.unlockElixirs : beast.upgradeElixirCost(cur);
    if (cur >= 10 || elixirs < cost) return false;
    elixirs -= cost;
    beastLevels[beast] = cur + 1;
    return true;
  }

  bool unlockOrUpgradeCompanion(CompanionHero hero) {
    final cur = companionLevels[hero] ?? 0;
    final cost = cur == 0 ? hero.unlockElixirs : hero.upgradeElixirCost(cur);
    if (cur >= 10 || elixirs < cost) return false;
    elixirs -= cost;
    companionLevels[hero] = cur + 1;
    return true;
  }

  /// 6) 물자 호송 & 심야 탐색 출발 및 수령 (지원패 3대 수급 경로 + 크리티컬·한 번 더 기연!).
  bool startSupplyConvoy() {
    if (highestUnlockedChapter < 2 || convoyActive) return false;
    convoyActive = true;
    convoyBattlesRemaining = 2;
    return true;
  }

  DispatchClaimResult? claimSupplyConvoy(Random rng) {
    if (!convoyActive || convoyBattlesRemaining > 0) return null;
    convoyActive = false;
    convoyCompletedCount++;
    convoySupplyBuffBattles = 3;

    final chScale = highestUnlockedChapter;
    int gainTokens = 55 + chScale * 18;
    int gainElixirs = 2 + (chScale ~/ 3);
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
    if (highestUnlockedChapter < 4 || exploreActive) return false;
    exploreActive = true;
    exploreBattlesRemaining = 2;
    return true;
  }

  DispatchClaimResult? claimNightExplore(Random rng) {
    if (!exploreActive || exploreBattlesRemaining > 0) return null;
    exploreActive = false;

    final chScale = highestUnlockedChapter;
    int gainTokens = 40 + chScale * 14;
    int gainElixirs = 3 + (chScale ~/ 3);
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
      gainTokens += 45;
    }

    tokens += gainTokens;
    elixirs += gainElixirs;
    supportTokens += gainSupport;
    _grantRandomShards(gainShards, rng);

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
  DispatchClaimResult? claimFullMoonSerendipity(Random rng) {
    if (moonOmenGauge < 100) return null;
    moonOmenGauge = 0;

    final chScale = highestUnlockedChapter;
    int gainTokens = 70 + chScale * 20;
    int gainElixirs = 3 + (chScale ~/ 2);
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

  void onBattleFinished({
    required StageSpec stage,
    required bool victory,
    required int stars,
    required int earnedTokens,
    required int earnedElixirs,
    required int usedSupportCount,
  }) {
    supportTokens = (supportTokens - usedSupportCount).clamp(0, 999);
    tokens += earnedTokens;
    elixirs += earnedElixirs;
    moonOmenGauge = (moonOmenGauge + (victory ? 28 : 14)).clamp(0, 100);

    if (convoySupplyBuffBattles > 0) {
      convoySupplyBuffBattles--;
    }

    if (victory) {
      if (convoyActive && convoyBattlesRemaining > 0) {
        convoyBattlesRemaining--;
      }
      if (exploreActive && exploreBattlesRemaining > 0) {
        exploreBattlesRemaining--;
      }

      final prevStars = stageStars[stage.code] ?? 0;
      if (stars > prevStars) {
        stageStars[stage.code] = stars;
        // 조건 달성 경로: 마을 식량/농산물/가축 무피해 ★3 첫 달성 시 지원패 수여!
        if (stars == 3 && prevStars < 3) {
          supportTokens += 1;
        }
      }

      if (stage.globalIndex > highestClearedGlobalStage) {
        highestClearedGlobalStage = stage.globalIndex;
        // 스토리 동료 자동 합류 처리!
        if (stage.chapterNumber == 2 && stage.stageNumber == 11) {
          companionLevels[CompanionHero.bandal] = max(1, companionLevels[CompanionHero.bandal] ?? 0);
        } else if (stage.chapterNumber == 4 && stage.stageNumber == 12) {
          companionLevels[CompanionHero.gurumi] = max(1, companionLevels[CompanionHero.gurumi] ?? 0);
        } else if (stage.chapterNumber == 5 && stage.stageNumber == 11) {
          companionLevels[CompanionHero.jeonggak] = max(1, companionLevels[CompanionHero.jeonggak] ?? 0);
        } else if (stage.chapterNumber == 6 && stage.stageNumber == 12) {
          companionLevels[CompanionHero.yonga] = max(1, companionLevels[CompanionHero.yonga] ?? 0);
          companionLevels[CompanionHero.mukhyeon] = max(1, companionLevels[CompanionHero.mukhyeon] ?? 0);
          supportTokens += 2;
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
        'launcherLvs': launcherPermanentLevels.map((k, v) => MapEntry(k.id, v)),
        'stones': unlockedStones.map((e) => e.id).toList(),
        'shards': stoneShards.map((k, v) => MapEntry(k.id, v)),
        'beasts': beastLevels.map((k, v) => MapEntry(k.id, v)),
        'companions': companionLevels.map((k, v) => MapEntry(k.id, v)),
        'coreStats': coreStatLevels.map((k, v) => MapEntry(k.name, v)),
        'stars': stageStars,
        'presets': presets.map((p) => p.toJson()).toList(),
      });

  factory PlayerProgress.decodeJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final p = PlayerProgress(
      tokens: (j['tokens'] as num?)?.toInt() ?? 120,
      elixirs: (j['elixirs'] as num?)?.toInt() ?? 4,
      trainingSeals: (j['seals'] as num?)?.toInt() ?? 15,
      naegongPoints: (j['naegong'] as num?)?.toInt() ?? 20,
      realmIndex: (j['realm'] as num?)?.toInt() ?? 0,
      centralGuardianLevel: (j['centralLv'] as num?)?.toInt() ?? 1,
      supportTokens: (j['support'] as num?)?.toInt() ?? 2,
      moonOmenGauge: (j['moon'] as num?)?.toInt() ?? 35,
      highestClearedGlobalStage: (j['cleared'] as num?)?.toInt() ?? 0,
      openedMeridianStep: (j['meridian'] as num?)?.toInt() ?? 0,
      dailyEnlightenmentUsed: (j['dailyUsed'] as num?)?.toInt() ?? 0,
      lastMeditationDayKey: (j['lastDay'] as String?) ?? '',
      convoyActive: (j['convoyOn'] as bool?) ?? false,
      convoyBattlesRemaining: (j['convoyRem'] as num?)?.toInt() ?? 0,
      convoySupplyBuffBattles: (j['convoyBuff'] as num?)?.toInt() ?? 0,
      convoyCompletedCount: (j['convoyCnt'] as num?)?.toInt() ?? 0,
      exploreActive: (j['exploreOn'] as bool?) ?? false,
      exploreBattlesRemaining: (j['exploreRem'] as num?)?.toInt() ?? 0,
      activePresetIndex: (j['presetIdx'] as num?)?.toInt() ?? 0,
    );

    if (j['launcherLvs'] is Map) {
      (j['launcherLvs'] as Map).forEach((k, v) {
        final lt = LauncherType.values.where((e) => e.id == k).firstOrNull;
        if (lt != null) p.launcherPermanentLevels[lt] = (v as num).toInt();
      });
    }
    if (j['stones'] is List) {
      for (final id in (j['stones'] as List)) {
        final sm = StoneMaterial.values.where((e) => e.id == id).firstOrNull;
        if (sm != null) p.unlockedStones.add(sm);
      }
    }
    if (j['shards'] is Map) {
      (j['shards'] as Map).forEach((k, v) {
        final sm = StoneMaterial.values.where((e) => e.id == k).firstOrNull;
        if (sm != null) p.stoneShards[sm] = (v as num).toInt();
      });
    }
    if (j['beasts'] is Map) {
      (j['beasts'] as Map).forEach((k, v) {
        final sb = SpiritBeast.values.where((e) => e.id == k).firstOrNull;
        if (sb != null) p.beastLevels[sb] = (v as num).toInt();
      });
    }
    if (j['companions'] is Map) {
      (j['companions'] as Map).forEach((k, v) {
        final ch = CompanionHero.values.where((e) => e.id == k).firstOrNull;
        if (ch != null) p.companionLevels[ch] = (v as num).toInt();
      });
    }
    if (j['coreStats'] is Map) {
      (j['coreStats'] as Map).forEach((k, v) {
        final cs = CoreStatType.values.where((e) => e.name == k).firstOrNull;
        if (cs != null) p.coreStatLevels[cs] = (v as num).toInt();
      });
    }
    if (j['stars'] is Map) {
      (j['stars'] as Map).forEach((k, v) {
        p.stageStars[k.toString()] = (v as num).toInt();
      });
    }
    if (j['presets'] is List) {
      final list = (j['presets'] as List)
          .map((e) => LoadoutPreset.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (list.isNotEmpty) {
        p.presets
          ..clear()
          ..addAll(list);
      }
    }
    return p;
  }
}
