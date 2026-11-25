import 'dart:math';

import 'allies.dart';
import 'campaign.dart';
import 'daily_quests_codex.dart';
import 'launchers.dart';
import 'materials.dart';
import 'mutants.dart';
import 'progression.dart';
import 'tactical_fun.dart';

/// 전장 화면에 떠오르는 말풍선·효과 문구.
class FloatingCallout {
  FloatingCallout({
    required this.pos,
    required this.text,
    required this.colorHex,
    this.ttlSec = 1.15,
    this.isBigBanner = false,
  });

  Vec2 pos;
  final String text;
  final int colorHex;
  double ttlSec;
  final bool isBigBanner;
}

/// 시각 파편·파동 모션그래픽 입자.
class FxBurst {
  FxBurst({
    required this.pos,
    required this.colorHex,
    required this.maxRadius,
    this.ttlSec = 0.45,
    this.durationSec = 0.45,
    this.isTriangleShatter = false,
  });

  final Vec2 pos;
  final int colorHex;
  final double maxRadius;
  double ttlSec;
  final double durationSec;
  final bool isTriangleShatter;

  double get progress =>
      (durationSec <= 0 || !durationSec.isFinite || !ttlSec.isFinite)
          ? 1.0
          : (1.0 - ttlSec / durationSec).clamp(0.0, 1.0);
}

/// 사운드 매니저가 재생할 오디오 이벤트 이름.
enum SoundCue {
  gearMotion,
  bowMotion,
  shieldWave,
  stoneHitCheongok,
  stoneHitHeavy,
  stoneHitIce,
  stoneHitWood,
  criticalShatter,
  pporokFall,
  serendipityJackpot,
  chulduFanfare,
  villageWarning,
  dawnPurify,
  loseBell,
}

/// 전장 위 길목 발사대 실체.
class ActiveLauncher {
  ActiveLauncher({
    required this.slotIndex,
    required this.pos,
    required this.type,
    required this.permanentLevel,
    this.terrainType = MountTerrainType.chokeGate,
    int? investedTokens,
    this.constructTimer = 0.0,
    this.constructDuration = 0.0,
  }) : investedTokens = investedTokens ?? type.buildCostTokens;

  final int slotIndex;
  final Vec2 pos;
  LauncherType type;
  int permanentLevel;
  final MountTerrainType terrainType;
  int investedTokens;
  int tier = 1;
  double cooldown = 0.22;
  double aimAngleRad = -pi / 2;
  double recoilAnim = 0.0;

  /// 실시간 포대 축조·단조 공정 타이머 (건설 시 2.2초, 승급 시 1.15초 동안 공사 진행 후 가동!).
  double constructTimer;
  double constructDuration;

  /// 변이 두목·역병수 마기 침식 둔화 타이머 (양수면 연사 -42% 둔화 · 플레이어 직접 터치 시 즉시 정화!).
  double corruptionTimer = 0.0;
  double purifiedBoostTimer = 0.0;
  double serendipityReloadLockTimer = 0.0;

  bool get isConstructing => constructTimer > 0.01;
  bool get isCorrupted => corruptionTimer > 0.01;

  double get constructProgress =>
      (constructDuration <= 0.01) ? 1.0 : (1.0 - constructTimer / constructDuration).clamp(0.0, 1.0);
}

/// 전장 위 침입 돌연변이 실체.
class ActiveMutant {
  ActiveMutant({
    required this.uid,
    required this.kind,
    required this.laneIndex,
    required this.waypoints,
    required this.pos,
    required this.maxHp,
    required this.speed,
    this.customName,
    this.customPortrait,
    this.lateralSeed = 0.0,
    this.laneLateralOffset = 0.0,
  })  : hp = maxHp,
        currentMaxHp = maxHp;

  final int uid;
  final MutantKind kind;
  final int laneIndex;
  final List<Vec2> waypoints;
  Vec2 pos;
  int waypointIndex = 1;
  final double maxHp;
  double currentMaxHp;
  double hp;
  final double speed;
  final String? customName;
  final String? customPortrait;

  Vec2 knockbackVel = const Vec2(0, 0);
  double freezeTimer = 0.0;
  double freezeImmuneTimer = 0.0;
  double slowTimer = 0.0;
  double oilSlipTimer = 0.0;
  final Set<int> checkedCliffIndices = <int>{};
  double contactHitCooldown = 0.0;
  double altarHitFlashTimer = 0.0;
  int spawnedWaveIndex = 0;
  double attackScaleSnapshot = 1.0;
  double sweatAnim = 0.0;

  /// 사실적인 침공 보행·질주·타격·피격·균열 소환·관성 곡선 선회 묘사용 실시간 상태값.
  Vec2 smoothVel = const Vec2(0, 0);
  double animPhase = 0.0;
  double headingRad = 1.5707963;
  double lateralSeed;
  final double laneLateralOffset;
  double attackAnimTimer = 0.0;
  double hitFlashTimer = 0.0;
  double dashBurstTimer = 0.0;
  bool roarShockUsed = false;
  double dashCooldown = 2.6;
  double spawnPortalTimer = 0.45;

  /// 길이 아닌 숲길 옆구리·지하 땅굴로 가로질러 침투하는 비정규 기습 변이체 여부!
  bool isInfiltrator = false;
  String infiltratorStyle = ''; // 'flank'(옆길 월담) 또는 'tunnel'(땅굴 분출)
  double emergeAnimTimer = 0.0;

  /// 중간보스 2차 재변이 & 우두머리 3페이즈 다단 변이 + 외각 장갑판·정밀 약점 저격 + 100타/1,000타 불멸 타수 실드 상태!
  int totalPhases = 1;
  int currentPhase = 1;
  int carapacePlatesLeft = 0;
  int maxCarapacePlates = 0;
  double phaseTransitionTimer = 0.0;
  double groggyExposeTimer = 0.0;
  double mutationScale = 1.0;
  double weakSpotAngleRad = -1.5707963;
  double flankCrackCooldown = 0.0;
  double corruptionCastCooldown = 3.8;

  /// 행동대장(100타+) · 중간보스(200~500타+) · 각 장 천련보스(1,000타+) 전용 누적 피격 타수 & 잔여 타수 실드!
  int maxHitShield = 0;
  int hitShieldLeft = 0;
  int totalHitsTaken = 0;
  String hierarchyRank = '';

  void enableBossPhases({
    required int phases,
    required int initialPlates,
    double phase1HpScale = 1.0,
  }) {
    totalPhases = phases.clamp(1, 3);
    currentPhase = 1;
    currentMaxHp = maxHp * phase1HpScale;
    hp = currentMaxHp;
    maxCarapacePlates = initialPlates.clamp(0, 6);
    carapacePlatesLeft = maxCarapacePlates;
    mutationScale = 1.0;
  }

  void enableHitShield(int requiredHits, {String rank = ''}) {
    maxHitShield = max(0, requiredHits);
    hitShieldLeft = maxHitShield;
    if (rank.isNotEmpty) {
      hierarchyRank = rank;
    }
  }

  bool get hasHitShield => hitShieldLeft > 0;

  double get hitShieldRatio =>
      maxHitShield <= 0 ? 0.0 : (hitShieldLeft / maxHitShield).clamp(0.0, 1.0);

  double get effectiveRadius => kind.radius * mutationScale;

  Vec2 get weakSpotWorldPos =>
      pos + Vec2(cos(weakSpotAngleRad), sin(weakSpotAngleRad)) * (effectiveRadius * 0.94);

  bool get hasActiveWeakPoint =>
      totalPhases > 1 &&
      (carapacePlatesLeft > 0 || hitShieldLeft > 0) &&
      phaseTransitionTimer <= 0;

  String get phaseTitleBadge {
    if (totalPhases <= 1) return '';
    if (totalPhases == 2) {
      return currentPhase == 1 ? '1차 변이' : '🧬2차 흉폭 재변이';
    }
    return switch (currentPhase) {
      1 => '1페이즈 · 마기 외각',
      2 => '2페이즈 · 흉폭 재변이',
      _ => '3페이즈 · 심연 진신',
    };
  }

  String get displayName => customName ?? kind.name;
}

/// 전장 위 자동 발사 수호 알 투사체.
class ActiveStoneProjectile {
  ActiveStoneProjectile({
    required this.sourceKey,
    required this.sourceLabel,
    required this.pos,
    required this.vel,
    required this.material,
    required this.shape,
    required this.damage,
    required this.knockback,
    required this.critChance,
    required this.colorHex,
    this.radius = 8.5,
    this.spinCurve = 0.0,
    this.pierceLeft = 0,
    this.aoeSplashRadius = 0.0,
    this.pullsEnemies = false,
    this.freezesOnHit = false,
    this.slowsOnHit = false,
    this.oilsOnHit = false,
    this.ignoresShield = false,
    this.isGiantCritSerendipity = false,
    this.clonedByGate = false,
    this.splitChild = false,
    this.maxTravelDist = 285.0,
    this.isPrecisionShot = false,
    this.precisionTargetPos,
    this.lockedWeakBossUid,
    this.fromWeakCrackerMount = false,
    this.projectileStyle = 'stoneDefault',
    this.freezeDurationOverride,
    this.homingTargetUid,
    this.executesLowHpNormal = false,
    this.splitsShadowOnHit = false,
    this.alreadySplitPerk = false,
    int extraBounces = 0,
  }) : bouncesLeft = shape.maxBounces + extraBounces;

  final String sourceKey;
  final String sourceLabel;
  Vec2 pos;
  Vec2 vel;
  final StoneMaterial material;
  final StoneShape shape;
  double damage;
  final double knockback;
  final double critChance;
  final int colorHex;
  final double radius;
  final double spinCurve;
  int pierceLeft;
  final double aoeSplashRadius;
  final bool pullsEnemies;
  final bool freezesOnHit;
  final bool slowsOnHit;
  final bool oilsOnHit;
  bool ignoresShield;
  final bool isGiantCritSerendipity;
  bool clonedByGate;
  final bool splitChild;
  double maxTravelDist;
  double traveledDist = 0.0;
  final bool isPrecisionShot;
  final Vec2? precisionTargetPos;
  final int? lockedWeakBossUid;
  final bool fromWeakCrackerMount;
  final double? freezeDurationOverride;
  int? homingTargetUid;
  final bool executesLowHpNormal;
  bool splitsShadowOnHit;
  bool alreadySplitPerk = false;

  /// 발사대·비기 계통별 고유 탄알·내공 외형 식별자 (`'rapidBolt'` | `'heavyMeteor'` | `'curveChakram'` | `'frostCrystal'` | `'qiBagua'` | `'sectSword'` | `'sectFist'` | `'sectTaiji'` | `'eogiUltimate'` | `'precisionLance'` | `'stoneDefault'`).
  final String projectileStyle;

  int bouncesLeft;
  bool bouncedOffObstacle = false;
  double lifeSec = 3.2;
  final Set<int> hitMutantIds = {};
  final List<Vec2> trail = [];
}

/// 전장을 가로지르는 심야 황금 보급 두꺼비.
class GoldenSupplyToad {
  GoldenSupplyToad({required this.pos, required this.vel});
  Vec2 pos;
  final Vec2 vel;
  bool alive = true;
}

/// 장치·동료별 전투 기여도 항목.
class ContributionEntry {
  ContributionEntry({
    required this.key,
    required this.label,
    this.totalDamage = 0,
    this.kills = 0,
  });
  final String key;
  final String label;
  double totalDamage;
  int kills;
}

/// 전투 종료 요약 보고서.
class BattleSummary {
  const BattleSummary({
    required this.victory,
    required this.stars,
    required this.earnedTokens,
    required this.earnedElixirs,
    required this.usedSupportCount,
    required this.pporokCount,
    required this.bankShotCount,
    required this.chainShatterCount,
    required this.serendipityCount,
    required this.granaryRatio,
    required this.cropsRatio,
    required this.livestockRatio,
    required this.contributions,
    required this.coachingTip,
    this.killCount = 0,
    this.wavesClearedCount = 0,
    this.encounteredMutants = const {},
    this.supportDeductedRealtime = false,
    this.bossElixirIncluded = false,
    this.convoyBuffConsumedRealtime = false,
    this.towerTookDamage = false,
  });

  final bool victory;
  final int stars;
  final int earnedTokens;
  final int earnedElixirs;
  final int usedSupportCount;
  final int pporokCount;
  final int bankShotCount;
  final int chainShatterCount;
  final int serendipityCount;
  final double granaryRatio;
  final double cropsRatio;
  final double livestockRatio;
  final List<ContributionEntry> contributions;
  final String coachingTip;
  final int killCount;
  final int wavesClearedCount;
  final Set<MutantKind> encounteredMutants;
  final bool supportDeductedRealtime;
  final bool bossElixirIncluded;
  final bool convoyBuffConsumedRealtime;
  final bool towerTookDamage;
}

class _PendingSpawn {
  _PendingSpawn({
    required this.delaySec,
    required this.kind,
    required this.laneIndex,
    this.waveIndex = 0,
    this.customTitle,
    this.customPortrait,
    this.customHitShield,
    this.hierarchyRank,
    this.startLaneProgress = 0.0,
    this.hpScale = 1.0,
  });

  double delaySec;
  final MutantKind kind;
  final int laneIndex;
  final int waveIndex;
  final String? customTitle;
  final String? customPortrait;
  final int? customHitShield;
  final String? hierarchyRank;
  final double startLaneProgress;
  final double hpScale;
}

/// 《수호알까기 · 탄지무림 심야기습》 실시간 & 자동 검증 공용 2차원 물리 전투 시뮬레이터.
class DefenseBattleSim {
  DefenseBattleSim({
    required this.stage,
    required DefenseDifficulty difficulty,
    required this.progress,
    LoadoutPreset? overridePreset,
    int seed = 20261115,
    this.allowSupportTokens = true,
    this.allowSerendipity = true,
    this.autoBuildForSimVerify = false,
  })  : difficulty = stage.isReincarnationBossStage
            ? DefenseDifficulty.nightmare
            : difficulty,
        chapter = CampaignCatalog.chapterOf(stage.chapterNumber),
        preset = overridePreset ?? progress.activePreset,
        rng = Random(seed) {
    _initBattle();
  }

  final StageSpec stage;
  final ChapterSpec chapter;
  final DefenseDifficulty difficulty;
  final PlayerProgress progress;
  final LoadoutPreset preset;
  final Random rng;
  final bool allowSupportTokens;
  final bool allowSerendipity;

  /// 각 장 코덱스 맵 원화의 실제 원형 석조 수호 제단 좌표 (중앙 수호탑 및 외곽 기공 방어막 중심!).
  Vec2 get towerPos => chapter.towerPos;
  Vec2 get shieldCenter => chapter.towerPos;

  /// 윤회 최종 보스전(`globalIndex == 888`)에서는 어느 난이도로 진입하더라도 항상 최고 극한(악몽+) 규격을 강제하며,
  /// 패배 시 소모했던 지원패·전술비약을 원상 복구하여 5% 미만 확률 도전을 막힘없이 반복할 수 있게 한다!
  DefenseDifficulty get effectiveDifficulty =>
      stage.isReincarnationBossStage ? DefenseDifficulty.nightmare : difficulty;

  /// 실시간 위험 비상 알림 & 2.8배 공격 지점 확대 영상 모니터 상태!
  CrisisAlertInfo? activeCrisis;
  Vec2? _crisisCamFocus;

  /// 자동 검증 시뮬레이터(`defense_verify_sim`)에서만 true로 두어 빈 초소를 순차 건설·승급한다.
  /// 실제 플레이에서는 false이며, 전투 시작 시 길목 발사대는 0개(모두 빈 초소)이고 플레이어가 직접 배치한다!
  final bool autoBuildForSimVerify;

  /// 운빨 무작위 초소 기본 소환 비용 (설치된 포탑 수에 비례해 +14⚡씩 체증!).
  static const int luckySummonCostTokens = 50;

  /// 신규 포대 축조 소요 시간(초) — 적 코앞에 닥쳐서 뒤늦게 지으면 뚫리도록 사전 포진 유도!
  static const double buildConstructSec = 2.2;

  /// 포대 승급 단조 소요 시간(초).
  static const double upgradeConstructSec = 1.15;

  /// 중앙 기명 수호탑의 자동 모드 근접 경계 사거리 (본진 결계 코앞 마지막 굽이 비상 견제 전용!).
  static const double centralAutoMaxRange = 148.0;

  /// 중앙 기명 수호탑의 수동 탄지 기본 유효 사거리 (720×1360 전장 하단~중단 권역 정밀 도탄!).
  static const double centralManualBaseRange = 365.0;

  /// 보스 정밀 약점 파쇄 신궁탄 재장전 간격(초).
  static const double precisionStrikeIntervalSec = 0.92;

  /// 마기 암석 잔해가 개척 완료된 초소 번호 집합 (기본 0·1번 최후방 거점만 개척 상태로 시작!).
  final Set<int> excavatedSlots = {0, 1};
  int excavatedPadCount = 0;
  int purifiedCorruptionCount = 0;

  late final CentralGuardianSpec centralSpec;
  late double shieldMaxHpDynamic;
  late double shieldHp;
  late double towerHp;
  double centralFireTimer = 0.25;
  double centralGearAngle = 0.0;
  double precisionStrikeCooldown = 0.0;
  int precisionHitCount = 0;
  int bossPhaseBreakCount = 0;
  bool autoPrecisionForVerify = true;

  /// 맨 아래 중앙 기명 수호탑 `자동 발사` ↔ `수동 탄지` 전환 상태 및 수동 공명 타이머.
  bool centralManualMode = false;
  double centralAimAngleRad = -pi / 2;
  double centralRecoilAnim = 0.0;
  double manualResonanceTimer = 0.0;

  /// 길목 초소가 최소 1곳 설치되었거나 수동 탄지 공명이 살아 있을 때만 진법(영수·동료·회복)이 활성화됨!
  bool get isFormationActive => launchers.isNotEmpty || manualResonanceTimer > 0;

  final Set<int> _gapWarningWaves = <int>{};

  /// 현재 물결에서 요구되는 진법 결속률(0.10 ~ 1.0):
  /// 초반에 포대 2~4개만 설치하고 방치하면 중후반 물결에서 진법 기맥이 끊겨 본진·동료 공명이 급감하고 빈 길목 마기 폭주가 발생한다!
  double get formationCoverageRatio {
    if (!isFormationActive) return 0.0;
    if (currentWaveIndex == 0 || elapsedSec < 26.0) return 1.0;

    int unlockedPads = 0;
    for (final m in activeMounts) {
      if (isSlotWaveUnlocked(m.slotIndex)) unlockedPads++;
    }
    if (unlockedPads <= 2) return 1.0;

    final double targetFrac = switch (currentWaveIndex) {
      1 => difficulty == DefenseDifficulty.nightmare ? 0.58 : 0.50,
      2 => difficulty == DefenseDifficulty.nightmare ? 0.76 : 0.68,
      _ => switch (difficulty) {
          DefenseDifficulty.easy => 0.65,
          DefenseDifficulty.normal => 0.78,
          DefenseDifficulty.nightmare => 0.88,
        },
    };

    // 연성 합체(merge)로 슬롯을 압축한 경우 물리 요구 대수에서 정당하게 차감 인정!
    // 단, 4~5초소 소규모 관문(1-1 포함)에서도 '포대 2개만 딸깍 짓고 방치'하면 결속이 깨지도록 최소 3.4기(합체 시 차감) 기준 적용!
    final double baseMinPads = currentWaveIndex >= 2
        ? max(unlockedPads * targetFrac, unlockedPads - 0.65)
        : unlockedPads * targetFrac;
    final double reqPads = max(
      currentWaveIndex >= 2 ? 3.4 : 2.0,
      baseMinPads - mergeEvolutionCount * 0.95,
    );
    final double padCountRatio = (launchers.length / reqPads).clamp(0.10, 1.0);

    double effectiveUnits =
        (liveFirepowerLv + liveReloadLv + liveRangeLv + liveBarrierLv) * 0.36 +
            mergeEvolutionCount * 0.85;
    for (final l in launchers) {
      effectiveUnits += switch (l.tier) {
        1 => 1.0,
        2 => 1.60,
        3 => 2.45,
        4 => 3.65,
        _ => 5.25,
      };
    }
    final double waveProg =
        (currentWaveIndex / max(1, stage.waves.length - 1)).clamp(0.0, 1.0);
    final double qualMult = 1.0 +
        max(0.0, waveProg - 0.34) *
            switch (difficulty) {
              DefenseDifficulty.easy => 0.22,
              DefenseDifficulty.normal => 0.52,
              DefenseDifficulty.nightmare => 0.85,
            };
    final double reqUnits = reqPads * qualMult;
    final double unitRatio = (effectiveUnits / max(1.0, reqUnits)).clamp(0.10, 1.0);
    return min(padCountRatio, unitRatio);
  }

  /// 본진 중앙탑·영수·동료·결계 자연회복에 곱해지는 진법 기맥 공명 배율 (결속률 95% 이상이면 1.0 유지, 소수 설치 방치 시 급감!).
  double get formationResonanceScale {
    final cov = formationCoverageRatio;
    if (cov >= 0.95) return 1.0;
    return pow(cov, 1.90).toDouble().clamp(0.06, 1.0);
  }

  static const List<double> _chapterExpectedDpsCurve = <double>[
    1.30,
    2.20,
    5.20,
    9.20,
    17.50,
    32.50,
    49.00,
    74.00,
    102.00,
    142.00,
  ];

  static const List<double> _nightmareChapterDensityMult = <double>[
    2.45,
    3.85,
    2.95,
    2.05,
    3.85,
    5.20,
    3.30,
    5.65,
    1.15,
    1.50,
  ];

  /// 환생(reincarnationCount >= 1) 시 기존 종결 능력치를 그대로 들고 1-1부터 출발하더라도
  /// 1~9현이 싱겁지 않도록 각 현의 초소 대수(4→14곳)·경로 길이에 맞춰 종결 스펙 기준선으로 끌어올린 기본 체력 곡선!
  /// (여기에 매 환생마다 3.0^reincarnationCount 배수 [1환생=3배, 2환생=9배, 3환생=27배...]가 전 난이도에 곱해진다!)
  static const List<double> _reincarnationEndgameBaseCurve = <double>[
    36.0,
    44.0,
    56.0,
    68.0,
    82.0,
    98.0,
    116.0,
    136.0,
    158.0,
    182.0,
  ];

  /// 【윤회 최종 보스전】 성공 확률 <5%(목표 약 2.0~4.5%) 정밀 보정 계수.
  static const double reincarnationBossHpPressure = 4.02;
  static const double reincarnationBossAtkPressure = 4.12;

  double get _playerLauncherDpsIndex {
    double permSum = 0.0;
    int permCnt = 0;
    for (final lt in LauncherType.values) {
      if (isLauncherTypeUnlocked(lt)) {
        permSum += (progress.launcherPermanentLevels[lt] ?? 1);
        permCnt++;
      }
    }
    final avgPerm = permCnt > 0 ? permSum / permCnt : 1.0;
    return (1.0 + (avgPerm - 1.0) * 0.16) *
        progress.realm.powerMult *
        preset.primaryStone.damageMultiplier *
        progress.transcendenceMultiplier *
        (1.0 +
            progress.meridianLauncherDmgBonus +
            progress.coreFirepowerBonus +
            progress.codexPowerBonus +
            progress.forgeMasteryPowerBonus);
  }

  /// 악몽(Nightmare) 난이도 전용 심야 공명 스케일링:
  /// 만렙·고성장 계정이 하위 현(1~7현) 악몽에 진입해도 '설치 몇 번에 순삭'되지 않고 전 100판 모두 진검 승부가 되도록 보정한다.
  double get _nightmareChallengeScale {
    if (difficulty != DefenseDifficulty.nightmare ||
        stage.globalIndex >= 900 ||
        stage.isReincarnationBossStage) {
      return 1.0;
    }
    final launcherDpsIdx = _playerLauncherDpsIndex;
    final chIdx =
        (stage.chapterNumber - 1).clamp(0, _chapterExpectedDpsCurve.length - 1);
    // 환생 회차에서는 이미 _reincarnationEndgameBaseCurve * 3^k 가 전 장을 종결 기준선×3^k로 끌어올렸으므로,
    // 기대 화력 역시 종결 기준선×3^k를 기준으로 삼아 중복 과잉 스케일링을 방지하고 성장 체감을 보존한다.
    final expectedDps = progress.reincarnationCount > 0
        ? (32.0 + chIdx * 12.2) * progress.reincarnationDifficultyMultiplier
        : _chapterExpectedDpsCurve[chIdx];
    final overRatio = launcherDpsIdx / expectedDps;
    if (overRatio <= 2.65) return 1.0;
    return pow(overRatio / 2.65, 0.84).toDouble().clamp(1.0, 58.0);
  }

  bool get isCentralReadyToFire => !isFinished && towerHp > 0 && centralFireTimer <= 0.04;

  bool get isPrecisionStrikeReady => !isFinished && towerHp > 0 && precisionStrikeCooldown <= 0.02;

  /// 현재 전장에 살아 있는 다단 변이(2페이즈 중간보스 / 3페이즈 대수괴) 중 최우선 위협 보스 반환!
  ActiveMutant? get activeMultiPhaseBoss {
    ActiveMutant? best;
    for (final m in mutants) {
      if (m.totalPhases <= 1) continue;
      if (best == null) {
        best = m;
        continue;
      }
      if (m.totalPhases != best.totalPhases) {
        if (m.totalPhases > best.totalPhases) best = m;
      } else if (m.pos.distanceTo(shieldCenter) <
          best.pos.distanceTo(shieldCenter)) {
        best = m;
      }
    }
    return best;
  }

  /// 마을 생태계 3대 지표 (1.0 = 평온/풍요, 0.0 = 황폐/폐사).
  double granaryHealth = 1.0;
  double cropsHealth = 1.0;
  double livestockHealth = 1.0;
  bool villageTookDamage = false;
  bool towerTookDamage = false;
  bool _convoyBuffConsumedRealtime = false;
  bool get hasConsumedConvoyBuff => _convoyBuffConsumedRealtime;

  /// 현장 건설 기력(⚡ · 초소 건설/승급 전용) 및 정산 누적 보상.
  int fieldTokens = 0;
  int earnedPermanentTokens = 0;
  int earnedElixirs = 0;
  double _permTokenCarry = 0.0;
  double _fieldTokenCarry = 0.0;
  double _autoChulduCooldown = 0.0;

  /// 내공 게이지 (0.0 ~ maxQiBars) 및 전술 비약 버프 타이머.
  double qiBars = 0.0;
  double get maxQiBars => progress.maxQiBars;
  double _autoEogiCooldown = 0.0;
  bool _encoreEogiReserved = false;
  double _qiBurstSynergyTimer = 0.0;
  double _fireBurstCooldown = 0.0;
  Vec2? _lastFireBurstPos;
  BattleSummary? _cachedSummary;
  double jeonggakHasteTimer = 0.0;
  double _jeonggakHasteMult = 1.45;
  double cheonghakBuffTimer = 0.0;
  double auroraCritTimer = 0.0;
  double seolhwaFrostShieldTimer = 0.0;
  double mukhyeonCooldownTimer = 0.0;

  /// 연쇄 타격 콤보 및 광폭 탄지 무쌍(피버 타임) 상태.
  int comboCount = 0;
  int bestCombo = 0;
  double comboResetTimer = 0.0;
  double feverGauge = 0.0;
  double feverTimer = 0.0;

  /// 물결 돌파 3택 1 로그라이트 비급(RoguePerk) 누적 스택 및 실시간 제한시간(6.5초 — 못 누르면 통과!) 상태.
  static const double perkWindowDurationSec = 6.5;
  final Map<RoguePerk, int> activePerks = {};
  final List<RoguePerk> pendingPerkChoices = [];
  int pendingPerkRolls = 0;
  double perkChoiceTimer = 0.0;

  /// 전투 중 멈춤 없이 실시간 기력(⚡)으로 누르는 전군 일괄 업그레이드 4종(화력·연사·사거리·결계) 레벨!
  int liveFirepowerLv = 0;
  int liveReloadLv = 0;
  int liveRangeLv = 0;
  int liveBarrierLv = 0;

  /// 실시간 사거리 강화 배율 (최대 4단, 단당 +11% 확장 — 무분별한 전체 맵 공격 차단!).
  double get liveRangeMultiplier => 1.0 + liveRangeLv.clamp(0, 4) * 0.11;

  /// 중앙 기명 수호탑의 현재 자동 경계 유효 사거리 (제4장 고지 봉화 특색 +24% 반영).
  double get effectiveCentralAutoRange =>
      (centralAutoMaxRange *
              (chapter.number == 4 ? 1.24 : 1.0) *
              liveRangeMultiplier)
          .clamp(142.0, 265.0);

  /// 중앙 기명 수호탑의 현재 수동 탄지 유효 사거리 (제4장 고지 봉화 특색 +24% 반영).
  double get effectiveCentralManualRange =>
      (centralManualBaseRange *
              (chapter.number == 4 ? 1.24 : 1.0) *
              liveRangeMultiplier)
          .clamp(345.0, 580.0);

  /// 장이 올라갈수록·고난도일수록 포대 축조 시간이 길어져 사전 포진 전략을 요구한다!
  double get effectiveBuildConstructSec {
    final diffScale = switch (difficulty) {
      DefenseDifficulty.easy => 0.90,
      DefenseDifficulty.normal => 1.00,
      DefenseDifficulty.nightmare => 1.15,
    };
    return chapter.buildDurationSec * diffScale;
  }

  /// 장별 마기 암석 개척 비용 배율 반영!
  int excavationCostForSlot(LauncherMountSlot slot) {
    if (slot.excavationCost <= 0) return 0;
    final diffScale = difficulty == DefenseDifficulty.nightmare ? 1.12 : 1.0;
    return (slot.excavationCost * chapter.excavationCostMultiplier * diffScale).round();
  }

  /// 현재 배치된 포탑 수 + 장별 건설 난이도 배율(`buildCostMultiplier`)에 비례해 증가하는 체증 건설비!
  int buildCostForType(LauncherType type) =>
      (type.progressiveBuildCost(launchers.length) * chapter.buildCostMultiplier).round();

  /// 전장 배치 포탑의 상위 형(1→2→3→4형) 단조 승급비 (장별 건설 난이도 배율 반영!).
  int upgradeCostForLauncher(ActiveLauncher l) =>
      (l.type.inBattleUpgradeCost(l.tier) * chapter.buildCostMultiplier).round();

  /// 진법 편성실(`preset.mountTypes`)과 관문 지형 추천을 결합한 해당 초소 최적 추천 병종!
  LauncherType preferredBuildTypeForSlot(LauncherMountSlot slot) {
    final fromPreset = slot.slotIndex < preset.mountTypes.length
        ? preset.mountTypes[slot.slotIndex]
        : slot.recommendedType;
    if (isLauncherTypeUnlocked(fromPreset)) return fromPreset;
    if (isLauncherTypeUnlocked(slot.recommendedType)) return slot.recommendedType;
    return LauncherType.rapid;
  }

  /// 현재 배치된 포탑 수 + 장별 건설 난이도 배율에 비례해 증가하는 운빨 소환 체증 비용!
  int get currentLuckySummonCost =>
      ((luckySummonCostTokens + launchers.length.clamp(0, 20) * 14) * chapter.buildCostMultiplier)
          .round();

  /// 해당 거점의 마기 암석 잔해가 개척 완료되었는지 여부.
  bool isSlotExcavated(int slotIndex) {
    final slot = mountSlotByIndex(slotIndex);
    if (slot == null) return false;
    return slot.excavationCost <= 0 || excavatedSlots.contains(slotIndex);
  }

  /// 같은 형 포탑 2기 합치기 각성 시 필요한 유료 연성 기력 (무료 합치기 꼼수 차단!).
  int mergeCostForSlot(int slotIndex) {
    final target = launcherAtSlot(slotIndex);
    if (target == null || target.tier >= 5) return 0;
    return 24 * target.tier;
  }

  /// 개별 길목 초소(ActiveLauncher)의 현재 유효 사거리 (5종 지형 보너스 + 장별 특색 + 계통 고유 사거리 + 승급 + 인접 증폭기 + 실시간 사거리업 반영).
  double effectiveLauncherRange(ActiveLauncher l) {
    final ch4WatchtowerBoost =
        (chapter.number == 4 && l.terrainType == MountTerrainType.highWatchtower) ? 1.24 : 1.0;
    double mult = l.terrainType.rangeMult *
        ch4WatchtowerBoost *
        liveRangeMultiplier *
        (1.0 + progress.corePrecisionBonus * 0.30);
    if (l.type != LauncherType.qiAmplifier) {
      final ch5AmpMult = chapter.number == 5 ? 1.35 : 1.0;
      int ampRangeStacks = 0;
      for (final other in launchers) {
        final auraR = 195.0 * (other.terrainType == MountTerrainType.spiritSpring ? 1.25 : 1.0);
        if (other != l &&
            !other.isConstructing &&
            other.type == LauncherType.qiAmplifier &&
            other.pos.distanceTo(l.pos) <= auraR) {
          mult += (0.14 + other.tier * 0.02) * ch5AmpMult;
          ampRangeStacks++;
          if (ampRangeStacks >= 2) break;
        }
      }
    }
    return (l.type.effectiveBaseRange(l.tier) * mult).clamp(116.0, 365.0);
  }

  /// 빈 초소 선택·미리보기 시 표시할 예정 유효 사거리 (편성 병종 + 지형 특성 + 4장 망루 보너스 즉시 반영).
  double previewSlotRange(LauncherMountSlot slot) {
    final pType = preferredBuildTypeForSlot(slot);
    final ch4Watch =
        (chapter.number == 4 && slot.terrainType == MountTerrainType.highWatchtower) ? 1.24 : 1.0;
    return (pType.baseRangePx *
            slot.terrainType.rangeMult *
            ch4Watch *
            liveRangeMultiplier *
            (1.0 + progress.corePrecisionBonus * 0.30))
        .clamp(116.0, 365.0);
  }

  /// 길이 아닌 옆숲·땅굴 비정규 침투 기습 타이머 및 출몰 카운트!
  double infiltrationTimer = 8.8;
  int infiltratorSpawnCount = 0;
  int infiltratorWaveCount = 0;

  /// 전장 핀볼 기물(×2·×3 진화 복제진 · 🎯화력 과녁패 · 심야 화약통 · 황금 보물 도깨비) 및 시각 연출 큐.
  late CloneGateZone cloneGate;
  late PowerTargetProp powerTarget;
  final List<PowderKegProp> powderKegs = [];
  TreasureGoblinEntity? treasureGoblin;
  int goblinSpawnsDone = 0;
  int powderKegsDetonated = 0;

  /// 실시간 긴급 현상수배 미션 단계(0~4), 기연 돌림판 횟수, 자동 비급 선택 편의 설정!
  int bountyQuestStep = 0;
  int rouletteSpinsAvailable = 1;
  double rouletteHyperBarrageTimer = 0.0;
  DestinyRoulettePrize? lastRoulettePrize;
  bool autoChoosePerks = false;
  bool _bossRouletteGranted = false;
  bool _emergencyRepulseUsed = false;
  final List<FlyingQiOrb> flyingQiOrbs = [];
  final List<LightningArcFx> lightningArcs = [];
  final List<MutantDeathRagdoll> deathRagdolls = [];
  final List<MuzzleFlashFx> muzzleFlashes = [];
  final List<DamagePopupFx> damagePopups = [];
  final List<ShockwaveRingFx> shockwaveRings = [];
  final Set<int> _earlyCalledWaves = {};
  final Set<int> _waveUnlockAnnounced = {};
  final Set<int> _waveClimaxAnnounced = {};

  /// 연속 격살 체인(Kill Streak) 및 본진 위기 심장박동 긴장감 지표(0.0 ~ 1.0).
  int killStreak = 0;
  int bestKillStreak = 0;
  double killStreakTimer = 0.0;
  double dangerPulseLevel = 0.0;

  /// 지원패(암행어사 출두) 슬롯 및 연출 타이머.
  int supportChargesLeft = 0;
  int usedSupportCount = 0;
  final Map<TacticalConsumable, int> _trialConsumableUsed = {};
  bool pendingFreeEncoreChuldu = false;
  double chulduSweepAnimTimer = 0.0;
  double dawnPurifyAnimTimer = 0.0;
  bool mukhyeonTriggered = false;

  /// 재미 지표 및 도감 누적 카운터.
  int killCount = 0;
  int wavesClearedCount = 0;
  int pporokCount = 0;
  int bankShotCount = 0;
  int chainShatterCount = 0;
  int serendipityCount = 0;
  int luckyJackpotSummonCount = 0;
  int mergeEvolutionCount = 0;
  int cloneSplitCount = 0;
  int heavyHitsOnShield = 0;
  int shieldYachaBlocks = 0;
  int swarmHitsOnShield = 0;
  final Set<MutantKind> encounteredMutants = {};

  int currentWaveIndex = 0;
  double wavePauseTimer = 0.6;
  bool goldenToadSpawned = false;
  GoldenSupplyToad? goldenToad;

  bool isFinished = false;
  bool isVictory = false;
  double elapsedSec = 0.0;
  int _nextMutantUid = 1;

  final List<ActiveLauncher> launchers = [];
  final List<_PendingSpawn> _spawnQueue = [];
  final List<ActiveMutant> mutants = [];
  final List<ActiveStoneProjectile> projectiles = [];
  final List<FloatingCallout> callouts = [];
  final List<FxBurst> bursts = [];
  final List<SoundCue> pendingSounds = [];
  final List<StoryLine> pendingStoryLines = [];
  final List<double> pillarAngles = [];

  /// 침공 길목 입구 독기 균열문 활성도(0.0 ~ 1.0), 전장 진동 및 보스 동반 침공 경보 상태.
  final List<double> lanePortalEnergy = [];
  double screenShakeTimer = 0.0;
  double screenShakeIntensity = 0.0;
  String? bossInvasionAlertText;
  double bossInvasionAlertTimer = 0.0;

  late double beastCooldown;
  final Map<CompanionHero, double> companionCooldowns = {};
  final Map<String, ContributionEntry> _contribMap = {};

  /// 이번 관문에서 개방된 길목 초소 목록 (`1-1` 2곳 → 후반 최대 10곳 점진 확장!).
  List<LauncherMountSlot> get activeMounts =>
      chapter.mounts.take(stage.maxMountCount.clamp(1, chapter.mounts.length)).toList();

  int perkStacks(RoguePerk perk) => activePerks[perk] ?? 0;

  void _initBattle() {
    centralSpec = CentralGuardianSpec.fromLevels(
      centralLevel: progress.centralGuardianLevel,
      realmDefenseMult: progress.realm.defenseMult,
      meridianShieldBonus: progress.meridianShieldHpBonus,
      meridianReloadBonus: progress.meridianCentralReloadBonus,
      coreFortitudeBonus: progress.coreFortitudeBonus +
          progress.codexPowerBonus +
          progress.forgeMasteryPowerBonus,
      coreFirepowerBonus: progress.coreFirepowerBonus +
          progress.codexPowerBonus +
          progress.forgeMasteryPowerBonus,
      transcendenceMultiplier: progress.transcendenceMultiplier,
    );
    shieldMaxHpDynamic =
        centralSpec.shieldMaxHp * (chapter.number == 6 ? 1.30 : 1.0);
    shieldHp = shieldMaxHpDynamic;
    towerHp = centralSpec.coreMaxHp;

    final hasConvoyBuff = progress.convoySupplyBuffBattles > 0;
    if (hasConvoyBuff &&
        allowSupportTokens &&
        !autoBuildForSimVerify &&
        !stage.isReincarnationBossStage) {
      progress.convoySupplyBuffBattles = max(0, progress.convoySupplyBuffBattles - 1);
      _convoyBuffConsumedRealtime = true;
    }
    final buffMult = hasConvoyBuff ? 1.20 : 1.0;
    fieldTokens = (stage.startingFieldTokens * buffMult).round();
    qiBars = (progress.realm.startQiBars + progress.meridianStartQiBonus).clamp(0.0, maxQiBars);

    _trialConsumableUsed.clear();
    if (allowSupportTokens) {
      if (stage.isReincarnationBossStage) {
        // <5% 극한 윤회 심판전에서는 패배 재도전 시 보유 지원패가 고갈되지 않도록 심판전 전용 공명 슬롯 부여
        supportChargesLeft = max(1, preset.supportSlotCount.clamp(0, 3));
      } else {
        supportChargesLeft = min(preset.supportSlotCount, progress.supportTokens);
      }
    }

    launchers.clear();
    excavatedSlots
      ..clear()
      ..addAll(const [0, 1]);

    // 전장 핀볼 기물 초기화: 각 장의 실제 제단 위치(하단·중앙·상단)와 석조 도로 굽이 위에 정확히 배치!
    final spinePts = chapter.smoothedVisualSpine;
    Vec2 spineAt(double ratio, Vec2 fallback) {
      if (spinePts.isEmpty) return fallback;
      final idx = ((spinePts.length - 1) * ratio).round().clamp(0, spinePts.length - 1);
      return spinePts[idx];
    }

    cloneGate = CloneGateZone(
      baseCenter: chapter.cloneGateBasePos,
      radius: 28.0,
      swayAmplitude: 108.0,
    );
    powerTarget = PowerTargetProp(
      baseCenter: chapter.powerTargetBasePos,
      radius: 23.0,
      swayAmplitude: 118.0,
    );
    powderKegs.clear();
    if (chapter.lanes.length >= 2 && (chapter.number == 6 || chapter.number == 2)) {
      final l0 = chapter.smoothedLane(0);
      final l1 = chapter.smoothedLane(1);
      Vec2 laneAt(List<Vec2> pts, double r, Vec2 fb) =>
          pts.isEmpty ? fb : pts[((pts.length - 1) * r).round().clamp(0, pts.length - 1)];
      powderKegs
        ..add(PowderKegProp(pos: laneAt(l0, 0.35, const Vec2(360, 320))))
        ..add(PowderKegProp(pos: laneAt(l1, 0.35, const Vec2(360, 920))))
        ..add(PowderKegProp(pos: spineAt(0.62, const Vec2(360, 520))));
    } else {
      powderKegs
        ..add(PowderKegProp(pos: spineAt(0.72, const Vec2(252, 680))))
        ..add(PowderKegProp(pos: spineAt(0.50, const Vec2(465, 480))))
        ..add(PowderKegProp(pos: spineAt(0.28, const Vec2(345, 290))));
    }

    for (final _ in chapter.pillars) {
      pillarAngles.add(0.0);
    }
    for (final _ in chapter.lanes) {
      lanePortalEnergy.add(0.0);
    }

    beastCooldown = 2.6;
    for (final hero in preset.companions) {
      if ((progress.companionLevels[hero] ?? 0) > 0) {
        companionCooldowns[hero] = 2.8 + companionCooldowns.length * 1.1;
      }
    }

    if (!autoBuildForSimVerify && stage.hasRescueReward) {
      callouts.add(
        FloatingCallout(
          pos: const Vec2(360, 152),
          text: '🆘 ${stage.rescueBadgeText} 작전!',
          colorHex: 0xFF72EFDD,
          ttlSec: 2.8,
          isBigBanner: true,
        ),
      );
    }

    _enqueueWave(0);
  }

  /// 초소 번호별 물결 봉인 해제 기준 (6~8물결 호흡에 맞춰 1→2→3→4물결 단계적 해금!).
  int unlockWaveNumberForSlot(int slotIndex) {
    if (slotIndex <= 1) return 1;
    if (slotIndex <= 5) return 2;
    if (slotIndex <= 9) return 3;
    return 4;
  }

  /// 현재 물결에서 해당 초소의 봉인이 풀려 개척·건설 가능한지 여부.
  bool isSlotWaveUnlocked(int slotIndex) =>
      (currentWaveIndex + 1) >= unlockWaveNumberForSlot(slotIndex);

  /// 상단 건설 기력 바 & 초소 발판에 표시할 실시간 조건 상태 계산!
  PadConditionInfo padConditionOf(int slotIndex) {
    final slot = mountSlotByIndex(slotIndex);
    final recType = slot == null ? LauncherType.rapid : preferredBuildTypeForSlot(slot);
    final recCost = buildCostForType(recType);
    final luckyCost = currentLuckySummonCost;
    final unlockWave = unlockWaveNumberForSlot(slotIndex);
    final excavCost = slot == null ? 0 : excavationCostForSlot(slot);

    final builtLauncher = launcherAtSlot(slotIndex);
    if (builtLauncher != null) {
      final badge = builtLauncher.isCorrupted
          ? '🕸️터치정화!'
          : (builtLauncher.isConstructing ? '🔨축조 중' : '가동 중');
      return PadConditionInfo(
        slotIndex: slotIndex,
        state: PadConditionState.built,
        unlockWaveNumber: unlockWave,
        currentQi: fieldTokens,
        luckySummonCost: luckyCost,
        directBuildCost: recCost,
        excavationCost: 0,
        chargeRatio: builtLauncher.constructProgress,
        shortBadge: badge,
        detailReason: builtLauncher.isCorrupted
            ? '마기 침식으로 연사가 느려졌습니다! 즉시 터치하면 무료 정화 및 연사 각성이 발동됩니다!'
            : (builtLauncher.isConstructing
                ? '기관 포대를 실시간 축조하고 있습니다 (${builtLauncher.constructTimer.toStringAsFixed(1)}초 남음).'
                : '배치 완료된 초소입니다. 터치하여 승급·연성합치기·교체·철거할 수 있습니다.'),
      );
    }

    if (!isSlotWaveUnlocked(slotIndex)) {
      return PadConditionInfo(
        slotIndex: slotIndex,
        state: PadConditionState.waveLocked,
        unlockWaveNumber: unlockWave,
        currentQi: fieldTokens,
        luckySummonCost: luckyCost,
        directBuildCost: recCost,
        excavationCost: excavCost,
        chargeRatio: ((currentWaveIndex + 1) / unlockWave).clamp(0.0, 0.99),
        shortBadge: '🔒$unlockWave물결 봉인',
        detailReason: '전방 전략 지형 거점입니다! 제$unlockWave물결 진입 후 마기 암석을 개척해 사용할 수 있습니다.',
      );
    }

    // ★ 마기 암석 잔해 개척 단계: 2번 이상 전방 요충지는 먼저 기력을 들여 개척해야 포대 건설 가능!
    if (!isSlotExcavated(slotIndex)) {
      final canExcavate = fieldTokens >= excavCost;
      return PadConditionInfo(
        slotIndex: slotIndex,
        state: PadConditionState.rubbleBlocked,
        unlockWaveNumber: unlockWave,
        currentQi: fieldTokens,
        luckySummonCost: luckyCost,
        directBuildCost: recCost,
        excavationCost: excavCost,
        chargeRatio: (fieldTokens / max(1, excavCost)).clamp(0.0, 1.0),
        shortBadge: canExcavate ? '⛏️개척가능($excavCost⚡)' : '🪨마기암석($excavCost⚡)',
        detailReason: canExcavate
            ? '전방 [${slot?.terrainType.name ?? '요충지'}] 거점의 마기 암석을 지금 개척($excavCost⚡)하여 포대 터를 닦으세요!'
            : '마기 암석이 거점을 가로막고 있습니다! 기력 $excavCost⚡을 모아 먼저 개척해야 포대를 세울 수 있습니다.',
      );
    }

    final cheapestUnlockedCost = LauncherType.values
        .where(isLauncherTypeUnlocked)
        .map(buildCostForType)
        .fold<int>(recCost, min);

    if (fieldTokens >= recCost) {
      return PadConditionInfo(
        slotIndex: slotIndex,
        state: PadConditionState.readyFullBuild,
        unlockWaveNumber: unlockWave,
        currentQi: fieldTokens,
        luckySummonCost: luckyCost,
        directBuildCost: recCost,
        chargeRatio: 1.0,
        shortBadge: '🔨축조($recCost⚡)',
        detailReason: '개척 완료! 지정 포대($recCost⚡ · 2.2초 축조) 또는 도박 소환($luckyCost⚡)을 지휘하세요.',
      );
    }

    if (fieldTokens >= cheapestUnlockedCost || fieldTokens >= luckyCost) {
      final minNeed = min(cheapestUnlockedCost, luckyCost);
      return PadConditionInfo(
        slotIndex: slotIndex,
        state: PadConditionState.readyLuckyOnly,
        unlockWaveNumber: unlockWave,
        currentQi: fieldTokens,
        luckySummonCost: luckyCost,
        directBuildCost: recCost,
        chargeRatio: (fieldTokens / recCost).clamp(0.0, 0.99),
        shortBadge: '🔨건설($minNeed⚡~)',
        detailReason: '기본 포대($cheapestUnlockedCost⚡) 축조 가능! 추천 병종($recCost⚡)까지는 ${recCost - fieldTokens}⚡ 남았습니다.',
      );
    }

    final targetNeed = min(cheapestUnlockedCost, luckyCost);
    return PadConditionInfo(
      slotIndex: slotIndex,
      state: PadConditionState.chargingQi,
      unlockWaveNumber: unlockWave,
      currentQi: fieldTokens,
      luckySummonCost: luckyCost,
      directBuildCost: recCost,
      chargeRatio: (fieldTokens / max(1, targetNeed)).clamp(0.0, 0.99),
      shortBadge: '⚡$fieldTokens/$targetNeed',
      detailReason: '포탑 수에 비례해 보급비가 증가했습니다! 적 처치·화약통 유폭으로 ${targetNeed - fieldTokens}⚡ 더 모으세요.',
    );
  }

  /// 해당 초소 번호에 배치된 발사대 조회 (비어 있으면 null).
  ActiveLauncher? launcherAtSlot(int slotIndex) {
    for (final l in launchers) {
      if (l.slotIndex == slotIndex) return l;
    }
    return null;
  }

  /// 이번 관문에 개방된 초소 정보 조회.
  LauncherMountSlot? mountSlotByIndex(int slotIndex) {
    for (final m in activeMounts) {
      if (m.slotIndex == slotIndex) return m;
    }
    return null;
  }

  /// 현재 물결에서 이미 개척 완료되어 즉시 포대를 올릴 수 있는 다음 빈 초소 번호.
  int? nextExcavatedEmptySlotIndex() {
    for (final m in activeMounts) {
      if (isSlotWaveUnlocked(m.slotIndex) &&
          isSlotExcavated(m.slotIndex) &&
          launcherAtSlot(m.slotIndex) == null) {
        return m.slotIndex;
      }
    }
    return null;
  }

  /// 현재 물결에서 개척 또는 건설 진행이 가능한 다음 빈 초소 번호.
  int? nextRecommendedSlotIndex() {
    final ready = nextExcavatedEmptySlotIndex();
    if (ready != null) return ready;
    for (final m in activeMounts) {
      if (isSlotWaveUnlocked(m.slotIndex) && launcherAtSlot(m.slotIndex) == null) {
        return m.slotIndex;
      }
    }
    return null;
  }

  /// 발사대 종류 해금 여부 확인 (현재 관문 장 번호 또는 환생 포함 무구 해금 장 기준).
  bool isLauncherTypeUnlocked(LauncherType type) =>
      type.unlockChapter <= max(stage.chapterNumber, progress.effectiveArsenalChapter);

  void _spawnFlyingQiOrb(Vec2 fromPos, int amount, {int colorHex = 0xFFFFD166}) {
    if (amount <= 0) return;
    if (flyingQiOrbs.length >= 28) {
      flyingQiOrbs.removeAt(0);
    }
    flyingQiOrbs.add(
      FlyingQiOrb(
        startPos: fromPos,
        targetPos: const Vec2(148, 14),
        amount: amount,
        colorHex: colorHex,
      ),
    );
  }

  void _spawnShockwaveRing(
    Vec2 pos, {
    required double maxRadius,
    required int colorHex,
    int secondaryColorHex = 0xFFFFFFFF,
    String style = 'critStar',
    double durationSec = 0.36,
  }) {
    if (shockwaveRings.length >= 34) {
      shockwaveRings.removeAt(0);
    }
    shockwaveRings.add(
      ShockwaveRingFx(
        pos: pos,
        maxRadius: maxRadius,
        colorHex: colorHex,
        secondaryColorHex: secondaryColorHex,
        style: style,
        durationSec: durationSec,
      ),
    );
  }

  /// 전방 전략 지형 거점(2번 이상)을 뒤덮은 마기 암석 잔해를 기력으로 파쇄·개척!
  bool excavateSlotInBattle(int slotIndex) {
    if (isFinished) return false;
    final slot = mountSlotByIndex(slotIndex);
    if (slot == null || !isSlotWaveUnlocked(slotIndex)) return false;
    if (isSlotExcavated(slotIndex)) return false;
    final cost = excavationCostForSlot(slot);
    if (fieldTokens < cost) return false;

    fieldTokens -= cost;
    excavatedSlots.add(slotIndex);
    excavatedPadCount++;
    manualResonanceTimer = max(manualResonanceTimer, 6.0);
    pendingSounds.add(SoundCue.criticalShatter);
    screenShakeTimer = max(screenShakeTimer, 0.16);
    screenShakeIntensity = max(screenShakeIntensity, 3.4);
    bursts.add(
      FxBurst(
        pos: slot.pos,
        colorHex: slot.terrainType.colorHex,
        maxRadius: 46,
        isTriangleShatter: true,
      ),
    );
    callouts.add(
      FloatingCallout(
        pos: slot.pos + const Vec2(0, -20),
        text: '⛏️ [${slot.terrainType.name}] 마기 암석 개척 완료! 포대 축조 가능!',
        colorHex: slot.terrainType.colorHex,
        isBigBanner: true,
      ),
    );
    return true;
  }

  /// 변이 두목·역병수의 마기 거미줄에 침식된 아군 포탑을 플레이어가 직접 터치해 즉시 정화 & 3.2초 연사 각성!
  bool cleanseLauncherAtSlot(int slotIndex) {
    if (isFinished) return false;
    final l = launcherAtSlot(slotIndex);
    if (l == null || !l.isCorrupted) return false;
    l.corruptionTimer = 0.0;
    l.purifiedBoostTimer = 3.2;
    purifiedCorruptionCount++;
    manualResonanceTimer = max(manualResonanceTimer, 6.0);
    pendingSounds.add(SoundCue.dawnPurify);
    bursts.add(FxBurst(pos: l.pos, colorHex: 0xFF72EFDD, maxRadius: 42));
    callouts.add(
      FloatingCallout(
        pos: l.pos + const Vec2(0, -20),
        text: '✨ 마기 침식 정화!! 3.2초간 연사 +25% 각성!',
        colorHex: 0xFF72EFDD,
      ),
    );
    return true;
  }

  /// 개척 완료된 빈 길목 초소에 플레이어가 직접 수호 발사대 축조 지시! (체증 보급비 + 2.2초 실시간 축조 공정)
  bool placeLauncherInBattle(int slotIndex, LauncherType type) {
    if (isFinished) return false;
    final slot = mountSlotByIndex(slotIndex);
    if (slot == null || !isSlotWaveUnlocked(slotIndex)) return false;
    if (!isSlotExcavated(slotIndex)) return false;
    if (launcherAtSlot(slotIndex) != null) return false;
    if (!isLauncherTypeUnlocked(type)) return false;

    final cost = buildCostForType(type);
    if (fieldTokens < cost) return false;
    fieldTokens -= cost;

    final permLv = progress.launcherPermanentLevels[type] ?? 1;
    final constructSec = effectiveBuildConstructSec;
    final created = ActiveLauncher(
      slotIndex: slot.slotIndex,
      pos: slot.pos,
      type: type,
      permanentLevel: permLv,
      terrainType: slot.terrainType,
      investedTokens: cost,
      constructTimer: constructSec,
      constructDuration: constructSec,
    );
    launchers.add(created);
    launchers.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: slot.pos, colorHex: slot.terrainType.colorHex, maxRadius: 36));
    callouts.add(
      FloatingCallout(
        pos: slot.pos + const Vec2(0, -18),
        text: '🔨 [${slot.terrainType.name}] ${type.name} 축조 개시!',
        colorHex: slot.terrainType.colorHex,
      ),
    );
    return true;
  }

  /// 개척된 초소에서 도박성 무작위 소환 (체증 비용 50⚡+14n⚡ · 6% 3형, 24% 2형, 70% 1형 · 2.2초 축조 공정!).
  ActiveLauncher? summonLuckyLauncherInBattle(int slotIndex) {
    if (isFinished) return null;
    final slot = mountSlotByIndex(slotIndex);
    if (slot == null || !isSlotWaveUnlocked(slotIndex)) return null;
    if (!isSlotExcavated(slotIndex)) return null;
    if (launcherAtSlot(slotIndex) != null) return null;
    final luckyCost = currentLuckySummonCost;
    if (fieldTokens < luckyCost) return null;

    fieldTokens -= luckyCost;

    final unlockedTypes = LauncherType.values.where(isLauncherTypeUnlocked).toList();
    final luckyPool = unlockedTypes.isEmpty ? <LauncherType>[LauncherType.rapid] : unlockedTypes;
    final rolledType = luckyPool[rng.nextInt(luckyPool.length)];
    final tierRoll = rng.nextDouble();
    final int rolledTier = tierRoll < 0.06 ? 3 : (tierRoll < 0.30 ? 2 : 1);

    final permLv = progress.launcherPermanentLevels[rolledType] ?? 1;
    final constructSec = effectiveBuildConstructSec;
    final created = ActiveLauncher(
      slotIndex: slot.slotIndex,
      pos: slot.pos,
      type: rolledType,
      permanentLevel: permLv,
      terrainType: slot.terrainType,
      investedTokens: luckyCost,
      constructTimer: constructSec,
      constructDuration: constructSec,
    )..tier = rolledTier;

    launchers.add(created);
    launchers.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    if (rolledTier >= 2) {
      luckyJackpotSummonCount++;
      serendipityCount++;
      pendingSounds.add(SoundCue.serendipityJackpot);
      screenShakeTimer = max(screenShakeTimer, rolledTier >= 3 ? 0.30 : 0.16);
      screenShakeIntensity = max(screenShakeIntensity, rolledTier >= 3 ? 5.8 : 3.2);
      bursts.add(
        FxBurst(
          pos: slot.pos,
          colorHex: rolledTier >= 3 ? 0xFFFFD166 : 0xFF72EFDD,
          maxRadius: rolledTier >= 3 ? 58 : 42,
          isTriangleShatter: rolledTier >= 3,
        ),
      );
      callouts.add(
        FloatingCallout(
          pos: slot.pos + const Vec2(0, -24),
          text: rolledTier >= 3
              ? '★대박 신화 소환!! $rolledTier형 ${rolledType.name} 강림!!'
              : '✦행운 희귀 소환! $rolledTier형 ${rolledType.name}!',
          colorHex: rolledTier >= 3 ? 0xFFFFD166 : 0xFF72EFDD,
          isBigBanner: rolledTier >= 3,
        ),
      );
    } else {
      pendingSounds.add(SoundCue.gearMotion);
      bursts.add(FxBurst(pos: slot.pos, colorHex: rolledType.colorHex, maxRadius: 32));
      callouts.add(
        FloatingCallout(
          pos: slot.pos + const Vec2(0, -18),
          text: '🎲 도박 소환: 1형 ${rolledType.name} 축조!',
          colorHex: rolledType.colorHex,
        ),
      );
    }
    return created;
  }

  /// 같은 종류·같은 형(1~4형 → 최대 ★5형 태초 신기!)의 다른 초소가 전장에 있는지 탐색 (축조 완료된 초소만!).
  int? findMergePartnerSlot(int slotIndex) {
    final target = launcherAtSlot(slotIndex);
    if (target == null || target.tier >= 5 || target.isConstructing) return null;
    for (final other in launchers) {
      if (other.slotIndex != slotIndex &&
          !other.isConstructing &&
          other.type == target.type &&
          other.tier == target.tier) {
        return other.slotIndex;
      }
    }
    return null;
  }

  /// 전장 전체에서 현재 보유 기력으로 유료 연성 합치기가 가능한 초소 쌍 조회!
  (int slotA, int slotB)? findAnyMergePair() {
    for (final l in launchers) {
      final partner = findMergePartnerSlot(l.slotIndex);
      if (partner != null && fieldTokens >= mergeCostForSlot(l.slotIndex)) {
        return (l.slotIndex, partner);
      }
    }
    return null;
  }

  /// 하단 「☯️ 연성 합치기」 실행 (연성 기력 소모 필수!).
  bool quickMergeAnyPair() {
    final pair = findAnyMergePair();
    if (pair == null) return false;
    return mergeLauncherAtSlot(pair.$1);
  }

  /// 이미 개척된 빈 초소에 도박 소환 실행 (개척 안 된 곳은 자동으로 못 지음!).
  ActiveLauncher? quickLuckySummonNextPad() {
    final nextSlot = nextExcavatedEmptySlotIndex();
    if (nextSlot == null) return null;
    return summonLuckyLauncherInBattle(nextSlot);
  }

  /// 이미 개척된 빈 초소에 지정 건설 실행 (맞춤 진법 편성 우선 반영!).
  bool quickDirectBuildNextPad() {
    final nextSlot = nextExcavatedEmptySlotIndex();
    if (nextSlot == null) return false;
    final slot = mountSlotByIndex(nextSlot);
    if (slot == null) return false;
    return placeLauncherInBattle(nextSlot, preferredBuildTypeForSlot(slot));
  }

  /// 같은 종류·같은 형 초소 2곳에 연성 기력(24×형수⚡)을 투입하여 상위 형(+1형, 최대 ★5형 태초 신기!) 진화 각성!
  bool mergeLauncherAtSlot(int slotIndex) {
    if (isFinished) return false;
    final target = launcherAtSlot(slotIndex);
    final partnerSlot = findMergePartnerSlot(slotIndex);
    if (target == null || partnerSlot == null) return false;
    final partner = launcherAtSlot(partnerSlot);
    if (partner == null) return false;

    final mergeCost = mergeCostForSlot(slotIndex);
    if (fieldTokens < mergeCost) return false;
    fieldTokens -= mergeCost;

    launchers.remove(partner);
    final unlockedTypes = LauncherType.values.where(isLauncherTypeUnlocked).toList();
    var mergePool = unlockedTypes.isEmpty ? <LauncherType>[LauncherType.rapid] : unlockedTypes;
    final directAttackers =
        launchers.where((l) => l.type != LauncherType.qiAmplifier).length;
    final hasNearbyAttacker = launchers.any(
      (l) =>
          l.slotIndex != slotIndex &&
          l.type != LauncherType.qiAmplifier &&
          l.pos.distanceTo(target.pos) <= 195.0,
    );
    if (directAttackers < 3 || !hasNearbyAttacker) {
      final directDps =
          mergePool.where((t) => t != LauncherType.qiAmplifier).toList();
      if (directDps.isNotEmpty) mergePool = directDps;
    }
    final evolvedType = mergePool[rng.nextInt(mergePool.length)];
    target.type = evolvedType;
    target.permanentLevel = progress.launcherPermanentLevels[evolvedType] ?? 1;
    target.tier = (target.tier + 1).clamp(2, 5);
    target.investedTokens += (partner.investedTokens * 0.70).round() + mergeCost;
    target.constructTimer = upgradeConstructSec;
    target.constructDuration = upgradeConstructSec;
    target.corruptionTimer = 0.0;
    mergeEvolutionCount++;
    serendipityCount++;

    final isMythic5 = target.tier >= 5;
    if (isMythic5) {
      rouletteSpinsAvailable++;
    }
    pendingSounds.add(SoundCue.serendipityJackpot);
    screenShakeTimer = max(screenShakeTimer, isMythic5 ? 0.38 : 0.25);
    screenShakeIntensity = max(screenShakeIntensity, isMythic5 ? 6.8 : 4.8);
    lightningArcs.add(
      LightningArcFx(
        from: partner.pos,
        to: target.pos,
        ttlSec: 0.45,
        colorHex: 0xFFFFD166,
      ),
    );
    bursts.add(
      FxBurst(
        pos: target.pos,
        colorHex: 0xFFFFD166,
        maxRadius: isMythic5 ? 78 : 56,
        isTriangleShatter: true,
      ),
    );
    callouts.add(
      FloatingCallout(
        pos: target.pos + const Vec2(0, -24),
        text: isMythic5
            ? '🌟 태초 신기 강림!! ★5형 ${target.type.name} 각성 + 🎰돌림판 개방!!'
            : '☯️ 합치기 각성 진화!! ${target.tier}형 ${target.type.name} 탄생!',
        colorHex: 0xFFFFD166,
        isBigBanner: true,
      ),
    );
    return true;
  }

  /// 배치된 발사대 조합에 따른 실시간 무림 진법 시너지 연결선 계산! (축조 완료된 포탑끼리만 발동!)
  List<ActiveSynergyLink> get activeSynergyLinks {
    if (launchers.length < 2) return const [];
    final links = <ActiveSynergyLink>[];
    for (int i = 0; i < launchers.length; i++) {
      final a = launchers[i];
      if (a.isConstructing) continue;
      for (int j = i + 1; j < launchers.length; j++) {
        final b = launchers[j];
        if (b.isConstructing) continue;
        final maxLinkDist =
            (a.type == b.type || (a.slotIndex <= 1 && b.slotIndex <= 1)) ? 680.0 : 460.0;
        if (a.pos.distanceTo(b.pos) > maxLinkDist) continue;
        final types = {a.type, b.type};
        if (types.containsAll([LauncherType.frostField, LauncherType.heavy])) {
          links.add(
            ActiveSynergyLink(
              slotA: a.slotIndex,
              slotB: b.slotIndex,
              posA: a.pos,
              posB: b.pos,
              synergyName: '쇄빙 파쇄진',
              bonusSummary: '빙결·감속 적 피해 +40%',
              colorHex: 0xFF90E0EF,
            ),
          );
        } else if (types.containsAll([LauncherType.rapid, LauncherType.curveSpin])) {
          links.add(
            ActiveSynergyLink(
              slotA: a.slotIndex,
              slotB: b.slotIndex,
              posA: a.pos,
              posB: b.pos,
              synergyName: '쌍류 탄막진',
              bonusSummary: '탄속 +18% · 관통 +1',
              colorHex: 0xFF72EFDD,
            ),
          );
        } else if (a.type == b.type) {
          final canMergeNow = a.tier == b.tier && a.tier < 5;
          links.add(
            ActiveSynergyLink(
              slotA: a.slotIndex,
              slotB: b.slotIndex,
              posA: a.pos,
              posB: b.pos,
              synergyName: '쌍성 공명진',
              bonusSummary: canMergeNow ? '합치기 가능 · 공속 +18%' : '쌍성 가속 · 공속 +18%',
              colorHex: 0xFFFFD166,
            ),
          );
        }
      }
    }
    return links;
  }

  /// 다음 물결 조기 호출 가능 여부 (킹덤러쉬식 하이리스크 보너스 기력 확보!).
  bool get canCallNextWaveEarly {
    if (isFinished) return false;
    if (currentWaveIndex + 1 >= stage.waves.length) return false;
    if (_earlyCalledWaves.contains(currentWaveIndex + 1)) return false;
    return _spawnQueue.length <= 8 && elapsedSec >= 3.0;
  }

  /// 다음 물결을 즉시 앞당겨 호출하고 보너스 건설 기력 +18⚡ 획득! (이전 물결 적이 모두 정리될 때 클리어 물결 집계)
  bool callNextWaveEarly() {
    if (!canCallNextWaveEarly) return false;
    final nextIdx = currentWaveIndex + 1;
    _earlyCalledWaves.add(nextIdx);
    currentWaveIndex = nextIdx;
    wavePauseTimer = 1.45;
    _enqueueWave(currentWaveIndex, appendExisting: true);
    _announceNewlyUnlockedPads();

    const bonusQi = 18;
    fieldTokens += bonusQi;
    _spawnFlyingQiOrb(const Vec2(360, 82), bonusQi, colorHex: 0xFF72EFDD);
    pendingSounds.add(SoundCue.serendipityJackpot);
    callouts.add(
      FloatingCallout(
        pos: const Vec2(360, 114),
        text: '⚡ 제${currentWaveIndex + 1}물결 조기 호출! 보너스 기력 +$bonusQi⚡!',
        colorHex: 0xFF72EFDD,
        isBigBanner: true,
      ),
    );
    _queuePerkRoll();
    return true;
  }

  void _announceNewlyUnlockedPads() {
    for (final slot in activeMounts) {
      if (slot.slotIndex >= 2 &&
          isSlotWaveUnlocked(slot.slotIndex) &&
          _waveUnlockAnnounced.add(slot.slotIndex)) {
        bursts.add(FxBurst(pos: slot.pos, colorHex: slot.terrainType.colorHex, maxRadius: 44));
        callouts.add(
          FloatingCallout(
            pos: slot.pos + const Vec2(0, -20),
            text: '🔓 ${slot.slotIndex + 1}번 ${slot.terrainType.shortBadge} 봉인 해제 (⛏️개척 가능)!',
            colorHex: slot.terrainType.colorHex,
          ),
        );
      }
    }
  }

  /// 현재 제시된 3장의 돌파 비급 중 가장 효율이 높은 ★최적 추천 비급 반환!
  RoguePerk? recommendedPerkChoice() {
    if (pendingPerkChoices.isEmpty) return null;
    const priority = <RoguePerk>[
      RoguePerk.splitShot,
      RoguePerk.corpseExplosion,
      RoguePerk.luckyAscension,
      RoguePerk.chainLightning,
      RoguePerk.warChest,
      RoguePerk.rapidBarrage,
      RoguePerk.frostNova,
      RoguePerk.armorBreaker,
      RoguePerk.allyAwakening,
      RoguePerk.giantBoulder,
      RoguePerk.ricochetMaster,
      RoguePerk.ironBastion,
    ];
    RoguePerk best = pendingPerkChoices.first;
    int bestRank = 999;
    for (final c in pendingPerkChoices) {
      final r = priority.indexOf(c);
      if (r >= 0 && r < bestRank) {
        bestRank = r;
        best = c;
      }
    }
    return best;
  }

  /// 꽝 없는 5칸 「🎰 운명의 태극 기연 돌림판」 즉시 회전 및 대박 보상 발동!
  DestinyRoulettePrize? spinDestinyRoulette() {
    if (isFinished || rouletteSpinsAvailable <= 0) return null;
    rouletteSpinsAvailable--;
    manualResonanceTimer = max(manualResonanceTimer, 8.0);
    serendipityCount++;

    final prize = DestinyRoulettePrize.values[rng.nextInt(DestinyRoulettePrize.values.length)];
    lastRoulettePrize = prize;
    pendingSounds.add(SoundCue.serendipityJackpot);
    screenShakeTimer = max(screenShakeTimer, 0.30);
    screenShakeIntensity = max(screenShakeIntensity, 5.5);

    switch (prize) {
      case DestinyRoulettePrize.hyperBarrage:
        rouletteHyperBarrageTimer = 9.0;
        auroraCritTimer = max(auroraCritTimer, 9.0);
        bursts.add(FxBurst(pos: towerPos, colorHex: 0xFFFFD166, maxRadius: 72, isTriangleShatter: true));
        break;
      case DestinyRoulettePrize.qiJackpot:
        fieldTokens += 48;
        _spawnFlyingQiOrb(const Vec2(360, 320), 48);
        bursts.add(FxBurst(pos: const Vec2(360, 320), colorHex: 0xFF72EFDD, maxRadius: 68));
        break;
      case DestinyRoulettePrize.mythicAwakening:
        final candidates = launchers.where((l) => l.tier < 5).toList();
        if (candidates.isEmpty) {
          if (nextExcavatedEmptySlotIndex() != null) {
            fieldTokens += currentLuckySummonCost;
            final created = quickLuckySummonNextPad();
            if (created != null) created.tier = max(created.tier, 2);
          } else {
            fieldTokens += 52;
            _spawnFlyingQiOrb(const Vec2(360, 320), 52);
          }
        } else {
          final picked = candidates[rng.nextInt(candidates.length)];
          picked.tier = (picked.tier + 1).clamp(2, 5);
          bursts.add(FxBurst(pos: picked.pos, colorHex: 0xFFC77DFF, maxRadius: 68, isTriangleShatter: true));
        }
        break;
      case DestinyRoulettePrize.tripleGateFrenzy:
        cloneGate.tripleOverdriveTimer = 10.0;
        cloneGate.pulseAnim = 1.0;
        powerTarget.powerStacks = 6;
        powerTarget.decayTimer = 12.0;
        powerTarget.pulseAnim = 1.0;
        bursts.add(FxBurst(pos: cloneGate.center, colorHex: 0xFFFF6B35, maxRadius: 72, isTriangleShatter: true));
        break;
      case DestinyRoulettePrize.freeChulduSweep:
        if (mutants.isEmpty) {
          pendingFreeEncoreChuldu = true;
        } else {
          triggerSupportChuldu(isFreeEncore: true);
        }
        shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * 0.50);
        break;
    }

    callouts.add(
      FloatingCallout(
        pos: const Vec2(200, 175),
        text: '🎰 돌림판 대박!! [${prize.title}] — ${prize.subtitle}',
        colorHex: prize.colorHex,
        ttlSec: 2.3,
        isBigBanner: true,
      ),
    );
    return prize;
  }

  /// 현재 진행 중인 실시간 「🏆 긴급 현상수배 미션」 정보 조회!
  BattleBountyQuest get currentBountyQuest {
    switch (bountyQuestStep) {
      case 0:
        return BattleBountyQuest(
          stepIndex: 1,
          title: '길목 초소 2곳 가동하기',
          current: launchers.length,
          goal: min(2, activeMounts.length),
          rewardQi: 38,
          bonusLabel: '+38⚡ 기력',
          allCleared: false,
        );
      case 1:
        return BattleBountyQuest(
          stepIndex: 2,
          title: '돌연변이 35마리 격살하기',
          current: killCount,
          goal: 35,
          rewardQi: 45,
          bonusLabel: '+45⚡ · 🎰돌림판+1',
          allCleared: false,
        );
      case 2:
        final highCount = launchers.where((l) => l.tier >= 2).length + powderKegsDetonated;
        return BattleBountyQuest(
          stepIndex: 3,
          title: '2형 이상 포탑 각성 또는 화약통 폭파',
          current: highCount,
          goal: 1,
          rewardQi: 55,
          bonusLabel: '+55⚡ · 열기 +50%',
          allCleared: false,
        );
      case 3:
        return BattleBountyQuest(
          stepIndex: 4,
          title: '심야 대군 85마리 토벌 달성',
          current: killCount,
          goal: 85,
          rewardQi: 70,
          bonusLabel: '+70⚡ · 📜비급 즉시개방',
          allCleared: false,
        );
      default:
        return BattleBountyQuest(
          stepIndex: 4,
          title: '전장 현상수배 전 단계 달성 완료!',
          current: 1,
          goal: 1,
          rewardQi: 0,
          bonusLabel: '전원 달성!',
          allCleared: true,
        );
    }
  }

  void _stepBountyQuests() {
    if (!isFormationActive || bountyQuestStep >= 4) return;
    final q = currentBountyQuest;
    if (q.current >= q.goal) {
      bountyQuestStep++;
      fieldTokens += q.rewardQi;
      earnedPermanentTokens += 15;
      _spawnFlyingQiOrb(const Vec2(200, 120), q.rewardQi, colorHex: 0xFF80ED99);
      if (q.stepIndex == 2) {
        rouletteSpinsAvailable++;
      } else if (q.stepIndex == 3) {
        feverGauge = (feverGauge + 50.0).clamp(0.0, 100.0);
      } else if (q.stepIndex == 4) {
        _queuePerkRoll();
      }
      pendingSounds.add(SoundCue.serendipityJackpot);
      callouts.add(
        FloatingCallout(
          pos: const Vec2(200, 114),
          text: '🏆 현상수배 달성!! [${q.title}] 보상 ${q.bonusLabel}!',
          colorHex: 0xFF80ED99,
          ttlSec: 2.0,
          isBigBanner: true,
        ),
      );
    }
  }

  int get liveFirepowerCost => 28 + liveFirepowerLv * 18;
  int get liveReloadCost => 28 + liveReloadLv * 18;
  int get liveRangeCost => 32 + liveRangeLv * 22;
  int get liveBarrierCost => 26 + liveBarrierLv * 16;

  /// 실시간 전군 사거리 일괄 확장 업그레이드 (최대 4단 · 단당 +11% 사거리 확장, 멈춤 없음!).
  bool upgradeLiveRange() {
    if (isFinished || liveRangeLv >= 4 || fieldTokens < liveRangeCost) {
      return false;
    }
    fieldTokens -= liveRangeCost;
    liveRangeLv++;
    manualResonanceTimer = max(manualResonanceTimer, 8.0);
    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: towerPos, colorHex: 0xFF72EFDD, maxRadius: 52));
    callouts.add(
      FloatingCallout(
        pos: towerPos + const Vec2(0, -44),
        text: '🔭 전군 유효 사거리 확장 $liveRangeLv단! (+${liveRangeLv * 11}%)',
        colorHex: 0xFF72EFDD,
      ),
    );
    return true;
  }

  /// 실시간 전군 화력 일괄 업그레이드 (최대 5단 · +15%/단, 멈춤 없음!).
  bool upgradeLiveFirepower() {
    if (isFinished || liveFirepowerLv >= 5 || fieldTokens < liveFirepowerCost) return false;
    fieldTokens -= liveFirepowerCost;
    liveFirepowerLv++;
    manualResonanceTimer = max(manualResonanceTimer, 8.0);
    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: towerPos, colorHex: 0xFFFF6B35, maxRadius: 48));
    callouts.add(
      FloatingCallout(
        pos: towerPos + const Vec2(0, -44),
        text: '⚔️ 전군 화력 실시간 강화 $liveFirepowerLv단! (+${liveFirepowerLv * 15}%)',
        colorHex: 0xFFFF6B35,
      ),
    );
    return true;
  }

  /// 실시간 전군 연사속도 일괄 업그레이드 (최대 5단 · +12%/단, 멈춤 없음!).
  bool upgradeLiveReload() {
    if (isFinished || liveReloadLv >= 5 || fieldTokens < liveReloadCost) return false;
    fieldTokens -= liveReloadCost;
    liveReloadLv++;
    manualResonanceTimer = max(manualResonanceTimer, 8.0);
    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: towerPos, colorHex: 0xFF4CC9F0, maxRadius: 48));
    callouts.add(
      FloatingCallout(
        pos: towerPos + const Vec2(0, -44),
        text: '⚡ 전군 연사 실시간 가속 $liveReloadLv단! (+${liveReloadLv * 12}%)',
        colorHex: 0xFF4CC9F0,
      ),
    );
    return true;
  }

  void _syncVillagePurification() {
    if (granaryHealth >= 0.999 &&
        cropsHealth >= 0.999 &&
        livestockHealth >= 0.999) {
      villageTookDamage = false;
    }
  }

  /// 실시간 방어 결계 증축 & 즉시 수복 업그레이드 (최대 5단 · +18% 최대치 & 28% 즉시 수리, 멈춤 없음!).
  bool upgradeLiveBarrier() {
    if (isFinished || liveBarrierLv >= 5 || fieldTokens < liveBarrierCost) return false;
    fieldTokens -= liveBarrierCost;
    liveBarrierLv++;
    manualResonanceTimer = max(manualResonanceTimer, 8.0);
    shieldMaxHpDynamic *= 1.18;
    shieldHp = min(shieldMaxHpDynamic, shieldHp + centralSpec.shieldMaxHp * 0.28);
    towerHp = min(centralSpec.coreMaxHp, towerHp + centralSpec.coreMaxHp * 0.25);
    granaryHealth = min(1.0, granaryHealth + 0.30);
    cropsHealth = min(1.0, cropsHealth + 0.30);
    livestockHealth = min(1.0, livestockHealth + 0.30);
    _syncVillagePurification();
    pendingSounds.add(SoundCue.shieldWave);
    bursts.add(FxBurst(pos: shieldCenter, colorHex: 0xFF80ED99, maxRadius: 64));
    callouts.add(
      FloatingCallout(
        pos: shieldCenter + const Vec2(0, -48),
        text: '🛡️ 수호 결계 증축 $liveBarrierLv단! 방어막 수복 완료!',
        colorHex: 0xFF80ED99,
      ),
    );
    return true;
  }

  void _queuePerkRoll() {
    if (pendingPerkChoices.isNotEmpty) {
      pendingPerkRolls++;
      return;
    }
    _generateThreePerkChoices();
    if (autoChoosePerks && pendingPerkChoices.isNotEmpty) {
      final rec = recommendedPerkChoice() ?? pendingPerkChoices.first;
      chooseRoguePerk(rec);
    }
  }

  void _generateThreePerkChoices() {
    pendingPerkChoices.clear();
    perkChoiceTimer = perkWindowDurationSec;
    final pool = List<RoguePerk>.from(RoguePerk.values);
    while (pendingPerkChoices.length < 3 && pool.isNotEmpty) {
      double totalWeight = 0;
      final weights = <double>[];
      for (final p in pool) {
        double w = switch (p.rarity) {
          RoguePerkRarity.common => 1.35,
          RoguePerkRarity.rare => 1.0,
          RoguePerkRarity.legendary => 0.72,
        };
        if (p == RoguePerk.luckyAscension && launchers.isEmpty) w *= 0.4;
        weights.add(w);
        totalWeight += w;
      }
      double pick = rng.nextDouble() * totalWeight;
      int chosenIdx = 0;
      for (int i = 0; i < pool.length; i++) {
        pick -= weights[i];
        if (pick <= 0) {
          chosenIdx = i;
          break;
        }
      }
      pendingPerkChoices.add(pool.removeAt(chosenIdx));
    }
  }

  /// 플레이어가 3장의 돌파 비급 중 1장을 선택해 즉시 적용!
  bool chooseRoguePerk(RoguePerk perk) {
    if (isFinished || !pendingPerkChoices.contains(perk)) return false;
    pendingPerkChoices.clear();
    perkChoiceTimer = 0.0;
    activePerks[perk] = (activePerks[perk] ?? 0) + 1;
    pendingSounds.add(SoundCue.serendipityJackpot);

    switch (perk) {
      case RoguePerk.warChest:
        fieldTokens += 42;
        _spawnFlyingQiOrb(const Vec2(360, 420), 42);
        break;
      case RoguePerk.luckyAscension:
        final upgradable = launchers.where((l) => l.tier < 4).toList();
        if (upgradable.isEmpty) {
          fieldTokens += 46;
          _spawnFlyingQiOrb(const Vec2(360, 420), 46);
        } else {
          final picked = upgradable[rng.nextInt(upgradable.length)];
          picked.tier = (picked.tier + 1).clamp(1, 4);
          bursts.add(
            FxBurst(
              pos: picked.pos,
              colorHex: 0xFFFFD166,
              maxRadius: 54,
              isTriangleShatter: true,
            ),
          );
          callouts.add(
            FloatingCallout(
              pos: picked.pos + const Vec2(0, -22),
              text: '★비급 각성! ${picked.type.name} ${picked.tier}형 승급!',
              colorHex: 0xFFFFD166,
              isBigBanner: true,
            ),
          );
        }
        break;
      case RoguePerk.ironBastion:
        shieldMaxHpDynamic *= 1.30;
        shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * 0.50);
        towerHp = min(centralSpec.coreMaxHp, towerHp + centralSpec.coreMaxHp * 0.40);
        granaryHealth = min(1.0, granaryHealth + 0.45);
        cropsHealth = min(1.0, cropsHealth + 0.45);
        livestockHealth = min(1.0, livestockHealth + 0.45);
        _syncVillagePurification();
        bursts.add(FxBurst(pos: shieldCenter, colorHex: 0xFF34D399, maxRadius: 76));
        break;
      default:
        bursts.add(FxBurst(pos: towerPos, colorHex: perk.colorHex, maxRadius: 52));
        break;
    }

    callouts.add(
      FloatingCallout(
        pos: const Vec2(200, 210),
        text: '📜 비급 습득: [${perk.title}] (${activePerks[perk]}중첩)!',
        colorHex: perk.colorHex,
        isBigBanner: true,
      ),
    );

    if (pendingPerkRolls > 0) {
      pendingPerkRolls--;
      _generateThreePerkChoices();
    }
    return true;
  }

  /// 초소 번호 기준 발사대 승급 (1형 → 4형).
  bool upgradeLauncherAtSlot(int slotIndex) {
    final l = launcherAtSlot(slotIndex);
    if (l == null) return false;
    return upgradeLauncherInBattle(launchers.indexOf(l));
  }

  /// 이미 배치된 초소의 발사대를 다른 종류로 교체 (기존 투입 증표 80% 환급 반영).
  bool replaceLauncherInBattle(int slotIndex, LauncherType newType) {
    if (isFinished) return false;
    final existing = launcherAtSlot(slotIndex);
    if (existing == null || existing.type == newType) return false;
    if (!isLauncherTypeUnlocked(newType)) return false;

    final refund = (existing.investedTokens * 0.80).round();
    final buildCost =
        (newType.progressiveBuildCost(max(0, launchers.length - 1)) * chapter.buildCostMultiplier)
            .round();
    if (fieldTokens + refund < buildCost) return false;

    fieldTokens = fieldTokens + refund - buildCost;
    final idx = launchers.indexOf(existing);
    final permLv = progress.launcherPermanentLevels[newType] ?? 1;
    final nextConstruct = existing.isConstructing
        ? max(existing.constructTimer, upgradeConstructSec)
        : upgradeConstructSec;
    launchers[idx] = ActiveLauncher(
      slotIndex: slotIndex,
      pos: existing.pos,
      type: newType,
      permanentLevel: permLv,
      terrainType: existing.terrainType,
      investedTokens: buildCost,
      constructTimer: nextConstruct,
      constructDuration: max(existing.constructDuration, nextConstruct),
    );

    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: existing.pos, colorHex: 0xFFFFD166, maxRadius: 32));
    callouts.add(
      FloatingCallout(
        pos: existing.pos + const Vec2(0, -18),
        text: '🔄 [${existing.terrainType.name}] ${newType.name} 교체!',
        colorHex: 0xFFFFD166,
      ),
    );
    return true;
  }

  /// 배치된 발사대 철거 및 투입 증표 80% 현장 환급!
  int dismantleLauncherInBattle(int slotIndex) {
    if (isFinished) return 0;
    final existing = launcherAtSlot(slotIndex);
    if (existing == null) return 0;
    final refund = (existing.investedTokens * 0.80).round();
    launchers.remove(existing);
    fieldTokens += refund;
    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: existing.pos, colorHex: 0xFFE9C46A, maxRadius: 26));
    callouts.add(
      FloatingCallout(
        pos: existing.pos + const Vec2(0, -18),
        text: '♻️ 초소 철거 (+$refund 기력 환급)',
        colorHex: 0xFFE9C46A,
      ),
    );
    return refund;
  }

  /// 맨 아래 중앙 기명 수호탑 `자동 발사` ↔ `수동 탄지` 전환.
  void setCentralManualMode(bool manual) {
    if (centralManualMode == manual) return;
    centralManualMode = manual;
    pendingSounds.add(SoundCue.gearMotion);
    callouts.add(
      FloatingCallout(
        pos: towerPos + const Vec2(0, -34),
        text: manual ? '🎯 중앙 탑: 수동 저격 탄지(전장 사거리·화력 ×1.8·도탄 +2)!' : '⚙️ 중앙 탑: 근접 자동 방어 가동!',
        colorHex: manual ? 0xFFFFD166 : 0xFF72EFDD,
      ),
    );
  }

  void toggleCentralManualMode() => setCentralManualMode(!centralManualMode);

  /// 보스의 빛나는 약점 과녁(🎯)을 전장에서 직접 터치하여 정밀 파갑 신궁탄 즉시 발사!
  /// (수동 모드로 미리 전환하지 않아도 즉시 격발되며, 약점 정타 시 외각 장갑판 1겹 파쇄 + 고정 피해!)
  bool firePrecisionStrikeAt(Vec2 targetArenaPos, {int? targetBossUid}) {
    if (!isPrecisionStrikeReady) return false;
    final reloadScale = 1.0 + liveReloadLv * 0.12;
    precisionStrikeCooldown = precisionStrikeIntervalSec / reloadScale;
    manualResonanceTimer = max(manualResonanceTimer, 8.0);
    centralRecoilAnim = 1.0;

    final origin = towerPos;
    ActiveMutant? lockedBoss;
    if (targetBossUid != null) {
      for (final m in mutants) {
        if (m.uid == targetBossUid && m.totalPhases > 1 && m.phaseTransitionTimer <= 0) {
          lockedBoss = m;
          break;
        }
      }
    }
    if (lockedBoss == null) {
      double bestWeakDist = 88.0;
      for (final m in mutants) {
        if (m.totalPhases <= 1 || m.phaseTransitionTimer > 0) continue;
        final dWeak = targetArenaPos.distanceTo(m.weakSpotWorldPos);
        if (dWeak <= bestWeakDist) {
          bestWeakDist = dWeak;
          lockedBoss = m;
        }
      }
    }

    final aimTarget = lockedBoss != null ? lockedBoss.weakSpotWorldPos : targetArenaPos;
    final delta = aimTarget - origin;
    final angle = delta.length > 4.0 ? atan2(delta.y, delta.x) : -pi / 2;
    centralAimAngleRad = angle;

    pendingSounds.add(SoundCue.bowMotion);
    screenShakeTimer = max(screenShakeTimer, 0.12);
    screenShakeIntensity = max(screenShakeIntensity, 2.8);
    if (muzzleFlashes.length < 28) {
      muzzleFlashes.add(
        MuzzleFlashFx(
          pos: origin + Vec2(cos(angle) * 26.0, sin(angle) * 26.0),
          angleRad: angle,
          colorHex: 0xFFFFD166,
          scale: 1.65,
        ),
      );
    }

    final stone = preset.primaryStone;
    final shape = preset.primaryShape;
    final boulderStacks = perkStacks(RoguePerk.giantBoulder);
    final frostStacks = perkStacks(RoguePerk.frostNova);
    final ricochetStacks = perkStacks(RoguePerk.ricochetMaster);
    final shotSpeed = 1040.0 * shape.speedFactor;
    final baseDmg = centralSpec.baseDamage *
        1.45 *
        (1.0 + liveFirepowerLv * 0.15) *
        powerTarget.damageMultiplier *
        stone.damageMultiplier *
        progress.realm.powerMult *
        (1.0 + progress.meridianLauncherDmgBonus);
    final radiusScale = (1.0 + boulderStacks * 0.38).clamp(1.0, 2.0);

    if (projectiles.length >= 180) {
      projectiles.removeAt(0);
    }
    projectiles.add(
      ActiveStoneProjectile(
        sourceKey: 'central_precision',
        sourceLabel: '중앙 기명 수호탑 (정밀 파갑탄)',
        pos: origin + const Vec2(0, -8),
        vel: Vec2(cos(angle) * shotSpeed, sin(angle) * shotSpeed),
        material: stone,
        shape: shape,
        damage: baseDmg,
        knockback: 92.0 *
            stone.knockbackMultiplier *
            shape.knockbackFactor *
            (1.0 + progress.meridianKnockbackBonus) *
            (1.0 + boulderStacks * 0.55),
        critChance: (0.65 + shape.critBonus + progress.meridianCritBonus).clamp(0.65, 1.0),
        colorHex: 0xFFFFD166,
        radius: 12.2 * radiusScale,
        pierceLeft: 2,
        aoeSplashRadius: 34.0,
        freezesOnHit: stone == StoneMaterial.hancheol || frostStacks > 0,
        slowsOnHit: stone == StoneMaterial.banseok || stone == StoneMaterial.bingbaek,
        ignoresShield: true,
        isPrecisionShot: true,
        precisionTargetPos: targetArenaPos,
        lockedWeakBossUid: lockedBoss?.uid,
        extraBounces: (chapter.number == 5 ? 2 : 0) + ricochetStacks * 2,
        maxTravelDist: 1680.0,
        projectileStyle: 'precisionLance',
      ),
    );
    _spawnShockwaveRing(
      origin,
      maxRadius: 46.0,
      colorHex: 0xFFFFD166,
      secondaryColorHex: 0xFFFF6B35,
      style: 'critStar',
      durationSec: 0.24,
    );
    return true;
  }

  /// 수동 탄지 조준 각도 보정 (하단 제단 기본용 상방 반구 유도).
  static double sanitizeManualAimAngle(double rawAngleRad) {
    if (!rawAngleRad.isFinite) return -pi / 2;
    double vx = cos(rawAngleRad);
    double vy = sin(rawAngleRad);
    if (vy > 0.18) {
      vy = -vy.abs().clamp(0.25, 1.0);
    }
    return atan2(vy, vx);
  }

  /// 각 장 수호탑 위치에 따른 조준 각도 보정 (전 10장 수호 제단이 모두 전장 내측 `y <= 1150`에 위치하므로 360° 전방위 직접 조준 개방!).
  double sanitizeAimAngleForChapter(double rawAngleRad) {
    if (!rawAngleRad.isFinite) {
      return towerPos.y < 420.0 ? pi / 2 : -pi / 2;
    }
    if (towerPos.y <= CampaignCatalog.arenaHeight - 130.0) {
      return atan2(sin(rawAngleRad), cos(rawAngleRad));
    }
    return sanitizeManualAimAngle(rawAngleRad);
  }

  /// 수동 탄지 도탄 궤적 예측선 계산 (현재 수동 유효 사거리·수호 알 모양·회전 정다각형 기둥 실제 법선 반사 반영!).
  List<Vec2> previewCentralManualRay(double rawAngleRad, {double? maxDist}) {
    final angle = sanitizeAimAngleForChapter(rawAngleRad);
    final origin = towerPos;
    Vec2 cur = origin;
    Vec2 dir = Vec2(cos(angle), sin(angle)).normalized;
    final pts = <Vec2>[origin];
    double rem = maxDist ?? effectiveCentralManualRange;
    final maxBounces = preset.primaryShape.maxBounces +
        2 +
        (chapter.number == 5 ? 2 : 0) +
        perkStacks(RoguePerk.ricochetMaster) * 2;
    int bounces = 0;

    const stepLen = 8.0;
    while (rem > 0) {
      final next = cur + dir * stepLen;
      rem -= stepLen;

      if (next.y <= 14 || next.y >= CampaignCatalog.arenaHeight - 12) {
        pts.add(
          Vec2(
            next.x.clamp(16.0, CampaignCatalog.arenaWidth - 16.0),
            next.y.clamp(14.0, CampaignCatalog.arenaHeight - 12.0),
          ),
        );
        break;
      }

      if (next.x <= 16.0 || next.x >= CampaignCatalog.arenaWidth - 16.0) {
        final hit = Vec2(next.x.clamp(16.0, CampaignCatalog.arenaWidth - 16.0), next.y);
        pts.add(hit);
        if (bounces >= maxBounces) break;
        bounces++;
        dir = Vec2(-dir.x, dir.y).normalized;
        cur = hit;
        continue;
      }

      bool hitPillar = false;
      for (int pIdx = 0; pIdx < chapter.pillars.length; pIdx++) {
        final pillar = chapter.pillars[pIdx];
        final angleOffset = pIdx < pillarAngles.length ? pillarAngles[pIdx] : 0.0;
        final (closestEdgePt, n, distEdge) =
            _closestPointOnRotatedPolygon(pillar, angleOffset, next);
        if (distEdge <= 8.5) {
          final hit = closestEdgePt + n * 9.0;
          pts.add(hit);
          if (bounces < maxBounces) {
            final dot = dir.x * n.x + dir.y * n.y;
            if (dot < 0) {
              dir = (dir - n * (2 * dot)).normalized;
            }
            cur = hit;
            bounces++;
            hitPillar = true;
          } else {
            rem = 0;
            hitPillar = true;
          }
          break;
        }
      }
      if (hitPillar) {
        if (rem <= 0) break;
        continue;
      }
      cur = next;
    }
    if (pts.last.distanceTo(cur) > 3.0) {
      pts.add(cur);
    }
    return pts;
  }

  /// 플레이어가 전장 좌표를 찍거나 당겨 쏜 수동 탄지 발사!
  bool fireCentralManualAt(Vec2 targetArenaPos) {
    final delta = targetArenaPos - towerPos;
    final defaultAim = towerPos.y < 420.0 ? pi / 2 : -pi / 2;
    final rawAngle = delta.length > 4.0 ? atan2(delta.y, delta.x) : defaultAim;
    return fireCentralManualAngle(rawAngle);
  }

  /// 플레이어가 조준한 각도로 중앙 기명 수호탑 수동 강화 탄지 발사 (3갈래 파쇄 산탄포)!
  bool fireCentralManualAngle(double rawAngleRad) {
    if (!isCentralReadyToFire) return false;
    final angle = sanitizeAimAngleForChapter(rawAngleRad);
    centralAimAngleRad = angle;
    centralRecoilAnim = 1.0;
    manualResonanceTimer = 7.5; // 수동 탄지 발사 시 7.5초간 동료·영수 공명 활성화!
    final feverBoost = feverTimer > 0 ? 1.65 : 1.0;
    final reloadBoost = 1.0 + liveReloadLv * 0.18;
    centralFireTimer = (centralSpec.fireIntervalSec * 0.40) /
        ((auroraCritTimer > 0 ? 1.55 : 1.0) * feverBoost * reloadBoost);
    pendingSounds.add(SoundCue.bowMotion);
    screenShakeTimer = max(screenShakeTimer, 0.11);
    screenShakeIntensity = max(screenShakeIntensity, 2.5);

    final origin = towerPos;
    final muzzlePos = origin + Vec2(cos(angle) * 22.0, sin(angle) * 22.0);
    if (muzzleFlashes.length < 28) {
      muzzleFlashes.add(
        MuzzleFlashFx(
          pos: muzzlePos,
          angleRad: angle,
          colorHex: 0xFFFFD166,
          scale: 1.50,
        ),
      );
    }

    if (qiBars >= 2.95) {
      final hadFourBars = qiBars >= 3.95;
      qiBars = max(0.0, qiBars - 3.0);
      _encoreEogiReserved = false;
      _qiBurstSynergyTimer = max(_qiBurstSynergyTimer, 2.5);
      final count = progress.realm.eogieoseokCount + 4 + (hadFourBars ? 2 : 0);
      screenShakeTimer = max(screenShakeTimer, 0.26);
      screenShakeIntensity = max(screenShakeIntensity, 5.2);
      callouts.add(
        FloatingCallout(
          pos: origin + const Vec2(0, -48),
          text: '⚡ 수동 어기어석 초필살 일제탄지! ($count기 폭풍 파쇄!)',
          colorHex: 0xFFFFD166,
          isBigBanner: true,
        ),
      );
      _spawnShockwaveRing(
        origin,
        maxRadius: 112.0,
        colorHex: 0xFFFFD166,
        secondaryColorHex: 0xFF72EFDD,
        style: 'skillUltimate',
        durationSec: 0.48,
      );
      final centralPowerMult =
          progress.realm.powerMult * (1.0 + progress.meridianLauncherDmgBonus);
      final rolledEogiSeren = allowSerendipity &&
          rng.nextDouble() < (0.14 + progress.meridianSerendipityBonus * 0.6);
      if (rolledEogiSeren) serendipityCount++;
      for (int i = 0; i < count; i++) {
        final spread = (i - (count - 1) / 2.0) * 0.10;
        _spawnManualDirectionalShot(
          origin: origin + Vec2((i - (count - 1) / 2.0) * 7.0, -6),
          angleRad: angle + spread,
          baseDamage: centralSpec.baseDamage * 2.65 * centralPowerMult,
          speed: 535,
          pierceBonus: 5,
          aoeRadius: 58,
          ignoresShield: true,
          knockbackScale: 1.65,
          projectileStyle: 'eogiUltimate',
          sourceLabelOverride: '중앙 기명 수호탑 (수동 어기어석)',
          preRolledSerendipity: rolledEogiSeren,
        );
      }
      _tryFireNalssaendolAcornWithCentral();
      return true;
    }

    SectTechnique? sectTech;
    double dmgMult = 1.75 *
        progress.realm.powerMult *
        (1.0 + progress.meridianLauncherDmgBonus); // 수동 직접 탄지 초장거리 파쇄 주포!
    if (qiBars >= 1.0 && !_encoreEogiReserved) {
      qiBars -= 1.0;
      _qiBurstSynergyTimer = max(_qiBurstSynergyTimer, 2.5);
      sectTech = preset.sectTechnique;
      dmgMult *= 1.35;
      _spawnShockwaveRing(
        origin,
        maxRadius: 72.0,
        colorHex: 0xFFC77DFF,
        secondaryColorHex: 0xFFFFD166,
        style: 'skillUltimate',
        durationSec: 0.34,
      );
    }

    final rolledManualSeren = allowSerendipity &&
        rng.nextDouble() < (0.14 + progress.meridianSerendipityBonus * 0.6);
    if (rolledManualSeren) serendipityCount++;

    // 정중앙 대구경 파쇄탄 + 좌우 2갈래 호위 비검탄 = 총 3갈래 시원한 일제 탄막!
    _spawnManualDirectionalShot(
      origin: origin + const Vec2(0, -6),
      angleRad: angle,
      baseDamage: centralSpec.baseDamage * dmgMult,
      speed: 520,
      pierceBonus: 3,
      aoeRadius: 38,
      knockbackScale: 1.50,
      sectTech: sectTech,
      preRolledSerendipity: rolledManualSeren,
    );
    for (final wing in const [-0.13, 0.13]) {
      _spawnManualDirectionalShot(
        origin: origin + Vec2(wing * 45.0, -6),
        angleRad: angle + wing,
        baseDamage: centralSpec.baseDamage * dmgMult * 0.56,
        speed: 495,
        pierceBonus: 1,
        aoeRadius: 0,
        knockbackScale: 1.10,
        preRolledSerendipity: rolledManualSeren,
      );
    }
    _tryFireNalssaendolAcornWithCentral();
    return true;
  }

  void _spawnManualDirectionalShot({
    required Vec2 origin,
    required double angleRad,
    required double baseDamage,
    required double speed,
    int pierceBonus = 0,
    double aoeRadius = 0.0,
    bool ignoresShield = false,
    double knockbackScale = 1.0,
    SectTechnique? sectTech,
    String? projectileStyle,
    String? sourceLabelOverride,
    bool? preRolledSerendipity,
  }) {
    if (projectiles.length >= 180) {
      projectiles.removeAt(0);
    }
    final stone = preset.primaryStone;
    final shape = preset.primaryShape;
    final boulderStacks = perkStacks(RoguePerk.giantBoulder);
    final ricochetStacks = perkStacks(RoguePerk.ricochetMaster);
    final frostStacks = perkStacks(RoguePerk.frostNova);
    final armorBreakStacks = perkStacks(RoguePerk.armorBreaker);
    final ch2SpeedBoost = chapter.number == 2 ? 1.15 : 1.0;
    final ch5ExtraBounce = chapter.number == 5 ? 2 : 0;
    final ch8KnockBoost = chapter.number == 8 ? 1.38 : 1.0;

    final finalSpeed = speed *
        ch2SpeedBoost *
        shape.speedFactor *
        (cheonghakBuffTimer > 0 ? 1.20 : 1.0) *
        (stone == StoneMaterial.manyeonGiju ? 1.18 : 1.0);
    final vel = Vec2(cos(angleRad) * finalSpeed, sin(angleRad) * finalSpeed);

    final isCritSerendipity = preRolledSerendipity ??
        (allowSerendipity &&
            rng.nextDouble() < (0.14 + progress.meridianSerendipityBonus * 0.6));
    if (preRolledSerendipity == null && isCritSerendipity) {
      serendipityCount++;
    }

    int pierce = pierceBonus +
        (stone == StoneMaterial.geumgang ? 1 : 0) +
        (stone == StoneMaterial.banseok ? 1 : 0);
    double splash = aoeRadius +
        (stone == StoneMaterial.obsidian ? 32.0 : 0.0) +
        (stone == StoneMaterial.uncheol ? 38.0 : 0.0) +
        (stone == StoneMaterial.yongrin ? 34.0 : 0.0);
    double curve = 0.0;
    bool bypassShield = ignoresShield || stone == StoneMaterial.jageum || armorBreakStacks > 0;

    String resolvedStyle = projectileStyle ?? 'stoneDefault';
    if (sectTech == SectTechnique.swordQi) {
      pierce += 3;
      resolvedStyle = 'sectSword';
    }
    if (sectTech == SectTechnique.ironFist) {
      splash = max(splash, 60.0);
      resolvedStyle = 'sectFist';
    }
    if (sectTech == SectTechnique.taiji) {
      curve = 1.25 * shape.spinCurveFactor;
      bypassShield = true;
      qiBars = (qiBars + 0.25 * (chapter.number == 10 ? 1.30 : 1.0)).clamp(0.0, maxQiBars);
      resolvedStyle = 'sectTaiji';
    }

    final liveDmgBoost = (1.0 + liveFirepowerLv * 0.15) * powerTarget.damageMultiplier;
    final finalDamage =
        baseDamage * liveDmgBoost * stone.damageMultiplier * (isCritSerendipity ? 1.38 : 1.0);
    final finalKnock = 48.0 *
        ch8KnockBoost *
        stone.knockbackMultiplier *
        shape.knockbackFactor *
        knockbackScale *
        (1.0 + boulderStacks * 0.55) *
        (1.0 + progress.meridianKnockbackBonus) *
        (stone == StoneMaterial.uncheol ? 1.25 : 1.0) *
        (stone == StoneMaterial.yongrin ? 1.35 : 1.0);
    final critChance = (0.18 +
            shape.critBonus +
            progress.meridianCritBonus +
            (feverTimer > 0 ? 0.35 : 0.0) +
            (cheonghakBuffTimer > 0 ? 0.10 : 0.0) +
            (stone == StoneMaterial.geumgang ? 0.08 : 0.0))
        .clamp(0.05, 0.90);
    final radiusScale =
        (1.0 + boulderStacks * 0.38).clamp(1.0, 2.0) * (feverTimer > 0 ? 1.18 : 1.0);

    projectiles.add(
      ActiveStoneProjectile(
        sourceKey: 'central_tower',
        sourceLabel: sourceLabelOverride ?? '중앙 기명 수호탑 (수동 탄지)',
        pos: origin,
        vel: vel,
        material: stone,
        shape: shape,
        damage: finalDamage,
        knockback: finalKnock,
        critChance: critChance,
        colorHex: (isCritSerendipity || feverTimer > 0) ? 0xFFFFD166 : stone.colorHex,
        radius: (isCritSerendipity ? 13.5 : 9.4) * radiusScale,
        spinCurve: curve,
        pierceLeft: pierce,
        aoeSplashRadius: splash,
        freezesOnHit: stone == StoneMaterial.hancheol || frostStacks > 0,
        slowsOnHit: stone == StoneMaterial.banseok || stone == StoneMaterial.bingbaek,
        ignoresShield: bypassShield,
        isGiantCritSerendipity: isCritSerendipity,
        splitsShadowOnHit: sectTech == SectTechnique.shadowClone,
        extraBounces: 2 + ch5ExtraBounce + ricochetStacks * 2,
        maxTravelDist: effectiveCentralManualRange * 1.15,
        projectileStyle: resolvedStyle,
      ),
    );

    // 영월살문 분신 쌍영탄은 명중 순간에 2갈래로 갈라진다(발사 시 중복 분신 생성 제거).
  }

  double _scoutSpawnProgressForLane(int laneIdx, int scoutOrder) {
    final lane = chapter.smoothedLane(laneIdx % chapter.lanes.length);
    if (lane.length < 6) return 0.35;
    final earlyPads = activeMounts.take(2).toList();
    if (earlyPads.isEmpty) return 0.45;

    // 제1물결 개방 초소(0·1번) 사거리 권역에 처음 진입하는 지점을 찾아, 그 바로 상류(4~12구간 앞)에서 기습 출현!
    // (초소 뒤쪽 사각지대에 스폰되어 무방비 함락되는 현상 원천 차단 + 4~7초 내 첫 교전 보장)
    int? engageIdx;
    for (int i = 0; i < lane.length; i++) {
      final pt = lane[i];
      if (earlyPads.any((pad) => pt.distanceTo(pad.pos) <= 124.0)) {
        engageIdx = i;
        break;
      }
    }
    if (engageIdx == null) {
      double bestD = double.infinity;
      int bestI = (lane.length * 0.45).round();
      for (int i = 0; i < lane.length; i++) {
        for (final pad in earlyPads) {
          final d = lane[i].distanceTo(pad.pos);
          if (d < bestD) {
            bestD = d;
            bestI = i;
          }
        }
      }
      engageIdx = bestI;
    }
    final upstreamIdx = max(0, engageIdx - (6 + scoutOrder * 4));
    return (upstreamIdx / max(1, lane.length - 1)).clamp(0.05, 0.56);
  }

  void _enqueueWave(int waveIdx, {bool appendExisting = false}) {
    if (!appendExisting) {
      _spawnQueue.clear();
    }
    if (waveIdx >= stage.waves.length) return;
    final groups = stage.waves[waveIdx];
    final startGrace = (waveIdx == 0 && !appendExisting) ? 1.85 : 0.40;
    if (waveIdx == 0 && !appendExisting) {
      // 초반 15초 침묵 방지! 제1물결 개방 초소(0·1번) 전방 수풀에 잠복해 있던 선봉 척후 독쥐 3마리가 즉시 기습 돌입해 4~7초 안에 첫 탄지 타격감이 터지도록 구성!
      for (int s = 0; s < 3; s++) {
        final scoutLaneIdx = s % chapter.lanes.length;
        _spawnQueue.add(
          _PendingSpawn(
            delaySec: 2.95 + s * 0.50,
            kind: MutantKind.swarmRat,
            laneIndex: scoutLaneIdx,
            waveIndex: waveIdx,
            customTitle: '선봉 척후 독쥐',
            startLaneProgress: _scoutSpawnProgressForLane(scoutLaneIdx, s),
            hpScale: 0.42,
          ),
        );
      }
    }
    bool hasBossInWave = false;
    int groupIdx = 0;
    for (final g in groups) {
      if (g.kind.isBoss) hasBossInWave = true;
      final lIdx = g.laneIndex % chapter.lanes.length;
      if (lIdx < lanePortalEnergy.length) {
        lanePortalEnergy[lIdx] = max(lanePortalEnergy[lIdx], 0.75);
      }
      // 제1물결에서는 선봉 독쥐가 먼저 내려오고 고속 들개·중형 변이가 순차 합류해 초반 인지 여유 확보!
      final groupStagger = (waveIdx == 0 && !appendExisting) ? groupIdx * 3.0 : 0.0;
      groupIdx++;
      final diffCountMult = g.kind.isBoss
          ? 1.0
          : switch (difficulty) {
              DefenseDifficulty.easy => 0.88,
              DefenseDifficulty.normal => 1.04,
              DefenseDifficulty.nightmare => 1.34,
            };
      final spawnTotal = g.kind.isBoss ? g.count : max(1, (g.count * diffCountMult).round());
      final adjInterval = g.kind.isBoss
          ? g.intervalSec
          : (g.intervalSec / max(0.85, sqrt(diffCountMult))).clamp(0.14, 1.50);
      for (int i = 0; i < spawnTotal; i++) {
        _spawnQueue.add(
          _PendingSpawn(
            delaySec: startGrace + groupStagger + i * adjInterval,
            kind: g.kind,
            laneIndex: lIdx,
            waveIndex: waveIdx,
            customTitle: g.customBossTitle,
            customPortrait: g.customPortrait,
            customHitShield: g.customHitShield,
            hierarchyRank: g.hierarchyRank,
          ),
        );
      }
    }
    // ★ 악몽(Nightmare) 전용 심야 정예 선봉 증원: 제3물결 이후 보스가 없는 물결에도 정예 중간보스가 추가 돌격!
    if (difficulty == DefenseDifficulty.nightmare &&
        stage.globalIndex < 900 &&
        waveIdx >= 2 &&
        !hasBossInWave &&
        waveIdx.isEven) {
      const nightmareElites = <MutantKind>[
        MutantKind.swiftShadowBoss,
        MutantKind.ironColossusBoss,
        MutantKind.crimsonBreakerBoss,
        MutantKind.raiderHeukpung,
      ];
      final eliteKind =
          nightmareElites[(stage.globalIndex + waveIdx) % nightmareElites.length];
      final eliteLane = (stage.globalIndex + waveIdx) % chapter.lanes.length;
      _spawnQueue.add(
        _PendingSpawn(
          delaySec: startGrace + 4.2,
          kind: eliteKind,
          laneIndex: eliteLane,
          waveIndex: waveIdx,
          customTitle: '악몽 혈전 선봉 ${eliteKind.name}',
          customHitShield: 90 + stage.chapterNumber * 18,
          hierarchyRank: '악몽 선봉장',
        ),
      );
      hasBossInWave = true;
    }
    if (hasBossInWave && !_bossRouletteGranted && waveIdx >= 1 && isFormationActive) {
      _bossRouletteGranted = true;
      rouletteSpinsAvailable++;
      callouts.add(
        FloatingCallout(
          pos: const Vec2(200, 142),
          text: '🎰 우두머리 경보! [운명의 기연 돌림판 +1회] 지급!',
          colorHex: 0xFFFFD166,
          ttlSec: 2.0,
          isBigBanner: true,
        ),
      );
    }
    _spawnQueue.sort((a, b) => a.delaySec.compareTo(b.delaySec));
  }

  /// 거점 발사대 수동/자동 실시간 버전 승급 (1형 → 4형 · 1.15초 단조 공정!).
  bool upgradeLauncherInBattle(int launcherIndex) {
    if (isFinished || launcherIndex < 0 || launcherIndex >= launchers.length) return false;
    final l = launchers[launcherIndex];
    if (l.tier >= 4 || l.isConstructing) return false;
    final cost = upgradeCostForLauncher(l);
    if (fieldTokens < cost) return false;
    fieldTokens -= cost;
    l.investedTokens += cost;
    l.tier++;
    l.constructTimer = upgradeConstructSec;
    l.constructDuration = upgradeConstructSec;
    l.corruptionTimer = 0.0;
    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: l.pos, colorHex: 0xFFFFD166, maxRadius: 34));
    callouts.add(
      FloatingCallout(
        pos: l.pos + const Vec2(0, -18),
        text: '${l.type.name} ${l.tier}형 단조 승급!',
        colorHex: 0xFFFFD166,
      ),
    );
    return true;
  }

  /// 전장 위기 순간 원터치 전술 비약·부적 발동!
  bool activateConsumable(TacticalConsumable item) {
    if (isFinished) return false;
    if (stage.isReincarnationBossStage) {
      final used = _trialConsumableUsed[item] ?? 0;
      final cap = max(1, min(2, progress.consumables[item] ?? 1));
      if (used >= cap) return false;
      _trialConsumableUsed[item] = used + 1;
    } else {
      final have = progress.consumables[item] ?? 0;
      if (have <= 0) return false;
      progress.consumables[item] = have - 1;
    }

    switch (item) {
      case TacticalConsumable.qiSurgePill:
        qiBars = maxQiBars;
        _qiBurstSynergyTimer = max(_qiBurstSynergyTimer, 2.5);
        pendingSounds.add(SoundCue.serendipityJackpot);
        bursts.add(FxBurst(pos: shieldCenter, colorHex: 0xFF34D399, maxRadius: 62));
        callouts.add(
          FloatingCallout(
            pos: shieldCenter + const Vec2(0, -54),
            text: '💊 기공 급속단 발동! 내공 ${maxQiBars.round()}칸 즉시 완충!',
            colorHex: 0xFF34D399,
            isBigBanner: true,
          ),
        );
        break;
      case TacticalConsumable.guardianRepairSeal:
        shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * 0.45);
        towerHp = min(centralSpec.coreMaxHp, towerHp + centralSpec.coreMaxHp * 0.35);
        granaryHealth = min(1.0, granaryHealth + 0.35);
        cropsHealth = min(1.0, cropsHealth + 0.35);
        livestockHealth = min(1.0, livestockHealth + 0.35);
        _syncVillagePurification();
        pendingSounds.add(SoundCue.shieldWave);
        bursts.add(FxBurst(pos: shieldCenter, colorHex: 0xFF60A5FA, maxRadius: 74));
        callouts.add(
          FloatingCallout(
            pos: shieldCenter + const Vec2(0, -54),
            text: '🛡️ 수호탑 수리패 발동! 방어막·마을 정화 복구!',
            colorHex: 0xFF60A5FA,
            isBigBanner: true,
          ),
        );
        break;
      case TacticalConsumable.auroraCritCharm:
        auroraCritTimer = 8.0;
        pendingSounds.add(SoundCue.serendipityJackpot);
        bursts.add(FxBurst(pos: shieldCenter, colorHex: 0xFFF59E0B, maxRadius: 68));
        callouts.add(
          FloatingCallout(
            pos: shieldCenter + const Vec2(0, -54),
            text: '⚡ 극광 회심부 발동! 8초간 연사 1.5배 & 확정 회심!',
            colorHex: 0xFFF59E0B,
            isBigBanner: true,
          ),
        );
        break;
    }
    return true;
  }

  /// 플레이어가 원할 때 즉시 또는 위기 조건 시 자동으로 「무림수호단 출두야~~!!」 발동!
  bool triggerSupportChuldu({bool isFreeEncore = false}) {
    if (isFinished) return false;
    if (!isFreeEncore) {
      if (stage.isReincarnationBossStage) {
        if (supportChargesLeft <= 0) return false;
        supportChargesLeft--;
        usedSupportCount++;
      } else {
        if (supportChargesLeft <= 0 || progress.supportTokens <= 0) return false;
        supportChargesLeft--;
        usedSupportCount++;
        progress.supportTokens = max(0, progress.supportTokens - 1);
      }
    }

    chulduSweepAnimTimer = 1.35;
    screenShakeTimer = max(screenShakeTimer, 0.42);
    screenShakeIntensity = max(screenShakeIntensity, 7.2);
    pendingSounds.add(SoundCue.chulduFanfare);
    _spawnShockwaveRing(
      shieldCenter,
      maxRadius: 210.0,
      colorHex: 0xFFFFD166,
      secondaryColorHex: 0xFF72EFDD,
      style: 'skillUltimate',
      durationSec: 0.62,
    );

    final isCritChuldu =
        allowSerendipity && rng.nextDouble() < (0.30 + progress.meridianSerendipityBonus);
    final isEncoreChuldu = !isFreeEncore &&
        allowSerendipity &&
        rng.nextDouble() < (0.24 + progress.meridianSerendipityBonus);

    if (isCritChuldu || isEncoreChuldu) {
      serendipityCount++;
      pendingSounds.add(SoundCue.serendipityJackpot);
    }

    final bannerTitle = isFreeEncore
        ? '🔁 한 번 더 출두야~~!! 무림수호단 유턴 재돌격!'
        : (isCritChuldu
            ? '⚡ 크리티컬 대출두!! 무림수호단 출두야~~!!'
            : '🎺 무림수호단 출두야~~!! 전군 몰이사냥!');
    callouts.add(
      FloatingCallout(
        pos: const Vec2(320, 260),
        text: bannerTitle,
        colorHex: 0xFFFFD166,
        ttlSec: 1.8,
        isBigBanner: true,
      ),
    );

    // 화면 전체 돌연변이 몰이사냥 일소 (다단 변이 보스는 재변이 무적 중이어도 즉시 강타 & 제단 바깥 방사형 밀침!)
    final copy = List<ActiveMutant>.from(mutants);
    for (final m in copy) {
      if (m.phaseTransitionTimer > 0) {
        m.phaseTransitionTimer = 0.0;
      }
      if (m.kind.isBoss && m.carapacePlatesLeft > 0) {
        m.carapacePlatesLeft = max(0, m.carapacePlatesLeft - 1);
        if (m.carapacePlatesLeft == 0) {
          m.groggyExposeTimer = max(m.groggyExposeTimer, 6.5);
        }
      }
      final outVec = m.pos - shieldCenter;
      final outDir = outVec.length > 1.0 ? outVec.normalized : const Vec2(0, -1);
      final meridianMult = 1.0 + progress.meridianLauncherDmgBonus;
      final knockMult = 1.0 + progress.meridianKnockbackBonus;
      final dmg = (m.kind.isBoss
              ? (stage.isReincarnationBossStage
                  ? min(
                      m.currentMaxHp * (isCritChuldu ? 0.13 : 0.075),
                      centralSpec.baseDamage *
                          (isCritChuldu ? 46.0 : 28.0) *
                          progress.realm.powerMult,
                    )
                  : m.currentMaxHp * (isCritChuldu ? 0.58 : 0.40))
              : m.maxHp * 3.0) *
          meridianMult;
      _applyDamageToMutant(
        m,
        dmg,
        sourceKey: 'support_chuldu',
        sourceLabel: '무림수호단 출두',
        knockDir: outDir,
        knockForce: 190 * knockMult,
        isCritical: true,
      );
      if (isCritChuldu) {
        fieldTokens += 4;
        earnedPermanentTokens += 3;
      }
    }

    // 혹시라도 연쇄 도중 분열·파생된 일반 변이체가 남아 있으면 잔여 찌꺼기 없이 완전 정화
    for (int pass = 0; pass < 3 && mutants.any((m) => !m.kind.isBoss); pass++) {
      for (final rem in List<ActiveMutant>.from(mutants)) {
        if (!rem.kind.isBoss) {
          final outVec = rem.pos - shieldCenter;
          final outDir = outVec.length > 1.0 ? outVec.normalized : const Vec2(0, -1);
          _applyDamageToMutant(
            rem,
            rem.maxHp * 3.0,
            sourceKey: 'support_chuldu',
            sourceLabel: '무림수호단 출두',
            knockDir: outDir,
            knockForce: 190,
            isCritical: true,
          );
        }
      }
    }

    // 외곽 기공 방어막 32% 즉시 복구 + 크리티컬 출두 시 마을 논밭·가축 즉시 100% 정화!
    shieldHp = (shieldHp + shieldMaxHpDynamic * 0.32).clamp(0.0, shieldMaxHpDynamic);
    if (isCritChuldu) {
      granaryHealth = 1.0;
      cropsHealth = 1.0;
      livestockHealth = 1.0;
    } else {
      cropsHealth = (cropsHealth + 0.25).clamp(0.0, 1.0);
    }
    _syncVillagePurification();

    if (isEncoreChuldu) {
      pendingFreeEncoreChuldu = true;
    }
    return true;
  }

  /// 물리 진행 (1배~4배 고속 배속에서도 탄알 터널링·궤도 이탈이 0건이 되도록 1/60초 이하 최대 16분할 연산).
  void step(double dt) {
    if (isFinished || !dt.isFinite || dt <= 0) return;
    final subSteps = ((dt - 1e-9) / (1.0 / 60.0)).ceil().clamp(1, 16);
    final subDt = dt / subSteps;
    for (int s = 0; s < subSteps && !isFinished; s++) {
      _stepSingle(subDt);
    }
  }

  void _stepSingle(double dt) {
    if (isFinished) return;
    elapsedSec += dt;
    centralGearAngle += dt * 1.8;

    if (precisionStrikeCooldown > 0) {
      precisionStrikeCooldown = max(0.0, precisionStrikeCooldown - dt);
    }
    if (_autoChulduCooldown > 0) {
      _autoChulduCooldown = max(0.0, _autoChulduCooldown - dt);
    }
    if (_qiBurstSynergyTimer > 0) {
      _qiBurstSynergyTimer = max(0.0, _qiBurstSynergyTimer - dt);
    }
    if (seolhwaFrostShieldTimer > 0) {
      seolhwaFrostShieldTimer = max(0.0, seolhwaFrostShieldTimer - dt);
    }
    if (mukhyeonCooldownTimer > 0) {
      mukhyeonCooldownTimer = max(0.0, mukhyeonCooldownTimer - dt);
    }
    if (_fireBurstCooldown > 0) {
      _fireBurstCooldown = max(0.0, _fireBurstCooldown - dt);
    }
    if (manualResonanceTimer > 0) manualResonanceTimer = max(0, manualResonanceTimer - dt);
    if (jeonggakHasteTimer > 0) jeonggakHasteTimer = max(0, jeonggakHasteTimer - dt);
    if (cheonghakBuffTimer > 0) cheonghakBuffTimer = max(0, cheonghakBuffTimer - dt);
    if (auroraCritTimer > 0) auroraCritTimer = max(0, auroraCritTimer - dt);
    if (rouletteHyperBarrageTimer > 0) {
      rouletteHyperBarrageTimer = max(0, rouletteHyperBarrageTimer - dt);
    }
    // 비급 3택 1 실시간 제한시간(6.5초) 감쇠 — 시간 안에 못 누르면 멈춤 없이 자동 통과!
    if (pendingPerkChoices.isNotEmpty && !autoBuildForSimVerify) {
      perkChoiceTimer -= dt;
      if (perkChoiceTimer <= 0) {
        if (autoChoosePerks) {
          final rec = recommendedPerkChoice() ?? pendingPerkChoices.first;
          chooseRoguePerk(rec);
        } else {
          pendingPerkChoices.clear();
          perkChoiceTimer = 0.0;
          callouts.add(
            FloatingCallout(
              pos: const Vec2(320, 96),
              text: '⏱ 비급 선택 시간 초과 — 전투 계속 진행!',
              colorHex: 0xFFADB5BD,
              ttlSec: 1.2,
            ),
          );
          if (pendingPerkRolls > 0) {
            pendingPerkRolls--;
            _generateThreePerkChoices();
          }
        }
      }
    }
    if (chulduSweepAnimTimer > 0) chulduSweepAnimTimer = max(0, chulduSweepAnimTimer - dt);
    if (dawnPurifyAnimTimer > 0) dawnPurifyAnimTimer = max(0, dawnPurifyAnimTimer - dt);
    if (feverTimer > 0) feverTimer = max(0, feverTimer - dt);
    if (comboResetTimer > 0) {
      comboResetTimer = max(0, comboResetTimer - dt);
      if (comboResetTimer <= 0) comboCount = 0;
    }
    if (killStreakTimer > 0) {
      killStreakTimer = max(0, killStreakTimer - dt);
      if (killStreakTimer <= 0) killStreak = 0;
    }

    // 본진 위기 긴장감(dangerPulseLevel) 계산: 720×1360 전장에서 괴물이 마을 하단(y >= 920)에 육박하거나 방어막이 45% 이하일 때 적색 심장박동 점등!
    double targetDanger = 0.0;
    if (shieldMaxHpDynamic > 0) {
      final shieldRatio = shieldHp / shieldMaxHpDynamic;
      if (shieldRatio < 0.45) {
        targetDanger = max(targetDanger, ((0.45 - shieldRatio) / 0.45).clamp(0.25, 1.0));
      }
    }
    for (final m in mutants) {
      final distShield = m.pos.distanceTo(shieldCenter);
      if (distShield <= 275.0) {
        final prox = ((275.0 - distShield) / 215.0).clamp(0.20, 1.0);
        targetDanger = max(targetDanger, m.kind.isBoss ? min(1.0, prox + 0.25) : prox);
      }
    }
    dangerPulseLevel += (targetDanger - dangerPulseLevel) * min(1.0, dt * 5.5);

    for (int i = 0; i < chapter.pillars.length; i++) {
      pillarAngles[i] += chapter.pillars[i].rotationSpeedRad * dt;
    }

    // ×2→×3 진화 복제 마법진 · 🎯화력 과녁패 유영 및 심야 화약통 재생성 갱신!
    cloneGate.phase += dt * 1.15;
    cloneGate.center = Vec2(
      cloneGate.baseCenter.x + sin(cloneGate.phase) * cloneGate.swayAmplitude,
      cloneGate.baseCenter.y + cos(cloneGate.phase * 0.7) * 8.0,
    );
    if (cloneGate.pulseAnim > 0) {
      cloneGate.pulseAnim = max(0, cloneGate.pulseAnim - dt * 3.0);
    }
    if (cloneGate.tripleOverdriveTimer > 0) {
      cloneGate.tripleOverdriveTimer = max(0, cloneGate.tripleOverdriveTimer - dt);
    }

    powerTarget.phase += dt * 1.28;
    powerTarget.center = Vec2(
      powerTarget.baseCenter.x - sin(powerTarget.phase) * powerTarget.swayAmplitude,
      powerTarget.baseCenter.y + sin(powerTarget.phase * 0.8) * 6.0,
    );
    if (powerTarget.pulseAnim > 0) {
      powerTarget.pulseAnim = max(0, powerTarget.pulseAnim - dt * 3.2);
    }
    if (powerTarget.powerStacks > 0) {
      powerTarget.decayTimer -= dt;
      if (powerTarget.decayTimer <= 0) {
        powerTarget.powerStacks = max(0, powerTarget.powerStacks - 1);
        powerTarget.decayTimer = powerTarget.powerStacks > 0 ? 4.5 : 0.0;
      }
    }
    for (final keg in powderKegs) {
      if (!keg.intact) {
        keg.respawnTimer -= dt;
        if (keg.respawnTimer <= 0) {
          keg.intact = true;
          bursts.add(FxBurst(pos: keg.pos, colorHex: 0xFFF77F00, maxRadius: 24));
        }
      }
    }

    // 황금 보물 도깨비 긴급 출몰 (18초 · 44초, 처치 시 기력 +34⚡ & 즉시 돌파 비급!)
    if ((goblinSpawnsDone == 0 && elapsedSec >= 18.0) ||
        (goblinSpawnsDone == 1 && elapsedSec >= 44.0)) {
      goblinSpawnsDone++;
      final fromLeft = goblinSpawnsDone.isOdd;
      final gobHp = (progress.reincarnationCount > 0 || stage.isReincarnationBossStage)
          ? _monsterHpScaleForWave(currentWaveIndex) * 4.2 * difficulty.hpMult
          : (68.0 + stage.chapterNumber * 42.0) * difficulty.hpMult;
      treasureGoblin = TreasureGoblinEntity(
        pos: Vec2(fromLeft ? 32.0 : CampaignCatalog.arenaWidth - 32.0, 436.0),
        vel: Vec2(fromLeft ? 82.0 : -82.0, 6.0),
        maxHp: gobHp,
      );
      callouts.add(
        FloatingCallout(
          pos: const Vec2(360, 385),
          text: '👹 황금 보물 도깨비 출현! 저격 처치 시 +34⚡ & 비급 획득!',
          colorHex: 0xFFFFD166,
          ttlSec: 2.2,
          isBigBanner: true,
        ),
      );
    }
    if (treasureGoblin != null && treasureGoblin!.alive) {
      final g = treasureGoblin!;
      g.animPhase += dt * 9.5;
      if (g.hitFlashTimer > 0) g.hitFlashTimer = max(0, g.hitFlashTimer - dt * 4.0);
      g.pos = Vec2(
        g.pos.x + g.vel.x * dt,
        436.0 + sin(g.animPhase * 0.65) * 18.0,
      );
      if (g.pos.x < 16 || g.pos.x > CampaignCatalog.arenaWidth - 16) {
        g.alive = false;
      }
    }

    // 초소가 설치된 상태에서만 호신 강기 방어막·수호탑 자연 회복 작동 (소수 설치 방치 시 진법 결속률 비례 감쇠!)
    if (launchers.isNotEmpty) {
      final resScale = formationResonanceScale;
      final chaosHealDamp = stage.isReincarnationBossStage ? 0.32 : 1.0;
      final fortScale = (1.0 +
              progress.coreFortitudeBonus +
              progress.elixirResonanceBonus * 0.45) *
          resScale *
          chaosHealDamp;
      if (shieldHp > 0 && shieldHp < shieldMaxHpDynamic) {
        final shieldRegenPerSec =
            max(1.25 * resScale, shieldMaxHpDynamic * 0.0085 * fortScale);
        shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldRegenPerSec * dt);
      }
      if (towerHp > 0 && towerHp < centralSpec.coreMaxHp) {
        final towerRegenPerSec = centralSpec.coreMaxHp * 0.0035 * fortScale;
        towerHp = min(centralSpec.coreMaxHp, towerHp + towerRegenPerSec * dt);
      }
    }

    if (centralRecoilAnim > 0) {
      centralRecoilAnim = max(0, centralRecoilAnim - dt * 4.2);
    }

    // 헤드리스 밸런스 검증(`autoBuildForSimVerify == true`) 시:
    // ① 대기 중인 돌파 비급(RoguePerk) 최적 1장 선택
    // ② 전방 마기 암석 개척(excavateSlotInBattle) + 체증 비용 포대 축조 시뮬레이션
    // ③ 마기 침식 포탑 정화 및 다단 변이 보스 정밀 약점 저격 시뮬레이션(`autoPrecisionForVerify`)
    if (autoBuildForSimVerify) {
      if (pendingPerkChoices.isNotEmpty) {
        final priority = <RoguePerk>[
          RoguePerk.splitShot,
          RoguePerk.corpseExplosion,
          RoguePerk.warChest,
          RoguePerk.luckyAscension,
          RoguePerk.chainLightning,
          RoguePerk.frostNova,
          RoguePerk.armorBreaker,
          RoguePerk.rapidBarrage,
          RoguePerk.allyAwakening,
          RoguePerk.giantBoulder,
          RoguePerk.ricochetMaster,
          RoguePerk.ironBastion,
        ];
        RoguePerk best = pendingPerkChoices.first;
        int bestRank = 999;
        for (final c in pendingPerkChoices) {
          final r = priority.indexOf(c);
          if (r >= 0 && r < bestRank) {
            bestRank = r;
            best = c;
          }
        }
        chooseRoguePerk(best);
      }

      if (autoPrecisionForVerify) {
        for (final l in launchers) {
          if (l.isCorrupted) {
            cleanseLauncherAtSlot(l.slotIndex);
            break;
          }
        }
      }

      final nextSlotIdx = nextRecommendedSlotIndex();
      if (nextSlotIdx != null) {
        final slot = mountSlotByIndex(nextSlotIdx)!;
        if (!isSlotExcavated(nextSlotIdx)) {
          if (fieldTokens >= excavationCostForSlot(slot)) {
            excavateSlotInBattle(nextSlotIdx);
          }
        } else {
          final desired = nextSlotIdx < preset.mountTypes.length
              ? preset.mountTypes[nextSlotIdx]
              : slot.recommendedType;
          final buildType = isLauncherTypeUnlocked(desired) ? desired : slot.recommendedType;
          if (fieldTokens >= buildCostForType(buildType)) {
            placeLauncherInBattle(nextSlotIdx, buildType);
          }
        }
      }

      if (autoPrecisionForVerify && isPrecisionStrikeReady) {
        final boss = activeMultiPhaseBoss;
        if (boss != null &&
            boss.phaseTransitionTimer <= 0 &&
            (boss.carapacePlatesLeft > 0 || boss.hitShieldLeft > 0)) {
          firePrecisionStrikeAt(boss.weakSpotWorldPos);
        }
      }
    }

    // 포탑 자동 승급: 현재 물결에 개방된 모든 초소에 이미 포대를 다 건설 완료(`nextRecommendedSlotIndex() == null`)한 뒤에만 잉여 기력으로 작동!
    // (초반에 3~4기만 딸깍 짓고 손 놓았을 때 알아서 4형 풀강으로 키워주는 프리패스 원천 차단!)
    final allowAutoUpgNow = launchers.isNotEmpty &&
        (autoBuildForSimVerify
            ? (nextRecommendedSlotIndex() == null ||
                (launchers.length >= min(3, activeMounts.length) && fieldTokens >= 78))
            : (preset.autoUpgradeInBattle &&
                currentWaveIndex >= 3 &&
                nextRecommendedSlotIndex() == null &&
                fieldTokens >= 105));
    if (allowAutoUpgNow) {
      final hasPendingPad = nextRecommendedSlotIndex() != null;
      final reserveForBuild = autoBuildForSimVerify ? 0 : (hasPendingPad ? 55 : 0);
      ActiveLauncher? bestCandidate;
      int bestCost = 999999;
      for (final l in launchers) {
        if (l.tier < 4 && !l.isConstructing) {
          final c = upgradeCostForLauncher(l);
          if (fieldTokens - c >= reserveForBuild && c < bestCost) {
            bestCost = c;
            bestCandidate = l;
          }
        }
      }
      if (bestCandidate != null) {
        upgradeLauncherInBattle(launchers.indexOf(bestCandidate));
      }
    }

    // 황금 보급 두꺼비 이벤트 (중반 1회 출현)
    if (!goldenToadSpawned && elapsedSec > 32.0 && allowSerendipity) {
      goldenToadSpawned = true;
      goldenToad = GoldenSupplyToad(
        pos: const Vec2(36, 590),
        vel: const Vec2(88, 5),
      );
      callouts.add(
        FloatingCallout(
          pos: const Vec2(220, 555),
          text: '🐸 황금 보급 두꺼비 출현! 도탄으로 잡아라!',
          colorHex: 0xFFFFD166,
        ),
      );
    }
    if (goldenToad != null && goldenToad!.alive) {
      goldenToad!.pos = goldenToad!.pos + goldenToad!.vel * dt;
      if (goldenToad!.pos.x > CampaignCatalog.arenaWidth - 18) {
        goldenToad!.alive = false;
      }
    }

    _stepWaveSpawning(dt);
    _stepOffPathInfiltrators(dt);
    _stepMutants(dt);
    _stepSpiritBeastAndCompanions(dt);
    _stepCentralGuardian(dt);
    _stepPathLaunchers(dt);
    _stepSupportAutoTrigger();
    _stepProjectiles(dt);
    _stepBountyQuests();
    _stepCrisisAlertMonitor(dt);
    _stepVisualTimers(dt);
    _checkWinLoseCondition();
  }

  void _stepWaveSpawning(double dt) {
    if (_spawnQueue.isNotEmpty) {
      for (final s in _spawnQueue) {
        s.delaySec -= dt;
      }
      while (_spawnQueue.isNotEmpty && _spawnQueue.first.delaySec <= 0) {
        final item = _spawnQueue.removeAt(0);
        _spawnMutant(item);
      }
      // 각 물결 중반부 대군 쇄도 긴장감 경보 연출!
      if (_spawnQueue.length <= 16 &&
          mutants.length >= 8 &&
          _waveClimaxAnnounced.add(currentWaveIndex)) {
        callouts.add(
          FloatingCallout(
            pos: const Vec2(320, 108),
            text: '🚨 제${currentWaveIndex + 1}물결 변이 대군 총돌격 쇄도!!',
            colorHex: 0xFFFF595E,
            ttlSec: 1.7,
            isBigBanner: true,
          ),
        );
      }
    } else if (mutants.isEmpty && currentWaveIndex + 1 < stage.waves.length) {
      wavePauseTimer -= dt;
      if (wavePauseTimer <= 0) {
        wavesClearedCount = max(wavesClearedCount, currentWaveIndex + 1);
        currentWaveIndex++;
        wavePauseTimer = 1.15;
        _enqueueWave(currentWaveIndex);
        _announceNewlyUnlockedPads();

        // 무정지 실시간 전투 중 동료·보스 서사 교신!
        if (currentWaveIndex == 2) {
          final ally = preset.companions.isNotEmpty ? preset.companions.first : null;
          pendingStoryLines.add(
            StoryLine(
              speaker: ally?.name ?? '사부',
              portraitPrefix: ally?.portraitPrefix ?? 'sabu',
              text: '제3물결 전방 요충지가 열렸소! 마기 암석을 개척해 협곡 상류부터 화망으로 조이시오!',
            ),
          );
        } else if (currentWaveIndex == stage.waves.length - 1) {
          final bossGroup = stage.waves[currentWaveIndex].where((g) => g.kind.isBoss).firstOrNull;
          if (bossGroup != null) {
            pendingStoryLines.add(
              StoryLine(
                speaker: bossGroup.customBossTitle ?? bossGroup.kind.name,
                portraitPrefix: bossGroup.customPortrait ??
                    (bossGroup.kind == MutantKind.raiderHeukpung
                        ? 'budumok'
                        : bossGroup.kind == MutantKind.rivalMukhyeon
                            ? 'mukhyeon'
                            : chapter.bossPortraitPrefix),
                text: bossGroup.kind.isMidBoss
                    ? '크하하! 2단 재변이 마갑을 두른 내 돌격을 막을 수 있겠느냐!'
                    : '어리석은 수호자여! 3페이즈 불멸 마갑을 정밀 신궁탄으로 깨지 못하면 이 마을은 잿더미다!',
              ),
            );
          }
        }

        // 물결 방어 성공 시(최소 1초소 건설 또는 수동 공명 상태) 보너스 기력 +15⚡ & 3택 1 돌파 비급 발동!
        if (isFormationActive) {
          const waveBonusQi = 15;
          fieldTokens += waveBonusQi;
          _spawnFlyingQiOrb(const Vec2(360, 620), waveBonusQi, colorHex: 0xFF72EFDD);
          _queuePerkRoll();
        }
      }
    }

    // 각 침공 길목 입구의 독기 균열문 활성도(0.0 ~ 1.0) 맥동 및 감쇠 갱신
    for (int lIdx = 0; lIdx < lanePortalEnergy.length; lIdx++) {
      final hasPending = _spawnQueue.any((s) => (s.laneIndex % chapter.lanes.length) == lIdx);
      if (hasPending) {
        final pulse = 0.64 + 0.24 * (0.5 + 0.5 * sin(elapsedSec * 6.5 + lIdx * 1.4));
        lanePortalEnergy[lIdx] = max(lanePortalEnergy[lIdx] - dt * 0.6, pulse).clamp(0.0, 1.0);
      } else {
        lanePortalEnergy[lIdx] = (lanePortalEnergy[lIdx] - dt * 1.15).clamp(0.0, 1.0);
      }
    }

    // 완료된 물결 집계: 해당 물결 이하의 대기 적 및 전장 생존 적이 모두 소탕된 최고 물결 기록!
    int completedWaveCnt = 0;
    for (int w = 0; w <= currentWaveIndex && w < stage.waves.length; w++) {
      final anyQueued = _spawnQueue.any((s) => s.waveIndex == w);
      final anyAlive = mutants.any((m) => !m.isInfiltrator && m.spawnedWaveIndex == w);
      if (!anyQueued && !anyAlive) {
        completedWaveCnt = w + 1;
      } else {
        break;
      }
    }
    if (completedWaveCnt > wavesClearedCount) {
      wavesClearedCount = completedWaveCnt;
    }

    if (pendingFreeEncoreChuldu && mutants.isNotEmpty) {
      pendingFreeEncoreChuldu = false;
      triggerSupportChuldu(isFreeEncore: true);
    }
  }

  /// 길이 아닌 옆구리 숲·지붕 월담 또는 빈 땅 한복판 지하 땅굴로 기습 침투하는 비정규 변이체 생성기!
  void _stepOffPathInfiltrators(double dt) {
    if (isFinished) return;
    for (final m in mutants) {
      if (m.emergeAnimTimer > 0) {
        m.emergeAnimTimer = max(0.0, m.emergeAnimTimer - dt);
      }
    }
    // 마지막 물결 스폰이 모두 끝난 정리 구간에서는 추가 생성하지 않아 깔끔한 승리 판정 보장
    if (_spawnQueue.isEmpty && currentWaveIndex + 1 >= stage.waves.length) {
      return;
    }
    // 제1물결 초반에는 플레이어가 첫 거점 포대를 축조할 시간을 보장하고, 제2물결(또는 25초 경과) 이후부터 중하단 기습 시작!
    if (currentWaveIndex < 1 && elapsedSec < 25.0) return;

    infiltrationTimer -= dt;
    if (infiltrationTimer > 0) return;
    infiltrationTimer = (13.4 - stage.chapterNumber * 0.28).clamp(9.2, 13.4);

    infiltratorWaveCount++;
    final waveMode = infiltratorWaveCount % 3;
    final isAirRaid = stage.chapterNumber >= 2 && waveMode == 0;
    final isTunnel = !isAirRaid && waveMode == 1;
    final squadCount = (1 + stage.chapterNumber ~/ 3 + currentWaveIndex ~/ 3).clamp(2, 4);
    for (int i = 0; i < squadCount; i++) {
      spawnOffPathInfiltrator(
        isTunnel: isTunnel,
        isAirborne: isAirRaid,
        squadOffsetIndex: i,
      );
    }
    callouts.add(
      FloatingCallout(
        pos: Vec2(360, isAirRaid ? 320 : (isTunnel ? 520 : 360)),
        text: isAirRaid
            ? '🪽 공중 급강하 기습!! 상공에서 혈익 박쥐 편대가 날아듭니다!'
            : (isTunnel
                ? '🕳️ 지하 땅굴 기습!! 길 밖 빈터에서 변이가 솟아오릅니다!'
                : '🌲 산비탈 월담 기습!! 길 밖 옆구리 숲에서 쳐들어옵니다!'),
        colorHex: isAirRaid ? 0xFFE63946 : 0xFFFF4D6D,
        ttlSec: 1.9,
        isBigBanner: true,
      ),
    );
  }

  /// 길 밖 비정규 침투(월담·땅굴·공중 강습) 괴물 1체 즉시 소환 (단위 시험 및 실시간 기습 공용).
  ActiveMutant spawnOffPathInfiltrator({
    required bool isTunnel,
    bool isAirborne = false,
    int squadOffsetIndex = 0,
  }) {
    infiltratorSpawnCount++;
    final fromLeft = (infiltratorWaveCount + squadOffsetIndex).isEven;
    final MutantKind kind = isAirborne
        ? MutantKind.bloodWingBat
        : (isTunnel
            ? (stage.chapterNumber >= 5 && squadOffsetIndex == 0
                ? MutantKind.ironBoar
                : (stage.chapterNumber >= 3 && squadOffsetIndex == 0
                    ? MutantKind.plagueToad
                    : MutantKind.bloodCocoon))
            : (stage.chapterNumber >= 6 && squadOffsetIndex == 0
                ? MutantKind.shieldYacha
                : (squadOffsetIndex == 0 ? MutantKind.sickHound : MutantKind.swarmRat)));
    encounteredMutants.add(kind);

    final fromSouthToNorth = towerPos.y < 420.0;
    final Vec2 startPos;
    final List<Vec2> offRoadWaypoints;
    if (isAirborne) {
      final sy = fromSouthToNorth
          ? (1160.0 - (squadOffsetIndex * 65.0) % 190.0)
          : (150.0 + (squadOffsetIndex * 65.0) % 190.0);
      startPos = Vec2(fromLeft ? 34.0 : CampaignCatalog.arenaWidth - 34.0, sy);
      final midSky = Vec2(
        fromLeft ? 510.0 : 210.0,
        (sy + (fromSouthToNorth ? -240.0 : 240.0)).clamp(120.0, 1220.0),
      );
      final divePt = Vec2(
        (towerPos.x + (fromLeft ? -72.0 : 72.0)).clamp(60.0, 660.0),
        (towerPos.y + (fromSouthToNorth ? 95.0 : -95.0)).clamp(140.0, 1180.0),
      );
      offRoadWaypoints = [
        startPos,
        midSky,
        divePt,
        towerPos,
        shieldCenter,
      ];
    } else if (isTunnel) {
      final tx = fromLeft
          ? (150.0 + (squadOffsetIndex * 38.0) % 120.0)
          : (570.0 - (squadOffsetIndex * 38.0) % 120.0);
      final ty = fromSouthToNorth
          ? (towerPos.y + 390.0 + (squadOffsetIndex % 3) * 44.0).clamp(480.0, 1120.0)
          : (min(towerPos.y - 260.0, stage.chapterNumber >= 5 ? 540.0 : 490.0) +
                  (squadOffsetIndex % 3) * 44.0)
              .clamp(190.0, 960.0);
      startPos = Vec2(tx, ty);
      final midY = fromSouthToNorth
          ? max(towerPos.y + 62.0, ty - 185.0)
          : min(towerPos.y - 55.0, ty + 185.0);
      final midTarget = Vec2(fromLeft ? 286.0 : 434.0, midY.clamp(140.0, 1180.0));
      offRoadWaypoints = [
        startPos,
        midTarget,
        Vec2(towerPos.x, (towerPos.y + (fromSouthToNorth ? 38.0 : -38.0)).clamp(110.0, 1220.0)),
        towerPos,
        shieldCenter,
      ];
    } else {
      final sy = fromSouthToNorth
          ? (towerPos.y + 520.0 + (squadOffsetIndex * 68.0) % 210.0).clamp(620.0, 1180.0)
          : (min(towerPos.y - 340.0, stage.chapterNumber >= 5 ? 340.0 : 290.0) +
                  (squadOffsetIndex * 68.0) % 160.0)
              .clamp(140.0, 880.0);
      startPos = Vec2(fromLeft ? 30.0 : CampaignCatalog.arenaWidth - 30.0, sy);
      final dirSign = fromSouthToNorth ? -1.0 : 1.0;
      final mid1 = Vec2(
        fromLeft ? 168.0 : 552.0,
        (sy + dirSign * 145.0).clamp(130.0, 1180.0),
      );
      final mid2Y = fromSouthToNorth
          ? max(towerPos.y + 52.0, sy - 290.0)
          : min(towerPos.y - 48.0, sy + 290.0);
      final mid2 = Vec2(fromLeft ? 282.0 : 438.0, mid2Y.clamp(130.0, 1180.0));
      offRoadWaypoints = [
        startPos,
        mid1,
        mid2,
        Vec2(towerPos.x, (towerPos.y + (fromSouthToNorth ? 36.0 : -36.0)).clamp(110.0, 1220.0)),
        towerPos,
        shieldCenter,
      ];
    }

    final chScale = _monsterHpScaleForWave(currentWaveIndex);
    final ch1Ease = (stage.chapterNumber == 1 && progress.reincarnationCount == 0) ? 0.94 : 1.0;
    final eliteFactor = (stage.chapterNumber >= 5 || progress.reincarnationCount > 0) ? 1.02 : 0.92;
    final maxHp =
        kind.baseHp * kind.swarmHpFactor * chScale * ch1Ease * difficulty.hpMult * eliteFactor;
    final ch7DesertHaste = chapter.number == 7 ? 1.08 : 1.0;
    final spd = kind.speed *
        (isAirborne ? 2.05 : (isTunnel ? 1.78 : 1.92)) *
        ch7DesertHaste *
        difficulty.speedMult;

    final m = ActiveMutant(
      uid: _nextMutantUid++,
      kind: kind,
      laneIndex: 0,
      waypoints: offRoadWaypoints,
      pos: startPos,
      maxHp: maxHp,
      speed: spd,
      customName: isAirborne
          ? '공중강습 ${kind.name}'
          : (isTunnel ? '땅굴 ${kind.name}' : '월담 ${kind.name}'),
      lateralSeed: rng.nextDouble() * pi * 2,
      laneLateralOffset: 0.0,
    )
      ..isInfiltrator = true
      ..infiltratorStyle = isAirborne ? 'air' : (isTunnel ? 'tunnel' : 'flank')
      ..emergeAnimTimer = 0.85
      ..spawnedWaveIndex = currentWaveIndex
      ..attackScaleSnapshot = _mutantAttackScaleForWave(currentWaveIndex)
      ..headingRad = atan2(
        offRoadWaypoints[1].y - startPos.y,
        offRoadWaypoints[1].x - startPos.x,
      );

    bursts.add(
      FxBurst(
        pos: startPos,
        colorHex: isAirborne ? 0xFFE63946 : (isTunnel ? 0xFFF77F00 : 0xFFFF4D6D),
        maxRadius: 32,
        isTriangleShatter: isTunnel,
      ),
    );
    mutants.add(m);
    return m;
  }

  String _bossSpecialtyBadge(MutantKind kind) {
    String stars(int n) => '${'★' * n.clamp(1, 5)}${'☆' * (5 - n.clamp(1, 5))}';
    switch (kind) {
      case MutantKind.swiftShadowBoss:
        return '스피드 ${stars(kind.speedRating)}';
      case MutantKind.ironColossusBoss:
        return '맷집 ${stars(kind.toughnessRating)}';
      case MutantKind.crimsonBreakerBoss:
        return '공격력 ${stars(kind.attackRating)}';
      case MutantKind.raiderHeukpung:
        return '돌격 ${stars(kind.attackRating)}';
      case MutantKind.rivalMukhyeon:
        return '검기 ${stars(kind.attackRating)}';
      case MutantKind.chapterOverlord:
        return '대수괴 ${stars(kind.attackRating)}';
      default:
        return '전투 ${stars(kind.attackRating)}';
    }
  }

  static const List<double> _chapterMonsterHpCurve = <double>[
    1.28, // 1장 (적절한 초반 압박감 강화 + 1포탑 방치 및 무배치 100% 함락 유지)
    2.05, // 2장 (쌍문 대교차로 X자 합류)
    4.95, // 3장 (3수문 청옥 운하섬 — 급격한 절벽 없이 자연스러운 상성 입문)
    8.60, // 4장 (외곽 4면 절벽 대나선 → 정중앙 봉화요새)
    16.50, // 5장 (90° 직각 황동 톱니 미궁)
    31.50, // 6장 (남북 양면 대협공 → 정중앙 백옥광장 — 5→6장 전환 벽 완화)
    48.00, // 7장 (남→북 역진격 8자 열사협곡 → 북단 절벽성채)
    76.00, // 8장 (사선 4척 전함 널빤지교 → 등대항)
    108.00, // 9장 (육각 흑요석 용암섬 사슬다리 → 적염신전)
    182.00, // 10장 (7성좌 부유옥섬 무지개교 · 3페이즈 보스 10연전)
  ];

  double _nightmareChallengeScaleForWave(int waveIdx) {
    final fullScale = _nightmareChallengeScale;
    if (fullScale <= 1.001) return 1.0;
    // 제1물결은 초소가 2곳만 열려 있으므로(특히 4·9장 다중 진입로) 초반 25초 억까 즉사를 막고,
    // 초소가 개방되는 제2~3물결부터 100% 심야 공명 전력으로 치솟는다!
    if (waveIdx <= 0) {
      return pow(fullScale, 0.28).toDouble().clamp(1.0, 3.2);
    }
    if (waveIdx == 1) {
      return pow(fullScale, 0.65).toDouble().clamp(1.0, 24.0);
    }
    return fullScale;
  }

  double _monsterHpScaleForWave(int waveIdx) {
    final chIdx = (stage.chapterNumber - 1).clamp(0, _chapterMonsterHpCurve.length - 1);
    final reincMult = progress.reincarnationDifficultyMultiplier;
    if (stage.isReincarnationBossStage) {
      // 【윤회 최종 보스전】: 악몽 10-10 종결 기준선(launcherDpsIdx ≈ 76) 및 발사대 연사율·동료 한계돌파까지 반영해 매 회차 승률 <5% 고정!
      double permSum = 0.0;
      int permCnt = 0;
      for (final lt in LauncherType.values) {
        if (isLauncherTypeUnlocked(lt)) {
          permSum += (progress.launcherPermanentLevels[lt] ?? 1);
          permCnt++;
        }
      }
      final avgPerm = permCnt > 0 ? permSum / permCnt : 1.0;
      final rateRatio = max(1.0, (1.0 + (avgPerm - 1.0) * 0.045) / 1.765);
      final maxAllyLv = progress.companionLevels.values.fold<int>(10, max);
      final allyRatio = max(1.0, (1.50 + maxAllyLv * 0.20) / 3.50);
      final extraThroughput = 0.70 * rateRatio + 0.30 * allyRatio;
      final playerPowerRatio = max(
        reincMult,
        (_playerLauncherDpsIndex / 76.0) * extraThroughput,
      );
      final wEsc = waveIdx <= 0
          ? 0.92
          : (1.0 + pow(waveIdx, 1.52).toDouble() * 0.25);
      return 182.0 *
          1.60 *
          reincarnationBossHpPressure *
          playerPowerRatio *
          wEsc;
    }
    if (stage.globalIndex >= 900) {
      final w = max(0, waveIdx);
      final endlessBase = 142.0 * reincMult;
      if (w <= 15) {
        return endlessBase * (1.0 + w * 0.135);
      }
      // 16~100물결: 막 10-10을 깬 계정은 중후반(40~85물결)에서 한계를 느끼고, 엔드게임 연마 계정이 100물결을 정복하는 곡선!
      return endlessBase * (1.0 + w * 0.135 + pow(w - 15, 1.33).toDouble() * 0.062);
    }
    final baseCh = progress.reincarnationCount > 0
        ? _reincarnationEndgameBaseCurve[chIdx] * reincMult
        : _chapterMonsterHpCurve[chIdx];
    // 물결이 진행되며 초소·비급·실시간 강화가 중첩되는 속도에 맞춰 중후반 적 본대 체력도 탄탄하게 상승! (입구컷 프리패스 방지)
    final waveEscalation = waveIdx <= 0
        ? (difficulty == DefenseDifficulty.nightmare ? 0.78 : 0.88)
        : switch (difficulty) {
            DefenseDifficulty.easy => 1.0 + pow(waveIdx, 1.22).toDouble() * 0.06,
            DefenseDifficulty.normal => 1.0 + pow(waveIdx, 1.38).toDouble() * 0.13,
            DefenseDifficulty.nightmare => 1.0 + pow(waveIdx, 1.48).toDouble() * 0.20,
          };
    final nmChTight = difficulty == DefenseDifficulty.nightmare
        ? _nightmareChapterDensityMult[chIdx]
        : 1.0;
    return baseCh *
        (1.0 + (stage.stageNumber - 1) * 0.065) *
        waveEscalation *
        nmChTight *
        _nightmareChallengeScaleForWave(waveIdx);
  }

  double _mutantAttackScaleForWave(int waveIdx) {
    if (stage.isReincarnationBossStage) {
      final maxAllyLv = progress.companionLevels.values.fold<int>(10, max);
      final allyHealScale = 1.0 + max(0, maxAllyLv - 10) * 0.018;
      final shieldRatio = max(
        pow(2.35, progress.reincarnationCount).toDouble(),
        (centralSpec.shieldMaxHp / 1550.0) * allyHealScale,
      );
      final wFactor = waveIdx == 0 ? 0.80 : (1.0 + waveIdx * 0.085);
      return 7.6 * 1.65 * reincarnationBossAtkPressure * shieldRatio * wFactor;
    }
    double chMult = stage.globalIndex >= 900
        ? 7.4
        : (progress.reincarnationCount > 0
            ? (4.4 + (stage.chapterNumber - 1) * 0.36)
            : (1.0 +
                (stage.chapterNumber - 1) * 0.50 +
                (stage.chapterNumber >= 6 ? (stage.chapterNumber - 5) * 0.42 : 0.0)));
    if (stage.globalIndex >= 900 && waveIdx > 15) {
      chMult *= 1.0 + (waveIdx - 15) * 0.033;
    }
    final reincAtkMult = progress.reincarnationCount > 0
        ? pow(2.35, progress.reincarnationCount).toDouble()
        : 1.0;
    final isFirstIntro = stage.globalIndex == 1 &&
        difficulty == DefenseDifficulty.normal &&
        progress.reincarnationCount == 0;
    final earlyWaveEase = (waveIdx == 0 && stage.globalIndex < 900) ? 0.65 : 1.0;
    final nmWaveScale = _nightmareChallengeScaleForWave(waveIdx);
    final diffMult = switch (difficulty) {
      DefenseDifficulty.easy => 0.82,
      DefenseDifficulty.normal => isFirstIntro ? 1.0 : 1.18,
      DefenseDifficulty.nightmare =>
        1.62 * pow(nmWaveScale, 0.22).toDouble(),
    };
    final ch9LavaAtk = chapter.number == 9 ? 1.10 : 1.0;
    return chMult * reincAtkMult * diffMult * ch9LavaAtk * earlyWaveEase;
  }

  /// 장 진행 및 난이도에 따른 변이체 방어막·수호탑 공격력 배율 (1-1 보통은 1.00 정확 유지).
  double get _mutantAttackScale => _mutantAttackScaleForWave(currentWaveIndex);

  void _spawnMutant(_PendingSpawn item) {
    encounteredMutants.add(item.kind);
    final laneIdx = item.laneIndex % chapter.lanes.length;
    final lane = item.kind.isFlying
        ? chapter.aerialLane(laneIdx)
        : chapter.smoothedLane(laneIdx);
    if (laneIdx < lanePortalEnergy.length) {
      lanePortalEnergy[laneIdx] = 1.0;
    }

    final chScale = _monsterHpScaleForWave(item.waveIndex);
    final ch1Ease = (stage.chapterNumber == 1 &&
            stage.globalIndex < 900 &&
            progress.reincarnationCount == 0)
        ? (item.kind.isBoss ? 0.76 : 0.96)
        : 1.0;
    final maxHp = item.kind.baseHp *
        item.kind.swarmHpFactor *
        chScale *
        ch1Ease *
        difficulty.hpMult *
        item.hpScale;
    final speedScale = item.kind.isFlying ? 2.15 : 2.45;
    final ch7DesertHaste = chapter.number == 7 ? 1.08 : 1.0;
    final spd = item.kind.speed *
        speedScale *
        ch7DesertHaste *
        (1.0 + (stage.chapterNumber - 1) * 0.025) *
        difficulty.speedMult;
    final latOffset = item.kind.isBoss ? 0.0 : (rng.nextDouble() - 0.5) * 14.0;
    final int startWpIdx = item.startLaneProgress <= 0.0
        ? 0
        : (lane.length * item.startLaneProgress).round().clamp(0, max(0, lane.length - 3)).toInt();
    final spawnPos = lane[startWpIdx] + Vec2(latOffset * 0.55, 0);

    final nextWp = startWpIdx + 2 < lane.length ? lane[startWpIdx + 2] : shieldCenter;
    final initDelta = nextWp - spawnPos;
    final initHeading = initDelta.length > 1e-4 ? atan2(initDelta.y, initDelta.x) : 1.5707963;

    final spawned = ActiveMutant(
      uid: _nextMutantUid++,
      kind: item.kind,
      laneIndex: laneIdx,
      waypoints: lane,
      pos: spawnPos,
      maxHp: maxHp,
      speed: spd,
      customName: item.customTitle,
      customPortrait: item.customPortrait,
      lateralSeed: rng.nextDouble() * pi * 2,
      laneLateralOffset: latOffset,
    )
      ..spawnedWaveIndex = item.waveIndex
      ..attackScaleSnapshot = _mutantAttackScaleForWave(item.waveIndex)
      ..waypointIndex = min<int>(lane.length - 1, startWpIdx + 1)
      ..headingRad = initHeading
      ..smoothVel = Vec2(cos(initHeading) * spd, sin(initHeading) * spd)
      ..dashCooldown = item.kind == MutantKind.swiftShadowBoss ? 2.2 : 2.6;

    // ★ 행동대장(100타+) · 중간보스(200~500타+) · 각 장 천련 대수괴(1,000타+) 다단 변이 및 타수 실드 가동!
    if (item.kind.isBoss) {
      final isNightmare = difficulty == DefenseDifficulty.nightmare;
      if (item.kind.isMidBoss) {
        spawned.enableBossPhases(
          phases: 2,
          initialPlates: (isNightmare && (stage.chapterNumber >= 3 || progress.reincarnationCount > 0)) ? 1 : 0,
          phase1HpScale: 0.78,
        );
      } else {
        spawned.enableBossPhases(
          phases: 3,
          initialPlates: stage.isReincarnationBossStage ? 4 : (isNightmare ? 3 : 2),
          phase1HpScale: stage.isReincarnationBossStage ? 0.85 : 0.68,
        );
      }
      spawned.weakSpotAngleRad = rng.nextDouble() * pi * 2;
      final baseShieldHits = item.customHitShield ?? item.kind.baseHitShield;
      final reincHitMult = 1.0 + progress.reincarnationCount * 0.22;
      final shieldHits = ((isNightmare ? baseShieldHits * 1.32 : baseShieldHits) * reincHitMult)
          .round();
      final rankLabel = item.hierarchyRank ?? (item.kind.isMidBoss ? '행동대장' : '장 보스');
      if (shieldHits > 0) {
        spawned.enableHitShield(shieldHits, rank: rankLabel);
      }
    }

    mutants.add(spawned);

    // 행동대장·중간보스·장 보스 동반 침공 긴급 전장 경보 및 진동 연출!
    if (item.kind.isBoss) {
      final bossLabel = item.customTitle ?? item.kind.name;
      final hitTag = spawned.maxHitShield > 0 ? '🛡️${spawned.maxHitShield}타 마갑 · ' : '';
      final prefix = item.kind.isMidBoss
          ? '🚨 중간보스 동반 침략(${spawned.hierarchyRank.isNotEmpty ? spawned.hierarchyRank : "2단 변이"})!'
          : '🚨 3페이즈 천련 대수괴 강림(${spawned.hierarchyRank.isNotEmpty ? spawned.hierarchyRank : "장 보스"})!';
      final badge = _bossSpecialtyBadge(item.kind);
      bossInvasionAlertText = '$prefix [$bossLabel] · $hitTag$badge';
      bossInvasionAlertTimer = 4.6;
      screenShakeTimer = max(screenShakeTimer, 0.36);
      screenShakeIntensity = max(screenShakeIntensity, item.kind.isMidBoss ? 5.4 : 8.0);
      pendingSounds.add(SoundCue.villageWarning);
      bursts.add(FxBurst(pos: spawnPos, colorHex: item.kind.colorHex, maxRadius: 54));
      callouts.add(
        FloatingCallout(
          pos: const Vec2(320, 138),
          text: bossInvasionAlertText!,
          colorHex: item.kind.colorHex,
          ttlSec: 2.3,
          isBigBanner: true,
        ),
      );
    }
  }

  void _stepMutants(double dt) {
    for (int i = mutants.length - 1; i >= 0; i--) {
      final m = mutants[i];
      if (m.freezeTimer > 0) m.freezeTimer = max(0, m.freezeTimer - dt);
      if (m.freezeImmuneTimer > 0) m.freezeImmuneTimer = max(0, m.freezeImmuneTimer - dt);
      if (m.slowTimer > 0) m.slowTimer = max(0, m.slowTimer - dt);
      if (m.oilSlipTimer > 0) m.oilSlipTimer = max(0, m.oilSlipTimer - dt);
      if (m.spawnPortalTimer > 0) m.spawnPortalTimer = max(0, m.spawnPortalTimer - dt);
      if (m.attackAnimTimer > 0) m.attackAnimTimer = max(0, m.attackAnimTimer - dt * 1.9);
      if (m.hitFlashTimer > 0) m.hitFlashTimer = max(0, m.hitFlashTimer - dt * 3.8);
      if (m.dashBurstTimer > 0) m.dashBurstTimer = max(0, m.dashBurstTimer - dt);
      if (m.groggyExposeTimer > 0) m.groggyExposeTimer = max(0, m.groggyExposeTimer - dt);
      if (m.flankCrackCooldown > 0) m.flankCrackCooldown = max(0, m.flankCrackCooldown - dt);
      if (m.contactHitCooldown > 0) m.contactHitCooldown = max(0, m.contactHitCooldown - dt);
      if (m.altarHitFlashTimer > 0) m.altarHitFlashTimer = max(0, m.altarHitFlashTimer - dt);

      // ★ 완전 빙결(freezeTimer > 0) 중인 변이체는 약점 회전·넉백·이동·독안개·포효·타격까지 100% 동결된다!
      if (m.freezeTimer > 0) {
        m.knockbackVel = const Vec2(0, 0);
        continue;
      }

      if (m.totalPhases > 1) {
        final spinDir = m.uid.isEven ? 1.0 : -1.0;
        final spinSpeed = m.currentPhase >= 3 ? 1.78 : 1.18;
        m.weakSpotAngleRad += dt * spinSpeed * spinDir;
      }

      // 재변이 각성 충격파 연출 중(0.68초)에는 제자리에서 마기를 응축!
      if (m.phaseTransitionTimer > 0) {
        m.phaseTransitionTimer = max(0.0, m.phaseTransitionTimer - dt);
        continue;
      }

      // 밀침 넉백 감쇠 적용 (공중 비행 변이는 지면 기름 미끄럼 무시!)
      if (m.knockbackVel.length > 2.0) {
        m.pos = m.pos + m.knockbackVel * dt;
        final damp = (!m.kind.isFlying && m.oilSlipTimer > 0) ? 2.4 : 4.6 * chapter.surfaceFriction;
        m.knockbackVel = m.knockbackVel * max(0.0, 1.0 - damp * dt);
      } else {
        m.knockbackVel = const Vec2(0, 0);
      }

      // 낭떠러지 장외 & 절벽 걸침 35%(제8장 현측 바다 50% + 묵객 먹물 감속 시 +18%!) 뽀록 판정! (공중 비행 변이 및 보스는 절벽 추락 면역!)
      final canFallOffCliff = !m.kind.isBoss &&
          !m.kind.isFlying &&
          (stage.chapterNumber <= 2 ||
              chapter.number == 8 ||
              (m.kind != MutantKind.ironBoar && m.kind != MutantKind.shieldYacha) ||
              m.hp <= m.maxHp * 0.65);
      final cliffInnerRatio = chapter.number == 8 ? 0.78 : 0.68;
      final inkBonus = m.slowTimer > 0 ? 0.18 : 0.0;
      final cliffEdgeDropProb = ((chapter.number == 8 ? 0.50 : 0.35) + inkBonus).clamp(0.0, 0.85);
      bool fellOff = false;
      for (int cliffIdx = 0; cliffIdx < chapter.cliffs.length; cliffIdx++) {
        final cliff = chapter.cliffs[cliffIdx];
        final dist = m.pos.distanceTo(cliff.center);
        if (canFallOffCliff && dist < cliff.radius * cliffInnerRatio) {
          fellOff = true;
          break;
        } else if (canFallOffCliff &&
            !m.checkedCliffIndices.contains(cliffIdx) &&
            dist < cliff.radius) {
          m.checkedCliffIndices.add(cliffIdx);
          if (rng.nextDouble() < cliffEdgeDropProb) {
            fellOff = true;
            break;
          } else {
            callouts.add(
              FloatingCallout(
                pos: m.pos + const Vec2(0, -14),
                text: '휴~ 안 떨어졌지롱!',
                colorHex: 0xFFE9C46A,
              ),
            );
          }
        }
      }
      if (!canFallOffCliff) {
        m.pos = Vec2(
          m.pos.x.clamp(16.0, CampaignCatalog.arenaWidth - 16.0),
          m.pos.y.clamp(10.0, CampaignCatalog.arenaHeight - 14.0),
        );
      } else if (!m.kind.isBoss &&
          (m.pos.x < 10 ||
              m.pos.x > CampaignCatalog.arenaWidth - 10 ||
              m.pos.y < 6 ||
              (m.pos.y > CampaignCatalog.arenaHeight - 6 && m.knockbackVel.y > 15.0))) {
        fellOff = true;
      } else if (m.pos.y > CampaignCatalog.arenaHeight - 10) {
        m.pos = Vec2(m.pos.x, CampaignCatalog.arenaHeight - 10.0);
      }
      if (fellOff) {
        pporokCount++;
        pendingSounds.add(SoundCue.pporokFall);
        final scream = m.kind.screams[rng.nextInt(m.kind.screams.length)];
        callouts.add(
          FloatingCallout(
            pos: m.pos,
            text: '뽀록 추락! "$scream"',
            colorHex: 0xFF80ED99,
          ),
        );
        if (preset.primaryStone == StoneMaterial.onok &&
            towerHp > 0 &&
            launchers.any((e) => !e.isConstructing)) {
          final healRatio = stage.globalIndex >= 900 ? 0.011 : 0.022;
          shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * healRatio);
        }
        _rewardMutantKill(m, bonusTokenMult: 1.5, sourceKey: 'cliff_pporok', sourceLabel: '절벽 추락 뽀록');
        mutants.removeAt(i);
        continue;
      }

      // 전진 이동 및 스피드 특화 보행·질주·편대 물리 (빙결 중에는 animPhase 정지!)
      if (m.freezeTimer <= 0) {
        // ★ 변이 두목 · 역병 두꺼비 · 대수괴의 주변 포탑 「🕸️마기 침식」 방해 기믹! (악몽에서는 2기 동시 침식!)
        if ((m.kind.isBoss || m.kind == MutantKind.plagueToad) && launchers.isNotEmpty) {
          m.corruptionCastCooldown -= dt;
          if (m.corruptionCastCooldown <= 0) {
            final isNightmare = difficulty == DefenseDifficulty.nightmare;
            m.corruptionCastCooldown = isNightmare
                ? (m.kind.isBoss ? 4.0 : 5.8)
                : (m.kind.isBoss ? 5.2 : 7.5);
            final maxTargets = (isNightmare && m.kind.isBoss) ? 2 : 1;
            final candidates = launchers
                .where((l) =>
                    !l.isConstructing &&
                    !l.isCorrupted &&
                    l.purifiedBoostTimer <= 0 &&
                    l.pos.distanceTo(m.pos) <= (isNightmare ? 285.0 : 245.0))
                .toList()
              ..sort((a, b) =>
                  a.pos.distanceTo(m.pos).compareTo(b.pos.distanceTo(m.pos)));
            for (final nearL in candidates.take(maxTargets)) {
              nearL.corruptionTimer = isNightmare ? 7.5 : 6.5;
              lightningArcs.add(
                LightningArcFx(
                  from: m.pos,
                  to: nearL.pos,
                  ttlSec: 0.36,
                  colorHex: 0xFFC77DFF,
                ),
              );
              bursts.add(FxBurst(pos: nearL.pos, colorHex: 0xFFC77DFF, maxRadius: 34));
              callouts.add(
                FloatingCallout(
                  pos: nearL.pos + const Vec2(0, -18),
                  text: '🕸️ 마기 침식(연사 -48%)! 포탑 터치로 정화하세요!',
                  colorHex: 0xFFC77DFF,
                ),
              );
            }
          }
        }
        if (m.kind == MutantKind.swiftShadowBoss) {
          m.dashCooldown -= dt;
          if (m.dashCooldown <= 0) {
            m.dashCooldown = m.currentPhase >= 2 ? 2.5 : 3.4;
            m.dashBurstTimer = 0.65;
            m.attackAnimTimer = max(m.attackAnimTimer, 1.30);
            bursts.add(
              FxBurst(
                pos: m.pos,
                colorHex: m.kind.colorHex,
                maxRadius: 32,
                ttlSec: 0.28,
                durationSec: 0.28,
              ),
            );
          }
        } else if (m.kind == MutantKind.sickHound) {
          m.dashCooldown -= dt;
          if (m.dashCooldown <= 0) {
            m.dashCooldown = 3.6;
            m.dashBurstTimer = 0.45;
            m.attackAnimTimer = max(m.attackAnimTimer, 0.90);
          }
        }

        double gaitMult = 1.0 + (m.currentPhase - 1) * 0.16;
        if (m.groggyExposeTimer > 0) {
          gaitMult *= 0.68;
        }
        // 100타·1,000타 타수 실드가 남은 최종 페이즈에서 체력이 바닥나면 마갑 돌진(0.45배속 유지 — 제자리 무한 정지 방지!) 전환!
        if (m.currentPhase >= m.totalPhases &&
            m.hitShieldLeft > 0 &&
            m.hp <= m.currentMaxHp * 0.15) {
          gaitMult *= 0.45;
        }
        if (m.dashBurstTimer > 0) {
          gaitMult *= m.kind == MutantKind.swiftShadowBoss ? 1.55 : 1.32;
        } else if (m.kind == MutantKind.plagueToad) {
          gaitMult *= 0.62 + 0.66 * sin(m.animPhase * 0.85).abs();
        } else if (m.kind == MutantKind.ironBoar || m.kind == MutantKind.ironColossusBoss) {
          gaitMult *= 0.94 + 0.12 * sin(m.animPhase * 0.9).abs();
        }

        final slowFactor = m.slowTimer > 0
            ? (stage.isReincarnationBossStage && m.kind.isBoss ? 0.78 : 0.58)
            : 1.0;
        final trialBossStride = (stage.isReincarnationBossStage && m.kind.isBoss)
            ? (1.18 + (elapsedSec > 165.0 ? min(0.85, (elapsedSec - 165.0) * 0.012) : 0.0))
            : 1.0;
        final covRatio = formationCoverageRatio;
        final gapSpeedSurge = (currentWaveIndex >= 2 && covRatio < 0.84)
            ? (1.0 + (0.84 - covRatio) * 0.68)
            : 1.0;
        if (currentWaveIndex >= 2 &&
            covRatio < 0.76 &&
            _gapWarningWaves.add(currentWaveIndex)) {
          callouts.add(
            FloatingCallout(
              pos: const Vec2(360, 168),
              text: '🚨 진법 기맥 공백! 빈 초소를 개척·증설하고 실시간 강화를 올리세요!',
              colorHex: 0xFFFF595E,
              ttlSec: 2.4,
              isBigBanner: true,
            ),
          );
        }
        final effectiveSpeed = m.speed * slowFactor * gaitMult * gapSpeedSurge * trialBossStride;

        // Catmull-Rom 곡선 경로 및 90° 직각 미궁 경로 정밀 주시(Look-Ahead Pure Pursuit)!
        if (m.waypoints.isNotEmpty) {
          final isOrtho = chapter.isOrthogonalLabyrinth && !m.kind.isFlying && !m.isInfiltrator;
          final reachDist = isOrtho ? 5.5 : 32.0;
          final dotDist = isOrtho ? 9.0 : 56.0;
          int wpIdx = m.waypointIndex.clamp(0, m.waypoints.length - 1);
          while (wpIdx + 1 < m.waypoints.length) {
            final curWp = m.waypoints[wpIdx];
            final distToWp = m.pos.distanceTo(curWp);
            if (distToWp < reachDist) {
              wpIdx++;
              continue;
            }
            final segNext = m.waypoints[wpIdx + 1] - curWp;
            final relPos = m.pos - curWp;
            if (distToWp < dotDist && (relPos.x * segNext.x + relPos.y * segNext.y) > 0) {
              wpIdx++;
              continue;
            }
            break;
          }
          m.waypointIndex = wpIdx;

          final lookIdx = min(wpIdx + (isOrtho ? 0 : 2), m.waypoints.length - 1);
          Vec2 targetPt = m.waypoints[lookIdx];
          final rawForward = (targetPt - m.pos);
          final baseDir = rawForward.length > 1e-4 ? rawForward.normalized : const Vec2(0, 1);

          if (!isOrtho && !m.kind.isBoss && rawForward.length > 26.0) {
            final perp = Vec2(-baseDir.y, baseDir.x);
            final swayAmp = m.kind.speedRating >= 4 ? 4.8 : 2.8;
            final lateralShift =
                m.laneLateralOffset * 0.55 + sin(m.animPhase * 0.55 + m.lateralSeed) * swayAmp;
            final candidatePt = targetPt + perp * lateralShift;
            final safeEdge =
                candidatePt.x >= 30.0 && candidatePt.x <= CampaignCatalog.arenaWidth - 30.0;
            final safeCliff =
                chapter.cliffs.every((c) => candidatePt.distanceTo(c.center) > c.radius + 6.0);
            if (safeEdge && safeCliff) {
              targetPt = candidatePt;
            }
          }

          Vec2 steerDir = (targetPt - m.pos).normalized;

          // 대규모 무리 겹침 방지 소프트 분리력 (90도 직각 미궁에서는 벽 모서리 이탈 방지)
          if (!isOrtho && !m.kind.isBoss && mutants.length > 1) {
            Vec2 sep = const Vec2(0, 0);
            int checks = 0;
            for (final other in mutants) {
              if (other.uid == m.uid || other.kind.isBoss) continue;
              final diff = m.pos - other.pos;
              final d = diff.length;
              final minGap = (m.effectiveRadius + other.effectiveRadius) * 0.85;
              if (d > 0.01 && d < minGap) {
                sep = sep + diff.normalized * ((minGap - d) / minGap);
              }
              checks++;
              if (checks >= 10) break;
            }
            if (sep.length > 0.01) {
              final candDir = (steerDir + sep * 0.34).normalized;
              final candPos = m.pos + candDir * (effectiveSpeed * dt);
              final safeEdge =
                  candPos.x >= 30.0 && candPos.x <= CampaignCatalog.arenaWidth - 30.0;
              final safeCliff =
                  chapter.cliffs.every((c) => candPos.distanceTo(c.center) > c.radius + 6.0);
              if (safeEdge && safeCliff) {
                steerDir = candDir;
              }
            }
          }

          final desiredVel = (isOrtho ? baseDir : steerDir) * effectiveSpeed;
          if (isOrtho || m.smoothVel.length < 1.0) {
            m.smoothVel = desiredVel;
          } else {
            final velBlend = min(1.0, dt * 13.5);
            m.smoothVel = Vec2(
              m.smoothVel.x + (desiredVel.x - m.smoothVel.x) * velBlend,
              m.smoothVel.y + (desiredVel.y - m.smoothVel.y) * velBlend,
            );
          }

          m.pos = m.pos + m.smoothVel * dt;
          final actualSpeed = m.smoothVel.length;
          m.animPhase += actualSpeed * dt * (0.105 + m.kind.speedRating * 0.018) + dt * 1.95;

          if (actualSpeed > 0.5) {
            final desiredHeading = atan2(m.smoothVel.y, m.smoothVel.x);
            final angleDiff =
                atan2(sin(desiredHeading - m.headingRad), cos(desiredHeading - m.headingRad));
            m.headingRad = m.headingRad + angleDiff * min(1.0, dt * 9.2);
          }
        }
      }

      // ★ 완전 빙결(freezeTimer > 0) 중인 변이체는 이동뿐만 아니라 독안개·포효·결계 및 수호탑 타격도 모두 동결된다!
      if (m.freezeTimer > 0) {
        continue;
      }

      // 독안개 오라가 마을 가까이에 오면 논밭 농산물이 서서히 시듦
      final distToCenter = m.pos.distanceTo(shieldCenter);
      if (m.kind.poisonAura && distToCenter < 310) {
        cropsHealth = (cropsHealth - 0.018 * dt).clamp(0.0, 1.0);
        villageTookDamage = true;
      }

      // 제2장 이상 또는 무한혈전(globalIndex >= 900) 중간보스·대수괴 마기 포효 충격파!
      if (!m.roarShockUsed &&
          m.kind.isBoss &&
          (stage.chapterNumber >= 2 || stage.globalIndex >= 900) &&
          (m.hp <= m.currentMaxHp * 0.60 || distToCenter <= 540.0) &&
          shieldHp > shieldMaxHpDynamic * 0.22) {
        m.roarShockUsed = true;
        final baseRatio = m.kind.isMidBoss ? 0.14 : 0.26;
        final diffScale = switch (difficulty) {
          DefenseDifficulty.easy => 0.55,
          DefenseDifficulty.normal => 1.0,
          DefenseDifficulty.nightmare => 1.48,
        };
        final frostDr = seolhwaFrostShieldTimer > 0 ? 0.75 : 1.0;
        final shockDmg = shieldMaxHpDynamic * baseRatio * diffScale * frostDr;
        shieldHp = max(shieldMaxHpDynamic * 0.18, shieldHp - shockDmg);
        screenShakeTimer = max(screenShakeTimer, 0.26);
        screenShakeIntensity = max(screenShakeIntensity, m.kind.isMidBoss ? 4.4 : 6.5);
        bursts.add(
          FxBurst(
            pos: m.pos,
            colorHex: m.kind.colorHex,
            maxRadius: m.kind.isMidBoss ? 56 : 84,
            isTriangleShatter: true,
          ),
        );
        callouts.add(
          FloatingCallout(
            pos: m.pos + const Vec2(0, -24),
            text: m.kind.isMidBoss
                ? '💢 중간보스 마기 포효!! 결계가 흔들립니다!'
                : '🌋 대수괴 광폭 마기 포효!! 결계 수복·출두 대비!',
            colorHex: 0xFFFF595E,
            ttlSec: 1.6,
            isBigBanner: !m.kind.isMidBoss,
          ),
        );
      }

      final phaseAttackMult = 1.0 + (m.currentPhase - 1) * 0.22;
      final carapaceRamMult = m.carapacePlatesLeft > 0 ? 1.48 : 1.0;
      final covForAtk = formationCoverageRatio;
      final gapAtkSurge = (currentWaveIndex >= 2 && covForAtk < 0.84)
          ? (1.0 + (0.84 - covForAtk) * 3.6)
          : 1.0;
      final trialRageMult = stage.isReincarnationBossStage
          ? (1.0 + max(0.0, elapsedSec - 90.0) * 0.032)
          : 1.0;
      final atkScale = (m.attackScaleSnapshot > 0 ? m.attackScaleSnapshot : _mutantAttackScale) *
          gapAtkSurge *
          trialRageMult;
      final frostShieldDr = seolhwaFrostShieldTimer > 0 ? 0.75 : 1.0;
      // 외곽 기공 방어막 충돌 처리 (외각 장갑이 깨지지 않은 다단 변이 보스는 결계를 1.48배로 부수며 밀침 저항!)
      if (shieldHp > 0 &&
          m.contactHitCooldown <= 0 &&
          distToCenter <= CampaignCatalog.outerShieldRadius + m.effectiveRadius * 0.5) {
        m.contactHitCooldown = 0.22;
        m.altarHitFlashTimer = 0.85;
        shieldHp = max(
          0,
          shieldHp - m.kind.attackPower * phaseAttackMult * carapaceRamMult * atkScale * frostShieldDr,
        );
        m.attackAnimTimer = 1.0;
        if (m.kind.toughnessRating >= 4 || m.kind == MutantKind.crimsonBreakerBoss) {
          heavyHitsOnShield++;
        }
        if (m.kind.speedRating >= 4) {
          swarmHitsOnShield++;
        }

        // 방어막 반동 충격파로 변이체 후방 밀침 (장갑을 두른 보스는 밀침 56% 저항 · 윤회 심판 보스는 무극 패기로 제단에 밀착 강타!)
        final pushScale = (isFormationActive ? 2.35 : 1.42) *
            (m.carapacePlatesLeft > 0 ? 0.44 : 1.0) *
            ((stage.isReincarnationBossStage && m.kind.isBoss) ? 0.22 : 1.0);
        final rawPush = m.pos - shieldCenter;
        final pushDir = rawPush.length > 1e-3 ? rawPush.normalized : const Vec2(0, -1);
        m.knockbackVel = pushDir * (centralSpec.shieldWavePush * pushScale / sqrt(m.kind.mass));
        pendingSounds.add(SoundCue.shieldWave);
        bursts.add(FxBurst(pos: m.pos, colorHex: 0xFF4CC9F0, maxRadius: 30));

        // 공격력 5성 보스(파성귀·묵현·대요마) 강타 시 파쇄 충격파 + 화면 진동!
        if (m.kind.isBoss && m.kind.attackRating >= 5) {
          bursts.add(
            FxBurst(
              pos: m.pos,
              colorHex: m.kind.colorHex,
              maxRadius: 62,
              ttlSec: 0.48,
              durationSec: 0.48,
              isTriangleShatter: true,
            ),
          );
          screenShakeTimer = max(screenShakeTimer, 0.32);
          screenShakeIntensity = max(screenShakeIntensity, 6.8);
        } else if (m.kind.isBoss) {
          screenShakeTimer = max(screenShakeTimer, 0.18);
          screenShakeIntensity = max(screenShakeIntensity, 3.8);
        }

        // 1회 한정 호신 반발 빙결 충격파 발동 (난이도별 차등 회복 · 방치 시 100% 함락!)
        if (!_emergencyRepulseUsed && shieldHp <= shieldMaxHpDynamic * 0.32) {
          _emergencyRepulseUsed = true;
          final repulseRefill = switch (difficulty) {
            DefenseDifficulty.easy => 0.55,
            DefenseDifficulty.normal => 0.38,
            DefenseDifficulty.nightmare => 0.24,
          };
          shieldHp = max(shieldHp, shieldMaxHpDynamic * repulseRefill);
          for (final nearM in mutants) {
            if (nearM.pos.distanceTo(shieldCenter) <= 420.0) {
              final rawRep = nearM.pos - shieldCenter;
              final repDir = rawRep.length > 1e-3 ? rawRep.normalized : const Vec2(0, -1);
              nearM.knockbackVel = repDir * 420.0;
              nearM.freezeTimer = max(nearM.freezeTimer, 1.6);
            }
          }
          bursts.add(FxBurst(pos: shieldCenter, colorHex: 0xFFFF595E, maxRadius: 112, isTriangleShatter: true));
          callouts.add(
            FloatingCallout(
              pos: shieldCenter + const Vec2(0, -76),
              text: '🚨 비상 결계 반발! 지금 즉시 초소를 소환하세요!',
              colorHex: 0xFFFFD166,
              ttlSec: 2.6,
              isBigBanner: true,
            ),
          );
        }

        if (shieldHp <= 0) {
          pendingSounds.add(SoundCue.villageWarning);
          callouts.add(
            FloatingCallout(
              pos: shieldCenter + const Vec2(0, -64),
              text: '⚠️ 외곽 기공 방어막 파손! 중앙 보호 장치를 사수하세요!',
              colorHex: 0xFFFF595E,
              isBigBanner: true,
            ),
          );
        }
      } else if (shieldHp <= 0 &&
          m.contactHitCooldown <= 0 &&
          (distToCenter <= CampaignCatalog.centralTowerRadius + 24.0 + m.kind.radius * 0.6 ||
              m.pos.distanceTo(towerPos) <=
                  CampaignCatalog.centralTowerRadius + 24.0 + m.kind.radius * 0.6)) {
        // 방어막이 깨진 상태에서 중앙 자동 보호 장치 직접 타격 → attackPower 비례 피해!
        m.contactHitCooldown = 0.22;
        m.altarHitFlashTimer = 0.85;
        towerTookDamage = true;
        towerHp = max(0, towerHp - m.kind.attackPower * 0.95 * phaseAttackMult * atkScale * frostShieldDr);
        m.attackAnimTimer = 1.0;
        final ecoHit = (0.05 + m.kind.attackPower * 0.0012).clamp(0.05, 0.14);
        granaryHealth = (granaryHealth - ecoHit).clamp(0.0, 1.0);
        cropsHealth = (cropsHealth - ecoHit).clamp(0.0, 1.0);
        livestockHealth = (livestockHealth - ecoHit * 1.1).clamp(0.0, 1.0);
        villageTookDamage = true;

        if (m.kind.isBoss && m.kind.attackRating >= 5) {
          bursts.add(
            FxBurst(
              pos: m.pos,
              colorHex: m.kind.colorHex,
              maxRadius: 58,
              ttlSec: 0.50,
              durationSec: 0.50,
              isTriangleShatter: true,
            ),
          );
          screenShakeTimer = max(screenShakeTimer, 0.32);
          screenShakeIntensity = max(screenShakeIntensity, 7.5);
        }

        final rawPush = m.pos - shieldCenter;
        final pushDir = rawPush.length > 1e-3 ? rawPush.normalized : const Vec2(0, -1);
        m.knockbackVel = pushDir * 64.0;
        pendingSounds.add(SoundCue.villageWarning);
      }
    }
  }

  void _stepCentralGuardian(double dt) {
    if (towerHp <= 0) return;
    if (centralFireTimer > 0) {
      centralFireTimer = max(0.0, centralFireTimer - dt);
    }
    if (mutants.isEmpty) return;

    final origin = towerPos;
    final maxR = centralManualMode ? effectiveCentralManualRange : effectiveCentralAutoRange;
    final target = _pickMostThreateningMutant(origin, maxRange: maxR);
    if (target == null) return;

    if (!centralManualMode) {
      final aimDir = (target.pos - origin).normalized;
      final desiredAngle = atan2(aimDir.y, aimDir.x);
      final diff = atan2(sin(desiredAngle - centralAimAngleRad), cos(desiredAngle - centralAimAngleRad));
      centralAimAngleRad = centralAimAngleRad + diff * min(1.0, dt * 10.0);
    }

    // 수동 탄지 모드일 때는 플레이어의 직접 조준 발사를 대기한다!
    if (centralManualMode) return;
    if (centralFireTimer > 0) return;

    final feverBoost = feverTimer > 0 ? 1.55 : 1.0;
    final liveReloadMult = 1.0 + liveReloadLv * 0.18;
    final idlePenalty = isFormationActive ? 1.0 : 1.85;
    centralFireTimer = (centralSpec.fireIntervalSec * idlePenalty) /
        ((auroraCritTimer > 0 ? 1.5 : 1.0) * feverBoost * liveReloadMult);
    centralRecoilAnim = 1.0;
    pendingSounds.add(SoundCue.gearMotion);

    // 초소가 단 1곳도 없고 수동 조준도 안 하는 방치 상태에서는 약한 경계 단발만 발사(도탄·범위 없음 → 100% 함락!)
    if (!isFormationActive) {
      final rawDir = (target.pos - origin).normalized;
      final guardCultMult =
          progress.realm.powerMult * (1.0 + progress.meridianLauncherDmgBonus);
      projectiles.add(
        ActiveStoneProjectile(
          sourceKey: 'central_tower',
          sourceLabel: '중앙 기명 수호탑 (비공명 경계)',
          pos: origin,
          vel: rawDir * 300.0,
          material: StoneMaterial.cheongok,
          shape: StoneShape.flat,
          damage: centralSpec.baseDamage * 0.25 * guardCultMult,
          knockback: 14.0 * (1.0 + progress.meridianKnockbackBonus),
          critChance: progress.meridianCritBonus.clamp(0.0, 0.35),
          colorHex: 0xFF72EFDD,
          radius: 6.5,
          pierceLeft: 0,
          aoeSplashRadius: 0.0,
          maxTravelDist: effectiveCentralAutoRange * 1.15,
        )..bouncesLeft = chapter.number == 5 ? 2 : 0,
      );
      return;
    }

    // 길목 초소가 1곳 이상 가동되어 진법이 연결되었을 때만 자동 어기어석·흡성탄지 발동!
    final activeTowers = launchers.where((e) => !e.isConstructing).toList();
    if (activeTowers.isNotEmpty && qiBars >= 2.95 && _autoEogiCooldown <= 0) {
      qiBars = max(0.0, qiBars - 3.0);
      _encoreEogiReserved = false;
      _autoEogiCooldown = 5.2;
      _qiBurstSynergyTimer = max(_qiBurstSynergyTimer, 2.5);
      _fireAutoEogieoseok(target);
      _tryFireNalssaendolAcornWithCentral();
      return;
    }

    final centralCultivationMult =
        progress.realm.powerMult *
        (1.0 + progress.meridianLauncherDmgBonus) *
        formationResonanceScale;

    if (!_encoreEogiReserved &&
        activeTowers.isNotEmpty &&
        qiBars >= 2.0 &&
        _countMutantsNear(target.pos, 80) >= 4) {
      qiBars -= 1.5;
      _qiBurstSynergyTimer = max(_qiBurstSynergyTimer, 2.0);
      _spawnStoneShot(
        sourceKey: 'central_tower',
        sourceLabel: '중앙 기명 수호탑 (흡성탄지)',
        origin: origin,
        target: target,
        baseDamage: centralSpec.baseDamage * 1.48 * centralCultivationMult,
        speed: 350,
        pullsEnemies: true,
        aoeRadius: 72,
        maxTravelDist: effectiveCentralAutoRange * 1.25,
      );
      _tryFireNalssaendolAcornWithCentral();
      return;
    }

    bool useSectTech = false;
    if (!_encoreEogiReserved && activeTowers.isNotEmpty && qiBars >= 1.0) {
      qiBars -= 1.0;
      _qiBurstSynergyTimer = max(_qiBurstSynergyTimer, 2.0);
      useSectTech = true;
    }

    _spawnStoneShot(
      sourceKey: 'central_tower',
      sourceLabel: '중앙 기명 수호탑',
      origin: origin,
      target: target,
      baseDamage:
          centralSpec.baseDamage * (useSectTech ? 1.35 : 0.85) * centralCultivationMult,
      speed: 345,
      pierceBonus: 0,
      sectTech: useSectTech ? preset.sectTechnique : null,
      maxTravelDist: effectiveCentralAutoRange * 1.18,
    );
    _tryFireNalssaendolAcornWithCentral();
  }

  /// 영수 날쌘돌이 장착되어 있을 때 중앙 수호탑 탄지마다 도토리 보조탄을 동시 연사!
  void _tryFireNalssaendolAcornWithCentral() {
    if (!isFormationActive || mutants.isEmpty) return;
    if (preset.equippedBeast != SpiritBeast.nalssaendol) return;
    final lv = progress.beastLevels[SpiritBeast.nalssaendol] ?? 0;
    if (lv <= 0) return;
    final allyMaxR = (278.0 * liveRangeMultiplier).clamp(268.0, 385.0);
    final target = _pickMostThreateningMutant(shieldCenter, maxRange: max(allyMaxR, effectiveCentralAutoRange));
    if (target == null) return;
    final allyMult = (1.0 + perkStacks(RoguePerk.allyAwakening) * 0.45) *
        (1.0 + progress.elixirResonanceBonus) *
        (1.0 + progress.meridianLauncherDmgBonus) *
        formationResonanceScale;
    final power =
        centralSpec.baseDamage * (1.15 + lv * 0.18) * progress.realm.powerMult * allyMult;
    _spawnStoneShot(
      sourceKey: 'beast_nalssaendol',
      sourceLabel: '영수 날쌘돌 (동반 도토리탄)',
      origin: shieldCenter + const Vec2(-36, -12),
      target: target,
      baseDamage: power,
      speed: 385,
      maxTravelDist: max(allyMaxR, effectiveCentralAutoRange) * 1.18,
    );
  }

  void _fireAutoEogieoseok(ActiveMutant primaryTarget) {
    final origin = towerPos;
    final activeTowers = launchers.where((e) => !e.isConstructing).toList();
    final distinctTypes = activeTowers.map((e) => e.type).toSet().length;
    final monoPenalty =
        (stage.chapterNumber >= 4 && activeTowers.length >= 3 && distinctTypes <= 1) ? 0.46 : 1.0;
    final centralCultivationMult =
        progress.realm.powerMult *
        (1.0 + progress.meridianLauncherDmgBonus) *
        formationResonanceScale;
    final count = progress.realm.eogieoseokCount + 1;
    final maxEogiRange = (285.0 * liveRangeMultiplier).clamp(275.0, 395.0);
    final candidates = mutants
        .where((m) => m.pos.distanceTo(origin) <= maxEogiRange)
        .toList();
    final pool = candidates.isNotEmpty ? candidates : <ActiveMutant>[primaryTarget];
    callouts.add(
      FloatingCallout(
        pos: origin + const Vec2(0, -52),
        text: '✨ 자동 어기어석 발동! 수호 알 $count기 편대 소탕!',
        colorHex: 0xFF72EFDD,
        isBigBanner: true,
      ),
    );
    pool.sort(
      (a, b) => a.pos
          .distanceTo(shieldCenter)
          .compareTo(b.pos.distanceTo(shieldCenter)),
    );
    _spawnShockwaveRing(
      origin,
      maxRadius: 105.0,
      colorHex: 0xFF72EFDD,
      secondaryColorHex: 0xFFFFD166,
      style: 'skillUltimate',
      durationSec: 0.45,
    );
    for (int i = 0; i < count; i++) {
      final tgt = pool[i % pool.length];
      _spawnStoneShot(
        sourceKey: 'central_tower',
        sourceLabel: '중앙 기명 수호탑 (어기어석)',
        origin: origin + Vec2((i - count / 2) * 14, -8),
        target: tgt,
        baseDamage: centralSpec.baseDamage * 2.15 * monoPenalty * centralCultivationMult,
        speed: 480,
        pierceBonus: 3,
        aoeRadius: 56,
        ignoresShield: true,
        maxTravelDist: maxEogiRange * 1.16,
        projectileStyle: 'eogiUltimate',
      );
    }

    if (allowSerendipity && rng.nextDouble() < (0.22 + progress.meridianSerendipityBonus)) {
      serendipityCount++;
      pendingSounds.add(SoundCue.serendipityJackpot);
      qiBars = max(qiBars, 2.98);
      _autoEogiCooldown = 0.65;
      _encoreEogiReserved = true;
      callouts.add(
        FloatingCallout(
          pos: shieldCenter + const Vec2(0, -92),
          text: '🔁 기연 · 한 번 더 어기어석 연속 장전!',
          colorHex: 0xFFFFD166,
        ),
      );
    }
  }

  void _stepPathLaunchers(double dt) {
    if (_autoEogiCooldown > 0) {
      _autoEogiCooldown = max(0.0, _autoEogiCooldown - dt);
    }
    final perkHaste = 1.0 + perkStacks(RoguePerk.rapidBarrage) * 0.30;
    final feverHaste = feverTimer > 0 ? 1.80 : 1.0;
    final rouletteHaste = rouletteHyperBarrageTimer > 0 ? 2.20 : 1.0;
    final liveReloadMult = 1.0 + liveReloadLv * 0.12;
    final hasteMult = (jeonggakHasteTimer > 0 ? _jeonggakHasteMult : 1.0) *
        (auroraCritTimer > 0 ? 1.50 : 1.0) *
        perkHaste *
        feverHaste *
        rouletteHaste *
        liveReloadMult;

    final links = activeSynergyLinks;
    final activeTowers = launchers.where((e) => !e.isConstructing).toList();
    final distinctTypes = activeTowers.map((e) => e.type).toSet().length;
    final hasNonAmpTower = activeTowers.any((e) => e.type != LauncherType.qiAmplifier);
    final monoOverload = stage.chapterNumber >= 4 && activeTowers.length >= 3 && distinctTypes <= 1;
    final ch6DiversityBoost = (chapter.number == 6 && distinctTypes >= 3) ? 1.20 : 1.0;
    final typeDiversityMult = monoOverload
        ? 0.45
        : (distinctTypes >= 4 ? 1.72 : (distinctTypes >= 3 ? 1.42 : 1.0)) * ch6DiversityBoost;
    // 실시간 화력업 및 과녁 배율은 _spawnStoneShot에서 일괄 곱해지므로 중복 제곱 증폭 차단!
    final fiveElemBonus = typeDiversityMult;
    final taijiQiGainMult = preset.sectTechnique == SectTechnique.taiji ? 1.25 : 1.0;

    int ampQiCount = 0;
    for (final l in launchers) {
      if (l.recoilAnim > 0) l.recoilAnim = max(0, l.recoilAnim - dt * 4.0);
      if (l.corruptionTimer > 0) l.corruptionTimer = max(0, l.corruptionTimer - dt);
      if (l.purifiedBoostTimer > 0) l.purifiedBoostTimer = max(0, l.purifiedBoostTimer - dt);
      if (l.serendipityReloadLockTimer > 0) {
        l.serendipityReloadLockTimer = max(0.0, l.serendipityReloadLockTimer - dt);
      }

      // 실시간 포대 축조·단조 공정 중에는 가동 준비!
      if (l.constructTimer > 0) {
        l.constructTimer = max(0.0, l.constructTimer - dt);
        if (l.constructTimer <= 0) {
          bursts.add(FxBurst(pos: l.pos, colorHex: l.terrainType.colorHex, maxRadius: 30));
        }
        continue;
      }

      final corruptionMult = l.isCorrupted ? 0.52 : (l.purifiedBoostTimer > 0 ? 1.25 : 1.0);
      final covNow = formationCoverageRatio;
      final isolationFactor = covNow >= 0.90 ? 1.0 : (0.30 + 0.70 * covNow);
      double ampReload = l.terrainType.reloadMult * corruptionMult * isolationFactor;
      double ampDamage = fiveElemBonus * l.terrainType.damageMult * isolationFactor;
      double ampCrit = (distinctTypes >= 3 ? 0.08 : 0.0) + l.terrainType.critBonus;
      int synPierce = l.terrainType.pierceBonus;
      double synSpeedMult = 1.0;

      for (final link in links) {
        if (link.slotA == l.slotIndex || link.slotB == l.slotIndex) {
          if (link.synergyName == '쌍성 공명진') ampReload += 0.18;
          if (link.synergyName == '쌍류 탄막진') {
            synSpeedMult = 1.18;
            synPierce += 1;
          }
        }
      }

      // 내공 증폭기는 자기 자신이나 다른 증폭기는 증폭하지 않고, 주변 다른 계통 포탑만 강력히 증폭(반경 195px · 최대 2중첩 · 제5장 +35% 과부하)!
      if (l.type != LauncherType.qiAmplifier) {
        final ch5AmpMult = chapter.number == 5 ? 1.35 : 1.0;
        int ampStacks = 0;
        for (final other in activeTowers) {
          final auraR = 195.0 * (other.terrainType == MountTerrainType.spiritSpring ? 1.25 : 1.0);
          if (other != l &&
              other.type == LauncherType.qiAmplifier &&
              other.pos.distanceTo(l.pos) <= auraR) {
            ampReload += (0.20 + other.tier * 0.06) * ch5AmpMult;
            ampDamage += (0.28 + other.tier * 0.09) * ch5AmpMult;
            ampCrit += (0.05 * other.tier) * ch5AmpMult;
            ampStacks++;
            if (ampStacks >= 2) break;
          }
        }
      }

      final ch10QiMult = (chapter.number == 10 ? 1.30 : 1.0) * taijiQiGainMult;
      if (l.type == LauncherType.qiAmplifier && hasNonAmpTower && ampQiCount < 2) {
        ampQiCount++;
        final springBoost = l.terrainType == MountTerrainType.spiritSpring ? 1.85 : 1.0;
        qiBars = (qiBars + (0.08 + l.tier * 0.03) * springBoost * ch10QiMult * dt)
            .clamp(0.0, maxQiBars);
        if (l.tier >= 4 && shieldHp > 0) {
          shieldHp = min(shieldMaxHpDynamic, shieldHp + 2.8 * springBoost * dt);
        }
      } else if (l.terrainType == MountTerrainType.spiritSpring && ampQiCount < 3) {
        qiBars = (qiBars + 0.035 * ch10QiMult * dt).clamp(0.0, maxQiBars);
      }

      l.cooldown -= dt * l.type.tierFireRateMultiplier(l.tier) * hasteMult * ampReload;
      if (l.cooldown > 0 || mutants.isEmpty) continue;

      final target = _pickTargetForLauncher(l);
      if (target == null) continue;

      final normalCd = l.type.baseCooldownSec / (1.0 + (l.permanentLevel - 1) * 0.045);
      l.cooldown = normalCd;
      if (allowSerendipity &&
          l.serendipityReloadLockTimer <= 0 &&
          rng.nextDouble() < (0.11 + progress.meridianSerendipityBonus)) {
        l.cooldown = max(0.16, normalCd * 0.28);
        l.serendipityReloadLockTimer = 1.45;
        serendipityCount++;
      }
      l.recoilAnim = 1.0;
      final dir = (target.pos - l.pos).normalized;
      l.aimAngleRad = atan2(dir.y, dir.x);
      pendingSounds.add(SoundCue.bowMotion);
      if (muzzleFlashes.length < 28) {
        muzzleFlashes.add(
          MuzzleFlashFx(
            pos: l.pos + dir * 18.0,
            angleRad: l.aimAngleRad,
            colorHex: l.type.colorHex,
            scale: l.type == LauncherType.heavy ? 1.38 : 0.96,
          ),
        );
      }

      final permScale = 1.0 + (l.permanentLevel - 1) * 0.16;
      final dmg = l.type.baseDamage *
          1.42 *
          l.type.tierDamageMultiplier(l.tier) *
          permScale *
          ampDamage *
          progress.realm.powerMult *
          progress.transcendenceMultiplier *
          (1.0 +
              progress.meridianLauncherDmgBonus +
              progress.coreFirepowerBonus +
              progress.codexPowerBonus +
              progress.forgeMasteryPowerBonus);

      final shotCount = l.type.projectilesPerShot(l.tier);
      final launcherRange = effectiveLauncherRange(l);
      final maxShotDist =
          launcherRange * (l.type == LauncherType.curveSpin ? 1.28 : 1.16);
      final launcherPierce = synPierce +
          switch (l.type) {
            LauncherType.rapid => 1 + (l.tier >= 3 ? 1 : 0),
            LauncherType.curveSpin => 2 + (l.tier >= 3 ? 2 : 0),
            _ => 0,
          };
      final chokeSplashMult = l.terrainType == MountTerrainType.chokeGate ? 1.20 : 1.0;
      final launcherSplash = switch (l.type) {
            LauncherType.heavy => 52.0 + l.tier * 11.0,
            LauncherType.frostField => 48.0 + l.tier * 9.0,
            _ => 0.0,
          } *
          chokeSplashMult;
      final spreadStep = switch (l.type) {
        LauncherType.rapid => 0.11,
        LauncherType.frostField => 0.16,
        LauncherType.curveSpin => 0.18,
        _ => 0.12,
      };
      final projStyle = switch (l.type) {
        LauncherType.rapid => 'rapidBolt',
        LauncherType.heavy => 'heavyMeteor',
        LauncherType.curveSpin => 'curveChakram',
        LauncherType.frostField => 'frostCrystal',
        LauncherType.qiAmplifier => 'qiBagua',
      };
      if (l.type == LauncherType.qiAmplifier) {
        _spawnShockwaveRing(
          l.pos,
          maxRadius: 56.0 + l.tier * 8.0,
          colorHex: 0xFFC77DFF,
          secondaryColorHex: 0xFFFFD166,
          style: 'baguaPulse',
          durationSec: 0.34,
        );
      }
      final ch4AntiAirSpeed =
          (chapter.number == 4 && target.kind.isFlying) ? 1.18 : 1.0;
      final rolledVolleySeren = allowSerendipity &&
          rng.nextDouble() < (0.07 + progress.meridianSerendipityBonus * 0.5);
      if (rolledVolleySeren) {
        serendipityCount++;
      }
      for (int s = 0; s < shotCount; s++) {
        final spreadRad = shotCount == 1 ? 0.0 : (s - (shotCount - 1) / 2) * spreadStep;
        final curveSign = (s.isEven ? 1.0 : -1.0);
        _spawnStoneShot(
          sourceKey: 'launcher_${l.slotIndex}',
          sourceLabel: '${l.type.name}(${l.slotIndex + 1}거점)',
          origin: l.pos,
          target: target,
          baseDamage: dmg,
          speed: l.type.projectileSpeed * synSpeedMult * ch4AntiAirSpeed,
          spreadAngleRad: spreadRad,
          extraCrit: ampCrit,
          spinCurve: l.type == LauncherType.curveSpin ? (1.15 + l.tier * 0.25) * curveSign : 0.0,
          pierceBonus: launcherPierce,
          ignoresShield: l.type == LauncherType.curveSpin ||
              (l.type == LauncherType.heavy && l.tier >= 3) ||
              l.terrainType == MountTerrainType.ambushRidge,
          aoeRadius: launcherSplash,
          freezesOnHit: l.type == LauncherType.frostField,
          knockbackScale: (l.type == LauncherType.heavy ? (1.65 + l.tier * 0.22) : 1.15) *
              l.terrainType.knockbackMult,
          maxTravelDist: maxShotDist,
          fromWeakCrackerMount: l.terrainType.cracksBossWeakPoint &&
              (l.type == LauncherType.heavy || l.type == LauncherType.curveSpin),
          projectileStyle: projStyle,
          sectTech: l.type == LauncherType.qiAmplifier ? preset.sectTechnique : null,
          preRolledSerendipity: rolledVolleySeren,
        );
      }
    }
  }

  void _stepSpiritBeastAndCompanions(double dt) {
    // 길목 초소가 단 1곳도 없고 수동 탄지 공명도 없으면 영수·동료가 출격하지 않음(방치 자동 클리어 원천 차단)!
    if (!isFormationActive) return;

    final allyPerkStacks = perkStacks(RoguePerk.allyAwakening);
    final cdFactor = (1.0 - progress.meridianAllyCooldownReduction) *
        pow(0.68, allyPerkStacks).toDouble();
    final allyMaxR = (278.0 * liveRangeMultiplier).clamp(268.0, 385.0);
    final hasTargetInAllyRange =
        _pickMostThreateningMutant(shieldCenter, maxRange: allyMaxR) != null;

    final beast = preset.equippedBeast;
    final beastLv = progress.beastLevels[beast] ?? 1;
    if (beastLv > 0) {
      beastCooldown -= dt;
      final canCastBeast = beast == SpiritBeast.geumgangTurtle
          ? (shieldHp < shieldMaxHpDynamic * 0.92 || hasTargetInAllyRange)
          : (beast == SpiritBeast.nalssaendol
              ? (centralManualMode && hasTargetInAllyRange)
              : hasTargetInAllyRange);
      if (beastCooldown <= 0 &&
          canCastBeast &&
          _checkConditionMet(
            preset.beastCondition,
            allowWithoutEnemies: beast == SpiritBeast.geumgangTurtle,
            maxRange: allyMaxR,
          )) {
        beastCooldown = beast.baseCooldownSec * cdFactor;
        _executeSpiritBeast(beast, beastLv);

        if (allowSerendipity && rng.nextDouble() < (0.20 + progress.meridianSerendipityBonus)) {
          serendipityCount++;
          beastCooldown = 0.35;
          callouts.add(
            FloatingCallout(
              pos: shieldCenter + const Vec2(45, -40),
              text: '🔁 기연 · ${beast.name} 한 번 더 연속 출격!',
              colorHex: 0xFFFFD166,
            ),
          );
        }
      }
    }

    for (final hero in companionCooldowns.keys.toList()) {
      companionCooldowns[hero] = (companionCooldowns[hero]! - dt);
      final cond = preset.companionConditions[hero] ?? hero.defaultCondition;
      final canCastHero = switch (hero) {
        CompanionHero.jeonggak => launchers.any((e) => !e.isConstructing) && mutants.isNotEmpty,
        CompanionHero.sinseung => shieldHp < shieldMaxHpDynamic * 0.95 ||
            cropsHealth < 0.96 ||
            livestockHealth < 0.96 ||
            granaryHealth < 0.96,
        _ => hasTargetInAllyRange,
      };
      final qiRechargeHeroReady = (hero == CompanionHero.cheongmyeong ||
              hero == CompanionHero.chwiseon) &&
          cond == AutoTriggerCondition.qiFullBurst &&
          qiBars < 1.5 &&
          hasTargetInAllyRange;
      if (companionCooldowns[hero]! <= 0 &&
          canCastHero &&
          (qiRechargeHeroReady ||
              _checkConditionMet(
                cond,
                allowWithoutEnemies: hero == CompanionHero.sinseung,
                maxRange: allyMaxR,
              ))) {
        companionCooldowns[hero] = hero.cooldownSec * cdFactor;
        _executeCompanionSkill(hero, progress.companionLevels[hero] ?? 1, triggerCond: cond);
      }
    }

    // 동료 묵현 위기 난입: 26초 재사용 대기로 장기전·무한혈전에서도 결계 위기마다 든든히 재개입!
    if (mukhyeonCooldownTimer <= 0 &&
        (launchers.isNotEmpty || elapsedSec >= 6.0) &&
        (progress.companionLevels[CompanionHero.mukhyeon] ?? 0) > 0 &&
        shieldHp <= shieldMaxHpDynamic * 0.35 &&
        mutants.isNotEmpty) {
      mukhyeonTriggered = true;
      mukhyeonCooldownTimer = 26.0 * cdFactor.clamp(0.45, 1.0);
      final mukLv =
          (progress.companionLevels[CompanionHero.mukhyeon] ?? 1).clamp(1, progress.maxAllyLevel);
      shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * 0.25);
      callouts.add(
        FloatingCallout(
          pos: shieldCenter + const Vec2(-40, -85),
          text: '⚔️ 묵현 긴급 난입(Lv.$mukLv)! "그 마을을 무너뜨리게 두진 않겠다!"',
          colorHex: 0xFFC77DFF,
          isBigBanner: true,
        ),
      );
      for (final m in List<ActiveMutant>.from(mutants)) {
        if (m.pos.distanceTo(shieldCenter) <= 520.0) {
          final rawDir = m.pos - shieldCenter;
          final outDir = rawDir.length > 1e-3 ? rawDir.normalized : const Vec2(0, -1);
          _applyDamageToMutant(
            m,
            centralSpec.baseDamage *
                4.5 *
                progress.realm.powerMult *
                (1.0 + progress.meridianLauncherDmgBonus) *
                (1.0 + (mukLv - 1) * 0.24),
            sourceKey: 'hero_mukhyeon',
            sourceLabel: '동료 묵현 (위기 난입)',
            knockDir: outDir,
            knockForce: 155,
            isCritical: true,
            fullArmorIgnore: true,
          );
        }
      }
    }
  }

  bool _checkConditionMet(
    AutoTriggerCondition cond, {
    bool allowWithoutEnemies = false,
    double maxRange = 9999.0,
  }) {
    if (mutants.isEmpty && !allowWithoutEnemies) return false;
    switch (cond) {
      case AutoTriggerCondition.anyEnemyInRange:
        return allowWithoutEnemies ||
            mutants.any(
              (m) => m.phaseTransitionTimer <= 0 && m.pos.distanceTo(shieldCenter) <= maxRange,
            );
      case AutoTriggerCondition.denseCluster:
        return mutants.any(
          (m) =>
              m.phaseTransitionTimer <= 0 &&
              m.pos.distanceTo(shieldCenter) <= maxRange &&
              _countMutantsNear(m.pos, 155.0) >= 4,
        );
      case AutoTriggerCondition.heavyOrBoss:
        return mutants.any(
          (m) =>
              m.phaseTransitionTimer <= 0 &&
              m.pos.distanceTo(shieldCenter) <= maxRange &&
              (m.kind.isBoss ||
                  m.kind == MutantKind.ironBoar ||
                  m.kind == MutantKind.shieldYacha),
        );
      case AutoTriggerCondition.shieldCrisis:
        return shieldHp <= shieldMaxHpDynamic * 0.60;
      case AutoTriggerCondition.qiFullBurst:
        return qiBars >= 2.95 || _qiBurstSynergyTimer > 0;
    }
  }

  ActiveMutant? _pickConditionMatchedTarget(
    AutoTriggerCondition? cond,
    double maxRange,
  ) {
    if (cond == AutoTriggerCondition.denseCluster) {
      ActiveMutant? bestCluster;
      int bestCount = 0;
      for (final m in mutants) {
        if (m.phaseTransitionTimer > 0 || m.pos.distanceTo(shieldCenter) > maxRange) continue;
        final cnt = _countMutantsNear(m.pos, 155.0);
        if (cnt > bestCount) {
          bestCount = cnt;
          bestCluster = m;
        }
      }
      if (bestCluster != null && bestCount >= 3) return bestCluster;
    } else if (cond == AutoTriggerCondition.heavyOrBoss) {
      ActiveMutant? bestHeavy;
      double bestDist = 999999;
      for (final m in mutants) {
        if (m.phaseTransitionTimer > 0 || m.pos.distanceTo(shieldCenter) > maxRange) continue;
        if (m.kind.isBoss || m.kind == MutantKind.ironBoar || m.kind == MutantKind.shieldYacha) {
          final d = m.pos.distanceTo(shieldCenter);
          if (d < bestDist) {
            bestDist = d;
            bestHeavy = m;
          }
        }
      }
      if (bestHeavy != null) return bestHeavy;
    }
    return _pickMostThreateningMutant(shieldCenter, maxRange: maxRange);
  }

  void _executeSpiritBeast(SpiritBeast beast, int lv) {
    final allyMaxR = (278.0 * liveRangeMultiplier).clamp(268.0, 385.0);
    final target = _pickConditionMatchedTarget(preset.beastCondition, allyMaxR);
    if (target == null && beast != SpiritBeast.geumgangTurtle) return;
    _spawnShockwaveRing(
      shieldCenter,
      maxRadius: 82.0,
      colorHex: 0xFF72EFDD,
      secondaryColorHex: 0xFFFFD166,
      style: 'skillUltimate',
      durationSec: 0.36,
    );
    final allyMult = (1.0 + perkStacks(RoguePerk.allyAwakening) * 0.45) *
        (1.0 + progress.elixirResonanceBonus) *
        (1.0 + progress.meridianLauncherDmgBonus) *
        formationResonanceScale;
    final power =
        centralSpec.baseDamage * (1.55 + lv * 0.22) * progress.realm.powerMult * allyMult;

    switch (beast) {
      case SpiritBeast.nalssaendol:
        _spawnStoneShot(
          sourceKey: 'beast_nalssaendol',
          sourceLabel: '영수 날쌘돌',
          origin: shieldCenter + const Vec2(-36, -12),
          target: target!,
          baseDamage: power,
          speed: 375,
          maxTravelDist: allyMaxR * 1.15,
        );
        break;
      case SpiritBeast.geumgangTurtle:
        final healDamp = stage.isReincarnationBossStage ? 0.36 : 1.0;
        final turtleHeal = shieldMaxHpDynamic * min(0.55, 0.16 + lv * 0.015) * healDamp;
        shieldHp = min(
          shieldMaxHpDynamic,
          shieldHp > 0 ? (shieldHp + turtleHeal) : (turtleHeal * 0.70),
        );
        final turtleContrib = _contribMap.putIfAbsent(
          'beast_geumgang',
          () => ContributionEntry(key: 'beast_geumgang', label: '영수 금강 (결계 수호)'),
        );
        turtleContrib.totalDamage += turtleHeal;
        pendingSounds.add(SoundCue.shieldWave);
        for (final m in List<ActiveMutant>.from(mutants)) {
          if (m.pos.distanceTo(shieldCenter) < 195) {
            final rawDir = m.pos - shieldCenter;
            final pushDir = rawDir.length > 1e-3 ? rawDir.normalized : const Vec2(0, -1);
            _applyDamageToMutant(
              m,
              power * 0.65,
              sourceKey: 'beast_geumgang',
              sourceLabel: '영수 금강 (현무 파동)',
              knockDir: pushDir,
              knockForce: 165.0,
              isCritical: false,
            );
          }
        }
        break;
      case SpiritBeast.cheonghak:
        cheonghakBuffTimer = min(10.0, 5.0 + lv * 0.25);
        _spawnStoneShot(
          sourceKey: 'beast_cheonghak',
          sourceLabel: '영수 청학',
          origin: shieldCenter + const Vec2(36, -12),
          target: target!,
          baseDamage: power * 1.2,
          speed: 410,
          pierceBonus: 2,
          ignoresShield: true,
          maxTravelDist: allyMaxR * 1.15,
        );
        break;
      case SpiritBeast.baekho:
        for (final offset in [-12.0, 12.0]) {
          _spawnStoneShot(
            sourceKey: 'beast_baekho',
            sourceLabel: '영수 백호',
            origin: shieldCenter + Vec2(offset, -16),
            target: target!,
            baseDamage: power * 1.35,
            speed: 395,
            knockbackScale: 1.85,
            aoeRadius: 56,
            homingTargetUid: offset < 0 ? target.uid : null,
            maxTravelDist: allyMaxR * 1.30,
          );
        }
        break;
      case SpiritBeast.geumryong:
        final inRange = mutants
            .where((m) => m.pos.distanceTo(shieldCenter) <= allyMaxR)
            .toList();
        final pool = inRange.isNotEmpty ? inRange : <ActiveMutant>[target!];
        const execRatio = 0.55;
        int executed = 0;
        for (final cand in List<ActiveMutant>.from(inRange)) {
          if (!cand.kind.isBoss &&
              cand.phaseTransitionTimer <= 0 &&
              cand.hp <= cand.currentMaxHp * execRatio &&
              executed < 3) {
            executed++;
            final rawDir = cand.pos - shieldCenter;
            _applyDamageToMutant(
              cand,
              cand.hp + 999.0,
              sourceKey: 'beast_geumryong',
              sourceLabel: '영수 금룡 (천룡 즉결)',
              knockDir: rawDir.length > 1e-3 ? rawDir.normalized : const Vec2(0, -1),
              knockForce: 190.0,
              isCritical: true,
              fullArmorIgnore: true,
            );
          }
        }
        for (int i = 0; i < 4; i++) {
          final livePool = pool.where((m) => mutants.contains(m)).toList();
          final tgt = livePool.isNotEmpty ? livePool[i % livePool.length] : pool[i % pool.length];
          _spawnStoneShot(
            sourceKey: 'beast_geumryong',
            sourceLabel: '영수 금룡',
            origin: shieldCenter + Vec2((i - 1.5) * 18, -20),
            target: tgt,
            baseDamage: power * 1.55,
            speed: 395,
            pierceBonus: 2,
            aoeRadius: 50,
            ignoresShield: true,
            executesLowHpNormal: true,
            maxTravelDist: allyMaxR * 1.18,
          );
        }
        break;
    }
  }

  void _executeCompanionSkill(
    CompanionHero hero,
    int lv, {
    AutoTriggerCondition? triggerCond,
  }) {
    final allyMaxR = (278.0 * liveRangeMultiplier).clamp(268.0, 385.0);
    final target = _pickConditionMatchedTarget(triggerCond, allyMaxR);
    final isBuffOnly = hero == CompanionHero.jeonggak || hero == CompanionHero.sinseung;
    if (target == null && !isBuffOnly) return;
    final allyMult = (1.0 + perkStacks(RoguePerk.allyAwakening) * 0.45) *
        (1.0 + progress.elixirResonanceBonus) *
        (1.0 + progress.meridianLauncherDmgBonus) *
        formationResonanceScale;
    final baseDmg =
        centralSpec.baseDamage * (1.50 + lv * 0.20) * progress.realm.powerMult * allyMult;
    final key = 'hero_${hero.id}';
    final label = '동료 ${hero.name}';

    switch (hero) {
      case CompanionHero.seokdu:
        final heavyTgt = mutants
                .where(
                  (m) =>
                      (m.kind.isBoss || m.kind == MutantKind.ironBoar) &&
                      m.pos.distanceTo(shieldCenter) <= allyMaxR,
                )
                .firstOrNull ??
            target!;
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: shieldCenter + const Vec2(-48, 0),
          target: heavyTgt,
          baseDamage: baseDmg * 1.45,
          speed: 315,
          knockbackScale: 2.1,
          ignoresShield: true,
          maxTravelDist: allyMaxR * 1.16,
        );
        break;
      case CompanionHero.yeonbi:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: shieldCenter + const Vec2(48, 0),
          target: target!,
          baseDamage: baseDmg * 1.25,
          speed: 350,
          spinCurve: 1.6,
          pierceBonus: 2,
          ignoresShield: true,
          maxTravelDist: allyMaxR * 1.16,
        );
        break;
      case CompanionHero.cheongmyeong:
        qiBars = (qiBars + min(1.85, 0.65 + lv * 0.04)).clamp(0.0, maxQiBars);
        // 마기 침식된 아군 초소 1기 즉시 정화!
        for (final l in launchers) {
          if (l.isCorrupted) {
            cleanseLauncherAtSlot(l.slotIndex);
            break;
          }
        }
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: shieldCenter,
          target: target!,
          baseDamage: baseDmg * 1.15,
          speed: 360,
          homingTargetUid: target.uid,
          maxTravelDist: allyMaxR * 1.18,
        );
        break;
      case CompanionHero.bandal:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: shieldCenter + const Vec2(-32, -8),
          target: target!,
          baseDamage: baseDmg * 1.20,
          speed: 365,
          aoeRadius: 72,
          oilsOnHit: true,
          maxTravelDist: allyMaxR * 1.32,
        );
        break;
      case CompanionHero.gurumi:
        final originGurumi = shieldCenter + const Vec2(32, -8);
        TerrainPillar? nearPillar;
        double bestPD = allyMaxR * 1.12;
        for (final pil in chapter.pillars) {
          final pd = pil.center.distanceTo(originGurumi);
          if (pd <= bestPD) {
            bestPD = pd;
            nearPillar = pil;
          }
        }
        if (nearPillar != null) {
          // 지형 기둥을 정확히 조준해 어부지리 도탄 2연타 유도!
          final aimPillar = ActiveMutant(
            uid: -9901,
            kind: MutantKind.swarmRat,
            laneIndex: 0,
            waypoints: <Vec2>[nearPillar.center],
            pos: nearPillar.center,
            maxHp: 1.0,
            speed: 0.0,
            lateralSeed: 0.0,
          );
          for (final spread in [-0.08, 0.08]) {
            _spawnStoneShot(
              sourceKey: key,
              sourceLabel: label,
              origin: originGurumi,
              target: aimPillar,
              baseDamage: baseDmg * 1.05,
              speed: 410,
              spreadAngleRad: spread,
              extraBouncesBonus: 3,
              maxTravelDist: allyMaxR * 1.38,
            );
          }
        } else {
          for (final spread in [-0.24, 0.24]) {
            _spawnStoneShot(
              sourceKey: key,
              sourceLabel: label,
              origin: originGurumi,
              target: target!,
              baseDamage: baseDmg * 0.98,
              speed: 385,
              spreadAngleRad: spread,
              extraBouncesBonus: 3,
              maxTravelDist: allyMaxR * 1.25,
            );
          }
        }
        break;
      case CompanionHero.jeonggak:
        _jeonggakHasteMult =
            (1.38 + lv * 0.03 + progress.elixirResonanceBonus * 0.20).clamp(1.40, 2.05);
        jeonggakHasteTimer = min(9.5, 4.5 + lv * 0.32);
        final jeongEntry = _contribMap.putIfAbsent(
          key,
          () => ContributionEntry(key: key, label: '$label (기관 가속)'),
        );
        jeongEntry.totalDamage += centralSpec.baseDamage * 1.2 * lv;
        callouts.add(
          FloatingCallout(
            pos: shieldCenter + const Vec2(0, -40),
            text: '⚙️ 정각 기관 가속! 전 발사대 연사 ${_jeonggakHasteMult.toStringAsFixed(2)}배!',
            colorHex: 0xFF90E0EF,
          ),
        );
        break;
      case CompanionHero.yonga:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: shieldCenter,
          target: target!,
          baseDamage: baseDmg * 1.60,
          speed: 390,
          pierceBonus: 3,
          aoeRadius: 44,
          maxTravelDist: allyMaxR * 1.16,
        );
        break;
      case CompanionHero.chwiseon:
        qiBars = (qiBars + min(2.40, 1.05 + lv * 0.06)).clamp(0.0, maxQiBars);
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: shieldCenter,
          target: target!,
          baseDamage: baseDmg * 1.25,
          speed: 345,
          spinCurve: -1.5,
          maxTravelDist: allyMaxR * 1.15,
        );
        break;
      case CompanionHero.mukgaek:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: shieldCenter,
          target: target!,
          baseDamage: baseDmg * 1.25,
          speed: 335,
          aoeRadius: 68,
          knockbackScale: 1.85,
          slowsOnHit: true,
          maxTravelDist: allyMaxR * 1.15,
        );
        break;
      case CompanionHero.seolhwa:
        seolhwaFrostShieldTimer = 4.5;
        if (shieldHp > 0) {
          shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * 0.10);
        }
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: shieldCenter,
          target: target!,
          baseDamage: baseDmg * 1.30,
          speed: 345,
          aoeRadius: 72,
          freezesOnHit: true,
          freezeDurationOverride: 1.65,
          maxTravelDist: allyMaxR * 1.15,
        );
        break;
      case CompanionHero.magyo:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: shieldCenter,
          target: target!,
          baseDamage: baseDmg * 1.45,
          speed: 335,
          aoeRadius: 76,
          pullsEnemies: true,
          maxTravelDist: allyMaxR * 1.15,
        );
        break;
      case CompanionHero.geomhwang:
        final inRange = mutants
            .where((m) => m.phaseTransitionTimer <= 0 && m.pos.distanceTo(shieldCenter) <= allyMaxR)
            .toList()
          ..sort((a, b) {
            final prioA = (a.kind.isBoss ? 2 : 0) + (a.kind.poisonAura ? 1 : 0);
            final prioB = (b.kind.isBoss ? 2 : 0) + (b.kind.poisonAura ? 1 : 0);
            if (prioA != prioB) return prioB.compareTo(prioA);
            return a.pos.distanceTo(shieldCenter).compareTo(b.pos.distanceTo(shieldCenter));
          });
        final pool = inRange.isNotEmpty ? inRange : <ActiveMutant>[target!];
        for (int i = 0; i < 3; i++) {
          final tgt = pool[i % pool.length];
          _spawnStoneShot(
            sourceKey: key,
            sourceLabel: label,
            origin: shieldCenter + Vec2((i - 1) * 16.0, -10),
            target: tgt,
            baseDamage: baseDmg * 0.95,
            speed: 415,
            extraCrit: 1.0,
            ignoresShield: true,
            homingTargetUid: tgt.uid,
            maxTravelDist: allyMaxR * 1.22,
          );
        }
        break;
      case CompanionHero.sinseung:
        final resonanceScale = 1.0 + progress.elixirResonanceBonus * 0.35;
        final healDamp = stage.isReincarnationBossStage ? 0.36 : 1.0;
        final shieldHealRatio = min(0.62, (0.18 + lv * 0.016) * resonanceScale) * healDamp;
        final ecoHeal = min(0.75, 0.24 + lv * 0.024);
        final healedAmt = shieldMaxHpDynamic * shieldHealRatio;
        if (shieldHp > 0) {
          shieldHp = min(shieldMaxHpDynamic, shieldHp + healedAmt);
        } else {
          shieldHp = min(shieldMaxHpDynamic, healedAmt * 0.65);
        }
        granaryHealth = min(1.0, granaryHealth + ecoHeal);
        cropsHealth = min(1.0, cropsHealth + ecoHeal);
        livestockHealth = min(1.0, livestockHealth + ecoHeal);
        _syncVillagePurification();
        final sinEntry = _contribMap.putIfAbsent(
          key,
          () => ContributionEntry(key: key, label: '$label (생기 정화)'),
        );
        sinEntry.totalDamage += healedAmt;
        pendingSounds.add(SoundCue.shieldWave);
        break;
      case CompanionHero.mukhyeon:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: '$label (흑검 정화참)',
          origin: shieldCenter + const Vec2(0, -16),
          target: target!,
          baseDamage: baseDmg * 1.55,
          speed: 425,
          pierceBonus: 4,
          aoeRadius: 48,
          ignoresShield: true,
          sectTech: SectTechnique.swordQi,
          maxTravelDist: allyMaxR * 1.18,
        );
        break;
    }
  }

  void _stepSupportAutoTrigger() {
    // 초소를 단 1곳도 짓지 않고 방치할 때는 지원패가 저절로 소비·발동되지 않음!
    if (!launchers.any((e) => !e.isConstructing) ||
        !allowSupportTokens ||
        supportChargesLeft <= 0 ||
        _autoChulduCooldown > 0 ||
        mutants.isEmpty) {
      return;
    }
    final shieldRatio = shieldMaxHpDynamic > 0 ? shieldHp / shieldMaxHpDynamic : 0.0;
    if (shieldRatio <= preset.supportTriggerShieldRatio) {
      if (triggerSupportChuldu()) {
        _autoChulduCooldown = 3.5;
      }
    }
  }

  void _spawnStoneShot({
    required String sourceKey,
    required String sourceLabel,
    required Vec2 origin,
    required ActiveMutant target,
    required double baseDamage,
    required double speed,
    double spreadAngleRad = 0.0,
    double extraCrit = 0.0,
    double spinCurve = 0.0,
    int pierceBonus = 0,
    double aoeRadius = 0.0,
    bool pullsEnemies = false,
    bool freezesOnHit = false,
    bool slowsOnHit = false,
    bool oilsOnHit = false,
    bool ignoresShield = false,
    double knockbackScale = 1.0,
    SectTechnique? sectTech,
    double maxTravelDist = 335.0,
    bool fromWeakCrackerMount = false,
    String projectileStyle = 'stoneDefault',
    double? freezeDurationOverride,
    int extraBouncesBonus = 0,
    int? homingTargetUid,
    bool executesLowHpNormal = false,
    bool? preRolledSerendipity,
  }) {
    if (projectiles.length >= 180) {
      projectiles.removeAt(0);
    }

    final stone = preset.primaryStone;
    final shape = preset.primaryShape;
    final boulderStacks = perkStacks(RoguePerk.giantBoulder);
    final ricochetStacks = perkStacks(RoguePerk.ricochetMaster);
    final frostStacks = perkStacks(RoguePerk.frostNova);
    final armorBreakStacks = perkStacks(RoguePerk.armorBreaker);
    final ch2SpeedBoost = chapter.number == 2 ? 1.15 : 1.0;
    final ch5ExtraBounce = chapter.number == 5 ? 2 : 0;
    final ch8KnockBoost = chapter.number == 8 ? 1.38 : 1.0;

    final finalSpeed = speed *
        ch2SpeedBoost *
        shape.speedFactor *
        (cheonghakBuffTimer > 0 ? 1.20 : 1.0) *
        (stone == StoneMaterial.manyeonGiju ? 1.18 : 1.0);
    final tof = (target.pos.distanceTo(origin) / max(180.0, finalSpeed)).clamp(0.02, 0.45);
    final leadScale = (0.72 + progress.corePrecisionBonus * 1.1).clamp(0.72, 1.18);
    final nextWp = target.waypoints[target.waypointIndex.clamp(0, target.waypoints.length - 1)];
    final moveVel = target.smoothVel.length > 4.0
        ? target.smoothVel
        : (nextWp - target.pos).normalized * target.speed;
    final predictedPos = target.pos + moveVel * (tof * leadScale);

    final rawDir = (predictedPos - origin).normalized;
    final baseAngle = atan2(rawDir.y, rawDir.x) + spreadAngleRad;
    final vel = Vec2(cos(baseAngle) * finalSpeed, sin(baseAngle) * finalSpeed);

    final isCritSerendipity = preRolledSerendipity ??
        (allowSerendipity &&
            rng.nextDouble() < (0.07 + progress.meridianSerendipityBonus * 0.5));
    if (preRolledSerendipity == null && isCritSerendipity) {
      serendipityCount++;
    }

    int pierce = pierceBonus +
        (stone == StoneMaterial.geumgang ? 1 : 0) +
        (stone == StoneMaterial.banseok ? 1 : 0);
    double splash = aoeRadius +
        (stone == StoneMaterial.obsidian ? 32.0 : 0.0) +
        (stone == StoneMaterial.uncheol ? 38.0 : 0.0) +
        (stone == StoneMaterial.yongrin ? 34.0 : 0.0);
    double curve = spinCurve * shape.spinCurveFactor;
    bool bypassShield = ignoresShield || stone == StoneMaterial.jageum || armorBreakStacks > 0;

    String resolvedStyle = projectileStyle;
    if (sectTech == SectTechnique.swordQi) {
      pierce += 3;
      if (projectileStyle == 'stoneDefault') resolvedStyle = 'sectSword';
    }
    if (sectTech == SectTechnique.ironFist) {
      splash = max(splash, 58.0);
      if (projectileStyle == 'stoneDefault') resolvedStyle = 'sectFist';
    }
    if (sectTech == SectTechnique.taiji) {
      curve = curve == 0 ? 1.35 : curve * 1.4;
      bypassShield = true;
      qiBars = (qiBars + 0.25 * (chapter.number == 10 ? 1.30 : 1.0)).clamp(0.0, maxQiBars);
      if (projectileStyle == 'stoneDefault') resolvedStyle = 'sectTaiji';
    }

    final liveDmgBoost = (1.0 + liveFirepowerLv * 0.15) * powerTarget.damageMultiplier;
    final finalDamage =
        baseDamage * liveDmgBoost * stone.damageMultiplier * (isCritSerendipity ? 1.38 : 1.0);
    final finalKnock = 46.0 *
        ch8KnockBoost *
        stone.knockbackMultiplier *
        shape.knockbackFactor *
        knockbackScale *
        (1.0 + boulderStacks * 0.55) *
        (1.0 + progress.meridianKnockbackBonus) *
        (stone == StoneMaterial.uncheol ? 1.25 : 1.0) *
        (stone == StoneMaterial.yongrin ? 1.35 : 1.0);
    final critChance = extraCrit >= 0.99
        ? 1.0
        : (0.10 +
                shape.critBonus +
                progress.meridianCritBonus +
                extraCrit +
                (feverTimer > 0 ? 0.35 : 0.0) +
                (cheonghakBuffTimer > 0 ? 0.10 : 0.0) +
                (stone == StoneMaterial.geumgang ? 0.08 : 0.0))
            .clamp(0.05, 0.88);
    final radiusScale =
        (1.0 + boulderStacks * 0.38).clamp(1.0, 2.0) * (feverTimer > 0 ? 1.16 : 1.0);
    final baseRadius = resolvedStyle == 'heavyMeteor'
        ? 11.8
        : (resolvedStyle == 'curveChakram' ? 10.2 : 8.5);
    final shotColor = (isCritSerendipity || feverTimer > 0)
        ? 0xFFFFD166
        : switch (resolvedStyle) {
            'rapidBolt' => 0xFF72EFDD,
            'heavyMeteor' => 0xFFFF6B35,
            'curveChakram' => 0xFF52B788,
            'frostCrystal' => 0xFF90E0EF,
            'qiBagua' => 0xFFC77DFF,
            'sectSword' => 0xFF4CC9F0,
            'sectFist' => 0xFFFF9F1C,
            'sectTaiji' => 0xFFE0AAFF,
            'eogiUltimate' => 0xFFFFD166,
            _ => stone.colorHex,
          };

    projectiles.add(
      ActiveStoneProjectile(
        sourceKey: sourceKey,
        sourceLabel: sourceLabel,
        pos: origin,
        vel: vel,
        material: stone,
        shape: shape,
        damage: finalDamage,
        knockback: finalKnock,
        critChance: critChance,
        colorHex: shotColor,
        radius: (isCritSerendipity ? 13.8 : baseRadius) * radiusScale,
        spinCurve: curve,
        pierceLeft: pierce,
        aoeSplashRadius: splash,
        pullsEnemies: pullsEnemies,
        freezesOnHit: freezesOnHit || stone == StoneMaterial.hancheol || frostStacks > 0,
        slowsOnHit: slowsOnHit || stone == StoneMaterial.banseok || stone == StoneMaterial.bingbaek,
        oilsOnHit: oilsOnHit,
        ignoresShield: bypassShield,
        isGiantCritSerendipity: isCritSerendipity,
        extraBounces: ch5ExtraBounce + ricochetStacks * 2 + extraBouncesBonus,
        maxTravelDist: maxTravelDist,
        fromWeakCrackerMount: fromWeakCrackerMount,
        projectileStyle: resolvedStyle,
        freezeDurationOverride: freezeDurationOverride,
        homingTargetUid: homingTargetUid,
        executesLowHpNormal: executesLowHpNormal,
        splitsShadowOnHit: sectTech == SectTechnique.shadowClone,
      ),
    );
    // 영월살문 분신 쌍영탄은 명중 순간에 2갈래로 분열된다(발사 시 중복 분신 생성 제거).
  }

  static double _distSegmentToPoint(Vec2 a, Vec2 b, Vec2 p) {
    final ab = b - a;
    final lenSq = ab.x * ab.x + ab.y * ab.y;
    if (lenSq <= 1e-6) return a.distanceTo(p);
    final ap = p - a;
    final t = ((ap.x * ab.x + ap.y * ab.y) / lenSq).clamp(0.0, 1.0);
    final closest = Vec2(a.x + ab.x * t, a.y + ab.y * t);
    return closest.distanceTo(p);
  }

  /// 선분 [a, b]와 중심 center · 반경 r 원의 최초 충돌 시각 t ∈ [0.0, 1.0] 반환 (비충돌 시 null).
  static double? _segmentCircleHitParam(Vec2 a, Vec2 b, Vec2 center, double r) {
    if (a.distanceTo(center) <= r) return 0.0;
    final d = b - a;
    final aCoeff = d.x * d.x + d.y * d.y;
    if (aCoeff <= 1e-8) return null;
    final f = a - center;
    final bCoeff = 2.0 * (f.x * d.x + f.y * d.y);
    final cCoeff = (f.x * f.x + f.y * f.y) - r * r;
    final disc = bCoeff * bCoeff - 4.0 * aCoeff * cCoeff;
    if (disc < 0) return null;
    final root = sqrt(disc);
    final t1 = (-bCoeff - root) / (2.0 * aCoeff);
    if (t1 >= 0.0 && t1 <= 1.0) return t1;
    final t2 = (-bCoeff + root) / (2.0 * aCoeff);
    if (t2 >= 0.0 && t2 <= 1.0) return 0.0;
    return null;
  }

  /// 회전 정다각형 기둥의 실제 N개 변에 대한 최단 수직 거리·접점·외향 법선 정밀 산출!
  static (Vec2 closestPt, Vec2 normal, double dist) _closestPointOnRotatedPolygon(
    TerrainPillar pillar,
    double angleOffset,
    Vec2 pt,
  ) {
    final nSides = pillar.sides.clamp(3, 12);
    final verts = List<Vec2>.generate(nSides, (k) {
      final th = angleOffset + (2.0 * pi * k / nSides);
      return Vec2(
        pillar.center.x + cos(th) * pillar.radius,
        pillar.center.y + sin(th) * pillar.radius,
      );
    });
    Vec2 bestClosest = verts.first;
    Vec2 bestNormal = const Vec2(0, -1);
    double minDist = double.infinity;
    bool insideAll = true;

    for (int k = 0; k < nSides; k++) {
      final v0 = verts[k];
      final v1 = verts[(k + 1) % nSides];
      final midAngle = angleOffset + ((k + 0.5) * 2.0 * pi / nSides);
      final faceNormal = Vec2(cos(midAngle), sin(midAngle));
      final relToV0 = pt - v0;
      if (relToV0.x * faceNormal.x + relToV0.y * faceNormal.y > 0) {
        insideAll = false;
      }
      final edge = v1 - v0;
      final edgeLenSq = edge.x * edge.x + edge.y * edge.y;
      final t = edgeLenSq > 1e-6
          ? ((relToV0.x * edge.x + relToV0.y * edge.y) / edgeLenSq).clamp(0.0, 1.0)
          : 0.0;
      final candClosest = Vec2(v0.x + edge.x * t, v0.y + edge.y * t);
      final d = candClosest.distanceTo(pt);
      if (d < minDist) {
        minDist = d;
        bestClosest = candClosest;
        bestNormal = faceNormal;
      }
    }

    if (insideAll) {
      return (bestClosest, bestNormal, 0.0);
    }
    return (bestClosest, bestNormal, minDist);
  }

  void _stepProjectiles(double dt) {
    final spawnedClones = <ActiveStoneProjectile>[];

    for (int i = projectiles.length - 1; i >= 0; i--) {
      final p = projectiles[i];
      p.lifeSec -= dt;
      if (p.lifeSec <= 0) {
        projectiles.removeAt(i);
        continue;
      }

      final remMaxDist = p.maxTravelDist - p.traveledDist;
      if (remMaxDist <= 1e-4) {
        projectiles.removeAt(i);
        continue;
      }

      if (p.trail.length >= 9) p.trail.removeAt(0);
      p.trail.add(p.pos);

      // 정밀 파갑탄(약점 추적) · 검황/청명 유도탄(타깃 사망 시 생존 보스·독오라·근접 표적 즉시 재획득!) · 태극 유인 궤적 유도!
      if (p.isPrecisionShot && p.lockedWeakBossUid != null) {
        for (final bm in mutants) {
          if (bm.uid == p.lockedWeakBossUid && bm.phaseTransitionTimer <= 0) {
            final toWeak = bm.weakSpotWorldPos - p.pos;
            if (toWeak.length > 2.0) {
              p.vel = toWeak.normalized * p.vel.length;
            }
            break;
          }
        }
      } else if (p.homingTargetUid != null) {
        ActiveMutant? liveHoming;
        for (final hm in mutants) {
          if (hm.uid == p.homingTargetUid && hm.phaseTransitionTimer <= 0) {
            liveHoming = hm;
            break;
          }
        }
        if (liveHoming == null && mutants.isNotEmpty) {
          double bestScore = -999999;
          for (final cand in mutants) {
            if (cand.phaseTransitionTimer > 0 || p.hitMutantIds.contains(cand.uid)) continue;
            final d = cand.pos.distanceTo(p.pos);
            if (d > 260.0) continue;
            final s = (cand.kind.isBoss ? 500.0 : 0.0) +
                (cand.kind.poisonAura ? 220.0 : 0.0) -
                d;
            if (s > bestScore) {
              bestScore = s;
              liveHoming = cand;
            }
          }
          p.homingTargetUid = liveHoming?.uid;
        }
        if (liveHoming != null) {
          final desired = (liveHoming.pos - p.pos).normalized * p.vel.length;
          final blend = min(1.0, dt * 10.5);
          p.vel = Vec2(
            p.vel.x + (desired.x - p.vel.x) * blend,
            p.vel.y + (desired.y - p.vel.y) * blend,
          ).normalized *
              p.vel.length;
        }
      } else if (p.projectileStyle == 'sectTaiji' && mutants.isNotEmpty) {
        ActiveMutant? nearTgt;
        double nearD = 185.0;
        for (final cand in mutants) {
          if (cand.phaseTransitionTimer > 0 || p.hitMutantIds.contains(cand.uid)) continue;
          final d = cand.pos.distanceTo(p.pos);
          if (d < nearD) {
            nearD = d;
            nearTgt = cand;
          }
        }
        if (nearTgt != null) {
          final desired = (nearTgt.pos - p.pos).normalized * p.vel.length;
          final blend = min(1.0, dt * 5.2);
          p.vel = Vec2(
            p.vel.x + (desired.x - p.vel.x) * blend,
            p.vel.y + (desired.y - p.vel.y) * blend,
          ).normalized *
              p.vel.length;
        } else if (p.spinCurve.abs() > 0.05) {
          final perp = Vec2(-p.vel.y, p.vel.x).normalized;
          p.vel = p.vel + perp * (p.spinCurve * 95.0 * dt);
        }
      } else if (p.spinCurve.abs() > 0.05) {
        final perp = Vec2(-p.vel.y, p.vel.x).normalized;
        p.vel = p.vel + perp * (p.spinCurve * 95.0 * dt);
      }

      // 남은 최대 사거리만큼 이동 벡터를 먼저 클램프하고 충돌 검사를 끝낸 뒤 소멸 판정!
      final prevPos = p.pos;
      final rawStep = p.vel * dt;
      final rawLen = rawStep.length;
      final clampedStep =
          (rawLen > remMaxDist && rawLen > 1e-6) ? rawStep * (remMaxDist / rawLen) : rawStep;
      Vec2 nextPos = prevPos + clampedStep;
      p.traveledDist += clampedStep.length;

      // 0) 장벽·회전 정다각형 기둥 선행 Swept 차단 & 반사 도탄 분할 (기둥 뒤 기물·적 오폭 원천 차단!)
      bool stoppedByObstacle = false;
      bool outOfBounds = false;
      final segments = <(Vec2, Vec2)>[];

      Vec2 curStart = prevPos;
      Vec2 curEnd = nextPos;

      if (!p.isPrecisionShot && chapter.pillars.isNotEmpty) {
        for (int pIdx = 0; pIdx < chapter.pillars.length; pIdx++) {
          final pillar = chapter.pillars[pIdx];
          if (_distSegmentToPoint(curStart, curEnd, pillar.center) >
              pillar.radius + p.radius + 4.0) {
            continue;
          }
          final angleOffset = pIdx < pillarAngles.length ? pillarAngles[pIdx] : 0.0;
          double? hitFrac;
          Vec2? hitClosest;
          Vec2? hitNormal;
          for (int sub = 1; sub <= 4; sub++) {
            final s = sub / 4.0;
            final samplePt = curStart + (curEnd - curStart) * s;
            final (closestPt, faceNormal, distEdge) =
                _closestPointOnRotatedPolygon(pillar, angleOffset, samplePt);
            final dotIn = p.vel.x * faceNormal.x + p.vel.y * faceNormal.y;
            if (distEdge <= p.radius && dotIn < 0) {
              hitFrac = s;
              hitClosest = closestPt;
              hitNormal = faceNormal;
              break;
            }
          }
          if (hitFrac != null && hitClosest != null && hitNormal != null) {
            final bouncePt = hitClosest + hitNormal * (p.radius + 1.5);
            segments.add((curStart, bouncePt));
            if (p.bouncesLeft <= 0) {
              p.pos = bouncePt;
              bursts.add(FxBurst(pos: bouncePt, colorHex: 0xFFFFD166, maxRadius: 16));
              stoppedByObstacle = true;
            } else {
              final dot = p.vel.x * hitNormal.x + p.vel.y * hitNormal.y;
              final reflected = (p.vel - hitNormal * (2.0 * dot)).normalized;
              final matBounce = 0.62 + p.material.restitution * 0.36;
              final newSpd = min(680.0, p.vel.length * pillar.restitutionBoost * matBounce);
              p.vel = reflected * newSpd;
              p.bouncesLeft--;
              p.bouncedOffObstacle = true;
              p.ignoresShield = true;
              p.maxTravelDist = max(p.maxTravelDist, min(485.0, p.maxTravelDist + 56.0));
              bursts.add(FxBurst(pos: bouncePt, colorHex: 0xFFFFD166, maxRadius: 22));

              // [비급: 뇌전 연쇄탄] 기둥 도탄 시 주변 변이 최대 3체에 번개 사슬 피해!
              final lightningStacks = perkStacks(RoguePerk.chainLightning);
              if (lightningStacks > 0 && mutants.isNotEmpty) {
                int chained = 0;
                Vec2 chainFrom = bouncePt;
                for (final other in List<ActiveMutant>.from(mutants)) {
                  if (other.phaseTransitionTimer > 0) continue;
                  if (other.pos.distanceTo(chainFrom) <= 125.0) {
                    if (lightningArcs.length < 24) {
                      lightningArcs.add(LightningArcFx(from: chainFrom, to: other.pos));
                    }
                    _applyDamageToMutant(
                      other,
                      p.damage * (0.45 + (lightningStacks - 1) * 0.25),
                      sourceKey: p.sourceKey,
                      sourceLabel: '뇌전 연쇄탄 (기둥 도탄)',
                      knockDir: (other.pos - chainFrom).normalized,
                      knockForce: 26.0,
                      isCritical: false,
                      fullArmorIgnore: true,
                      chainDepth: 2,
                    );
                    chainFrom = other.pos;
                    chained++;
                    if (chained >= 3) break;
                  }
                }
              }

              final remAfterBounce = (1.0 - hitFrac) * clampedStep.length;
              curStart = bouncePt;
              curEnd = bouncePt + reflected * remAfterBounce;
            }
            break;
          }
        }
      }

      if (!stoppedByObstacle) {
        if (curEnd.x < 16.0 || curEnd.x > CampaignCatalog.arenaWidth - 16.0) {
          final wallX = curEnd.x.clamp(16.0, CampaignCatalog.arenaWidth - 16.0);
          final dx = curEnd.x - curStart.x;
          final tWall = dx.abs() > 1e-5 ? ((wallX - curStart.x) / dx).clamp(0.0, 1.0) : 1.0;
          final wallHit = Vec2(wallX, curStart.y + (curEnd.y - curStart.y) * tWall);
          segments.add((curStart, wallHit));
          if (p.bouncesLeft > 0) {
            final keep = p.material.bounceKeep;
            p.vel = Vec2(-p.vel.x * keep, p.vel.y * keep);
            p.bouncesLeft--;
            p.bouncedOffObstacle = true;
            p.ignoresShield = true;
            p.maxTravelDist = max(p.maxTravelDist, min(485.0, p.maxTravelDist + 56.0));
            final remAfterWall = (1.0 - tWall) * curStart.distanceTo(curEnd);
            final postWall = wallHit + p.vel.normalized * remAfterWall;
            segments.add((wallHit, postWall));
            p.pos = postWall;
          } else {
            p.pos = wallHit;
            stoppedByObstacle = true;
          }
        } else {
          segments.add((curStart, curEnd));
          p.pos = curEnd;
        }
      }

      if (p.pos.y < 10.0 || p.pos.y > CampaignCatalog.arenaHeight - 10.0) {
        outOfBounds = true;
      }

      bool consumed = false;
      for (final (segA, segB) in segments) {
        if (consumed) break;

        // 1) ×2→×3 진화 배율 복제 마법진 선분 통과 판정 (유도·즉결·분신·기피격 목록 완전 보존!)
        if (!p.clonedByGate &&
            !p.isPrecisionShot &&
            projectiles.length + spawnedClones.length < 180 &&
            _distSegmentToPoint(segA, segB, cloneGate.center) <=
                cloneGate.radius + p.radius * 0.5) {
          p.clonedByGate = true;
          p.maxTravelDist = max(p.maxTravelDist, min(485.0, p.maxTravelDist + 64.0));
          cloneGate.pulseAnim = 1.0;
          cloneSplitCount++;
          final isTriple = cloneGate.tripleOverdriveTimer > 0;
          if (!isTriple) {
            cloneGate.passCharge++;
            if (cloneGate.passCharge >= 10) {
              cloneGate.passCharge = 0;
              cloneGate.tripleOverdriveTimer = 8.0;
              pendingSounds.add(SoundCue.serendipityJackpot);
              callouts.add(
                FloatingCallout(
                  pos: cloneGate.center + const Vec2(0, -24),
                  text: '🔥 배율 관문 진화!! 8초간 [×3 삼류 폭주진] 가동!!',
                  colorHex: 0xFFFF6B35,
                  isBigBanner: true,
                ),
              );
            }
          }
          final spd = p.vel.length;
          final baseA = atan2(p.vel.y, p.vel.x);
          final spawnPos = cloneGate.center;
          if (isTriple) {
            for (final offA in const [-0.17, 0.17]) {
              final a = baseA + offA;
              spawnedClones.add(
                ActiveStoneProjectile(
                  sourceKey: p.sourceKey,
                  sourceLabel: '${p.sourceLabel} (×3폭주)',
                  pos: spawnPos,
                  vel: Vec2(cos(a) * spd, sin(a) * spd),
                  material: p.material,
                  shape: p.shape,
                  damage: p.damage * 0.90,
                  knockback: p.knockback * 0.90,
                  critChance: p.critChance,
                  colorHex: 0xFFFF6B35,
                  radius: p.radius * 0.96,
                  spinCurve: p.spinCurve,
                  pierceLeft: p.pierceLeft,
                  aoeSplashRadius: p.aoeSplashRadius,
                  pullsEnemies: p.pullsEnemies,
                  freezesOnHit: p.freezesOnHit,
                  slowsOnHit: p.slowsOnHit,
                  oilsOnHit: p.oilsOnHit,
                  ignoresShield: p.ignoresShield,
                  isGiantCritSerendipity: p.isGiantCritSerendipity,
                  fromWeakCrackerMount: p.fromWeakCrackerMount,
                  freezeDurationOverride: p.freezeDurationOverride,
                  homingTargetUid: p.homingTargetUid,
                  executesLowHpNormal: p.executesLowHpNormal,
                  splitsShadowOnHit: p.splitsShadowOnHit,
                  alreadySplitPerk: p.alreadySplitPerk,
                  clonedByGate: true,
                  splitChild: p.splitChild,
                  maxTravelDist: max(125.0, p.maxTravelDist - p.traveledDist + 48.0),
                  projectileStyle: p.projectileStyle,
                )
                  ..bouncesLeft = p.bouncesLeft
                  ..bouncedOffObstacle = p.bouncedOffObstacle
                  ..hitMutantIds.addAll(p.hitMutantIds),
              );
            }
            bursts.add(FxBurst(pos: cloneGate.center, colorHex: 0xFFFF6B35, maxRadius: 36));
          } else {
            p.vel = Vec2(cos(baseA - 0.14) * spd, sin(baseA - 0.14) * spd);
            final twinA = baseA + 0.14;
            spawnedClones.add(
              ActiveStoneProjectile(
                sourceKey: p.sourceKey,
                sourceLabel: '${p.sourceLabel} (×2복제)',
                pos: spawnPos,
                vel: Vec2(cos(twinA) * spd, sin(twinA) * spd),
                material: p.material,
                shape: p.shape,
                damage: p.damage * 0.88,
                knockback: p.knockback * 0.90,
                critChance: p.critChance,
                colorHex: 0xFF72EFDD,
                radius: p.radius * 0.95,
                spinCurve: p.spinCurve,
                pierceLeft: p.pierceLeft,
                aoeSplashRadius: p.aoeSplashRadius,
                pullsEnemies: p.pullsEnemies,
                freezesOnHit: p.freezesOnHit,
                slowsOnHit: p.slowsOnHit,
                oilsOnHit: p.oilsOnHit,
                ignoresShield: p.ignoresShield,
                isGiantCritSerendipity: p.isGiantCritSerendipity,
                fromWeakCrackerMount: p.fromWeakCrackerMount,
                freezeDurationOverride: p.freezeDurationOverride,
                homingTargetUid: p.homingTargetUid,
                executesLowHpNormal: p.executesLowHpNormal,
                splitsShadowOnHit: p.splitsShadowOnHit,
                alreadySplitPerk: p.alreadySplitPerk,
                clonedByGate: true,
                splitChild: p.splitChild,
                maxTravelDist: max(125.0, p.maxTravelDist - p.traveledDist + 48.0),
                projectileStyle: p.projectileStyle,
              )
                ..bouncesLeft = p.bouncesLeft
                ..bouncedOffObstacle = p.bouncedOffObstacle
                ..hitMutantIds.addAll(p.hitMutantIds),
            );
            bursts.add(FxBurst(pos: cloneGate.center, colorHex: 0xFF72EFDD, maxRadius: 30));
          }
        }

        // 1-B) 🎯 화력 증폭 과녁패 적중 판정
        if (!p.hitMutantIds.contains(-777) &&
            _distSegmentToPoint(segA, segB, powerTarget.center) <=
                powerTarget.radius + p.radius * 0.6) {
          p.hitMutantIds.add(-777);
          final prevStacks = powerTarget.powerStacks;
          powerTarget.powerStacks = (powerTarget.powerStacks + 1).clamp(1, 6);
          powerTarget.decayTimer = 11.0;
          powerTarget.pulseAnim = 1.0;
          bursts.add(FxBurst(pos: powerTarget.center, colorHex: 0xFFFFD166, maxRadius: 26));
          if (powerTarget.powerStacks > prevStacks) {
            fieldTokens += 2;
            callouts.add(
              FloatingCallout(
                pos: powerTarget.center + const Vec2(0, -18),
                text: '🎯 전군 화력 +${powerTarget.bonusPercent}% 증폭!',
                colorHex: 0xFFFFD166,
              ),
            );
          }
        }

        // 2) 심야 화약통 유폭 판정
        for (final keg in powderKegs) {
          if (keg.intact && _distSegmentToPoint(segA, segB, keg.pos) <= 18.0 + p.radius) {
            keg.intact = false;
            keg.respawnTimer = 14.0;
            powderKegsDetonated++;
            const kegBonusQi = 16;
            fieldTokens += kegBonusQi;
            _spawnFlyingQiOrb(keg.pos, kegBonusQi, colorHex: 0xFFF77F00);
            pendingSounds.add(SoundCue.criticalShatter);
            screenShakeTimer = max(screenShakeTimer, 0.28);
            screenShakeIntensity = max(screenShakeIntensity, 5.6);
            bursts.add(
              FxBurst(
                pos: keg.pos,
                colorHex: 0xFFFF6B35,
                maxRadius: 94,
                ttlSec: 0.48,
                durationSec: 0.48,
                isTriangleShatter: true,
              ),
            );
            callouts.add(
              FloatingCallout(
                pos: keg.pos + const Vec2(0, -18),
                text: '🧨 화약통 대폭발!! (+$kegBonusQi⚡ 기력!)',
                colorHex: 0xFFFF6B35,
                isBigBanner: true,
              ),
            );
            final kegMult = chapter.number == 2 ? 1.45 : 1.0;
            final blastDmg = (52.0 + stage.chapterNumber * 20.0) *
                kegMult *
                progress.realm.powerMult *
                progress.transcendenceMultiplier;
            _spawnShockwaveRing(
              keg.pos,
              maxRadius: 108.0,
              colorHex: 0xFFFF6B35,
              secondaryColorHex: 0xFFFFD166,
              style: 'heavyCrater',
              durationSec: 0.44,
            );
            for (final m in List<ActiveMutant>.from(mutants)) {
              if (m.pos.distanceTo(keg.pos) <= 94.0) {
                _applyDamageToMutant(
                  m,
                  blastDmg,
                  sourceKey: 'powder_keg',
                  sourceLabel: '심야 화약통 유폭',
                  knockDir: (m.pos - keg.pos).normalized,
                  knockForce: 150.0,
                  isCritical: true,
                  halfArmorPenetration: true,
                );
              }
            }
          }
        }

        // 3) 황금 보물 도깨비 타격 & 처치 보상
        if (treasureGoblin != null &&
            treasureGoblin!.alive &&
            !p.hitMutantIds.contains(-888) &&
            _distSegmentToPoint(segA, segB, treasureGoblin!.pos) <= 20.0 + p.radius) {
          p.hitMutantIds.add(-888);
          final g = treasureGoblin!;
          g.hitFlashTimer = 1.0;
          g.hp -= p.damage * 1.25;
          bursts.add(FxBurst(pos: g.pos, colorHex: 0xFFFFD166, maxRadius: 28));
          if (g.hp <= 0) {
            g.alive = false;
            const gobQi = 34;
            fieldTokens += gobQi;
            earnedPermanentTokens += 35;
            _spawnFlyingQiOrb(g.pos, gobQi);
            pendingSounds.add(SoundCue.serendipityJackpot);
            screenShakeTimer = max(screenShakeTimer, 0.30);
            screenShakeIntensity = max(screenShakeIntensity, 5.2);
            callouts.add(
              FloatingCallout(
                pos: g.pos + const Vec2(0, -18),
                text: '👹 보물 도깨비 토벌 대박!! +$gobQi⚡ 기력 & 비급 획득!',
                colorHex: 0xFFFFD166,
                isBigBanner: true,
              ),
            );
            _queuePerkRoll();
          }
        }

        // 4) 황금 보급 두꺼비 포획 (도탄 시 +65⚡ 대박 보너스 · 직격 시 +45⚡!)
        if (goldenToad != null &&
            goldenToad!.alive &&
            _distSegmentToPoint(segA, segB, goldenToad!.pos) < p.radius + 16.0) {
          goldenToad!.alive = false;
          final toadQi = p.bouncedOffObstacle ? 65 : 45;
          fieldTokens += toadQi;
          earnedPermanentTokens += p.bouncedOffObstacle ? 45 : 35;
          earnedElixirs += 2;
          _spawnFlyingQiOrb(goldenToad!.pos, toadQi);
          pendingSounds.add(SoundCue.serendipityJackpot);
          callouts.add(
            FloatingCallout(
              pos: goldenToad!.pos,
              text: p.bouncedOffObstacle
                  ? '🐸 황금 두꺼비 도탄 대박!! 기력 +$toadQi⚡ · 영약 +2!'
                  : '🐸 황금 두꺼비 포획! 기력 +$toadQi⚡ · 영약 +2!',
              colorHex: 0xFFFFD166,
              isBigBanner: true,
            ),
          );
        }

        // 5) 돌연변이 최단 충돌 시각 t ∈ [0, 1] 정렬 다중 관통 판정 (전열→후열 물리 순서 100% 보장!)
        final hitCandidates = <(double, ActiveMutant)>[];
        for (final m in mutants) {
          if (m.phaseTransitionTimer > 0) continue;
          if (p.hitMutantIds.contains(m.uid)) continue;
          if (p.isPrecisionShot && p.lockedWeakBossUid != null && m.uid != p.lockedWeakBossUid) {
            continue;
          }
          final tHit = _segmentCircleHitParam(segA, segB, m.pos, p.radius + m.effectiveRadius);
          if (tHit != null) {
            hitCandidates.add((tHit, m));
          }
        }
        if (hitCandidates.length > 1) {
          hitCandidates.sort((a, b) => a.$1.compareTo(b.$1));
        }

        final savedFinalPos = p.pos;
        for (final (tHit, m) in hitCandidates) {
          if (!mutants.contains(m) || m.phaseTransitionTimer > 0 || p.hitMutantIds.contains(m.uid)) {
            continue;
          }
          p.hitMutantIds.add(m.uid);
          p.pos = segA + (segB - segA) * tHit;
          _resolveProjectileHitMutant(p, m, spawnedClones);

          if (p.pierceLeft > 0) {
            p.pierceLeft--;
            p.pos = savedFinalPos;
            continue;
          } else if (p.bouncesLeft > 0 &&
              (p.material.grade >= 6 || perkStacks(RoguePerk.ricochetMaster) > 0)) {
            p.bouncesLeft--;
            p.vel = Vec2(-p.vel.y * 0.78, p.vel.x * 0.78) * p.material.bounceKeep;
            p.pos = m.pos + p.vel.normalized * (m.effectiveRadius + p.radius + 1.0);
            break;
          } else {
            consumed = true;
            break;
          }
        }
      }

      if (consumed ||
          stoppedByObstacle ||
          outOfBounds ||
          p.traveledDist >= p.maxTravelDist - 1e-4) {
        projectiles.removeAt(i);
      }
    }

    if (spawnedClones.isNotEmpty) {
      projectiles.addAll(spawnedClones);
    }
  }

  void _resolveProjectileHitMutant(
    ActiveStoneProjectile p,
    ActiveMutant m,
    List<ActiveStoneProjectile> spawnedClones,
  ) {
    if (m.phaseTransitionTimer > 0) {
      bursts.add(FxBurst(pos: m.pos, colorHex: 0xFFC77DFF, maxRadius: 24));
      return;
    }

    // 연쇄 콤보 및 광폭 탄지 피버 게이지 충전!
    comboCount++;
    if (comboCount > bestCombo) bestCombo = comboCount;
    comboResetTimer = 2.6;
    if (feverTimer <= 0) {
      feverGauge = (feverGauge + 2.8).clamp(0.0, 100.0);
      if (feverGauge >= 100.0) {
        feverGauge = 0.0;
        feverTimer = 6.5;
        pendingSounds.add(SoundCue.serendipityJackpot);
        screenShakeTimer = max(screenShakeTimer, 0.25);
        screenShakeIntensity = max(screenShakeIntensity, 4.5);
        bursts.add(FxBurst(pos: towerPos, colorHex: 0xFFFFD166, maxRadius: 72));
        callouts.add(
          FloatingCallout(
            pos: const Vec2(320, 210),
            text: '🔥 광폭 탄지 무쌍(피버 타임) 돌입!! 6.5초간 전 초소 폭주!',
            colorHex: 0xFFFFD166,
            ttlSec: 2.0,
            isBigBanner: true,
          ),
        );
      }
    }

    final isCrit = p.isPrecisionShot ||
        auroraCritTimer > 0 ||
        rouletteHyperBarrageTimer > 0 ||
        p.isGiantCritSerendipity ||
        rng.nextDouble() < p.critChance;
    final ch10CritBonus = chapter.number == 10 ? 0.45 : 0.0;
    double mult = isCrit ? (1.65 + ch10CritBonus + progress.corePrecisionBonus) : 1.0;

    // ★ 보스 정밀 약점 다격 & 지형 측면 파쇄 & 외각 장갑판 물리 처리!
    double precisionBonusTrueDmg = 0.0;
    bool crackedWeakPointNow = false;
    if (m.totalPhases > 1) {
      final hitWeakBullseye = p.isPrecisionShot &&
          (p.lockedWeakBossUid == m.uid ||
              p.pos.distanceTo(m.weakSpotWorldPos) <= m.effectiveRadius * 1.25 ||
              (p.precisionTargetPos != null &&
                  p.precisionTargetPos!.distanceTo(m.weakSpotWorldPos) <= 88.0));

      if (hitWeakBullseye) {
        crackedWeakPointNow = true;
        precisionHitCount++;
        mult *= 1.32;
        final hpCapRatio = difficulty == DefenseDifficulty.nightmare
            ? (m.carapacePlatesLeft > 0 ? 0.032 : 0.018)
            : (m.carapacePlatesLeft > 0 ? 0.065 : 0.042);
        precisionBonusTrueDmg = min(p.damage * 2.4, m.currentMaxHp * hpCapRatio);
        if (m.freezeImmuneTimer <= 0) {
          m.freezeTimer = max(m.freezeTimer, 0.36);
          m.freezeImmuneTimer = 2.1;
        }
        fieldTokens += 5;
        _spawnFlyingQiOrb(m.weakSpotWorldPos, 5, colorHex: 0xFFFFD166);
        if (m.carapacePlatesLeft > 0) {
          m.carapacePlatesLeft--;
          pendingSounds.add(SoundCue.criticalShatter);
          screenShakeTimer = max(screenShakeTimer, 0.24);
          screenShakeIntensity = max(screenShakeIntensity, 5.2);
          bursts.add(
            FxBurst(
              pos: m.weakSpotWorldPos,
              colorHex: 0xFFFFD166,
              maxRadius: 58,
              isTriangleShatter: true,
            ),
          );
          if (m.carapacePlatesLeft == 0) {
            m.groggyExposeTimer = 7.0;
            fieldTokens += 12;
            callouts.add(
              FloatingCallout(
                pos: m.pos + const Vec2(0, -28),
                text: '💥 외각 장갑 완전 붕괴!! 7초간 무방비(피해 ×1.85)!',
                colorHex: 0xFFFFD166,
                ttlSec: 2.0,
                isBigBanner: true,
              ),
            );
          } else {
            callouts.add(
              FloatingCallout(
                pos: m.pos + const Vec2(0, -24),
                text: '🎯 정밀 약점 파쇄!! (남은 장갑 ${m.carapacePlatesLeft}겹)',
                colorHex: 0xFFFFD166,
                ttlSec: 1.4,
              ),
            );
          }
        } else {
          callouts.add(
            FloatingCallout(
              pos: m.pos + const Vec2(0, -22),
              text: '⚡ 무방비 급소 직격!!',
              colorHex: 0xFFFFD166,
              ttlSec: 1.2,
            ),
          );
        }
      } else if (m.carapacePlatesLeft > 0 &&
          (m.totalPhases < 3 || m.carapacePlatesLeft > 1 || stage.chapterNumber <= 2) &&
          p.fromWeakCrackerMount &&
          m.flankCrackCooldown <= 0) {
        final incomingVec = (p.pos - m.pos);
        final hitAngle = incomingVec.length > 1e-3
            ? atan2(incomingVec.y, incomingVec.x)
            : atan2(-p.vel.y, -p.vel.x);
        if (cos(hitAngle - m.weakSpotAngleRad) >= 0.42) {
          crackedWeakPointNow = true;
          precisionHitCount++;
          m.flankCrackCooldown = 4.6;
          m.carapacePlatesLeft--;
          precisionBonusTrueDmg = stage.isReincarnationBossStage
              ? min(p.damage * 2.4, m.currentMaxHp * 0.022)
              : m.currentMaxHp * 0.07;
          pendingSounds.add(SoundCue.criticalShatter);
          bursts.add(
            FxBurst(
              pos: m.weakSpotWorldPos,
              colorHex: 0xFF80ED99,
              maxRadius: 46,
              isTriangleShatter: true,
            ),
          );
          if (m.carapacePlatesLeft == 0) {
            m.groggyExposeTimer = 7.0;
            callouts.add(
              FloatingCallout(
                pos: m.pos + const Vec2(0, -26),
                text: '🗡️ 지형 약점 관통 · 외각 붕괴!! 7초간 무방비!',
                colorHex: 0xFF80ED99,
                ttlSec: 1.9,
                isBigBanner: true,
              ),
            );
          } else {
            callouts.add(
              FloatingCallout(
                pos: m.pos + const Vec2(0, -22),
                text: '🗡️ 지형 약점 타격! (남은 장갑 ${m.carapacePlatesLeft}겹)',
                colorHex: 0xFF80ED99,
              ),
            );
          }
        }
      }

      if (m.groggyExposeTimer > 0) {
        mult *= 1.85;
      }
    }

    if (p.bouncedOffObstacle) {
      mult *= 1.35 + perkStacks(RoguePerk.ricochetMaster) * 0.55;
      bankShotCount++;
      fieldTokens += 2;
      callouts.add(
        FloatingCallout(
          pos: m.pos + const Vec2(0, -16),
          text: '🎱 어부지리 도탄 대박!',
          colorHex: 0xFF72EFDD,
        ),
      );
    }

    // 5종 발사대 정밀 상성 분화 (제3장 이상 본격 발동 — 입문 1~2장은 기본 장갑 공식 그대로 보존)
    final isRapid = p.sourceLabel.contains('속사');
    final isHeavy = p.sourceLabel.contains('중포');
    final isCurve = p.sourceLabel.contains('곡사');

    // 빙결·서리 취성 효과: 한빙 역장기 등으로 얼거나 느려진 적은 타 병종 포격에 +45% 추가 파쇄 피해!
    // 또한 '쇄빙 파쇄진'(한빙+중포 인접 연결)에 실제 참여 중인 발사대는 한철·만년빙옥진 보유 여부와 무관하게 +40% 쇄빙 시너지 증폭!
    final isChilled = m.freezeTimer > 0 || m.slowTimer > 0;
    if (isChilled && (!p.freezesOnHit || isHeavy)) {
      mult *= 1.45;
      if (p.sourceKey.startsWith('launcher_')) {
        final slotId = int.tryParse(p.sourceKey.substring('launcher_'.length));
        if (slotId != null &&
            activeSynergyLinks.any(
              (l) => l.synergyName == '쇄빙 파쇄진' && (l.slotA == slotId || l.slotB == slotId),
            )) {
          mult *= 1.40;
        }
      }
    }

    final isHeavyArmorTarget = m.kind == MutantKind.ironBoar ||
        m.kind == MutantKind.ironColossusBoss ||
        m.kind == MutantKind.raiderHeukpung ||
        m.kind == MutantKind.chapterOverlord;
    final isAgileSwarmTarget = m.kind == MutantKind.swarmRat ||
        m.kind == MutantKind.sickHound ||
        m.kind == MutantKind.bloodWingBat ||
        m.kind == MutantKind.swiftShadowBoss;

    // 🪽 공중 비행 변이 대공 상성: 속사 탄지기·곡사 회전기·영수 청학이 공중 표적을 +36% 추격 요격!
    if (m.kind.isFlying &&
        (isRapid ||
            isCurve ||
            p.sourceKey == 'beast_cheonghak' ||
            p.sourceKey == 'hero_yeonbi' ||
            p.sourceKey == 'hero_gurumi')) {
      mult *= 1.36;
    }

    if (stage.chapterNumber >= 3) {
      if (isRapid) {
        if (isAgileSwarmTarget || m.kind.isFlying) {
          mult *= 1.38;
        } else if (isHeavyArmorTarget || m.kind.isBoss) {
          mult *= 0.11;
        } else if (m.kind == MutantKind.shieldYacha) {
          mult *= 0.18;
        }
      } else if (isHeavy) {
        if (isHeavyArmorTarget || m.kind.isBoss) {
          mult *= 1.70;
        } else if (isAgileSwarmTarget) {
          mult *= 0.14;
        }
      } else if (isCurve) {
        if (m.kind.isFlying ||
            m.kind == MutantKind.shieldYacha ||
            m.kind == MutantKind.bloodCocoon ||
            m.kind == MutantKind.plagueToad) {
          mult *= 1.58;
        } else if (isHeavyArmorTarget || m.kind.isBoss) {
          mult *= 0.15;
        }
      }
    }

    final armorBreakStacks = perkStacks(RoguePerk.armorBreaker);
    if (armorBreakStacks > 0 && m.kind.isBoss) {
      mult *= 1.0 + armorBreakStacks * 0.40;
    }

    // 뼈방패 야차는 전방 방패 각도(정면 반구)에서 날아오는 직사 탄알만 감쇠하며, 측면·후방 우회탄 및 벽 도탄에는 방패가 뚫린다!
    if (m.kind.frontShieldReduction > 0 &&
        !p.ignoresShield &&
        !p.bouncedOffObstacle &&
        armorBreakStacks == 0) {
      final shotDir = p.vel.normalized;
      final facing = Vec2(cos(m.headingRad), sin(m.headingRad));
      final dotFront = shotDir.x * facing.x + shotDir.y * facing.y;
      if (dotFront < 0.15) {
        mult *= (1.0 - m.kind.frontShieldReduction);
        shieldYachaBlocks++;
      }
    }

    final ch3FreezeMult = chapter.number == 3 ? 1.35 : 1.0;
    if (p.freezesOnHit) {
      if (m.freezeImmuneTimer <= 0) {
        final baseFreezeSec = p.freezeDurationOverride ?? (m.kind.isBoss ? 0.85 : 1.15);
        m.freezeTimer = max(m.freezeTimer, baseFreezeSec * ch3FreezeMult);
        m.freezeImmuneTimer = m.kind.isBoss ? 3.8 : 2.8;
      }
      m.slowTimer = max(m.slowTimer, 2.8 * ch3FreezeMult);
      _spawnShockwaveRing(
        m.pos,
        maxRadius: 48.0,
        colorHex: 0xFF90E0EF,
        secondaryColorHex: 0xFFCAF0F8,
        style: 'frostNova',
        durationSec: 0.30,
      );
    } else if (p.slowsOnHit || p.material == StoneMaterial.bingbaek) {
      final slowSec = p.material == StoneMaterial.banseok ? 1.35 : 2.5;
      m.slowTimer = max(m.slowTimer, slowSec * ch3FreezeMult);
    }
    if (p.oilsOnHit) {
      m.oilSlipTimer = 4.0;
    }

    if (isCrit) {
      pendingSounds.add(SoundCue.criticalShatter);
      qiBars = (qiBars + 0.06 * (chapter.number == 10 ? 1.30 : 1.0)).clamp(0.0, maxQiBars);
      screenShakeTimer = max(screenShakeTimer, 0.09);
      screenShakeIntensity = max(screenShakeIntensity, 2.2);
      _spawnShockwaveRing(
        m.pos,
        maxRadius: p.isGiantCritSerendipity ? 74.0 : 52.0,
        colorHex: 0xFFFFD166,
        secondaryColorHex: 0xFFE63946,
        style: 'critStar',
        durationSec: 0.32,
      );
      if ((chapter.number == 7 || chapter.number == 9) &&
          (_fireBurstCooldown <= 0 ||
              _lastFireBurstPos == null ||
              m.pos.distanceTo(_lastFireBurstPos!) > 85.0)) {
        _fireBurstCooldown = 0.16;
        _lastFireBurstPos = m.pos;
        final fireR = chapter.number == 9 ? 54.0 : 44.0;
        _spawnShockwaveRing(
          m.pos,
          maxRadius: fireR + 12.0,
          colorHex: 0xFFFF6B35,
          secondaryColorHex: 0xFFFFD166,
          style: 'heavyCrater',
          durationSec: 0.38,
        );
        for (final near in List<ActiveMutant>.from(mutants)) {
          if (near.uid != m.uid &&
              near.phaseTransitionTimer <= 0 &&
              near.pos.distanceTo(m.pos) <= fireR) {
            _applyDamageToMutant(
              near,
              p.damage * (chapter.number == 9 ? 0.38 : 0.30),
              sourceKey: p.sourceKey,
              sourceLabel: chapter.number == 9 ? '화구 용암 분출' : '열사 태양 폭발',
              knockDir: (near.pos - m.pos).normalized,
              knockForce: 45.0,
              isCritical: false,
              halfArmorPenetration: true,
              chainDepth: 2,
            );
          }
        }
      }
    } else if (p.material == StoneMaterial.bingbaek || p.material == StoneMaterial.hancheol) {
      pendingSounds.add(SoundCue.stoneHitIce);
    } else if (p.material == StoneMaterial.manyeonGiju) {
      pendingSounds.add(SoundCue.stoneHitWood);
    } else if (p.material.density >= 2.0) {
      pendingSounds.add(SoundCue.stoneHitHeavy);
    } else {
      pendingSounds.add(SoundCue.stoneHitCheongok);
    }
    qiBars = (qiBars + 0.025 * (chapter.number == 10 ? 1.30 : 1.0)).clamp(0.0, maxQiBars);

    final hitDir = p.vel.normalized;
    final halfPen = armorBreakStacks > 0 ||
        isHeavy ||
        p.isPrecisionShot ||
        p.material.density >= 1.35 ||
        isCrit;
    final precisionStrikeHits = crackedWeakPointNow
        ? 42
        : (p.isPrecisionShot
            ? 24
            : (p.projectileStyle == 'eogiUltimate' ? 16 : 0));
    double resolvedRawDmg = p.damage * mult + precisionBonusTrueDmg;
    if (p.executesLowHpNormal &&
        !m.kind.isBoss &&
        m.hp <= m.currentMaxHp * 0.55) {
      resolvedRawDmg = max(resolvedRawDmg, m.hp + 999.0);
    }
    _applyDamageToMutant(
      m,
      resolvedRawDmg,
      sourceKey: p.sourceKey,
      sourceLabel: p.sourceLabel,
      knockDir: hitDir,
      knockForce: p.knockback,
      isCritical: isCrit,
      halfArmorPenetration: halfPen,
      jageumArmorPenetration: p.material == StoneMaterial.jageum,
      fullArmorIgnore: p.isPrecisionShot ||
          crackedWeakPointNow ||
          armorBreakStacks > 0 ||
          (p.executesLowHpNormal && !m.kind.isBoss && m.hp <= m.currentMaxHp * 0.55) ||
          (stage.chapterNumber >= 3 && isHeavy),
      bypassCarapace: crackedWeakPointNow,
      extraHitStrikes: precisionStrikeHits,
    );

    // [문파 비공: 영월살문 분신 쌍영탄] 적중 순간 알이 둘로 갈라져 양옆 길목 변이체 동시 타격!
    if (p.splitsShadowOnHit && !p.splitChild && projectiles.length + spawnedClones.length < 180) {
      p.splitsShadowOnHit = false;
      final spd = p.vel.length * 0.90;
      final baseA = atan2(p.vel.y, p.vel.x);
      final ch5Extra = chapter.number == 5 ? 2 : 0;
      for (final deltaA in const [-0.42, 0.42]) {
        final a = baseA + deltaA;
        spawnedClones.add(
          ActiveStoneProjectile(
            sourceKey: p.sourceKey,
            sourceLabel: '${p.sourceLabel} (쌍영분신)',
            pos: m.pos,
            vel: Vec2(cos(a) * spd, sin(a) * spd),
            material: p.material,
            shape: p.shape,
            damage: p.damage * 0.56,
            knockback: p.knockback * 0.70,
            critChance: p.critChance,
            colorHex: 0xFFC77DFF,
            radius: max(6.4, p.radius * 0.78),
            pierceLeft: 1,
            extraBounces: ch5Extra,
            ignoresShield: p.ignoresShield,
            clonedByGate: true,
            splitChild: true,
          )..hitMutantIds.add(m.uid),
        );
      }
    }

    // [비급: 쌍탄 분열비급] 첫 적 적중 시 1회만 2갈래 분열탄 생성! (관통탄 중복 다단 분열 차단!)
    final splitStacks = perkStacks(RoguePerk.splitShot);
    if (splitStacks > 0 &&
        !p.splitChild &&
        !p.alreadySplitPerk &&
        projectiles.length + spawnedClones.length < 180) {
      p.alreadySplitPerk = true;
      final spd = p.vel.length * 0.92;
      final baseA = atan2(p.vel.y, p.vel.x);
      final splitDmg = p.damage * (0.52 + (splitStacks - 1) * 0.40);
      final ch5Extra = chapter.number == 5 ? 2 : 0;
      for (final deltaA in [-0.36, 0.36]) {
        final a = baseA + deltaA;
        spawnedClones.add(
          ActiveStoneProjectile(
            sourceKey: p.sourceKey,
            sourceLabel: '${p.sourceLabel} (분열탄)',
            pos: m.pos,
            vel: Vec2(cos(a) * spd, sin(a) * spd),
            material: p.material,
            shape: p.shape,
            damage: splitDmg,
            knockback: p.knockback * 0.65,
            critChance: p.critChance,
            colorHex: 0xFFFF6B35,
            radius: max(6.2, p.radius * 0.76),
            pierceLeft: 0,
            extraBounces: ch5Extra,
            freezesOnHit: p.freezesOnHit,
            ignoresShield: p.ignoresShield,
            alreadySplitPerk: true,
            clonedByGate: true,
            splitChild: true,
          )..hitMutantIds.add(m.uid),
        );
      }
    }

    // [비급: 뇌전 연쇄탄] 주변 적 최대 3체에게 번개 사슬 피해!
    final lightningStacks = perkStacks(RoguePerk.chainLightning);
    if (lightningStacks > 0 && mutants.isNotEmpty) {
      int chained = 0;
      Vec2 prevPos = m.pos;
      for (final other in List<ActiveMutant>.from(mutants)) {
        if (other.uid == m.uid) continue;
        if (other.pos.distanceTo(prevPos) <= 105.0) {
          if (lightningArcs.length < 24) {
            lightningArcs.add(LightningArcFx(from: prevPos, to: other.pos));
          }
          _applyDamageToMutant(
            other,
            p.damage * (0.45 + (lightningStacks - 1) * 0.25),
            sourceKey: p.sourceKey,
            sourceLabel: '뇌전 연쇄탄',
            knockDir: (other.pos - prevPos).normalized,
            knockForce: 24.0,
            isCritical: false,
            fullArmorIgnore: true,
            chainDepth: 2,
          );
          prevPos = other.pos;
          chained++;
          if (chained >= 3) break;
        }
      }
    }

    if (p.pullsEnemies) {
      for (final other in mutants) {
        if (other != m && other.pos.distanceTo(m.pos) < 95) {
          other.pos = other.pos + (m.pos - other.pos) * 0.42;
        }
      }
    }

    if (p.aoeSplashRadius > 0) {
      final isHeavyCannon = p.sourceLabel.contains('중포') || p.aoeSplashRadius >= 48.0;
      bursts.add(
        FxBurst(
          pos: m.pos,
          colorHex: p.colorHex,
          maxRadius: p.aoeSplashRadius,
          isTriangleShatter: isHeavyCannon,
        ),
      );
      if (isHeavyCannon) {
        screenShakeTimer = max(screenShakeTimer, 0.12);
        screenShakeIntensity = max(screenShakeIntensity, 2.8);
        _spawnShockwaveRing(
          m.pos,
          maxRadius: p.aoeSplashRadius * 1.15,
          colorHex: 0xFFFF6B35,
          secondaryColorHex: 0xFFFFD166,
          style: 'heavyCrater',
          durationSec: 0.34,
        );
      }
      final pushAwayFromAltar =
          p.projectileStyle == 'sectFist' || p.material == StoneMaterial.banseok;
      for (final other in List<ActiveMutant>.from(mutants)) {
        if (other.uid != m.uid && other.pos.distanceTo(m.pos) <= p.aoeSplashRadius) {
          if (p.oilsOnHit) {
            other.oilSlipTimer = max(other.oilSlipTimer, 4.0);
          }
          if (p.freezesOnHit) {
            if (other.freezeImmuneTimer <= 0) {
              final splashFreeze =
                  (p.freezeDurationOverride ?? (other.kind.isBoss ? 0.65 : 0.95)) * ch3FreezeMult;
              other.freezeTimer = max(other.freezeTimer, splashFreeze);
              other.freezeImmuneTimer = other.kind.isBoss ? 3.8 : 2.8;
            }
            other.slowTimer = max(other.slowTimer, 2.4 * ch3FreezeMult);
          } else if (p.slowsOnHit || p.material == StoneMaterial.bingbaek) {
            other.slowTimer = max(other.slowTimer, 2.0 * ch3FreezeMult);
          }
          final rawSplashKnock = pushAwayFromAltar
              ? (other.pos - shieldCenter)
              : (other.pos - m.pos);
          final splashKnockDir =
              rawSplashKnock.length > 1e-3 ? rawSplashKnock.normalized : hitDir;
          _applyDamageToMutant(
            other,
            p.damage * 0.58,
            sourceKey: p.sourceKey,
            sourceLabel: p.sourceLabel,
            knockDir: splashKnockDir,
            knockForce: p.knockback * (pushAwayFromAltar ? 0.95 : 0.75),
            isCritical: false,
            halfArmorPenetration: halfPen,
            fullArmorIgnore: armorBreakStacks > 0,
          );
        }
      }
    }
  }

  void _applyDamageToMutant(
    ActiveMutant m,
    double dmg, {
    required String sourceKey,
    required String sourceLabel,
    required Vec2 knockDir,
    required double knockForce,
    required bool isCritical,
    bool halfArmorPenetration = false,
    bool jageumArmorPenetration = false,
    bool fullArmorIgnore = false,
    bool bypassCarapace = false,
    int chainDepth = 0,
    int extraHitStrikes = 0,
  }) {
    if (!mutants.contains(m) || m.phaseTransitionTimer > 0) return;
    m.hitFlashTimer = 1.0;

    // ★ 행동대장(100타+) · 중간보스 · 천련 보스(1,000타+) 다중 연타(Multi-Hit) 파쇄 시스템!
    final int hitBurst = extraHitStrikes > 0
        ? extraHitStrikes
        : (sourceKey == 'support_chuldu'
            ? 150
            : (sourceLabel.contains('어기어석')
                ? 16
                : (sourceLabel.contains('중포')
                    ? (isCritical ? 12 : 9)
                    : (sourceLabel.contains('곡사')
                        ? (isCritical ? 9 : 6)
                        : (sourceLabel.contains('한빙')
                            ? (isCritical ? 7 : 5)
                            : (chainDepth > 0 ? 3 : (isCritical ? 7 : 4)))))));
    m.totalHitsTaken += hitBurst;
    if (m.hitShieldLeft > 0) {
      final prevShield = m.hitShieldLeft;
      m.hitShieldLeft = max(0, m.hitShieldLeft - hitBurst);
      if (prevShield > 0 && m.hitShieldLeft == 0 && m.maxHitShield > 0) {
        fieldTokens += 16;
        _spawnFlyingQiOrb(m.pos, 16, colorHex: 0xFFFFD166);
        m.groggyExposeTimer = max(m.groggyExposeTimer, 6.0);
        pendingSounds.add(SoundCue.criticalShatter);
        bursts.add(
          FxBurst(
            pos: m.pos,
            colorHex: 0xFFFFD166,
            maxRadius: 68,
            isTriangleShatter: true,
          ),
        );
        callouts.add(
          FloatingCallout(
            pos: m.pos + const Vec2(0, -30),
            text: '💥 [${m.displayName}] ${m.maxHitShield}타 마갑 완전 파쇄!! (누적 ${m.totalHitsTaken} HIT!)',
            colorHex: 0xFFFFD166,
            ttlSec: 2.1,
            isBigBanner: true,
          ),
        );
      }
    }

    double armor = fullArmorIgnore ? 0.0 : m.kind.armorReduction;
    if (armor > 0) {
      if (jageumArmorPenetration) {
        armor *= 0.55; // 자금석: 외피 방어 45% 무시!
      }
      final penetratesHalf = halfArmorPenetration ||
          isCritical ||
          preset.primaryStone.density >= 1.35 ||
          sourceLabel.contains('중포');
      if (penetratesHalf) {
        armor *= 0.5;
      }
    }
    double carapaceMult = 1.0;
    if (m.carapacePlatesLeft > 0 && !bypassCarapace && sourceKey != 'support_chuldu') {
      if (m.totalPhases >= 3) {
        carapaceMult = stage.chapterNumber == 1 ? 0.24 : 0.08;
      } else {
        carapaceMult = 0.26;
      }
    }
    // ★ 빈 초소 마기 외피: 제3물결 이후 열린 초소를 절반 이상 비워두고 소수 포대(2~3기)만 방치하면,
    // 빈 길목의 심야 독기가 적을 감싸 피해의 최대 90%를 흡수한다! (만렙 계정 소수 설치 프리패스 원천 봉쇄!)
    double gapBypassMult = 1.0;
    if (currentWaveIndex >= 2 && sourceKey != 'support_chuldu') {
      final cov = formationCoverageRatio;
      if (cov < 0.80) {
        gapBypassMult = pow(cov / 0.80, 2.6).toDouble().clamp(0.08, 1.0);
      }
    }
    final rawEffective = (sourceKey == 'support_chuldu' && !m.kind.isBoss)
        ? dmg
        : dmg * (1.0 - armor).clamp(0.1, 1.0) * carapaceMult * gapBypassMult;
    final effectiveDmg = (sourceKey == 'support_chuldu' && !m.kind.isBoss)
        ? rawEffective
        : min(1000000000000000000.0, rawEffective);

    final dealt = min(m.hp, effectiveDmg);
    m.hp -= effectiveDmg;

    // ★ 100대·1,000대 타수 실드가 남아 있는 최종 페이즈 보스는 타수 실드를 다 깎기 전까지 절대 죽지 않고 버팀!
    if (m.hp <= 0 && m.currentPhase >= m.totalPhases && m.hitShieldLeft > 0) {
      m.hp = max(1.0, m.currentMaxHp * 0.04);
    }

    final impactScale = (stage.chapterNumber <= 2 && difficulty != DefenseDifficulty.nightmare)
        ? 1.0
        : (0.18 + 0.82 * (effectiveDmg / max(1.0, m.currentMaxHp * 0.14)).clamp(0.0, 1.0));
    final nightmareKnockResist = (stage.isReincarnationBossStage && m.kind.isBoss)
        ? (elapsedSec > 165.0 ? 0.04 : 0.16)
        : (difficulty == DefenseDifficulty.nightmare
            ? 0.56
            : (difficulty == DefenseDifficulty.normal ? 0.88 : 1.0));
    final oilKnockBoost = (!m.kind.isFlying && m.oilSlipTimer > 0) ? 1.25 : 1.0;
    m.knockbackVel = m.knockbackVel +
        knockDir *
            ((knockForce * impactScale * oilKnockBoost * nightmareKnockResist) /
                sqrt(m.kind.mass));
    final isKillingBlow = m.hp <= 0;

    // 찰진 타격 숫자 팝업 (치명타·격살·중대형 타격 위주로 최대 38개 풀 유지!)
    final shownDmg = effectiveDmg.round().clamp(1, 99999);
    if ((isCritical || isKillingBlow || shownDmg >= 18) && damagePopups.length < 38) {
      final jitterX = (rng.nextDouble() - 0.5) * 28.0;
      damagePopups.add(
        DamagePopupFx(
          pos: m.pos + Vec2(jitterX * 0.35, -m.effectiveRadius * 0.7),
          vel: Vec2(jitterX * 1.4, isCritical ? -62.0 : -46.0),
          damage: shownDmg,
          isCrit: isCritical,
          isKill: isKillingBlow,
          colorHex: isCritical
              ? 0xFFFFD166
              : (isKillingBlow ? 0xFFFF6B35 : 0xFFF8F9FA),
        ),
      );
    }

    final entry = _contribMap.putIfAbsent(
      sourceKey,
      () => ContributionEntry(key: sourceKey, label: sourceLabel),
    );
    entry.totalDamage += dealt;

    // ★ 중간보스 2차 재변이 & 대수괴 3페이즈 각성! (최종 페이즈 전까지는 죽지 않고 더 강하게 재변이!)
    if (isKillingBlow && m.currentPhase < m.totalPhases) {
      _triggerBossPhaseEvolution(m);
      return;
    }

    if (isKillingBlow) {
      final wasChilled = m.freezeTimer > 0 || m.slowTimer > 0;
      entry.kills++;
      mutants.remove(m);

      // ★ 돌연변이·괴물 격살 랙돌 날아가기 & 산산조각 파편 폭발 연출!
      if (deathRagdolls.length >= 44) {
        deathRagdolls.removeAt(0);
      }
      final safeDir = knockDir.length > 0.05 ? knockDir.normalized : const Vec2(0, -1);
      final flySpeed = (210.0 + knockForce * 2.2).clamp(185.0, 460.0);
      final sideKick = (rng.nextDouble() - 0.5) * 95.0;
      final perp = Vec2(-safeDir.y, safeDir.x);
      deathRagdolls.add(
        MutantDeathRagdoll(
          kind: m.kind,
          pos: m.pos,
          vel: safeDir * flySpeed + perp * sideKick,
          spinVel: (rng.nextBool() ? 1.0 : -1.0) * (8.5 + rng.nextDouble() * 8.0),
          visualDiameter: m.kind.visualDiameter,
          bodyWidthRatio: m.kind.bodyWidthRatio,
          colorHex: m.kind.colorHex,
          isCriticalKill: isCritical || m.kind.isBoss,
          durationSec: m.kind.isBoss ? 0.65 : 0.44,
        ),
      );

      // 모든 변이 처치 시 시원한 수묵·독기 파열 이펙트 (보스 처치 시 3중 대폭발 지진!)
      bursts.add(
        FxBurst(
          pos: m.pos,
          colorHex: m.kind.isBoss
              ? 0xFFFFD166
              : (isCritical ? 0xFFFF6B35 : m.kind.colorHex),
          maxRadius: m.kind.isBoss
              ? 88.0
              : (m.kind.visualDiameter * 0.72).clamp(20.0, 48.0),
          ttlSec: m.kind.isBoss ? 0.55 : 0.28,
          durationSec: m.kind.isBoss ? 0.55 : 0.28,
          isTriangleShatter: isCritical || m.kind.isBoss || m.kind.visualDiameter >= 35.0,
        ),
      );
      if (m.kind.isBoss) {
        pendingSounds.add(SoundCue.criticalShatter);
        screenShakeTimer = max(screenShakeTimer, 0.42);
        screenShakeIntensity = max(screenShakeIntensity, 7.8);
        callouts.add(
          FloatingCallout(
            pos: m.pos + const Vec2(0, -24),
            text: '💥 [${m.displayName}] 완전 격파!!',
            colorHex: 0xFFFFD166,
            ttlSec: 1.9,
            isBigBanner: true,
          ),
        );
      }

      if (preset.primaryStone == StoneMaterial.onok &&
          towerHp > 0 &&
          launchers.any((e) => !e.isConstructing)) {
        final healRatio = stage.globalIndex >= 900 ? 0.011 : 0.022;
        shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * healRatio);
      }

      // 출두 처치 시 파생되는 연쇄 폭발이 보스 마갑을 개체당 150타씩 즉사 증발시키지 않도록 파생 키 분리!
      final chainSourceKey =
          sourceKey == 'support_chuldu' ? 'support_chuldu_chain' : sourceKey;

      // [비급: 홍련 폭렬파] 처치 시 화염 유폭! (무한 체력 비례 즉사 방지를 위해 실제 타격 화력 기반으로 상한 제어)
      final corpseStacks = perkStacks(RoguePerk.corpseExplosion);
      if (corpseStacks > 0 && chainDepth < 2) {
        bursts.add(
          FxBurst(
            pos: m.pos,
            colorHex: 0xFFE63946,
            maxRadius: 62,
            isTriangleShatter: true,
          ),
        );
        final cappedHpBlast = min(
          m.maxHp * 0.12,
          centralSpec.baseDamage * progress.realm.powerMult * 4.2,
        );
        final blastDmg =
            (effectiveDmg * 0.42 + cappedHpBlast) * (0.75 + corpseStacks * 0.25);
        for (final near in List<ActiveMutant>.from(mutants)) {
          if (near.pos.distanceTo(m.pos) <= 62.0) {
            _applyDamageToMutant(
              near,
              blastDmg,
              sourceKey: chainSourceKey,
              sourceLabel: '홍련 폭렬파',
              knockDir: (near.pos - m.pos).normalized,
              knockForce: 68.0,
              isCritical: false,
              halfArmorPenetration: true,
              chainDepth: chainDepth + 1,
            );
          }
        }
      }

      // [비급: 만년 빙옥진] 빙결·감속 적 처치 시 얼음 파편 폭발!
      final frostStacks = perkStacks(RoguePerk.frostNova);
      if (frostStacks > 0 && wasChilled && chainDepth < 2) {
        bursts.add(FxBurst(pos: m.pos, colorHex: 0xFF90E0EF, maxRadius: 54));
        for (final near in List<ActiveMutant>.from(mutants)) {
          if (near.pos.distanceTo(m.pos) <= 54.0) {
            near.slowTimer = max(near.slowTimer, 2.5);
            _applyDamageToMutant(
              near,
              18.0 * frostStacks * progress.realm.powerMult,
              sourceKey: chainSourceKey,
              sourceLabel: '만년 빙옥진',
              knockDir: (near.pos - m.pos).normalized,
              knockForce: 42.0,
              isCritical: false,
              chainDepth: chainDepth + 1,
            );
          }
        }
      }

      if (isCritical) {
        if (chainDepth < 2) {
          bursts.add(
            FxBurst(
              pos: m.pos,
              colorHex: 0xFFFFD166,
              maxRadius: 56,
              isTriangleShatter: true,
            ),
          );
          bool hitChainNeighbor = false;
          for (final near in List<ActiveMutant>.from(mutants)) {
            if (near.pos.distanceTo(m.pos) <= 58.0) {
              hitChainNeighbor = true;
              _applyDamageToMutant(
                near,
                effectiveDmg * 0.52,
                sourceKey: chainSourceKey,
                sourceLabel: sourceLabel,
                knockDir: (near.pos - m.pos).normalized,
                knockForce: knockForce * 0.7,
                isCritical: true,
                halfArmorPenetration: true,
                chainDepth: chainDepth + 1,
              );
            }
          }
          if (hitChainNeighbor) {
            chainShatterCount++;
          }
        }
      } else if (m.kind.splitsOnDeath) {
        for (final dx in [-10.0, 10.0]) {
          final childSpd = MutantKind.swarmRat.speed *
              1.30 *
              (1.0 + (stage.chapterNumber - 1) * 0.02) *
              difficulty.speedMult;
          mutants.add(
            ActiveMutant(
              uid: _nextMutantUid++,
              kind: MutantKind.swarmRat,
              laneIndex: m.laneIndex,
              waypoints: m.waypoints,
              pos: m.pos + Vec2(dx, 0),
              maxHp: m.maxHp * 0.28,
              speed: childSpd,
              lateralSeed: rng.nextDouble() * pi * 2,
              laneLateralOffset: m.isInfiltrator ? 0.0 : dx * 0.7,
            )
              ..isInfiltrator = m.isInfiltrator
              ..infiltratorStyle = m.infiltratorStyle
              ..spawnedWaveIndex = m.spawnedWaveIndex
              ..attackScaleSnapshot = m.attackScaleSnapshot
              ..waypointIndex = m.waypointIndex
              ..headingRad = m.headingRad
              ..smoothVel = m.smoothVel.length > 2.0
                  ? m.smoothVel.normalized * childSpd
                  : Vec2(cos(m.headingRad) * childSpd, sin(m.headingRad) * childSpd),
          );
        }
      }

      _rewardMutantKill(
        m,
        bonusTokenMult: isCritical ? 1.25 : 1.0,
        sourceKey: sourceKey,
        sourceLabel: sourceLabel,
      );
    }
  }

  void _rewardMutantKill(
    ActiveMutant m, {
    required double bonusTokenMult,
    required String sourceKey,
    required String sourceLabel,
  }) {
    killCount++;
    killStreak++;
    if (killStreak > bestKillStreak) bestKillStreak = killStreak;
    killStreakTimer = 3.2;

    // 연속 격살 체인 달성 시 보너스 기력 & 피버 열기 급상승 & 무쌍 배너!
    if (killStreak == 12 || killStreak == 25 || killStreak == 45 || (killStreak >= 70 && killStreak % 30 == 0)) {
      final streakBonus = killStreak >= 45 ? 10 : (killStreak >= 25 ? 7 : 4);
      fieldTokens += streakBonus;
      feverGauge = (feverGauge + 16.0).clamp(0.0, 100.0);
      _spawnFlyingQiOrb(m.pos, streakBonus, colorHex: 0xFFFF6B35);
      screenShakeTimer = max(screenShakeTimer, 0.16);
      screenShakeIntensity = max(screenShakeIntensity, 3.6);
      callouts.add(
        FloatingCallout(
          pos: const Vec2(200, 132),
          text: '🔥 $killStreak연속 무쌍 학살!! (+$streakBonus⚡ · 열기 급상승!)',
          colorHex: 0xFFFF6B35,
          ttlSec: 1.5,
          isBigBanner: true,
        ),
      );
    }

    final warChestMult = 1.0 + perkStacks(RoguePerk.warChest) * 0.25;
    final baseDrop = m.kind == MutantKind.sickHound && killCount % 3 == 0
        ? 2
        : m.kind.dropTokens;
    // 전투 중 건설 기력(fieldTokens)은 난이도가 높다고 부풀려 주지 않아야 진정한 고난이도 긴장감이 유지됨!
    // 단, 소수점 누적 보급통(_fieldTokenCarry)으로 혈자리 기력 획득 +10% 보너스가 1⚡ 소형 몹에서도 정확히 누적 발동!
    final rawDrop = baseDrop *
        bonusTokenMult *
        warChestMult *
        (1.0 + progress.meridianTokenDropBonus);
    _fieldTokenCarry += rawDrop;
    final drop = _fieldTokenCarry.floor().clamp(0, 160);
    if (drop > 0) {
      _fieldTokenCarry -= drop;
      fieldTokens += drop;
    }
    _permTokenCarry += rawDrop * 0.34 * difficulty.rewardMult;
    final permWhole = _permTokenCarry.floor();
    if (permWhole > 0) {
      _permTokenCarry -= permWhole;
      earnedPermanentTokens += permWhole.clamp(1, 150);
    }
    // 화면이 지저분해지지 않도록 1⚡ 소형 구슬은 2마리당 1번씩 묶어 쏘고 중대형·보스는 즉시 발사!
    if (drop >= 2 || killCount.isEven) {
      _spawnFlyingQiOrb(
        m.pos,
        drop,
        colorHex: m.kind.isBoss ? 0xFF72EFDD : 0xFFFFD166,
      );
    }
  }

  void _triggerBossPhaseEvolution(ActiveMutant m) {
    m.currentPhase++;
    bossPhaseBreakCount++;
    m.phaseTransitionTimer = 0.68;
    m.groggyExposeTimer = 0.0;
    m.freezeTimer = 0.0;
    m.mutationScale = m.currentPhase == 2 ? 1.18 : 1.32;
    m.weakSpotAngleRad = rng.nextDouble() * pi * 2;

    if (m.totalPhases == 2) {
      m.currentMaxHp = m.maxHp * 1.10;
      m.maxCarapacePlates = 2;
    } else {
      m.currentMaxHp = m.maxHp * (m.currentPhase == 2 ? 0.90 : 1.15);
      m.maxCarapacePlates = m.currentPhase == 2 ? 3 : 4;
    }
    m.carapacePlatesLeft = m.maxCarapacePlates;
    m.hp = m.currentMaxHp;

    // 페이즈 격파 보상 기력 지급!
    const phaseQi = 18;
    fieldTokens += phaseQi;
    _spawnFlyingQiOrb(m.pos, phaseQi, colorHex: 0xFFFFD166);

    // 재변이 충격파와 함께 변이 호위병 즉석 소환!
    final escortCount = m.currentPhase >= 3 ? 3 : 2;
    for (int e = 0; e < escortCount; e++) {
      final escortKind = e == 0
          ? (stage.chapterNumber >= 4 ? MutantKind.shieldYacha : MutantKind.sickHound)
          : (e == 1
              ? (stage.chapterNumber >= 3 ? MutantKind.plagueToad : MutantKind.swarmRat)
              : MutantKind.ironBoar);
      encounteredMutants.add(escortKind);
      final escortSpd = escortKind.speed *
          1.92 *
          (1.0 + (stage.chapterNumber - 1) * 0.024) *
          difficulty.speedMult;
      final offsetX = (e - (escortCount - 1) / 2.0) * 28.0;
      mutants.add(
        ActiveMutant(
          uid: _nextMutantUid++,
          kind: escortKind,
          laneIndex: m.laneIndex,
          waypoints: m.waypoints,
          pos: Vec2(
            (m.pos.x + offsetX).clamp(28.0, CampaignCatalog.arenaWidth - 28.0),
            m.pos.y,
          ),
          maxHp: escortKind.baseHp *
              escortKind.swarmHpFactor *
              _monsterHpScaleForWave(m.spawnedWaveIndex) *
              (stage.chapterNumber == 1 ? 0.85 : 1.0) *
              difficulty.hpMult,
          speed: escortSpd,
          lateralSeed: rng.nextDouble() * pi * 2,
          laneLateralOffset: offsetX * 0.4,
        )
          ..spawnedWaveIndex = m.spawnedWaveIndex
          ..attackScaleSnapshot = m.attackScaleSnapshot
          ..waypointIndex = m.waypointIndex
          ..headingRad = m.headingRad
          ..smoothVel = Vec2(cos(m.headingRad) * escortSpd, sin(m.headingRad) * escortSpd),
      );
    }

    pendingSounds.add(SoundCue.villageWarning);
    pendingSounds.add(SoundCue.criticalShatter);
    screenShakeTimer = max(screenShakeTimer, m.currentPhase >= 3 ? 0.46 : 0.34);
    screenShakeIntensity = max(screenShakeIntensity, m.currentPhase >= 3 ? 8.2 : 6.2);
    bursts.add(
      FxBurst(
        pos: m.pos,
        colorHex: m.currentPhase >= 3 ? 0xFFFF006E : 0xFFC77DFF,
        maxRadius: m.currentPhase >= 3 ? 105.0 : 82.0,
        ttlSec: 0.62,
        durationSec: 0.62,
        isTriangleShatter: true,
      ),
    );

    final banner = m.totalPhases == 2
        ? '🧬 [${m.displayName}] 2차 흉폭 재변이!! 🛡️장갑 2겹 · 🎯약점을 노려라!'
        : (m.currentPhase == 2
            ? '🌋 [${m.displayName}] 제2페이즈 재변이!! 🛡️장갑 3겹 · 🎯약점 다격!'
            : '💀 [${m.displayName}] 최종 3페이즈 진신 폭주!! 🛡️장갑 4겹 · 🎯약점 파쇄!');
    bossInvasionAlertText = banner;
    bossInvasionAlertTimer = 3.8;
    callouts.add(
      FloatingCallout(
        pos: m.pos + const Vec2(0, -32),
        text: banner,
        colorHex: m.currentPhase >= 3 ? 0xFFFF4D6D : 0xFFFFD166,
        ttlSec: 2.3,
        isBigBanner: true,
      ),
    );
  }

  ActiveMutant? _pickMostThreateningMutant(Vec2 origin, {required double maxRange}) {
    ActiveMutant? best;
    double bestDistToVillage = 999999;
    for (final m in mutants) {
      if (m.phaseTransitionTimer > 0) continue;
      if (m.pos.distanceTo(origin) > maxRange) continue;
      final dVillage = m.pos.distanceTo(shieldCenter);
      if (dVillage < bestDistToVillage) {
        bestDistToVillage = dVillage;
        best = m;
      }
    }
    return best;
  }

  ActiveMutant? _pickTargetForLauncher(ActiveLauncher l) {
    ActiveMutant? best;
    double bestScore = -999999;
    final maxR = effectiveLauncherRange(l);
    final minR = l.type.minRangePx;
    for (final m in mutants) {
      if (m.phaseTransitionTimer > 0) continue;
      final dist = m.pos.distanceTo(l.pos);
      if (dist > maxR || dist < minR) continue;
      double score = 1100.0 - m.pos.distanceTo(shieldCenter);
      if (m.isInfiltrator) {
        score += 125.0; // 길 밖에서 직선 기습하는 월담·땅굴·공중강습 침투조 우선 요격!
      }
      if (m.kind.isFlying && (l.type == LauncherType.rapid || l.type == LauncherType.curveSpin)) {
        score += 135.0; // 대공 화망 우선 조준!
      }
      final canCrackWeak = l.terrainType.cracksBossWeakPoint &&
          (l.type == LauncherType.heavy || l.type == LauncherType.curveSpin);
      if (canCrackWeak && m.hasActiveWeakPoint) {
        score += 210.0; // 약점 파쇄 자격이 있는 중포·곡사 초소만 장갑 보스 최우선 조준!
      }
      if (l.type == LauncherType.heavy && (m.kind.isBoss || m.kind.toughnessRating >= 4)) {
        score += 185;
      } else if (l.type == LauncherType.curveSpin && m.kind.frontShieldReduction >= 0.25) {
        score += 185;
      } else if (l.type == LauncherType.frostField && m.freezeTimer <= 0) {
        score += 130 + (m.kind.speedRating >= 4 ? 70 : 0);
      } else if (l.type == LauncherType.rapid) {
        if (m.kind.speedRating >= 4 && !m.kind.isBoss) {
          score += 85;
        } else if (stage.chapterNumber >= 3 && m.kind.isBoss && m.carapacePlatesLeft > 0) {
          score -= 190; // 외각 장갑 보스에게 탄을 낭비하지 않고 잡몹·비행 변이를 먼저 정리!
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }

  int _countMutantsNear(Vec2 center, double radius) {
    int c = 0;
    for (final m in mutants) {
      if (m.pos.distanceTo(center) <= radius) c++;
    }
    return c;
  }

  String _compassForPos(Vec2 p) {
    final horiz = p.x < 255.0 ? '서' : (p.x > 465.0 ? '동' : '중앙');
    final vert = p.y < 380.0 ? '북' : (p.y < 760.0 ? '중' : '남');
    if (horiz == '중앙') return '$vert단';
    return '$vert$horiz';
  }

  String _describeArenaZone(ActiveMutant m) {
    if (m.pos.distanceTo(chapter.granaryPos) <= 135.0) {
      return '${_compassForPos(chapter.granaryPos)} 식량창고';
    }
    if (m.pos.distanceTo(chapter.livestockPos) <= 135.0) {
      return '${_compassForPos(chapter.livestockPos)} 가축우리';
    }
    if (m.pos.distanceTo(chapter.cropsPos) <= 145.0) {
      return '${_compassForPos(chapter.cropsPos)} 황금논밭';
    }
    if (m.pos.distanceTo(shieldCenter) <= CampaignCatalog.outerShieldRadius + 38.0) {
      return '${_compassForPos(shieldCenter)} 수호제단 결계';
    }
    final horiz = m.pos.x < 255.0
        ? '서쪽'
        : (m.pos.x > 465.0 ? '동쪽' : '중앙');
    final vert = m.pos.y < 360.0
        ? '북단'
        : (m.pos.y < 660.0 ? '중단' : '하단');
    if (m.kind.isFlying) {
      return '$vert $horiz 상공 방공망';
    }
    if (m.isInfiltrator) {
      return m.infiltratorStyle == 'tunnel'
          ? '$vert $horiz 지하 땅굴'
          : '$vert $horiz 성벽 월담지';
    }
    return '$vert $horiz 석교 길목';
  }

  /// 실시간 위험 비상 알림 & 돌연변이 공격 지점 2.8배 확대 영상 모니터 갱신!
  void _stepCrisisAlertMonitor(double dt) {
    if (isFinished || mutants.isEmpty) {
      activeCrisis = null;
      _crisisCamFocus = null;
      return;
    }

    final shieldRatio = shieldMaxHpDynamic > 0
        ? (shieldHp / shieldMaxHpDynamic).clamp(0.0, 1.0)
        : 0.0;
    final towerRatio = centralSpec.coreMaxHp > 0
        ? (towerHp / centralSpec.coreMaxHp).clamp(0.0, 1.0)
        : 0.0;

    ActiveMutant? urgentTarget;
    double bestThreatScore = -1.0;
    bool directHitNow = false;

    for (final m in mutants) {
      final distAltar = m.pos.distanceTo(shieldCenter);
      final hittingAltar = m.altarHitFlashTimer > 0.05 ||
          distAltar <= CampaignCatalog.outerShieldRadius + m.effectiveRadius + 24.0;
      final proxBoost = max(0.0, 920.0 - distAltar) * 0.26;
      double score = 0.0;

      if (hittingAltar) {
        score = 1000.0 - distAltar + (m.kind.isBoss ? 220.0 : 0.0);
      } else if ((shieldRatio <= 0.62 || towerRatio < 0.96 || cropsHealth < 0.92) &&
          distAltar <= 340.0) {
        score = 820.0 - distAltar + (m.kind.isBoss ? 180.0 : 0.0);
      } else if (m.kind.isBoss && (distAltar <= 880.0 || m.maxHitShield >= 100)) {
        score = 680.0 + proxBoost + (m.maxHitShield >= 1000 ? 120.0 : 0.0);
      } else if ((m.kind.isFlying || m.isInfiltrator) && distAltar <= 680.0) {
        score = 560.0 + proxBoost;
      } else if (distAltar <= 220.0) {
        score = 500.0 - distAltar;
      }

      if (score > bestThreatScore) {
        bestThreatScore = score;
        urgentTarget = m;
        directHitNow = hittingAltar;
      }
    }

    if (urgentTarget == null || bestThreatScore <= 0) {
      activeCrisis = null;
      _crisisCamFocus = null;
      return;
    }

    final prevFocus = _crisisCamFocus;
    final desiredFocus = urgentTarget.pos;
    if (prevFocus == null || prevFocus.distanceTo(desiredFocus) > 260.0) {
      _crisisCamFocus = desiredFocus;
    } else {
      final blend = min(1.0, dt * 8.5);
      _crisisCamFocus = Vec2(
        prevFocus.x + (desiredFocus.x - prevFocus.x) * blend,
        prevFocus.y + (desiredFocus.y - prevFocus.y) * blend,
      );
    }

    final zone = _describeArenaZone(urgentTarget);
    final double severity = directHitNow
        ? 1.0
        : (shieldRatio <= 0.50
            ? 0.94
            : (urgentTarget.maxHitShield >= 1000
                ? 0.90
                : (urgentTarget.kind.isBoss || urgentTarget.kind.isFlying ? 0.80 : 0.68)));

    final String headline;
    if (directHitNow) {
      headline = '🚨 비상 경보! [$zone] ${urgentTarget.displayName} 결계 강타 중!';
    } else if (urgentTarget.maxHitShield >= 1000) {
      headline =
          '🚨 천련보스 경보! [$zone] ${urgentTarget.displayName} (${urgentTarget.totalHitsTaken}/${urgentTarget.maxHitShield}타)';
    } else if (urgentTarget.kind.isFlying) {
      headline = '🚨 방공 비상! [$zone] 공중 변이 [${urgentTarget.displayName}] 강습!';
    } else if (urgentTarget.isInfiltrator) {
      headline = '🚨 기습 경보! [$zone] [${urgentTarget.displayName}] 우회 침투!';
    } else {
      headline = '⚠️ 위험 감지! [$zone] [${urgentTarget.displayName}] 본진 육박!';
    }

    activeCrisis = CrisisAlertInfo(
      zoneName: zone,
      headline: headline,
      attackerUid: urgentTarget.uid,
      attackerKind: urgentTarget.kind,
      attackerName: urgentTarget.displayName,
      focusPos: _crisisCamFocus!,
      rawTargetPos: urgentTarget.hasActiveWeakPoint
          ? urgentTarget.weakSpotWorldPos
          : urgentTarget.pos,
      severity: severity,
      isDirectAttack: directHitNow,
      totalHitsTaken: urgentTarget.totalHitsTaken,
      hitShieldLeft: urgentTarget.hitShieldLeft,
      maxHitShield: urgentTarget.maxHitShield,
    );
  }

  void _stepVisualTimers(double dt) {
    if (screenShakeTimer > 0) {
      screenShakeTimer = max(0.0, screenShakeTimer - dt);
      if (screenShakeTimer <= 0) {
        screenShakeIntensity = 0.0;
      }
    }
    if (bossInvasionAlertTimer > 0) {
      bossInvasionAlertTimer = max(0.0, bossInvasionAlertTimer - dt);
      if (bossInvasionAlertTimer <= 0) {
        bossInvasionAlertText = null;
      }
    }
    for (int i = flyingQiOrbs.length - 1; i >= 0; i--) {
      final orb = flyingQiOrbs[i];
      orb.progress += dt * 2.1;
      if (orb.progress >= 1.0) {
        flyingQiOrbs.removeAt(i);
      } else {
        final t = orb.progress;
        final inv = 1.0 - t;
        final ctrl = Vec2(
          (orb.startPos.x + orb.targetPos.x) * 0.5 - 32.0,
          min(orb.startPos.y, orb.targetPos.y) - 28.0,
        );
        orb.currentPos = orb.startPos * (inv * inv) +
            ctrl * (2 * inv * t) +
            orb.targetPos * (t * t);
      }
    }
    for (int i = lightningArcs.length - 1; i >= 0; i--) {
      lightningArcs[i].ttlSec -= dt;
      if (lightningArcs[i].ttlSec <= 0) lightningArcs.removeAt(i);
    }
    for (int i = muzzleFlashes.length - 1; i >= 0; i--) {
      muzzleFlashes[i].ttlSec -= dt;
      if (muzzleFlashes[i].ttlSec <= 0) muzzleFlashes.removeAt(i);
    }
    for (int i = shockwaveRings.length - 1; i >= 0; i--) {
      shockwaveRings[i].ttlSec -= dt;
      if (shockwaveRings[i].ttlSec <= 0) shockwaveRings.removeAt(i);
    }
    for (int i = deathRagdolls.length - 1; i >= 0; i--) {
      final r = deathRagdolls[i];
      r.ttlSec -= dt;
      if (r.ttlSec <= 0) {
        deathRagdolls.removeAt(i);
      } else {
        r.pos = r.pos + r.vel * dt;
        r.vel = r.vel * max(0.0, 1.0 - 4.2 * dt);
        r.rotationRad += r.spinVel * dt;
      }
    }
    for (int i = damagePopups.length - 1; i >= 0; i--) {
      final dp = damagePopups[i];
      dp.ttlSec -= dt;
      if (dp.ttlSec <= 0) {
        damagePopups.removeAt(i);
      } else {
        dp.pos = dp.pos + dp.vel * dt;
        dp.vel = Vec2(dp.vel.x * 0.92, dp.vel.y + 82.0 * dt);
      }
    }
    final seenCalloutTexts = <String>{};
    for (int i = callouts.length - 1; i >= 0; i--) {
      callouts[i].ttlSec -= dt;
      callouts[i].pos = callouts[i].pos + const Vec2(0, -14 * 0.016);
      if (callouts[i].ttlSec <= 0 || !seenCalloutTexts.add(callouts[i].text)) {
        callouts.removeAt(i);
      }
    }
    if (callouts.length > 6) {
      callouts.removeRange(0, callouts.length - 6);
    }
    for (int i = bursts.length - 1; i >= 0; i--) {
      bursts[i].ttlSec -= dt;
      if (bursts[i].ttlSec <= 0) bursts.removeAt(i);
    }
    if (bursts.length > 48) {
      bursts.removeRange(0, bursts.length - 48);
    }
  }

  void _checkWinLoseCondition() {
    if (shieldHp <= 0 && towerHp <= 0) {
      isFinished = true;
      isVictory = false;
      granaryHealth = 0.0;
      cropsHealth = 0.0;
      livestockHealth = 0.0;
      villageTookDamage = true;
      pendingSounds.add(SoundCue.loseBell);
      return;
    }

    final allWavesDone =
        currentWaveIndex + 1 >= stage.waves.length && _spawnQueue.isEmpty && mutants.isEmpty;
    if (allWavesDone) {
      isFinished = true;
      isVictory = true;
      wavesClearedCount = stage.waves.length;
      dawnPurifyAnimTimer = 1.5;
      earnedElixirs += stage.clearElixirBonus +
          (stage.isBossStage ? (2 + (stage.chapterNumber ~/ 3)) : 0);
      earnedPermanentTokens += stage.isReincarnationBossStage
          ? 320
          : (20 + stage.chapterNumber * 8);
      pendingSounds.add(SoundCue.dawnPurify);
    }
  }

  BattleSummary buildSummary() {
    if (isFinished && _cachedSummary != null) {
      return _cachedSummary!;
    }
    _syncVillagePurification();
    final ecoAvg = (granaryHealth + cropsHealth + livestockHealth) / 3.0;
    final ecoMin = min(granaryHealth, min(cropsHealth, livestockHealth));
    int stars = 0;
    if (isVictory) {
      if (shieldHp > 0 &&
          !villageTookDamage &&
          !towerTookDamage &&
          ecoAvg >= 0.99 &&
          ecoMin >= 0.99) {
        stars = 3;
      } else if (ecoAvg >= 0.55) {
        stars = 2;
      } else {
        stars = 1;
      }
    }

    int finalTokens = earnedPermanentTokens;
    int finalElixirs = earnedElixirs;
    if (isVictory &&
        allowSerendipity &&
        rng.nextDouble() < (0.24 + progress.meridianSerendipityBonus)) {
      finalTokens = (finalTokens * 1.5).round();
      finalElixirs += 1;
      serendipityCount++;
    }

    final contribList = List<ContributionEntry>.unmodifiable(
      (_contribMap.values
              .map(
                (e) => ContributionEntry(
                  key: e.key,
                  label: e.label,
                  totalDamage: e.totalDamage,
                  kills: e.kills,
                ),
              )
              .toList()
            ..sort((a, b) => b.totalDamage.compareTo(a.totalDamage))),
    );

    String tip;
    if (isVictory) {
      tip = stars == 3
          ? '완벽한 수호 진법입니다! 외곽 결계와 마을 3요소를 든든히 지켜냈습니다!'
          : '승리했습니다! 초소 조합 시너지와 돌파 비급·합치기 진화를 활용하면 ★3 만점 수호가 쉬워집니다.';
    } else if (launchers.isEmpty) {
      tip = '길목 초소가 0곳이라 본진이 돌파당했습니다! 초반 군수 기력(⚡)으로 반드시 빈 초소에 지정 축조(45⚡~) 또는 도박 소환(50⚡~)을 실행하세요!';
    } else if (shieldYachaBlocks >= 6) {
      tip = '뼈방패 야차에게 정면 탄이 막혔습니다! 거점에 「곡사 회전기」를 세우거나 「파갑 멸마송」 비급을 선택해보세요.';
    } else if (heavyHitsOnShield >= 3) {
      tip = '중갑 돌진 변이체가 방어막을 부쉈습니다! 「중포 탄지기 + 한빙 역장기(쇄빙 파쇄진)」 조합을 배치해보세요.';
    } else if (swarmHitsOnShield >= 5) {
      tip = '빠른 무리에 포위되었습니다! 「속사 탄지기」 건설과 「쌍탄 분열비급 · 홍련 폭렬파」 비급을 활용해보세요.';
    } else {
      tip = '기명 심법 수련에서 혈자리를 개통하고, 전장의 화약통과 ×2 복제 마법진을 중앙탑 수동 탄지로 노려보세요!';
    }

    final summary = BattleSummary(
      victory: isVictory,
      stars: stars,
      earnedTokens: finalTokens,
      earnedElixirs: finalElixirs,
      usedSupportCount: usedSupportCount,
      pporokCount: pporokCount,
      bankShotCount: bankShotCount,
      chainShatterCount: chainShatterCount,
      serendipityCount: serendipityCount,
      granaryRatio: granaryHealth,
      cropsRatio: cropsHealth,
      livestockRatio: livestockHealth,
      contributions: contribList,
      coachingTip: tip,
      killCount: killCount,
      wavesClearedCount: isVictory ? stage.waves.length : wavesClearedCount,
      encounteredMutants: Set<MutantKind>.unmodifiable(encounteredMutants),
      supportDeductedRealtime: true,
      bossElixirIncluded: true,
      convoyBuffConsumedRealtime: _convoyBuffConsumedRealtime,
      towerTookDamage: towerTookDamage,
    );
    if (isFinished) {
      _cachedSummary = summary;
    }
    return summary;
  }
}
