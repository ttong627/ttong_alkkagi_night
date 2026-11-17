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
    int? investedTokens,
  }) : investedTokens = investedTokens ?? type.buildCostTokens;

  final int slotIndex;
  final Vec2 pos;
  LauncherType type;
  final int permanentLevel;
  int investedTokens;
  int tier = 1;
  double cooldown = 0.22;
  double aimAngleRad = -pi / 2;
  double recoilAnim = 0.0;
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
  }) : hp = maxHp;

  final int uid;
  final MutantKind kind;
  final int laneIndex;
  final List<Vec2> waypoints;
  Vec2 pos;
  int waypointIndex = 1;
  final double maxHp;
  double hp;
  final double speed;
  final String? customName;
  final String? customPortrait;

  Vec2 knockbackVel = const Vec2(0, 0);
  double freezeTimer = 0.0;
  double freezeImmuneTimer = 0.0;
  double slowTimer = 0.0;
  double oilSlipTimer = 0.0;
  bool cliffChecked = false;
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
    this.oilsOnHit = false,
    this.ignoresShield = false,
    this.isGiantCritSerendipity = false,
    this.clonedByGate = false,
    this.splitChild = false,
    this.maxTravelDist = 230.0,
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
  final bool oilsOnHit;
  bool ignoresShield;
  final bool isGiantCritSerendipity;
  bool clonedByGate;
  final bool splitChild;
  double maxTravelDist;
  double traveledDist = 0.0;

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
  ContributionEntry({required this.key, required this.label});
  final String key;
  final String label;
  double totalDamage = 0;
  int kills = 0;
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
}

class _PendingSpawn {
  _PendingSpawn({
    required this.delaySec,
    required this.kind,
    required this.laneIndex,
    this.customTitle,
    this.customPortrait,
  });

  double delaySec;
  final MutantKind kind;
  final int laneIndex;
  final String? customTitle;
  final String? customPortrait;
}

/// 《수호알까기 · 탄지무림 심야기습》 실시간 & 자동 검증 공용 2차원 물리 전투 시뮬레이터.
class DefenseBattleSim {
  DefenseBattleSim({
    required this.stage,
    required this.difficulty,
    required this.progress,
    LoadoutPreset? overridePreset,
    int seed = 20261115,
    this.allowSupportTokens = true,
    this.allowSerendipity = true,
    this.autoBuildForSimVerify = false,
  })  : chapter = CampaignCatalog.chapterOf(stage.chapterNumber),
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

  /// 자동 검증 시뮬레이터(`defense_verify_sim`)에서만 true로 두어 빈 초소를 순차 건설·승급한다.
  /// 실제 플레이에서는 false이며, 전투 시작 시 길목 발사대는 0개(모두 빈 초소)이고 플레이어가 직접 배치한다!
  final bool autoBuildForSimVerify;

  /// 운빨 무작위 초소 소환 비용 (일반 지정 건설 45~60기력보다 저렴하며 대박 시 2·3형 즉시 강림!).
  static const int luckySummonCostTokens = 35;

  /// 중앙 기명 수호탑의 자동 모드 근접 경계 사거리 (본진 결계 코앞 마지막 굽이만 경계!).
  static const double centralAutoMaxRange = 136.0;

  /// 중앙 기명 수호탑의 수동 탄지 기본 유효 사거리 (무제한 전장 저격 차단 · 하단~중하단 권역 정밀 도탄!).
  static const double centralManualBaseRange = 195.0;

  late final CentralGuardianSpec centralSpec;
  late double shieldMaxHpDynamic;
  late double shieldHp;
  late double towerHp;
  double centralFireTimer = 0.25;
  double centralGearAngle = 0.0;

  /// 맨 아래 중앙 기명 수호탑 `자동 발사` ↔ `수동 탄지` 전환 상태 및 수동 공명 타이머.
  bool centralManualMode = false;
  double centralAimAngleRad = -pi / 2;
  double centralRecoilAnim = 0.0;
  double manualResonanceTimer = 0.0;

  /// 길목 초소가 최소 1곳 설치되었거나 수동 탄지 공명이 살아 있을 때만 진법(영수·동료·회복)이 활성화됨!
  bool get isFormationActive => launchers.isNotEmpty || manualResonanceTimer > 0;

  bool get isCentralReadyToFire => !isFinished && towerHp > 0 && centralFireTimer <= 0.04;

  /// 마을 생태계 3대 지표 (1.0 = 평온/풍요, 0.0 = 황폐/폐사).
  double granaryHealth = 1.0;
  double cropsHealth = 1.0;
  double livestockHealth = 1.0;

  /// 현장 건설 기력(⚡ · 초소 건설/승급 전용) 및 정산 누적 보상.
  int fieldTokens = 0;
  int earnedPermanentTokens = 0;
  int earnedElixirs = 0;
  double _permTokenCarry = 0.0;

  /// 내공 게이지 (0.0 ~ 3.0칸) 및 전술 비약 버프 타이머.
  double qiBars = 0.0;
  double _autoEogiCooldown = 0.0;
  double jeonggakHasteTimer = 0.0;
  double cheonghakBuffTimer = 0.0;
  double auroraCritTimer = 0.0;

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

  /// 중앙 기명 수호탑의 현재 자동 경계 유효 사거리.
  double get effectiveCentralAutoRange =>
      (centralAutoMaxRange * liveRangeMultiplier).clamp(120.0, 185.0);

  /// 중앙 기명 수호탑의 현재 수동 탄지 유효 사거리 (조준선 및 탄알 비거리 한계선).
  double get effectiveCentralManualRange =>
      (centralManualBaseRange * liveRangeMultiplier).clamp(190.0, 282.0);

  /// 개별 길목 초소(ActiveLauncher)의 현재 유효 사거리 (발사대 계통별 고유 사거리 + 승급 + 인접 증폭기 + 실시간 사거리업 반영).
  double effectiveLauncherRange(ActiveLauncher l) {
    double mult = liveRangeMultiplier * (1.0 + progress.corePrecisionBonus * 0.30);
    if (l.type != LauncherType.qiAmplifier) {
      for (final other in launchers) {
        if (other != l &&
            other.type == LauncherType.qiAmplifier &&
            other.pos.distanceTo(l.pos) <= 140.0) {
          mult += 0.14 + other.tier * 0.02;
          break;
        }
      }
    }
    return (l.type.effectiveBaseRange(l.tier) * mult).clamp(96.0, 236.0);
  }

  /// 빈 초소 선택·미리보기 시 표시할 예정 유효 사거리.
  double previewSlotRange(LauncherMountSlot slot) =>
      (slot.recommendedType.baseRangePx * liveRangeMultiplier).clamp(96.0, 220.0);

  /// 길이 아닌 옆숲·땅굴 비정규 침투 기습 타이머 및 출몰 카운트!
  double infiltrationTimer = 8.8;
  int infiltratorSpawnCount = 0;

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
    );
    shieldMaxHpDynamic = centralSpec.shieldMaxHp;
    shieldHp = shieldMaxHpDynamic;
    towerHp = centralSpec.coreMaxHp;

    final buffMult = progress.convoySupplyBuffBattles > 0 ? 1.20 : 1.0;
    fieldTokens = (stage.startingFieldTokens * buffMult).round();
    qiBars = (progress.realm.startQiBars + progress.meridianStartQiBonus).clamp(0.0, 3.0);

    if (allowSupportTokens) {
      supportChargesLeft = min(preset.supportSlotCount, progress.supportTokens);
    }

    launchers.clear();

    // 전장 핀볼 기물 초기화: 구곡양장 아홉 굽이길 중하단 요충지에 배치하여 제한된 사거리·도탄으로 노리는 재미 극대화!
    cloneGate = CloneGateZone(
      baseCenter: const Vec2(200, 402),
      radius: 23.0,
      swayAmplitude: 54.0,
    );
    powerTarget = PowerTargetProp(
      baseCenter: const Vec2(200, 298),
      radius: 19.0,
      swayAmplitude: 58.0,
    );
    powderKegs
      ..clear()
      ..add(PowderKegProp(pos: const Vec2(88, 366)))
      ..add(PowderKegProp(pos: const Vec2(312, 248)));

    for (final _ in chapter.pillars) {
      pillarAngles.add(0.0);
    }
    for (final _ in chapter.lanes) {
      lanePortalEnergy.add(0.0);
    }

    beastCooldown = 1.8;
    for (final hero in preset.companions) {
      if ((progress.companionLevels[hero] ?? 0) > 0) {
        companionCooldowns[hero] = 2.0 + companionCooldowns.length * 0.9;
      }
    }

    if (!autoBuildForSimVerify && stage.hasRescueReward) {
      callouts.add(
        FloatingCallout(
          pos: const Vec2(200, 126),
          text: '🆘 ${stage.rescueBadgeText} 작전!',
          colorHex: 0xFF72EFDD,
          ttlSec: 2.8,
          isBigBanner: true,
        ),
      );
    }

    _enqueueWave(0);
  }

  /// 초소 번호별 물결 봉인 해제 기준 (0~2번: 1물결 즉시, 3~5번: 2물결, 6~9번: 3물결 개방!).
  int unlockWaveNumberForSlot(int slotIndex) {
    if (slotIndex <= 2) return 1;
    if (slotIndex <= 5) return 2;
    return 3;
  }

  /// 현재 물결에서 해당 초소의 봉인이 풀려 건설 가능한지 여부.
  bool isSlotWaveUnlocked(int slotIndex) =>
      (currentWaveIndex + 1) >= unlockWaveNumberForSlot(slotIndex);

  /// 상단 건설 기력 바 & 초소 발판에 표시할 실시간 조건 상태 계산!
  PadConditionInfo padConditionOf(int slotIndex) {
    final slot = mountSlotByIndex(slotIndex);
    final recCost = slot?.recommendedType.buildCostTokens ?? 45;
    final unlockWave = unlockWaveNumberForSlot(slotIndex);

    if (launcherAtSlot(slotIndex) != null) {
      return PadConditionInfo(
        slotIndex: slotIndex,
        state: PadConditionState.built,
        unlockWaveNumber: unlockWave,
        currentQi: fieldTokens,
        luckySummonCost: luckySummonCostTokens,
        directBuildCost: recCost,
        chargeRatio: 1.0,
        shortBadge: '가동 중',
        detailReason: '배치 완료된 초소입니다. 터치하여 승급·합치기·교체·철거할 수 있습니다.',
      );
    }

    if (!isSlotWaveUnlocked(slotIndex)) {
      return PadConditionInfo(
        slotIndex: slotIndex,
        state: PadConditionState.waveLocked,
        unlockWaveNumber: unlockWave,
        currentQi: fieldTokens,
        luckySummonCost: luckySummonCostTokens,
        directBuildCost: recCost,
        chargeRatio: ((currentWaveIndex + 1) / unlockWave).clamp(0.0, 0.99),
        shortBadge: '🔒$unlockWave물결 개방',
        detailReason: '전방 전략 초소입니다! 제$unlockWave물결에 진입하면 봉인이 자동으로 해제됩니다.',
      );
    }

    if (fieldTokens >= recCost) {
      return PadConditionInfo(
        slotIndex: slotIndex,
        state: PadConditionState.readyFullBuild,
        unlockWaveNumber: unlockWave,
        currentQi: fieldTokens,
        luckySummonCost: luckySummonCostTokens,
        directBuildCost: recCost,
        chargeRatio: 1.0,
        shortBadge: '🔨건설 가능!',
        detailReason: '건설 기력 충족! 운빨 대박 소환($luckySummonCostTokens⚡) 또는 지정 발사대($recCost⚡)를 즉시 세울 수 있습니다.',
      );
    }

    if (fieldTokens >= luckySummonCostTokens) {
      return PadConditionInfo(
        slotIndex: slotIndex,
        state: PadConditionState.readyLuckyOnly,
        unlockWaveNumber: unlockWave,
        currentQi: fieldTokens,
        luckySummonCost: luckySummonCostTokens,
        directBuildCost: recCost,
        chargeRatio: (fieldTokens / recCost).clamp(0.0, 0.99),
        shortBadge: '🎲운빨가능($luckySummonCostTokens⚡)',
        detailReason: '운빨 무작위 소환($luckySummonCostTokens⚡) 즉시 가능! 지정 건설($recCost⚡)까지는 ${recCost - fieldTokens}⚡ 남았습니다.',
      );
    }

    return PadConditionInfo(
      slotIndex: slotIndex,
      state: PadConditionState.chargingQi,
      unlockWaveNumber: unlockWave,
      currentQi: fieldTokens,
      luckySummonCost: luckySummonCostTokens,
      directBuildCost: recCost,
      chargeRatio: (fieldTokens / luckySummonCostTokens).clamp(0.0, 0.99),
      shortBadge: '⚡$fieldTokens/$luckySummonCostTokens',
      detailReason: '변이 처치·화약통 유폭·물결 조기 호출로 기력(⚡)을 모으세요! (${luckySummonCostTokens - fieldTokens}⚡ 더 모으면 소환 가능)',
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

  /// 현재 물결에서 즉시 건설할 수 있는 다음 추천 빈 초소 번호 (모두 배치되었거나 물결 잠금이면 null).
  int? nextRecommendedSlotIndex() {
    for (final m in activeMounts) {
      if (isSlotWaveUnlocked(m.slotIndex) && launcherAtSlot(m.slotIndex) == null) {
        return m.slotIndex;
      }
    }
    return null;
  }

  /// 발사대 종류 해금 여부 확인.
  bool isLauncherTypeUnlocked(LauncherType type) =>
      type.unlockChapter <= max(stage.chapterNumber, progress.highestUnlockedChapter) + 1;

  void _spawnFlyingQiOrb(Vec2 fromPos, int amount, {int colorHex = 0xFFFFD166}) {
    if (amount <= 0) return;
    if (flyingQiOrbs.length >= 28) {
      flyingQiOrbs.removeAt(0);
    }
    flyingQiOrbs.add(
      FlyingQiOrb(
        startPos: fromPos,
        targetPos: const Vec2(138, 12),
        amount: amount,
        colorHex: colorHex,
      ),
    );
  }

  /// 빈 길목 초소에 플레이어가 직접 수호 발사대 신규 배치!
  bool placeLauncherInBattle(int slotIndex, LauncherType type) {
    if (isFinished) return false;
    final slot = mountSlotByIndex(slotIndex);
    if (slot == null || !isSlotWaveUnlocked(slotIndex)) return false;
    if (launcherAtSlot(slotIndex) != null) return false;
    if (!isLauncherTypeUnlocked(type)) return false;

    final cost = type.buildCostTokens;
    if (fieldTokens < cost) return false;
    fieldTokens -= cost;

    final permLv = progress.launcherPermanentLevels[type] ?? 1;
    final created = ActiveLauncher(
      slotIndex: slot.slotIndex,
      pos: slot.pos,
      type: type,
      permanentLevel: permLv,
      investedTokens: cost,
    );
    launchers.add(created);
    launchers.sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: slot.pos, colorHex: 0xFF72EFDD, maxRadius: 34));
    callouts.add(
      FloatingCallout(
        pos: slot.pos + const Vec2(0, -18),
        text: '🛠️ ${type.name} 건설 완료!',
        colorHex: 0xFF72EFDD,
      ),
    );
    return true;
  }

  /// 《운빨존많겜》 스타일 운빨 할인 무작위 초소 소환 (35⚡ — 15% 확률 3형 대박, 35% 확률 2형 강림, 미해금 상위 발사대도 출현!).
  ActiveLauncher? summonLuckyLauncherInBattle(int slotIndex) {
    if (isFinished) return null;
    final slot = mountSlotByIndex(slotIndex);
    if (slot == null || !isSlotWaveUnlocked(slotIndex)) return null;
    if (launcherAtSlot(slotIndex) != null) return null;
    if (fieldTokens < luckySummonCostTokens) return null;

    fieldTokens -= luckySummonCostTokens;

    final rolledType = LauncherType.values[rng.nextInt(LauncherType.values.length)];
    final tierRoll = rng.nextDouble();
    final int rolledTier = tierRoll < 0.16 ? 3 : (tierRoll < 0.50 ? 2 : 1);

    final permLv = progress.launcherPermanentLevels[rolledType] ?? 1;
    final created = ActiveLauncher(
      slotIndex: slot.slotIndex,
      pos: slot.pos,
      type: rolledType,
      permanentLevel: permLv,
      investedTokens: luckySummonCostTokens + (rolledTier - 1) * 25,
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
          text: '🎲 운빨 소환: 1형 ${rolledType.name}!',
          colorHex: rolledType.colorHex,
        ),
      );
    }
    return created;
  }

  /// 같은 종류·같은 형(1~4형 → 최대 ★5형 태초 신기!)의 다른 초소가 전장에 있는지 탐색.
  int? findMergePartnerSlot(int slotIndex) {
    final target = launcherAtSlot(slotIndex);
    if (target == null || target.tier >= 5) return null;
    for (final other in launchers) {
      if (other.slotIndex != slotIndex &&
          other.type == target.type &&
          other.tier == target.tier) {
        return other.slotIndex;
      }
    }
    return null;
  }

  /// 전장 전체에서 즉시 무료 합치기가 가능한 초소 쌍 조회 (하단 원터치 합체 편의 버튼용!).
  (int slotA, int slotB)? findAnyMergePair() {
    for (final l in launchers) {
      final partner = findMergePartnerSlot(l.slotIndex);
      if (partner != null) {
        return (l.slotIndex, partner);
      }
    }
    return null;
  }

  /// 하단 원터치 「☯️ 즉시 합치기」 편의 실행!
  bool quickMergeAnyPair() {
    final pair = findAnyMergePair();
    if (pair == null) return false;
    return mergeLauncherAtSlot(pair.$1);
  }

  /// 하단 원터치 「🎲 즉시 운빨소환(35⚡)」 편의 실행 (맵의 작은 초소를 직접 안 찾아 눌러도 즉시 배치!).
  ActiveLauncher? quickLuckySummonNextPad() {
    final nextSlot = nextRecommendedSlotIndex();
    if (nextSlot == null) return null;
    return summonLuckyLauncherInBattle(nextSlot);
  }

  /// 하단 원터치 「🔨 추천초소 즉시건설」 편의 실행!
  bool quickDirectBuildNextPad() {
    final nextSlot = nextRecommendedSlotIndex();
    if (nextSlot == null) return false;
    final slot = mountSlotByIndex(nextSlot);
    if (slot == null) return false;
    final rec = isLauncherTypeUnlocked(slot.recommendedType)
        ? slot.recommendedType
        : LauncherType.rapid;
    return placeLauncherInBattle(nextSlot, rec);
  }

  /// 같은 종류·같은 형 초소 2곳을 무료(0⚡)로 합쳐 상위 형(+1형, 최대 ★5형 태초 신기!) 무작위 진화 초소로 각성!
  bool mergeLauncherAtSlot(int slotIndex) {
    if (isFinished) return false;
    final target = launcherAtSlot(slotIndex);
    final partnerSlot = findMergePartnerSlot(slotIndex);
    if (target == null || partnerSlot == null) return false;
    final partner = launcherAtSlot(partnerSlot);
    if (partner == null) return false;

    launchers.remove(partner);
    final evolvedType = LauncherType.values[rng.nextInt(LauncherType.values.length)];
    target.type = evolvedType;
    target.tier = (target.tier + 1).clamp(2, 5);
    target.investedTokens += (partner.investedTokens * 0.75).round();
    mergeEvolutionCount++;
    serendipityCount++;

    final isMythic5 = target.tier >= 5;
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
            ? '🌟 태초 신기 강림!! ★5형 ${target.type.name} 초월 각성!!'
            : '☯️ 합치기 각성 진화!! ${target.tier}형 ${target.type.name} 탄생!',
        colorHex: 0xFFFFD166,
        isBigBanner: true,
      ),
    );
    return true;
  }

  /// 배치된 발사대 조합에 따른 실시간 무림 진법 시너지 연결선 계산!
  List<ActiveSynergyLink> get activeSynergyLinks {
    if (launchers.length < 2) return const [];
    final links = <ActiveSynergyLink>[];
    for (int i = 0; i < launchers.length; i++) {
      for (int j = i + 1; j < launchers.length; j++) {
        final a = launchers[i];
        final b = launchers[j];
        if (a.pos.distanceTo(b.pos) > 250) continue;
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
          links.add(
            ActiveSynergyLink(
              slotA: a.slotIndex,
              slotB: b.slotIndex,
              posA: a.pos,
              posB: b.pos,
              synergyName: '쌍성 공명진',
              bonusSummary: '합치기 가능 · 공속 +18%',
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

  /// 다음 물결을 즉시 앞당겨 호출하고 보너스 건설 기력 +18⚡ 획득!
  bool callNextWaveEarly() {
    if (!canCallNextWaveEarly) return false;
    final nextIdx = currentWaveIndex + 1;
    _earlyCalledWaves.add(nextIdx);
    wavesClearedCount = max(wavesClearedCount, currentWaveIndex + 1);
    currentWaveIndex = nextIdx;
    wavePauseTimer = 1.45;
    _enqueueWave(currentWaveIndex, appendExisting: true);
    _announceNewlyUnlockedPads();

    const bonusQi = 18;
    fieldTokens += bonusQi;
    _spawnFlyingQiOrb(const Vec2(200, 74), bonusQi, colorHex: 0xFF72EFDD);
    pendingSounds.add(SoundCue.serendipityJackpot);
    callouts.add(
      FloatingCallout(
        pos: const Vec2(200, 96),
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
      if (slot.slotIndex >= 3 &&
          isSlotWaveUnlocked(slot.slotIndex) &&
          _waveUnlockAnnounced.add(slot.slotIndex)) {
        bursts.add(FxBurst(pos: slot.pos, colorHex: 0xFFFFD166, maxRadius: 42));
        callouts.add(
          FloatingCallout(
            pos: slot.pos + const Vec2(0, -18),
            text: '🔓 ${slot.slotIndex + 1}번 전략 초소 봉인 해제!',
            colorHex: 0xFFFFD166,
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
        bursts.add(FxBurst(pos: CampaignCatalog.centralTowerPos, colorHex: 0xFFFFD166, maxRadius: 72, isTriangleShatter: true));
        break;
      case DestinyRoulettePrize.qiJackpot:
        fieldTokens += 85;
        _spawnFlyingQiOrb(const Vec2(200, 260), 85);
        bursts.add(FxBurst(pos: const Vec2(200, 260), colorHex: 0xFF72EFDD, maxRadius: 68));
        break;
      case DestinyRoulettePrize.mythicAwakening:
        final candidates = launchers.where((l) => l.tier < 5).toList();
        if (candidates.isEmpty) {
          if (nextRecommendedSlotIndex() != null) {
            fieldTokens += 35;
            final created = quickLuckySummonNextPad();
            if (created != null) created.tier = max(created.tier, 2);
          } else {
            fieldTokens += 90;
            _spawnFlyingQiOrb(const Vec2(200, 260), 90);
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
        triggerSupportChuldu(isFreeEncore: true);
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
    bursts.add(FxBurst(pos: CampaignCatalog.centralTowerPos, colorHex: 0xFF72EFDD, maxRadius: 52));
    callouts.add(
      FloatingCallout(
        pos: CampaignCatalog.centralTowerPos + const Vec2(0, -44),
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
    bursts.add(FxBurst(pos: CampaignCatalog.centralTowerPos, colorHex: 0xFFFF6B35, maxRadius: 48));
    callouts.add(
      FloatingCallout(
        pos: CampaignCatalog.centralTowerPos + const Vec2(0, -44),
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
    bursts.add(FxBurst(pos: CampaignCatalog.centralTowerPos, colorHex: 0xFF4CC9F0, maxRadius: 48));
    callouts.add(
      FloatingCallout(
        pos: CampaignCatalog.centralTowerPos + const Vec2(0, -44),
        text: '⚡ 전군 연사 실시간 가속 $liveReloadLv단! (+${liveReloadLv * 12}%)',
        colorHex: 0xFF4CC9F0,
      ),
    );
    return true;
  }

  /// 실시간 방어 결계 증축 & 즉시 수복 업그레이드 (최대 5단 · +20% 최대치 & 40% 즉시 수리, 멈춤 없음!).
  bool upgradeLiveBarrier() {
    if (isFinished || liveBarrierLv >= 5 || fieldTokens < liveBarrierCost) return false;
    fieldTokens -= liveBarrierCost;
    liveBarrierLv++;
    manualResonanceTimer = max(manualResonanceTimer, 8.0);
    shieldMaxHpDynamic *= 1.20;
    shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * 0.42);
    towerHp = min(centralSpec.coreMaxHp, towerHp + centralSpec.coreMaxHp * 0.35);
    granaryHealth = min(1.0, granaryHealth + 0.30);
    cropsHealth = min(1.0, cropsHealth + 0.30);
    livestockHealth = min(1.0, livestockHealth + 0.30);
    pendingSounds.add(SoundCue.shieldWave);
    bursts.add(FxBurst(pos: CampaignCatalog.villageCenter, colorHex: 0xFF80ED99, maxRadius: 64));
    callouts.add(
      FloatingCallout(
        pos: CampaignCatalog.villageCenter + const Vec2(0, -48),
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
    if (!pendingPerkChoices.contains(perk)) return false;
    pendingPerkChoices.clear();
    perkChoiceTimer = 0.0;
    activePerks[perk] = (activePerks[perk] ?? 0) + 1;
    pendingSounds.add(SoundCue.serendipityJackpot);

    switch (perk) {
      case RoguePerk.warChest:
        fieldTokens += 65;
        _spawnFlyingQiOrb(const Vec2(200, 320), 65);
        break;
      case RoguePerk.luckyAscension:
        final upgradable = launchers.where((l) => l.tier < 4).toList();
        if (upgradable.isEmpty) {
          fieldTokens += 75;
          _spawnFlyingQiOrb(const Vec2(200, 320), 75);
        } else {
          final picked = upgradable[rng.nextInt(upgradable.length)];
          final jump = rng.nextDouble() < 0.35 ? 2 : 1;
          picked.tier = (picked.tier + jump).clamp(1, 4);
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
        bursts.add(FxBurst(pos: CampaignCatalog.villageCenter, colorHex: 0xFF34D399, maxRadius: 76));
        break;
      default:
        bursts.add(FxBurst(pos: CampaignCatalog.centralTowerPos, colorHex: perk.colorHex, maxRadius: 52));
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
    final buildCost = newType.buildCostTokens;
    if (fieldTokens + refund < buildCost) return false;

    fieldTokens = fieldTokens + refund - buildCost;
    final idx = launchers.indexOf(existing);
    final permLv = progress.launcherPermanentLevels[newType] ?? 1;
    launchers[idx] = ActiveLauncher(
      slotIndex: slotIndex,
      pos: existing.pos,
      type: newType,
      permanentLevel: permLv,
      investedTokens: buildCost,
    );

    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: existing.pos, colorHex: 0xFFFFD166, maxRadius: 32));
    callouts.add(
      FloatingCallout(
        pos: existing.pos + const Vec2(0, -18),
        text: '🔄 ${newType.name} 교체 배치!',
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
        pos: CampaignCatalog.centralTowerPos + const Vec2(0, -34),
        text: manual ? '🎯 중앙 탑: 수동 저격 탄지(전장 사거리·화력 ×1.8·도탄 +2)!' : '⚙️ 중앙 탑: 근접 자동 방어 가동!',
        colorHex: manual ? 0xFFFFD166 : 0xFF72EFDD,
      ),
    );
  }

  void toggleCentralManualMode() => setCentralManualMode(!centralManualMode);

  /// 수동 탄지 조준 각도 보정 (아래쪽 마을 뒤로 잘못 쏘지 않도록 상방 반구 유도).
  static double sanitizeManualAimAngle(double rawAngleRad) {
    if (!rawAngleRad.isFinite) return -pi / 2;
    double vx = cos(rawAngleRad);
    double vy = sin(rawAngleRad);
    if (vy > 0.18) {
      vy = -vy.abs().clamp(0.25, 1.0);
    }
    return atan2(vy, vx);
  }

  /// 수동 탄지 도탄 궤적 예측선 계산 (현재 수동 유효 사거리 한계선 및 벽면·기둥 1회 반사 반영).
  List<Vec2> previewCentralManualRay(double rawAngleRad, {double? maxDist}) {
    final angle = sanitizeManualAimAngle(rawAngleRad);
    final origin = CampaignCatalog.centralTowerPos;
    Vec2 cur = origin;
    Vec2 dir = Vec2(cos(angle), sin(angle)).normalized;
    final pts = <Vec2>[origin];
    double rem = maxDist ?? effectiveCentralManualRange;
    int bounces = 0;

    const stepLen = 8.0;
    while (rem > 0) {
      final next = cur + dir * stepLen;
      rem -= stepLen;

      if (next.y <= 14 || next.y >= CampaignCatalog.arenaHeight - 12) {
        pts.add(Vec2(next.x.clamp(16.0, CampaignCatalog.arenaWidth - 16.0), next.y.clamp(14.0, 668.0)));
        break;
      }

      if (next.x <= 16.0 || next.x >= CampaignCatalog.arenaWidth - 16.0) {
        final hit = Vec2(next.x.clamp(16.0, CampaignCatalog.arenaWidth - 16.0), next.y);
        pts.add(hit);
        if (bounces >= 1) break;
        bounces++;
        dir = Vec2(-dir.x, dir.y).normalized;
        cur = hit;
        continue;
      }

      bool hitPillar = false;
      for (final pillar in chapter.pillars) {
        final toP = next - pillar.center;
        if (toP.length <= pillar.radius + 7.5) {
          final n = toP.normalized;
          final hit = pillar.center + n * (pillar.radius + 8.0);
          pts.add(hit);
          if (bounces < 1) {
            final dot = dir.x * n.x + dir.y * n.y;
            dir = (dir - n * (2 * dot)).normalized;
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
    final delta = targetArenaPos - CampaignCatalog.centralTowerPos;
    final rawAngle = delta.length > 4.0 ? atan2(delta.y, delta.x) : -pi / 2;
    return fireCentralManualAngle(rawAngle);
  }

  /// 플레이어가 조준한 각도로 중앙 기명 수호탑 수동 강화 탄지 발사 (3갈래 파쇄 산탄포)!
  bool fireCentralManualAngle(double rawAngleRad) {
    if (!isCentralReadyToFire) return false;
    final angle = sanitizeManualAimAngle(rawAngleRad);
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

    final origin = CampaignCatalog.centralTowerPos;
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
      qiBars = 0.0;
      final count = progress.realm.eogieoseokCount + 4;
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
      for (int i = 0; i < count; i++) {
        final spread = (i - (count - 1) / 2.0) * 0.10;
        _spawnManualDirectionalShot(
          origin: origin + Vec2((i - (count - 1) / 2.0) * 7.0, -6),
          angleRad: angle + spread,
          baseDamage: centralSpec.baseDamage * 2.65,
          speed: 535,
          pierceBonus: 5,
          aoeRadius: 58,
          ignoresShield: true,
          knockbackScale: 1.65,
        );
      }
      return true;
    }

    SectTechnique? sectTech;
    double dmgMult = 1.75; // 수동 직접 탄지 초장거리 파쇄 주포!
    if (qiBars >= 1.0) {
      qiBars -= 1.0;
      sectTech = preset.sectTechnique;
      dmgMult *= 1.35;
    }

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
    );
    for (final wing in const [-0.13, 0.13]) {
      _spawnManualDirectionalShot(
        origin: origin + Vec2(wing * 45.0, -6),
        angleRad: angle + wing,
        baseDamage: centralSpec.baseDamage * dmgMult * 0.56,
        speed: 495,
        pierceBonus: 2,
        aoeRadius: 0,
        knockbackScale: 1.10,
      );
    }
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

    final finalSpeed = speed *
        shape.speedFactor *
        (cheonghakBuffTimer > 0 ? 1.20 : 1.0) *
        (stone == StoneMaterial.manyeonGiju ? 1.18 : 1.0);
    final vel = Vec2(cos(angleRad) * finalSpeed, sin(angleRad) * finalSpeed);

    final isCritSerendipity =
        allowSerendipity && rng.nextDouble() < (0.14 + progress.meridianSerendipityBonus * 0.6);
    if (isCritSerendipity) {
      serendipityCount++;
    }

    int pierce = pierceBonus + (stone == StoneMaterial.geumgang ? 1 : 0);
    double splash = aoeRadius + (stone == StoneMaterial.obsidian ? 32.0 : 0.0);
    double curve = 0.0;
    bool bypassShield = ignoresShield || stone == StoneMaterial.jageum || armorBreakStacks > 0;

    if (sectTech == SectTechnique.swordQi) pierce += 3;
    if (sectTech == SectTechnique.ironFist) splash = max(splash, 60.0);
    if (sectTech == SectTechnique.taiji) {
      curve = 1.25 * shape.spinCurveFactor;
      bypassShield = true;
      qiBars = (qiBars + 0.25).clamp(0.0, 3.0);
    }

    final liveDmgBoost = (1.0 + liveFirepowerLv * 0.15) * powerTarget.damageMultiplier;
    final finalDamage =
        baseDamage * liveDmgBoost * stone.damageMultiplier * (isCritSerendipity ? 2.1 : 1.0);
    final finalKnock = 48.0 *
        stone.knockbackMultiplier *
        shape.knockbackFactor *
        knockbackScale *
        (1.0 + boulderStacks * 0.55) *
        (1.0 + progress.meridianKnockbackBonus) *
        (stone == StoneMaterial.yongrin ? 1.35 : 1.0);
    final critChance = (0.18 +
            shape.critBonus +
            progress.meridianCritBonus +
            (feverTimer > 0 ? 0.35 : 0.0) +
            (cheonghakBuffTimer > 0 ? 0.10 : 0.0) +
            (stone == StoneMaterial.geumgang ? 0.08 : 0.0))
        .clamp(0.05, 0.90);
    final radiusScale = (1.0 + boulderStacks * 0.36).clamp(1.0, 2.0) * (feverTimer > 0 ? 1.18 : 1.0);

    projectiles.add(
      ActiveStoneProjectile(
        sourceKey: 'central_tower',
        sourceLabel: '중앙 기명 수호탑 (수동 탄지)',
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
        ignoresShield: bypassShield,
        isGiantCritSerendipity: isCritSerendipity,
        extraBounces: 2 + ricochetStacks * 2,
        maxTravelDist: effectiveCentralManualRange * 1.15,
      ),
    );

    if (sectTech == SectTechnique.shadowClone) {
      final cloneAngle = angleRad + 0.16;
      projectiles.add(
        ActiveStoneProjectile(
          sourceKey: 'central_tower',
          sourceLabel: '중앙 기명 수호탑 (수동 분신탄)',
          pos: origin,
          vel: Vec2(cos(cloneAngle) * finalSpeed, sin(cloneAngle) * finalSpeed),
          material: stone,
          shape: shape,
          damage: finalDamage * 0.80,
          knockback: finalKnock * 0.85,
          critChance: critChance,
          colorHex: 0xFFC77DFF,
          radius: 8.8 * radiusScale,
          pierceLeft: max(0, pierce - 1),
          extraBounces: 1 + ricochetStacks * 2,
          maxTravelDist: effectiveCentralManualRange * 1.15,
        ),
      );
    }
  }

  void _enqueueWave(int waveIdx, {bool appendExisting = false}) {
    if (!appendExisting) {
      _spawnQueue.clear();
    }
    if (waveIdx >= stage.waves.length) return;
    final groups = stage.waves[waveIdx];
    final startGrace = (waveIdx == 0 && !appendExisting) ? 2.0 : 0.40;
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
      for (int i = 0; i < g.count; i++) {
        _spawnQueue.add(
          _PendingSpawn(
            delaySec: startGrace + groupStagger + i * g.intervalSec,
            kind: g.kind,
            laneIndex: lIdx,
            customTitle: g.customBossTitle,
            customPortrait: g.customPortrait,
          ),
        );
      }
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

  /// 거점 발사대 수동/자동 실시간 버전 승급 (1형 → 4형).
  bool upgradeLauncherInBattle(int launcherIndex) {
    if (launcherIndex < 0 || launcherIndex >= launchers.length) return false;
    final l = launchers[launcherIndex];
    if (l.tier >= 4) return false;
    final cost = l.type.inBattleUpgradeCost(l.tier);
    if (fieldTokens < cost) return false;
    fieldTokens -= cost;
    l.investedTokens += cost;
    l.tier++;
    pendingSounds.add(SoundCue.gearMotion);
    bursts.add(FxBurst(pos: l.pos, colorHex: 0xFFFFD166, maxRadius: 34));
    callouts.add(
      FloatingCallout(
        pos: l.pos + const Vec2(0, -18),
        text: '${l.type.name} ${l.tier}형 승급!',
        colorHex: 0xFFFFD166,
      ),
    );
    return true;
  }

  /// 전장 위기 순간 원터치 전술 비약·부적 발동!
  bool activateConsumable(TacticalConsumable item) {
    if (isFinished) return false;
    final have = progress.consumables[item] ?? 0;
    if (have <= 0) return false;
    progress.consumables[item] = have - 1;

    switch (item) {
      case TacticalConsumable.qiSurgePill:
        qiBars = 3.0;
        pendingSounds.add(SoundCue.serendipityJackpot);
        bursts.add(FxBurst(pos: CampaignCatalog.villageCenter, colorHex: 0xFF34D399, maxRadius: 62));
        callouts.add(
          FloatingCallout(
            pos: CampaignCatalog.villageCenter + const Vec2(0, -54),
            text: '💊 기공 급속단 발동! 내공 3칸 즉시 완충!',
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
        pendingSounds.add(SoundCue.shieldWave);
        bursts.add(FxBurst(pos: CampaignCatalog.villageCenter, colorHex: 0xFF60A5FA, maxRadius: 74));
        callouts.add(
          FloatingCallout(
            pos: CampaignCatalog.villageCenter + const Vec2(0, -54),
            text: '🛡️ 수호탑 수리패 발동! 방어막·마을 정화 복구!',
            colorHex: 0xFF60A5FA,
            isBigBanner: true,
          ),
        );
        break;
      case TacticalConsumable.auroraCritCharm:
        auroraCritTimer = 8.0;
        pendingSounds.add(SoundCue.serendipityJackpot);
        bursts.add(FxBurst(pos: CampaignCatalog.villageCenter, colorHex: 0xFFF59E0B, maxRadius: 68));
        callouts.add(
          FloatingCallout(
            pos: CampaignCatalog.villageCenter + const Vec2(0, -54),
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
    if (!isFreeEncore) {
      if (supportChargesLeft <= 0) return false;
      supportChargesLeft--;
      usedSupportCount++;
    }

    chulduSweepAnimTimer = 1.35;
    screenShakeTimer = max(screenShakeTimer, 0.42);
    screenShakeIntensity = max(screenShakeIntensity, 7.2);
    pendingSounds.add(SoundCue.chulduFanfare);

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
        pos: const Vec2(200, 210),
        text: bannerTitle,
        colorHex: 0xFFFFD166,
        ttlSec: 1.8,
        isBigBanner: true,
      ),
    );

    // 화면 전체 돌연변이 몰이사냥 일소 (보스는 대폭 타격!)
    final copy = List<ActiveMutant>.from(mutants);
    for (final m in copy) {
      final dmg = m.kind.isBoss
          ? m.maxHp * (isCritChuldu ? 0.62 : 0.42)
          : m.maxHp * 3.0;
      _applyDamageToMutant(
        m,
        dmg,
        sourceKey: 'support_chuldu',
        sourceLabel: '무림수호단 출두',
        knockDir: const Vec2(0, -1),
        knockForce: 190,
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
          _applyDamageToMutant(
            rem,
            rem.maxHp * 3.0,
            sourceKey: 'support_chuldu',
            sourceLabel: '무림수호단 출두',
            knockDir: const Vec2(0, -1),
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

    if (isEncoreChuldu) {
      pendingFreeEncoreChuldu = true;
    }
    return true;
  }

  /// 물리 진행 (1배~4배 고속 배속에서도 탄알 터널링·궤도 이탈이 0건이 되도록 1/60초 이하 미세 분할 연산).
  void step(double dt) {
    if (isFinished || !dt.isFinite || dt <= 0) return;
    final subSteps = ((dt - 1e-9) / (1.0 / 60.0)).ceil().clamp(1, 8);
    final subDt = dt / subSteps;
    for (int s = 0; s < subSteps && !isFinished; s++) {
      _stepSingle(subDt);
    }
  }

  void _stepSingle(double dt) {
    if (isFinished) return;
    elapsedSec += dt;
    centralGearAngle += dt * 1.8;

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
              pos: const Vec2(200, 86),
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

    // 본진 위기 긴장감(dangerPulseLevel) 계산: 괴물이 마을 코앞(y >= 445)에 육박하거나 방어막이 45% 이하일 때 적색 심장박동 점등!
    double targetDanger = 0.0;
    if (shieldMaxHpDynamic > 0) {
      final shieldRatio = shieldHp / shieldMaxHpDynamic;
      if (shieldRatio < 0.45) {
        targetDanger = max(targetDanger, ((0.45 - shieldRatio) / 0.45).clamp(0.25, 1.0));
      }
    }
    for (final m in mutants) {
      if (m.pos.y >= 445.0) {
        final prox = ((m.pos.y - 445.0) / 115.0).clamp(0.20, 1.0);
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

    // 황금 보물 도깨비 긴급 출몰 (16초 · 36초, 처치 시 기력 +55⚡ & 즉시 돌파 비급!)
    if ((goblinSpawnsDone == 0 && elapsedSec >= 15.5) ||
        (goblinSpawnsDone == 1 && elapsedSec >= 35.5)) {
      goblinSpawnsDone++;
      final fromLeft = goblinSpawnsDone.isOdd;
      final gobHp = (58.0 + stage.chapterNumber * 36.0) * difficulty.hpMult;
      treasureGoblin = TreasureGoblinEntity(
        pos: Vec2(fromLeft ? 24.0 : CampaignCatalog.arenaWidth - 24.0, 212.0),
        vel: Vec2(fromLeft ? 48.0 : -48.0, 6.0),
        maxHp: gobHp,
      );
      callouts.add(
        FloatingCallout(
          pos: const Vec2(200, 186),
          text: '👹 황금 보물 도깨비 출현! 저격 처치 시 +55⚡ & 비급 획득!',
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
        212.0 + sin(g.animPhase * 0.65) * 14.0,
      );
      if (g.pos.x < 14 || g.pos.x > CampaignCatalog.arenaWidth - 14) {
        g.alive = false;
      }
    }

    // 초소가 최소 1곳 설치된 상태에서만 호신 강기 방어막 자연 회복 작동 (무배치 방치 클리어 차단!)
    if (launchers.isNotEmpty && shieldHp > 0 && shieldHp < shieldMaxHpDynamic) {
      shieldHp = min(
        shieldMaxHpDynamic,
        shieldHp + (1.4 + progress.coreFortitudeBonus * 14.0) * dt,
      );
    }

    if (centralRecoilAnim > 0) {
      centralRecoilAnim = max(0, centralRecoilAnim - dt * 4.2);
    }

    // 헤드리스 밸런스 검증(`autoBuildForSimVerify == true`) 시:
    // ① 대기 중인 돌파 비급(RoguePerk) 최적 1장 자동 선택
    // ② 현재 개방된 빈 초소에 순차 배치 시뮬레이션
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

      final nextSlotIdx = nextRecommendedSlotIndex();
      if (nextSlotIdx != null) {
        final slot = mountSlotByIndex(nextSlotIdx)!;
        final desired = nextSlotIdx < preset.mountTypes.length
            ? preset.mountTypes[nextSlotIdx]
            : slot.recommendedType;
        final buildType = isLauncherTypeUnlocked(desired) ? desired : slot.recommendedType;
        if (fieldTokens >= buildType.buildCostTokens) {
          placeLauncherInBattle(nextSlotIdx, buildType);
        }
      }
    }

    // 이미 배치된 발사대의 자동 버전 업그레이드
    final allowAutoUpgNow = preset.autoUpgradeInBattle &&
        launchers.isNotEmpty &&
        (!autoBuildForSimVerify ||
            nextRecommendedSlotIndex() == null ||
            launchers.length >= min(3, activeMounts.length) && fieldTokens >= 85);
    if (allowAutoUpgNow) {
      ActiveLauncher? bestCandidate;
      int bestCost = 999999;
      for (final l in launchers) {
        if (l.tier < 4) {
          final c = l.type.inBattleUpgradeCost(l.tier);
          if (fieldTokens >= c && c < bestCost) {
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
    if (!goldenToadSpawned && elapsedSec > 24.0 && allowSerendipity) {
      goldenToadSpawned = true;
      goldenToad = GoldenSupplyToad(
        pos: const Vec2(28, 285),
        vel: const Vec2(56, 4),
      );
      callouts.add(
        FloatingCallout(
          pos: const Vec2(90, 265),
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
    _stepCentralGuardian(dt);
    _stepPathLaunchers(dt);
    _stepSpiritBeastAndCompanions(dt);
    _stepSupportAutoTrigger();
    _stepProjectiles(dt);
    _stepBountyQuests();
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
            pos: const Vec2(200, 92),
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

        // 물결 방어 성공 시(최소 1초소 건설 또는 수동 공명 상태) 보너스 기력 +22⚡ & 3택 1 돌파 비급 발동!
        if (isFormationActive) {
          const waveBonusQi = 22;
          fieldTokens += waveBonusQi;
          _spawnFlyingQiOrb(const Vec2(200, 320), waveBonusQi, colorHex: 0xFF72EFDD);
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

    if (pendingFreeEncoreChuldu && mutants.length >= 3) {
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
    if (elapsedSec < 9.0) return;

    infiltrationTimer -= dt;
    if (infiltrationTimer > 0) return;
    infiltrationTimer = (10.5 - stage.chapterNumber * 0.35).clamp(6.8, 10.5);

    final isTunnel = infiltratorSpawnCount.isOdd;
    final squadCount = (2 + stage.chapterNumber ~/ 3 + currentWaveIndex ~/ 2).clamp(2, 4);
    for (int i = 0; i < squadCount; i++) {
      spawnOffPathInfiltrator(isTunnel: isTunnel, squadOffsetIndex: i);
    }
    callouts.add(
      FloatingCallout(
        pos: Vec2(200, isTunnel ? 325 : 225),
        text: isTunnel
            ? '🕳️ 지하 땅굴 기습!! 길 밖 빈터에서 변이가 솟아오릅니다!'
            : '🌲 산비탈 월담 기습!! 길 밖 옆구리 숲에서 쳐들어옵니다!',
        colorHex: 0xFFFF4D6D,
        ttlSec: 1.9,
        isBigBanner: true,
      ),
    );
  }

  /// 길 밖 비정규 침투 괴물 1체 즉시 소환 (단위 시험 및 실시간 기습 공용).
  ActiveMutant spawnOffPathInfiltrator({
    required bool isTunnel,
    int squadOffsetIndex = 0,
  }) {
    infiltratorSpawnCount++;
    final fromLeft = (infiltratorSpawnCount + squadOffsetIndex).isEven;
    final MutantKind kind = isTunnel
        ? (stage.chapterNumber >= 5 && squadOffsetIndex == 0
            ? MutantKind.ironBoar
            : (stage.chapterNumber >= 3 && squadOffsetIndex == 0
                ? MutantKind.plagueToad
                : MutantKind.bloodCocoon))
        : (stage.chapterNumber >= 6 && squadOffsetIndex == 0
            ? MutantKind.shieldYacha
            : (squadOffsetIndex == 0 ? MutantKind.sickHound : MutantKind.swarmRat));
    encounteredMutants.add(kind);

    final Vec2 startPos;
    final List<Vec2> offRoadWaypoints;
    if (isTunnel) {
      final tx = fromLeft
          ? (88.0 + (squadOffsetIndex * 24.0) % 68.0)
          : (312.0 - (squadOffsetIndex * 24.0) % 68.0);
      final baseTy = stage.chapterNumber >= 5 ? 345.0 : 285.0;
      final ty = baseTy + (squadOffsetIndex % 3) * 32.0;
      startPos = Vec2(tx, ty);
      final midTarget = Vec2(
        fromLeft ? 144.0 : 256.0,
        (ty + 118.0).clamp(390.0, 535.0),
      );
      offRoadWaypoints = [
        startPos,
        midTarget,
        CampaignCatalog.centralTowerPos,
        CampaignCatalog.villageCenter,
      ];
    } else {
      final sy = (stage.chapterNumber >= 5 ? 215.0 : 165.0) + (squadOffsetIndex * 46.0) % 150.0;
      startPos = Vec2(fromLeft ? 22.0 : CampaignCatalog.arenaWidth - 22.0, sy);
      final mid1 = Vec2(fromLeft ? 78.0 : 322.0, sy + 95.0);
      final mid2 = Vec2(fromLeft ? 122.0 : 278.0, (sy + 210.0).clamp(370.0, 540.0));
      offRoadWaypoints = [
        startPos,
        mid1,
        mid2,
        CampaignCatalog.centralTowerPos,
        CampaignCatalog.villageCenter,
      ];
    }

    final chScale = _monsterHpScale;
    final ch1Ease = stage.chapterNumber == 1 ? 0.68 : 1.0;
    final eliteFactor = stage.chapterNumber >= 5 ? 1.04 : 0.86;
    final maxHp =
        kind.baseHp * kind.swarmHpFactor * chScale * ch1Ease * difficulty.hpMult * eliteFactor;
    final spd = kind.speed * (isTunnel ? 1.02 : 1.12) * difficulty.speedMult;

    final m = ActiveMutant(
      uid: _nextMutantUid++,
      kind: kind,
      laneIndex: 0,
      waypoints: offRoadWaypoints,
      pos: startPos,
      maxHp: maxHp,
      speed: spd,
      customName: isTunnel ? '땅굴 ${kind.name}' : '월담 ${kind.name}',
      lateralSeed: rng.nextDouble() * pi * 2,
      laneLateralOffset: 0.0,
    )
      ..isInfiltrator = true
      ..infiltratorStyle = isTunnel ? 'tunnel' : 'flank'
      ..emergeAnimTimer = 0.85
      ..headingRad = atan2(
        offRoadWaypoints[1].y - startPos.y,
        offRoadWaypoints[1].x - startPos.x,
      );

    bursts.add(
      FxBurst(
        pos: startPos,
        colorHex: isTunnel ? 0xFFF77F00 : 0xFFFF4D6D,
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
    1.00, // 1장 (입문 환영 구간 보존)
    2.35, // 2장
    14.50, // 3장 (무강화·단일병종 첫 성장 벽 형성)
    22.50, // 4장
    40.00, // 5장
    56.00, // 6장
    78.00, // 7장
    108.00, // 8장
    146.00, // 9장
    195.00, // 10장 (결전 보스 10연전)
  ];

  /// 플레이어 영구 강화·내공 경지·수호석 성장에 비례하는 장별 변이체 체력 배율.
  double get _monsterHpScale {
    final chIdx = (stage.chapterNumber - 1).clamp(0, _chapterMonsterHpCurve.length - 1);
    final baseCh = _chapterMonsterHpCurve[chIdx];
    if (stage.globalIndex >= 900) {
      final w = currentWaveIndex;
      if (w <= 15) {
        return baseCh * (1.0 + w * 0.14);
      }
      return baseCh * (1.0 + 15 * 0.14) * pow(1.19, w - 15).toDouble();
    }
    return baseCh * (1.0 + (stage.stageNumber - 1) * 0.052);
  }

  /// 장 진행 및 난이도에 따른 변이체 방어막·수호탑 공격력 배율 (1-1 보통은 1.00 정확 유지).
  double get _mutantAttackScale {
    double chMult = 1.0 +
        (stage.chapterNumber - 1) * 0.48 +
        (stage.chapterNumber >= 6 ? (stage.chapterNumber - 5) * 0.42 : 0.0);
    if (stage.globalIndex >= 900 && currentWaveIndex > 15) {
      chMult *= pow(1.16, currentWaveIndex - 15).toDouble();
    }
    final diffMult = switch (difficulty) {
      DefenseDifficulty.easy => 0.82,
      DefenseDifficulty.normal => 1.0,
      DefenseDifficulty.nightmare => 1.45,
    };
    return chMult * diffMult;
  }

  void _spawnMutant(_PendingSpawn item) {
    encounteredMutants.add(item.kind);
    final laneIdx = item.laneIndex % chapter.lanes.length;
    final lane = chapter.smoothedLane(laneIdx);
    if (laneIdx < lanePortalEnergy.length) {
      lanePortalEnergy[laneIdx] = 1.0;
    }

    final chScale = _monsterHpScale;
    final ch1Ease = stage.chapterNumber == 1 ? (item.kind.isBoss ? 0.48 : 0.78) : 1.0;
    final maxHp = item.kind.baseHp *
        item.kind.swarmHpFactor *
        chScale *
        ch1Ease *
        difficulty.hpMult;
    // 2.1배 길어진 구곡양장 아홉 굽이 협곡길 위를 역동적으로 휘돌아 내려오도록 행군 속도 1.34배 조율!
    final spd =
        item.kind.speed * 1.34 * (1.0 + (stage.chapterNumber - 1) * 0.022) * difficulty.speedMult;
    final latOffset = item.kind.isBoss ? 0.0 : (rng.nextDouble() - 0.5) * 14.0;
    final spawnPos = lane.first + Vec2(latOffset * 0.65, 0);

    final nextWp = lane.length > 2 ? lane[2] : CampaignCatalog.villageCenter;
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
      ..headingRad = initHeading
      ..smoothVel = Vec2(cos(initHeading) * spd, sin(initHeading) * spd)
      ..dashCooldown = item.kind == MutantKind.swiftShadowBoss ? 2.2 : 2.6;

    mutants.add(spawned);

    // 중간보스·우두머리 동반 침공 긴급 전장 경보 및 등장 진동 연출!
    if (item.kind.isBoss) {
      final bossLabel = item.customTitle ?? item.kind.name;
      final prefix = item.kind.isMidBoss ? '🚨 중간보스 동반 침략!' : '🚨 심야 대수괴 강림!';
      final badge = _bossSpecialtyBadge(item.kind);
      bossInvasionAlertText = '$prefix [$bossLabel] · $badge · 전투력 ${item.kind.combatPower}';
      bossInvasionAlertTimer = 4.5;
      screenShakeTimer = max(screenShakeTimer, 0.36);
      screenShakeIntensity = max(screenShakeIntensity, item.kind.isMidBoss ? 5.4 : 8.0);
      pendingSounds.add(SoundCue.villageWarning);
      bursts.add(FxBurst(pos: spawnPos, colorHex: item.kind.colorHex, maxRadius: 48));
      callouts.add(
        FloatingCallout(
          pos: const Vec2(200, 125),
          text: bossInvasionAlertText!,
          colorHex: item.kind.colorHex,
          ttlSec: 2.2,
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

      // 밀침 넉백 감쇠 적용
      if (m.knockbackVel.length > 2.0) {
        m.pos = m.pos + m.knockbackVel * dt;
        final damp = m.oilSlipTimer > 0 ? 2.4 : 4.6 * chapter.surfaceFriction;
        m.knockbackVel = m.knockbackVel * max(0.0, 1.0 - damp * dt);
      } else {
        m.knockbackVel = const Vec2(0, 0);
      }

      // 낭떠러지 장외 & 절벽 걸침 35% 뽀록 판정! (중갑·방패 정예는 체력 65% 이하로 약해졌을 때만 장외 추락 허용해 무강화 밀치기 꼼수 차단)
      final canFallOffCliff = !m.kind.isBoss &&
          (stage.chapterNumber <= 2 ||
              (m.kind != MutantKind.ironBoar && m.kind != MutantKind.shieldYacha) ||
              m.hp <= m.maxHp * 0.65);
      bool fellOff = false;
      for (final cliff in chapter.cliffs) {
        final dist = m.pos.distanceTo(cliff.center);
        if (canFallOffCliff && dist < cliff.radius * 0.68) {
          fellOff = true;
          break;
        } else if (canFallOffCliff && !m.cliffChecked && dist < cliff.radius) {
          m.cliffChecked = true;
          if (rng.nextDouble() < 0.35) {
            fellOff = true;
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
          m.pos.x.clamp(14.0, CampaignCatalog.arenaWidth - 14.0),
          max(10.0, m.pos.y),
        );
      } else if (!m.kind.isBoss &&
          (m.pos.x < 10 || m.pos.x > CampaignCatalog.arenaWidth - 10 || m.pos.y < 6)) {
        fellOff = true;
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
        _rewardMutantKill(m, bonusTokenMult: 1.5, sourceKey: 'cliff_pporok', sourceLabel: '절벽 추락 뽀록');
        mutants.removeAt(i);
        continue;
      }

      // 전진 이동 및 스피드 특화 보행·질주·편대 물리 (빙결 중에는 animPhase 정지!)
      if (m.freezeTimer <= 0) {
        if (m.kind == MutantKind.swiftShadowBoss) {
          m.dashCooldown -= dt;
          if (m.dashCooldown <= 0) {
            m.dashCooldown = 3.4;
            m.dashBurstTimer = 0.65;
            m.attackAnimTimer = max(m.attackAnimTimer, 1.30);
            bursts.add(
              FxBurst(
                pos: m.pos,
                colorHex: m.kind.colorHex,
                maxRadius: 28,
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

        double gaitMult = 1.0;
        if (m.dashBurstTimer > 0) {
          gaitMult = m.kind == MutantKind.swiftShadowBoss ? 1.55 : 1.32;
        } else if (m.kind == MutantKind.plagueToad) {
          gaitMult = 0.62 + 0.66 * sin(m.animPhase * 0.85).abs();
        } else if (m.kind == MutantKind.ironBoar || m.kind == MutantKind.ironColossusBoss) {
          gaitMult = 0.94 + 0.12 * sin(m.animPhase * 0.9).abs();
        }

        final slowFactor = m.slowTimer > 0 ? 0.58 : 1.0;
        final effectiveSpeed = m.speed * slowFactor * gaitMult;

        // Catmull-Rom 곡선 경로 전방 주시(Look-Ahead Pure Pursuit) + 급커브 궤도 맴돎 원천 차단!
        if (m.waypoints.isNotEmpty) {
          int wpIdx = m.waypointIndex.clamp(0, m.waypoints.length - 1);
          while (wpIdx + 1 < m.waypoints.length) {
            final curWp = m.waypoints[wpIdx];
            final distToWp = m.pos.distanceTo(curWp);
            if (distToWp < 24.0) {
              wpIdx++;
              continue;
            }
            final segNext = m.waypoints[wpIdx + 1] - curWp;
            final relPos = m.pos - curWp;
            if (distToWp < 42.0 && (relPos.x * segNext.x + relPos.y * segNext.y) > 0) {
              wpIdx++;
              continue;
            }
            break;
          }
          m.waypointIndex = wpIdx;

          final lookIdx = min(wpIdx + 2, m.waypoints.length - 1);
          Vec2 targetPt = m.waypoints[lookIdx];
          final rawForward = (targetPt - m.pos);
          final baseDir = rawForward.length > 1e-4 ? rawForward.normalized : const Vec2(0, 1);

          if (!m.kind.isBoss && rawForward.length > 26.0) {
            final perp = Vec2(-baseDir.y, baseDir.x);
            final swayAmp = m.kind.speedRating >= 4 ? 3.8 : 2.2;
            final lateralShift =
                m.laneLateralOffset * 0.55 + sin(m.animPhase * 0.55 + m.lateralSeed) * swayAmp;
            final candidatePt = targetPt + perp * lateralShift;
            final safeEdge =
                candidatePt.x >= 26.0 && candidatePt.x <= CampaignCatalog.arenaWidth - 26.0;
            final safeCliff =
                chapter.cliffs.every((c) => candidatePt.distanceTo(c.center) > c.radius + 5.0);
            if (safeEdge && safeCliff) {
              targetPt = candidatePt;
            }
          }

          Vec2 steerDir = (targetPt - m.pos).normalized;

          // 대규모 무리 겹침 방지 소프트 분리력 (물결처럼 자연스럽게 퍼지며 전진)
          if (!m.kind.isBoss && mutants.length > 1) {
            Vec2 sep = const Vec2(0, 0);
            int checks = 0;
            for (final other in mutants) {
              if (other.uid == m.uid || other.kind.isBoss) continue;
              final diff = m.pos - other.pos;
              final d = diff.length;
              final minGap = (m.kind.radius + other.kind.radius) * 0.82;
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
                  candPos.x >= 26.0 && candPos.x <= CampaignCatalog.arenaWidth - 26.0;
              final safeCliff =
                  chapter.cliffs.every((c) => candPos.distanceTo(c.center) > c.radius + 5.0);
              if (safeEdge && safeCliff) {
                steerDir = candDir;
              }
            }
          }

          final desiredVel = steerDir * effectiveSpeed;
          final velBlend = min(1.0, dt * 13.5);
          if (m.smoothVel.length < 1.0) {
            m.smoothVel = desiredVel;
          } else {
            m.smoothVel = Vec2(
              m.smoothVel.x + (desiredVel.x - m.smoothVel.x) * velBlend,
              m.smoothVel.y + (desiredVel.y - m.smoothVel.y) * velBlend,
            );
          }

          m.pos = m.pos + m.smoothVel * dt;
          final actualSpeed = m.smoothVel.length;
          m.animPhase += actualSpeed * dt * (0.125 + m.kind.speedRating * 0.022) + dt * 1.95;

          if (actualSpeed > 0.5) {
            final desiredHeading = atan2(m.smoothVel.y, m.smoothVel.x);
            final angleDiff =
                atan2(sin(desiredHeading - m.headingRad), cos(desiredHeading - m.headingRad));
            m.headingRad = m.headingRad + angleDiff * min(1.0, dt * 9.2);
          }
        }
      }

      // 독안개 오라가 마을 가까이에 오면 논밭 농산물이 서서히 시듦
      final distToCenter = m.pos.distanceTo(CampaignCatalog.villageCenter);
      if (m.kind.poisonAura && distToCenter < 220) {
        cropsHealth = (cropsHealth - 0.018 * dt).clamp(0.0, 1.0);
      }

      // 제2장 이상 중간보스·대수괴 마기 포효 충격파 (체력 60% 이하 또는 중원 진입 시 1회 외곽 결계 진동 압박!)
      if (!m.roarShockUsed &&
          m.kind.isBoss &&
          stage.chapterNumber >= 2 &&
          (m.hp <= m.maxHp * 0.60 || m.pos.y >= 245.0) &&
          shieldHp > shieldMaxHpDynamic * 0.22) {
        m.roarShockUsed = true;
        final baseRatio = m.kind.isMidBoss ? 0.14 : 0.26;
        final diffScale = switch (difficulty) {
          DefenseDifficulty.easy => 0.55,
          DefenseDifficulty.normal => 1.0,
          DefenseDifficulty.nightmare => 1.48,
        };
        final shockDmg = shieldMaxHpDynamic * baseRatio * diffScale;
        shieldHp = max(shieldMaxHpDynamic * 0.18, shieldHp - shockDmg);
        screenShakeTimer = max(screenShakeTimer, 0.26);
        screenShakeIntensity = max(screenShakeIntensity, m.kind.isMidBoss ? 4.4 : 6.5);
        bursts.add(
          FxBurst(
            pos: m.pos,
            colorHex: m.kind.colorHex,
            maxRadius: m.kind.isMidBoss ? 52 : 76,
            isTriangleShatter: true,
          ),
        );
        callouts.add(
          FloatingCallout(
            pos: m.pos + const Vec2(0, -22),
            text: m.kind.isMidBoss
                ? '💢 중간보스 마기 포효!! 결계가 흔들립니다!'
                : '🌋 대수괴 광폭 마기 포효!! 결계 수복·출두 대비!',
            colorHex: 0xFFFF595E,
            ttlSec: 1.6,
            isBigBanner: !m.kind.isMidBoss,
          ),
        );
      }

      // 외곽 기공 방어막 충돌 처리 (attackPower 비례 타격 & 덮치기 모션)
      if (shieldHp > 0 && distToCenter <= CampaignCatalog.outerShieldRadius + m.kind.radius * 0.5) {
        shieldHp = max(0, shieldHp - m.kind.attackPower * _mutantAttackScale);
        m.attackAnimTimer = 1.0;
        if (m.kind.toughnessRating >= 4 || m.kind == MutantKind.crimsonBreakerBoss) {
          heavyHitsOnShield++;
        }
        if (m.kind.speedRating >= 4) {
          swarmHitsOnShield++;
        }

    // 방어막 반동 충격파로 변이체 후방 밀침 (초보자 초반 20초 정비 여유는 주되 끝까지 방치 시 100% 돌파당함!)
    final pushScale = isFormationActive ? 2.15 : 1.32;
    final pushDir = (m.pos - CampaignCatalog.villageCenter).normalized;
    m.knockbackVel = pushDir * (centralSpec.shieldWavePush * pushScale / sqrt(m.kind.mass));
        pendingSounds.add(SoundCue.shieldWave);
        bursts.add(FxBurst(pos: m.pos, colorHex: 0xFF4CC9F0, maxRadius: 28));

        // 공격력 5성 보스(파성귀·묵현·대요마) 강타 시 파쇄 충격파 + 화면 진동!
        if (m.kind.isBoss && m.kind.attackRating >= 5) {
          bursts.add(
            FxBurst(
              pos: m.pos,
              colorHex: m.kind.colorHex,
              maxRadius: 56,
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

        // 초보자가 화면을 익히는 동안 즉사하지 않도록 1회 한정 호신 반발 빙결 충격파 발동 (끝까지 방치 시 재돌파되어 100% 함락!)
        if (!_emergencyRepulseUsed && shieldHp <= shieldMaxHpDynamic * 0.38) {
          _emergencyRepulseUsed = true;
          shieldHp = max(shieldHp, shieldMaxHpDynamic * 0.78);
          for (final nearM in mutants) {
            if (nearM.pos.distanceTo(CampaignCatalog.villageCenter) <= 280.0) {
              final repDir = (nearM.pos - CampaignCatalog.villageCenter).normalized;
              nearM.knockbackVel = repDir * 320.0;
              nearM.freezeTimer = max(nearM.freezeTimer, 1.9);
            }
          }
          bursts.add(FxBurst(pos: CampaignCatalog.villageCenter, colorHex: 0xFFFF595E, maxRadius: 96, isTriangleShatter: true));
          callouts.add(
            FloatingCallout(
              pos: const Vec2(200, 310),
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
              pos: CampaignCatalog.villageCenter + const Vec2(0, -55),
              text: '⚠️ 외곽 기공 방어막 파손! 중앙 보호 장치를 사수하세요!',
              colorHex: 0xFFFF595E,
              isBigBanner: true,
            ),
          );
        }
      } else if (shieldHp <= 0 &&
          (distToCenter <= CampaignCatalog.centralTowerRadius + 24.0 + m.kind.radius * 0.6 ||
              m.pos.distanceTo(CampaignCatalog.centralTowerPos) <=
                  CampaignCatalog.centralTowerRadius + 24.0 + m.kind.radius * 0.6)) {
        // 방어막이 깨진 상태에서 중앙 자동 보호 장치 직접 타격 → attackPower 비례 피해!
        towerHp = max(0, towerHp - m.kind.attackPower * 0.95 * _mutantAttackScale);
        m.attackAnimTimer = 1.0;
        final ecoHit = (0.05 + m.kind.attackPower * 0.0012).clamp(0.05, 0.14);
        granaryHealth = (granaryHealth - ecoHit).clamp(0.0, 1.0);
        cropsHealth = (cropsHealth - ecoHit).clamp(0.0, 1.0);
        livestockHealth = (livestockHealth - ecoHit * 1.1).clamp(0.0, 1.0);

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

        final pushDir = (m.pos - CampaignCatalog.villageCenter).normalized;
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

    final origin = CampaignCatalog.centralTowerPos;
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
      projectiles.add(
        ActiveStoneProjectile(
          sourceKey: 'central_tower',
          sourceLabel: '중앙 기명 수호탑 (비공명 경계)',
          pos: origin,
          vel: rawDir * 300.0,
          material: StoneMaterial.cheongok,
          shape: StoneShape.flat,
          damage: centralSpec.baseDamage * 0.25,
          knockback: 14.0,
          critChance: 0.0,
          colorHex: 0xFF72EFDD,
          radius: 6.5,
          pierceLeft: 0,
          aoeSplashRadius: 0.0,
          maxTravelDist: effectiveCentralAutoRange * 1.15,
        )..bouncesLeft = 0,
      );
      return;
    }

    // 길목 초소가 1곳 이상 가동되어 진법이 연결되었을 때만 자동 어기어석·흡성탄지 발동! (내부 재사용 대기시간 5.2초로 무한 폭격 꼼수 차단)
    if (launchers.isNotEmpty && qiBars >= 2.95 && _autoEogiCooldown <= 0) {
      qiBars = 0.0;
      _autoEogiCooldown = 5.2;
      _fireAutoEogieoseok(target);
      return;
    }

    if (launchers.isNotEmpty && qiBars >= 2.0 && _countMutantsNear(target.pos, 80) >= 4) {
      qiBars -= 1.5;
      _spawnStoneShot(
        sourceKey: 'central_tower',
        sourceLabel: '중앙 기명 수호탑 (흡성탄지)',
        origin: origin,
        target: target,
        baseDamage: centralSpec.baseDamage * 1.48,
        speed: 350,
        pullsEnemies: true,
        aoeRadius: 72,
        maxTravelDist: effectiveCentralAutoRange * 1.25,
      );
      return;
    }

    bool useSectTech = false;
    if (launchers.isNotEmpty && qiBars >= 1.0) {
      qiBars -= 1.0;
      useSectTech = true;
    }

    _spawnStoneShot(
      sourceKey: 'central_tower',
      sourceLabel: '중앙 기명 수호탑',
      origin: origin,
      target: target,
      baseDamage: centralSpec.baseDamage * (useSectTech ? 1.35 : 0.85),
      speed: 345,
      pierceBonus: 0,
      sectTech: useSectTech ? preset.sectTechnique : null,
      maxTravelDist: effectiveCentralAutoRange * 1.18,
    );
  }

  void _fireAutoEogieoseok(ActiveMutant primaryTarget) {
    final origin = CampaignCatalog.centralTowerPos;
    final distinctTypes = launchers.map((e) => e.type).toSet().length;
    final monoPenalty =
        (stage.chapterNumber >= 4 && launchers.length >= 3 && distinctTypes <= 1) ? 0.46 : 1.0;
    final count = progress.realm.eogieoseokCount + 1;
    final maxEogiRange = (215.0 * liveRangeMultiplier).clamp(210.0, 290.0);
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
          .distanceTo(CampaignCatalog.villageCenter)
          .compareTo(b.pos.distanceTo(CampaignCatalog.villageCenter)),
    );
    for (int i = 0; i < count; i++) {
      final tgt = pool[i % pool.length];
      _spawnStoneShot(
        sourceKey: 'central_tower',
        sourceLabel: '중앙 기명 수호탑 (어기어석)',
        origin: origin + Vec2((i - count / 2) * 14, -8),
        target: tgt,
        baseDamage: centralSpec.baseDamage * 2.15 * monoPenalty,
        speed: 390,
        pierceBonus: 3,
        aoeRadius: 52,
        ignoresShield: true,
        maxTravelDist: maxEogiRange * 1.16,
      );
    }

    if (allowSerendipity && rng.nextDouble() < (0.22 + progress.meridianSerendipityBonus)) {
      serendipityCount++;
      pendingSounds.add(SoundCue.serendipityJackpot);
      qiBars = 2.95;
      callouts.add(
        FloatingCallout(
          pos: CampaignCatalog.villageCenter + const Vec2(0, -92),
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
    final hasteMult = (jeonggakHasteTimer > 0 ? 1.45 : 1.0) *
        (auroraCritTimer > 0 ? 1.50 : 1.0) *
        perkHaste *
        feverHaste *
        rouletteHaste *
        liveReloadMult;

    final links = activeSynergyLinks;
    final distinctTypes = launchers.map((e) => e.type).toSet().length;
    final hasNonAmpTower = launchers.any((e) => e.type != LauncherType.qiAmplifier);
    final monoOverload = stage.chapterNumber >= 4 && launchers.length >= 3 && distinctTypes <= 1;
    final typeDiversityMult = monoOverload
        ? 0.45
        : (distinctTypes >= 4 ? 1.72 : (distinctTypes >= 3 ? 1.42 : 1.0));
    // 실시간 화력업 및 과녁 배율은 _spawnStoneShot에서 일괄 곱해지므로 중복 제곱 증폭 차단!
    final fiveElemBonus = typeDiversityMult;

    int ampQiCount = 0;
    for (final l in launchers) {
      if (l.recoilAnim > 0) l.recoilAnim = max(0, l.recoilAnim - dt * 4.0);

      double ampReload = 1.0;
      double ampDamage = fiveElemBonus;
      double ampCrit = distinctTypes >= 3 ? 0.08 : 0.0;
      int synPierce = 0;
      double synSpeedMult = 1.0;

      for (final link in links) {
        if (link.slotA == l.slotIndex || link.slotB == l.slotIndex) {
          if (link.synergyName == '쌍성 공명진') ampReload += 0.18;
          if (link.synergyName == '쌍류 탄막진') {
            synSpeedMult = 1.18;
            synPierce = 1;
          }
        }
      }

      // 내공 증폭기는 자기 자신이나 다른 증폭기는 증폭하지 않고, 주변 다른 계통 포탑만 강력히 증폭(최대 2중첩)!
      if (l.type != LauncherType.qiAmplifier) {
        int ampStacks = 0;
        for (final other in launchers) {
          if (other != l &&
              other.type == LauncherType.qiAmplifier &&
              other.pos.distanceTo(l.pos) <= 145) {
            ampReload += 0.20 + other.tier * 0.06;
            ampDamage += 0.28 + other.tier * 0.09;
            ampCrit += 0.05 * other.tier;
            ampStacks++;
            if (ampStacks >= 2) break;
          }
        }
      }

      if (l.type == LauncherType.qiAmplifier && hasNonAmpTower && ampQiCount < 2) {
        ampQiCount++;
        qiBars = (qiBars + (0.08 + l.tier * 0.03) * dt).clamp(0.0, 3.0);
        if (l.tier >= 4 && shieldHp > 0) {
          shieldHp = min(shieldMaxHpDynamic, shieldHp + 2.8 * dt);
        }
      }

      l.cooldown -= dt * l.type.tierFireRateMultiplier(l.tier) * hasteMult * ampReload;
      if (l.cooldown > 0 || mutants.isEmpty) continue;

      final target = _pickTargetForLauncher(l);
      if (target == null) continue;

      l.cooldown = l.type.baseCooldownSec / (1.0 + (l.permanentLevel - 1) * 0.045);
      if (allowSerendipity && rng.nextDouble() < (0.11 + progress.meridianSerendipityBonus)) {
        l.cooldown = 0.08;
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
      final launcherSplash = switch (l.type) {
        LauncherType.heavy => 48.0 + l.tier * 10.0,
        LauncherType.frostField => 44.0 + l.tier * 8.0,
        _ => 0.0,
      };
      final spreadStep = switch (l.type) {
        LauncherType.rapid => 0.11,
        LauncherType.frostField => 0.16,
        LauncherType.curveSpin => 0.18,
        _ => 0.12,
      };
      for (int s = 0; s < shotCount; s++) {
        final spreadRad = shotCount == 1 ? 0.0 : (s - (shotCount - 1) / 2) * spreadStep;
        final curveSign = (s.isEven ? 1.0 : -1.0);
        _spawnStoneShot(
          sourceKey: 'launcher_${l.slotIndex}',
          sourceLabel: '${l.type.name}(${l.slotIndex + 1}거점)',
          origin: l.pos,
          target: target,
          baseDamage: dmg,
          speed: l.type.projectileSpeed * synSpeedMult,
          spreadAngleRad: spreadRad,
          extraCrit: ampCrit,
          spinCurve: l.type == LauncherType.curveSpin ? (1.15 + l.tier * 0.25) * curveSign : 0.0,
          pierceBonus: launcherPierce,
          ignoresShield: l.type == LauncherType.curveSpin || (l.type == LauncherType.heavy && l.tier >= 3),
          aoeRadius: launcherSplash,
          freezesOnHit: l.type == LauncherType.frostField,
          knockbackScale: l.type == LauncherType.heavy ? (1.65 + l.tier * 0.22) : 1.15,
          maxTravelDist: maxShotDist,
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

    final beast = preset.equippedBeast;
    final beastLv = progress.beastLevels[beast] ?? 1;
    if (beastLv > 0) {
      beastCooldown -= dt;
      if (beastCooldown <= 0 && _checkConditionMet(preset.beastCondition)) {
        beastCooldown = beast.baseCooldownSec * cdFactor;
        _executeSpiritBeast(beast, beastLv);

        if (allowSerendipity && rng.nextDouble() < (0.20 + progress.meridianSerendipityBonus)) {
          serendipityCount++;
          beastCooldown = 0.35;
          callouts.add(
            FloatingCallout(
              pos: CampaignCatalog.villageCenter + const Vec2(45, -40),
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
      if (companionCooldowns[hero]! <= 0 && _checkConditionMet(cond)) {
        companionCooldowns[hero] = hero.cooldownSec * cdFactor;
        _executeCompanionSkill(hero, progress.companionLevels[hero] ?? 1);
      }
    }

    if (!mukhyeonTriggered &&
        launchers.isNotEmpty &&
        (progress.companionLevels[CompanionHero.mukhyeon] ?? 0) > 0 &&
        shieldHp <= shieldMaxHpDynamic * 0.35 &&
        mutants.isNotEmpty) {
      mukhyeonTriggered = true;
      final mukLv = (progress.companionLevels[CompanionHero.mukhyeon] ?? 1).clamp(1, 10);
      shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * 0.25);
      callouts.add(
        FloatingCallout(
          pos: const Vec2(200, 310),
          text: '⚔️ 묵현 긴급 난입(Lv.$mukLv)! "그 마을을 무너뜨리게 두진 않겠다!"',
          colorHex: 0xFFC77DFF,
          isBigBanner: true,
        ),
      );
      for (final m in List<ActiveMutant>.from(mutants)) {
        if (m.pos.y > 240) {
          _applyDamageToMutant(
            m,
            centralSpec.baseDamage * 4.5 * (1.0 + (mukLv - 1) * 0.24),
            sourceKey: 'hero_mukhyeon',
            sourceLabel: '동료 묵현 (위기 난입)',
            knockDir: const Vec2(0, -1),
            knockForce: 155,
            isCritical: true,
          );
        }
      }
    }
  }

  bool _checkConditionMet(AutoTriggerCondition cond) {
    if (mutants.isEmpty) return false;
    switch (cond) {
      case AutoTriggerCondition.anyEnemyInRange:
        return true;
      case AutoTriggerCondition.denseCluster:
        return mutants.length >= 4;
      case AutoTriggerCondition.heavyOrBoss:
        return mutants.any(
          (m) =>
              m.kind.isBoss ||
              m.kind == MutantKind.ironBoar ||
              m.kind == MutantKind.shieldYacha,
        );
      case AutoTriggerCondition.shieldCrisis:
        return shieldHp <= shieldMaxHpDynamic * 0.65 || mutants.any((m) => m.pos.y > 410);
      case AutoTriggerCondition.qiFullBurst:
        return qiBars >= 1.2 || mutants.length >= 3;
    }
  }

  void _executeSpiritBeast(SpiritBeast beast, int lv) {
    final allyMaxR = (212.0 * liveRangeMultiplier).clamp(205.0, 285.0);
    final target = _pickMostThreateningMutant(CampaignCatalog.villageCenter, maxRange: allyMaxR);
    if (target == null) return;
    final allyMult = 1.0 + perkStacks(RoguePerk.allyAwakening) * 0.45;
    final power =
        centralSpec.baseDamage * (1.55 + lv * 0.22) * progress.realm.powerMult * allyMult;

    switch (beast) {
      case SpiritBeast.nalssaendol:
        _spawnStoneShot(
          sourceKey: 'beast_nalssaendol',
          sourceLabel: '영수 날쌘돌',
          origin: CampaignCatalog.villageCenter + const Vec2(-36, -12),
          target: target,
          baseDamage: power,
          speed: 375,
          maxTravelDist: allyMaxR * 1.15,
        );
        break;
      case SpiritBeast.geumgangTurtle:
        if (shieldHp > 0) {
          shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * (0.16 + lv * 0.015));
        }
        pendingSounds.add(SoundCue.shieldWave);
        for (final m in mutants) {
          if (m.pos.distanceTo(CampaignCatalog.villageCenter) < 170) {
            m.knockbackVel = (m.pos - CampaignCatalog.villageCenter).normalized * 135;
          }
        }
        break;
      case SpiritBeast.cheonghak:
        cheonghakBuffTimer = 5.0;
        _spawnStoneShot(
          sourceKey: 'beast_cheonghak',
          sourceLabel: '영수 청학',
          origin: CampaignCatalog.villageCenter + const Vec2(36, -12),
          target: target,
          baseDamage: power * 1.2,
          speed: 410,
          pierceBonus: 2,
          ignoresShield: true,
          maxTravelDist: allyMaxR * 1.15,
        );
        break;
      case SpiritBeast.baekho:
        for (final offset in [-18.0, 18.0]) {
          _spawnStoneShot(
            sourceKey: 'beast_baekho',
            sourceLabel: '영수 백호',
            origin: CampaignCatalog.villageCenter + Vec2(offset, -16),
            target: target,
            baseDamage: power * 1.35,
            speed: 360,
            knockbackScale: 1.85,
            aoeRadius: 42,
            maxTravelDist: allyMaxR * 1.15,
          );
        }
        break;
      case SpiritBeast.geumryong:
        final inRange = mutants
            .where((m) => m.pos.distanceTo(CampaignCatalog.villageCenter) <= allyMaxR)
            .toList();
        final pool = inRange.isNotEmpty ? inRange : <ActiveMutant>[target];
        for (int i = 0; i < 4; i++) {
          final tgt = pool[i % pool.length];
          _spawnStoneShot(
            sourceKey: 'beast_geumryong',
            sourceLabel: '영수 금룡',
            origin: CampaignCatalog.villageCenter + Vec2((i - 1.5) * 18, -20),
            target: tgt,
            baseDamage: power * 1.55,
            speed: 395,
            pierceBonus: 2,
            aoeRadius: 50,
            ignoresShield: true,
            maxTravelDist: allyMaxR * 1.18,
          );
        }
        break;
    }
  }

  void _executeCompanionSkill(CompanionHero hero, int lv) {
    final allyMaxR = (212.0 * liveRangeMultiplier).clamp(205.0, 285.0);
    final target = _pickMostThreateningMutant(CampaignCatalog.villageCenter, maxRange: allyMaxR);
    if (target == null) return;
    final allyMult = 1.0 + perkStacks(RoguePerk.allyAwakening) * 0.45;
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
                      m.pos.distanceTo(CampaignCatalog.villageCenter) <= allyMaxR,
                )
                .firstOrNull ??
            target;
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: CampaignCatalog.villageCenter + const Vec2(-48, 0),
          target: heavyTgt,
          baseDamage: baseDmg * 1.45,
          speed: 315,
          knockbackScale: 2.1,
          ignoresShield: true,
        );
        break;
      case CompanionHero.yeonbi:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: CampaignCatalog.villageCenter + const Vec2(48, 0),
          target: target,
          baseDamage: baseDmg * 1.25,
          speed: 350,
          spinCurve: 1.6,
          pierceBonus: 2,
          ignoresShield: true,
        );
        break;
      case CompanionHero.cheongmyeong:
        qiBars = (qiBars + 0.70).clamp(0.0, 3.0);
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: CampaignCatalog.villageCenter,
          target: target,
          baseDamage: baseDmg * 1.15,
          speed: 360,
        );
        break;
      case CompanionHero.bandal:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: CampaignCatalog.villageCenter + const Vec2(-32, -8),
          target: target,
          baseDamage: baseDmg * 1.20,
          speed: 330,
          aoeRadius: 58,
          oilsOnHit: true,
        );
        break;
      case CompanionHero.gurumi:
        for (final spread in [-0.24, 0.24]) {
          _spawnStoneShot(
            sourceKey: key,
            sourceLabel: label,
            origin: CampaignCatalog.villageCenter + const Vec2(32, -8),
            target: target,
            baseDamage: baseDmg * 0.95,
            speed: 380,
            spreadAngleRad: spread,
          );
        }
        break;
      case CompanionHero.jeonggak:
        jeonggakHasteTimer = 5.0;
        callouts.add(
          FloatingCallout(
            pos: CampaignCatalog.villageCenter + const Vec2(0, -40),
            text: '⚙️ 정각 기관 가속! 전 발사대 연사 1.45배!',
            colorHex: 0xFF90E0EF,
          ),
        );
        break;
      case CompanionHero.yonga:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: CampaignCatalog.villageCenter,
          target: target,
          baseDamage: baseDmg * 1.60,
          speed: 390,
          pierceBonus: 3,
          aoeRadius: 44,
        );
        break;
      case CompanionHero.chwiseon:
        qiBars = (qiBars + 1.15).clamp(0.0, 3.0);
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: CampaignCatalog.villageCenter,
          target: target,
          baseDamage: baseDmg * 1.25,
          speed: 345,
          spinCurve: -1.5,
        );
        break;
      case CompanionHero.mukgaek:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: CampaignCatalog.villageCenter,
          target: target,
          baseDamage: baseDmg * 1.25,
          speed: 335,
          aoeRadius: 62,
          knockbackScale: 1.7,
        );
        break;
      case CompanionHero.seolhwa:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: CampaignCatalog.villageCenter,
          target: target,
          baseDamage: baseDmg * 1.30,
          speed: 345,
          aoeRadius: 64,
          freezesOnHit: true,
        );
        break;
      case CompanionHero.magyo:
        _spawnStoneShot(
          sourceKey: key,
          sourceLabel: label,
          origin: CampaignCatalog.villageCenter,
          target: target,
          baseDamage: baseDmg * 1.45,
          speed: 335,
          aoeRadius: 76,
          pullsEnemies: true,
        );
        break;
      case CompanionHero.geomhwang:
        final inRange = mutants
            .where((m) => m.pos.distanceTo(CampaignCatalog.villageCenter) <= allyMaxR)
            .toList();
        final pool = inRange.isNotEmpty ? inRange : <ActiveMutant>[target];
        for (int i = 0; i < 3; i++) {
          final tgt = pool[i % pool.length];
          _spawnStoneShot(
            sourceKey: key,
            sourceLabel: label,
            origin: CampaignCatalog.villageCenter + Vec2((i - 1) * 16.0, -10),
            target: tgt,
            baseDamage: baseDmg * 0.92,
            speed: 415,
            extraCrit: 0.25,
            ignoresShield: true,
            maxTravelDist: allyMaxR * 1.15,
          );
        }
        break;
      case CompanionHero.sinseung:
        if (shieldHp > 0) {
          shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * 0.22);
        }
        cropsHealth = min(1.0, cropsHealth + 0.30);
        livestockHealth = min(1.0, livestockHealth + 0.30);
        pendingSounds.add(SoundCue.shieldWave);
        break;
      case CompanionHero.mukhyeon:
        break;
    }
  }

  void _stepSupportAutoTrigger() {
    // 초소를 단 1곳도 짓지 않고 방치할 때는 지원패가 저절로 소비·발동되지 않음!
    if (launchers.isEmpty || !allowSupportTokens || supportChargesLeft <= 0 || mutants.isEmpty) {
      return;
    }
    final shieldRatio = shieldMaxHpDynamic > 0 ? shieldHp / shieldMaxHpDynamic : 0.0;
    if (shieldRatio <= preset.supportTriggerShieldRatio && mutants.length >= 2) {
      triggerSupportChuldu();
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
    bool oilsOnHit = false,
    bool ignoresShield = false,
    double knockbackScale = 1.0,
    SectTechnique? sectTech,
    double maxTravelDist = 235.0,
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

    final leadFactor = (0.18 + progress.corePrecisionBonus * 0.8).clamp(0.18, 0.55);
    final nextWp = target.waypoints[target.waypointIndex.clamp(0, target.waypoints.length - 1)];
    final moveVel = target.smoothVel.length > 4.0
        ? target.smoothVel
        : (nextWp - target.pos).normalized * target.speed;
    final predictedPos = target.pos + moveVel * leadFactor;

    final rawDir = (predictedPos - origin).normalized;
    final baseAngle = atan2(rawDir.y, rawDir.x) + spreadAngleRad;
    final finalSpeed = speed *
        shape.speedFactor *
        (cheonghakBuffTimer > 0 ? 1.20 : 1.0) *
        (stone == StoneMaterial.manyeonGiju ? 1.18 : 1.0);
    final vel = Vec2(cos(baseAngle) * finalSpeed, sin(baseAngle) * finalSpeed);

    final isCritSerendipity =
        allowSerendipity && rng.nextDouble() < (0.07 + progress.meridianSerendipityBonus * 0.5);
    if (isCritSerendipity) {
      serendipityCount++;
    }

    int pierce = pierceBonus + (stone == StoneMaterial.geumgang ? 1 : 0);
    double splash = aoeRadius + (stone == StoneMaterial.obsidian ? 32.0 : 0.0);
    double curve = spinCurve * shape.spinCurveFactor;
    bool bypassShield = ignoresShield || stone == StoneMaterial.jageum || armorBreakStacks > 0;

    if (sectTech == SectTechnique.swordQi) pierce += 3;
    if (sectTech == SectTechnique.ironFist) splash = max(splash, 58.0);
    if (sectTech == SectTechnique.taiji) {
      curve = curve == 0 ? 1.35 : curve * 1.4;
      bypassShield = true;
      qiBars = (qiBars + 0.25).clamp(0.0, 3.0);
    }

    final liveDmgBoost = (1.0 + liveFirepowerLv * 0.15) * powerTarget.damageMultiplier;
    final finalDamage =
        baseDamage * liveDmgBoost * stone.damageMultiplier * (isCritSerendipity ? 2.1 : 1.0);
    final finalKnock = 46.0 *
        stone.knockbackMultiplier *
        shape.knockbackFactor *
        knockbackScale *
        (1.0 + boulderStacks * 0.55) *
        (1.0 + progress.meridianKnockbackBonus) *
        (stone == StoneMaterial.yongrin ? 1.35 : 1.0);
    final critChance = (0.10 +
            shape.critBonus +
            progress.meridianCritBonus +
            extraCrit +
            (feverTimer > 0 ? 0.35 : 0.0) +
            (cheonghakBuffTimer > 0 ? 0.10 : 0.0) +
            (stone == StoneMaterial.geumgang ? 0.08 : 0.0))
        .clamp(0.05, 0.88);
    final radiusScale = (1.0 + boulderStacks * 0.36).clamp(1.0, 2.0) * (feverTimer > 0 ? 1.16 : 1.0);

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
        colorHex: (isCritSerendipity || feverTimer > 0) ? 0xFFFFD166 : stone.colorHex,
        radius: (isCritSerendipity ? 13.5 : 8.5) * radiusScale,
        spinCurve: curve,
        pierceLeft: pierce,
        aoeSplashRadius: splash,
        pullsEnemies: pullsEnemies,
        freezesOnHit: freezesOnHit || stone == StoneMaterial.hancheol || frostStacks > 0,
        oilsOnHit: oilsOnHit,
        ignoresShield: bypassShield,
        isGiantCritSerendipity: isCritSerendipity,
        extraBounces: ricochetStacks * 2,
        maxTravelDist: maxTravelDist,
      ),
    );

    if (sectTech == SectTechnique.shadowClone) {
      final cloneAngle = baseAngle + 0.18;
      projectiles.add(
        ActiveStoneProjectile(
          sourceKey: sourceKey,
          sourceLabel: '$sourceLabel (분신탄)',
          pos: origin,
          vel: Vec2(cos(cloneAngle) * finalSpeed, sin(cloneAngle) * finalSpeed),
          material: stone,
          shape: shape,
          damage: finalDamage * 0.78,
          knockback: finalKnock * 0.85,
          critChance: critChance,
          colorHex: 0xFFC77DFF,
          radius: 8.2 * radiusScale,
          extraBounces: ricochetStacks * 2,
          maxTravelDist: maxTravelDist,
        ),
      );
    }
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

      if (p.trail.length >= 9) p.trail.removeAt(0);
      p.trail.add(p.pos);

      if (p.spinCurve.abs() > 0.05) {
        final perp = Vec2(-p.vel.y, p.vel.x).normalized;
        p.vel = p.vel + perp * (p.spinCurve * 95.0 * dt);
      }

      final stepDelta = p.vel * dt;
      p.pos = p.pos + stepDelta;
      p.traveledDist += stepDelta.length;
      if (p.traveledDist >= p.maxTravelDist) {
        projectiles.removeAt(i);
        continue;
      }

      // 1) ×2→×3 진화 배율 복제 마법진 통과 시 알이 2개 또는 3개(폭주 시!)로 복제 증식!
      if (!p.clonedByGate &&
          projectiles.length + spawnedClones.length < 180 &&
          p.pos.distanceTo(cloneGate.center) <= cloneGate.radius + p.radius * 0.5) {
        p.clonedByGate = true;
        p.maxTravelDist = min(315.0, p.maxTravelDist + 48.0);
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
        if (isTriple) {
          for (final offA in const [-0.17, 0.17]) {
            final a = baseA + offA;
            spawnedClones.add(
              ActiveStoneProjectile(
                sourceKey: p.sourceKey,
                sourceLabel: '${p.sourceLabel} (×3폭주)',
                pos: p.pos,
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
                oilsOnHit: p.oilsOnHit,
                ignoresShield: p.ignoresShield,
                clonedByGate: true,
                splitChild: p.splitChild,
                maxTravelDist: max(125.0, p.maxTravelDist - p.traveledDist + 48.0),
              )..bouncesLeft = p.bouncesLeft,
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
              pos: p.pos,
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
              oilsOnHit: p.oilsOnHit,
              ignoresShield: p.ignoresShield,
              clonedByGate: true,
              splitChild: p.splitChild,
              maxTravelDist: max(125.0, p.maxTravelDist - p.traveledDist + 48.0),
            )..bouncesLeft = p.bouncesLeft,
          );
          bursts.add(FxBurst(pos: cloneGate.center, colorHex: 0xFF72EFDD, maxRadius: 30));
        }
      }

      // 1-B) 🎯 화력 증폭 과녁패 적중 판정 (맞힐수록 +10% → +60% 전군 화력 급상승 & 기력 +2⚡!)
      if (!p.hitMutantIds.contains(-777) &&
          p.pos.distanceTo(powerTarget.center) <= powerTarget.radius + p.radius * 0.6) {
        p.hitMutantIds.add(-777);
        final prevStacks = powerTarget.powerStacks;
        powerTarget.powerStacks = (powerTarget.powerStacks + 1).clamp(1, 6);
        powerTarget.decayTimer = 11.0;
        powerTarget.pulseAnim = 1.0;
        fieldTokens += 2;
        bursts.add(FxBurst(pos: powerTarget.center, colorHex: 0xFFFFD166, maxRadius: 26));
        if (powerTarget.powerStacks > prevStacks) {
          callouts.add(
            FloatingCallout(
              pos: powerTarget.center + const Vec2(0, -18),
              text: '🎯 전군 화력 +${powerTarget.bonusPercent}% 증폭!',
              colorHex: 0xFFFFD166,
            ),
          );
        }
      }

      // 2) 심야 화약통 유폭 판정 (대폭발 범위 피해 + 건설 기력 구슬 +16⚡!)
      for (final keg in powderKegs) {
        if (keg.intact && p.pos.distanceTo(keg.pos) <= 18.0 + p.radius) {
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
          final blastDmg = (52.0 + stage.chapterNumber * 20.0) * progress.realm.powerMult;
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

      // 3) 황금 보물 도깨비 타격 & 처치 대박 보상!
      if (treasureGoblin != null &&
          treasureGoblin!.alive &&
          p.pos.distanceTo(treasureGoblin!.pos) <= 20.0 + p.radius) {
        final g = treasureGoblin!;
        g.hitFlashTimer = 1.0;
        g.hp -= p.damage * 1.25;
        bursts.add(FxBurst(pos: g.pos, colorHex: 0xFFFFD166, maxRadius: 28));
        if (g.hp <= 0) {
          g.alive = false;
          const gobQi = 55;
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

      // 좌우 담장 반사 도탄
      if (p.pos.x < 16 || p.pos.x > CampaignCatalog.arenaWidth - 16) {
        if (p.bouncesLeft > 0) {
          p.pos = Vec2(p.pos.x.clamp(16.0, CampaignCatalog.arenaWidth - 16.0), p.pos.y);
          p.vel = Vec2(-p.vel.x * p.material.bounceKeep, p.vel.y * p.material.bounceKeep);
          p.bouncesLeft--;
          p.bouncedOffObstacle = true;
          p.ignoresShield = true;
          p.maxTravelDist = min(315.0, p.maxTravelDist + 42.0);
        } else {
          projectiles.removeAt(i);
          continue;
        }
      }
      if (p.pos.y < 10 || p.pos.y > CampaignCatalog.arenaHeight - 10) {
        projectiles.removeAt(i);
        continue;
      }

      // 회전 다각형 기둥 1.4배 가속 반발 도탄!
      for (final pillar in chapter.pillars) {
        final toP = p.pos - pillar.center;
        final dist = toP.length;
        if (dist < pillar.radius + p.radius && p.bouncesLeft > 0) {
          final n = toP.normalized;
          final dot = p.vel.x * n.x + p.vel.y * n.y;
          final reflected = p.vel - n * (2 * dot);
          p.vel = reflected.normalized * min(520.0, p.vel.length * pillar.restitutionBoost * 0.92);
          p.pos = pillar.center + n * (pillar.radius + p.radius + 2.0);
          p.bouncesLeft--;
          p.bouncedOffObstacle = true;
          p.ignoresShield = true;
          p.maxTravelDist = min(315.0, p.maxTravelDist + 42.0);
          bursts.add(FxBurst(pos: p.pos, colorHex: 0xFFFFD166, maxRadius: 22));
        }
      }

      // 황금 보급 두꺼비 도탄 포획!
      if (goldenToad != null &&
          goldenToad!.alive &&
          p.pos.distanceTo(goldenToad!.pos) < p.radius + 16.0) {
        goldenToad!.alive = false;
        fieldTokens += 45;
        earnedPermanentTokens += 35;
        earnedElixirs += 2;
        _spawnFlyingQiOrb(goldenToad!.pos, 45);
        pendingSounds.add(SoundCue.serendipityJackpot);
        callouts.add(
          FloatingCallout(
            pos: goldenToad!.pos,
            text: '🐸 황금 두꺼비 포획 대박! 기력 +45⚡ · 영약 +2!',
            colorHex: 0xFFFFD166,
            isBigBanner: true,
          ),
        );
      }

      // 돌연변이 충돌 판정
      bool consumed = false;
      for (int mIdx = mutants.length - 1; mIdx >= 0; mIdx--) {
        if (mIdx >= mutants.length) continue;
        final m = mutants[mIdx];
        if (p.hitMutantIds.contains(m.uid)) continue;
        if (p.pos.distanceTo(m.pos) <= p.radius + m.kind.radius) {
          p.hitMutantIds.add(m.uid);
          _resolveProjectileHitMutant(p, m, spawnedClones);

          if (p.pierceLeft > 0) {
            p.pierceLeft--;
          } else if (p.bouncesLeft > 0 && (p.material.grade >= 6 || perkStacks(RoguePerk.ricochetMaster) > 0)) {
            p.bouncesLeft--;
            p.vel = Vec2(-p.vel.y * 0.78, p.vel.x * 0.78) * p.material.bounceKeep;
            p.bouncedOffObstacle = true;
          } else {
            consumed = true;
          }
          break;
        }
      }
      if (consumed) {
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
        bursts.add(FxBurst(pos: CampaignCatalog.centralTowerPos, colorHex: 0xFFFFD166, maxRadius: 72));
        callouts.add(
          FloatingCallout(
            pos: const Vec2(200, 155),
            text: '🔥 광폭 탄지 무쌍(피버 타임) 돌입!! 6.5초간 전 초소 폭주!',
            colorHex: 0xFFFFD166,
            ttlSec: 2.0,
            isBigBanner: true,
          ),
        );
      }
    }

    final isCrit =
        auroraCritTimer > 0 || p.isGiantCritSerendipity || rng.nextDouble() < p.critChance;
    double mult = isCrit ? (1.65 + progress.corePrecisionBonus) : 1.0;

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

    // 빙결·서리 취성 효과: 한빙 역장기 등으로 얼거나 느려진 적은 타 병종 포격에 +45% 추가 파쇄 피해!
    if (!p.freezesOnHit && (m.freezeTimer > 0 || m.slowTimer > 0)) {
      mult *= 1.45;
      if (activeSynergyLinks.any((l) => l.synergyName == '쇄빙 파쇄진')) {
        mult *= 1.22;
      }
    }

    // 5종 발사대 정밀 상성 분화 (제3장 이상 본격 발동 — 입문 1~2장은 기본 장갑 공식 그대로 보존)
    final isRapid = p.sourceLabel.contains('속사');
    final isHeavy = p.sourceLabel.contains('중포');
    final isCurve = p.sourceLabel.contains('곡사');
    final isHeavyArmorTarget = m.kind == MutantKind.ironBoar ||
        m.kind == MutantKind.ironColossusBoss ||
        m.kind == MutantKind.raiderHeukpung ||
        m.kind == MutantKind.chapterOverlord;
    final isAgileSwarmTarget = m.kind == MutantKind.swarmRat ||
        m.kind == MutantKind.sickHound ||
        m.kind == MutantKind.swiftShadowBoss;

    if (stage.chapterNumber >= 3) {
      if (isRapid) {
        if (isAgileSwarmTarget) {
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
        if (m.kind == MutantKind.shieldYacha ||
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

    if (m.kind.frontShieldReduction > 0 &&
        !p.ignoresShield &&
        !p.bouncedOffObstacle &&
        armorBreakStacks == 0) {
      mult *= (1.0 - m.kind.frontShieldReduction);
      shieldYachaBlocks++;
    }

    if (p.freezesOnHit) {
      if (m.freezeImmuneTimer <= 0) {
        m.freezeTimer = max(m.freezeTimer, m.kind.isBoss ? 0.85 : 1.15);
        m.freezeImmuneTimer = m.kind.isBoss ? 3.8 : 2.8;
      }
      m.slowTimer = max(m.slowTimer, 2.8);
    } else if (p.material == StoneMaterial.bingbaek) {
      m.slowTimer = max(m.slowTimer, 2.5);
    }
    if (p.oilsOnHit) {
      m.oilSlipTimer = 4.0;
    }

    if (isCrit) {
      pendingSounds.add(SoundCue.criticalShatter);
      qiBars = (qiBars + 0.06).clamp(0.0, 3.0);
    } else if (p.material == StoneMaterial.bingbaek || p.material == StoneMaterial.hancheol) {
      pendingSounds.add(SoundCue.stoneHitIce);
    } else if (p.material == StoneMaterial.manyeonGiju) {
      pendingSounds.add(SoundCue.stoneHitWood);
    } else if (p.material.density >= 2.0) {
      pendingSounds.add(SoundCue.stoneHitHeavy);
    } else {
      pendingSounds.add(SoundCue.stoneHitCheongok);
    }
    qiBars = (qiBars + 0.025).clamp(0.0, 3.0);

    final hitDir = p.vel.normalized;
    final halfPen = armorBreakStacks > 0 ||
        isHeavy ||
        p.material.density >= 1.35 ||
        isCrit;
    _applyDamageToMutant(
      m,
      p.damage * mult,
      sourceKey: p.sourceKey,
      sourceLabel: p.sourceLabel,
      knockDir: hitDir,
      knockForce: p.knockback,
      isCritical: isCrit,
      halfArmorPenetration: halfPen,
      fullArmorIgnore: armorBreakStacks > 0 || (stage.chapterNumber >= 3 && isHeavy),
    );

    // [비급: 쌍탄 분열비급] 첫 적 적중 시 2갈래 분열탄 생성!
    final splitStacks = perkStacks(RoguePerk.splitShot);
    if (splitStacks > 0 && !p.splitChild && projectiles.length + spawnedClones.length < 180) {
      final spd = p.vel.length * 0.92;
      final baseA = atan2(p.vel.y, p.vel.x);
      final splitDmg = p.damage * (0.52 + (splitStacks - 1) * 0.35);
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
            freezesOnHit: p.freezesOnHit,
            ignoresShield: p.ignoresShield,
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
        screenShakeTimer = max(screenShakeTimer, 0.10);
        screenShakeIntensity = max(screenShakeIntensity, 2.4);
      }
      for (final other in List<ActiveMutant>.from(mutants)) {
        if (other.uid != m.uid && other.pos.distanceTo(m.pos) <= p.aoeSplashRadius) {
          _applyDamageToMutant(
            other,
            p.damage * 0.58,
            sourceKey: p.sourceKey,
            sourceLabel: p.sourceLabel,
            knockDir: (other.pos - m.pos).normalized,
            knockForce: p.knockback * 0.75,
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
    bool fullArmorIgnore = false,
    int chainDepth = 0,
  }) {
    if (!mutants.contains(m)) return;
    m.hitFlashTimer = 1.0;

    double armor = fullArmorIgnore ? 0.0 : m.kind.armorReduction;
    if (armor > 0) {
      final penetratesHalf = halfArmorPenetration ||
          isCritical ||
          preset.primaryStone.density >= 1.35 ||
          sourceLabel.contains('중포');
      if (penetratesHalf) {
        armor *= 0.5;
      }
    }
    final effectiveDmg = (sourceKey == 'support_chuldu' && !m.kind.isBoss)
        ? dmg
        : dmg * (1.0 - armor).clamp(0.1, 1.0);

    final dealt = min(m.hp, effectiveDmg);
    m.hp -= effectiveDmg;
    final impactScale = stage.chapterNumber <= 2
        ? 1.0
        : (0.22 + 0.78 * (effectiveDmg / max(1.0, m.maxHp * 0.14)).clamp(0.0, 1.0));
    m.knockbackVel =
        m.knockbackVel + knockDir * ((knockForce * impactScale) / sqrt(m.kind.mass));
    final isKillingBlow = m.hp <= 0;

    // 찰진 타격 숫자 팝업 (치명타·격살·중대형 타격 위주로 최대 38개 풀 유지!)
    final shownDmg = effectiveDmg.round().clamp(1, 99999);
    if ((isCritical || isKillingBlow || shownDmg >= 18) && damagePopups.length < 38) {
      final jitterX = (rng.nextDouble() - 0.5) * 28.0;
      damagePopups.add(
        DamagePopupFx(
          pos: m.pos + Vec2(jitterX * 0.35, -m.kind.radius * 0.7),
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

      if (preset.primaryStone == StoneMaterial.onok && shieldHp > 0 && launchers.isNotEmpty) {
        final healRatio = stage.globalIndex >= 900 ? 0.008 : 0.016;
        shieldHp = min(shieldMaxHpDynamic, shieldHp + shieldMaxHpDynamic * healRatio);
      }

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
              sourceKey: sourceKey,
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
              sourceKey: sourceKey,
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
          chainShatterCount++;
          bursts.add(
            FxBurst(
              pos: m.pos,
              colorHex: 0xFFFFD166,
              maxRadius: 56,
              isTriangleShatter: true,
            ),
          );
          for (final near in List<ActiveMutant>.from(mutants)) {
            if (near.pos.distanceTo(m.pos) <= 58.0) {
              _applyDamageToMutant(
                near,
                effectiveDmg * 0.52,
                sourceKey: sourceKey,
                sourceLabel: sourceLabel,
                knockDir: (near.pos - m.pos).normalized,
                knockForce: knockForce * 0.7,
                isCritical: true,
                halfArmorPenetration: true,
                chainDepth: chainDepth + 1,
              );
            }
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
              ..waypointIndex = m.waypointIndex
              ..headingRad = m.headingRad
              ..smoothVel = m.smoothVel.length > 2.0
                  ? m.smoothVel.normalized * childSpd
                  : Vec2(0, childSpd),
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

    final warChestMult = 1.0 + perkStacks(RoguePerk.warChest) * 0.30;
    final baseDrop = m.kind == MutantKind.sickHound && killCount.isEven
        ? 2
        : m.kind.dropTokens;
    final drop = (baseDrop *
            bonusTokenMult *
            warChestMult *
            (1.0 + progress.meridianTokenDropBonus) *
            difficulty.rewardMult)
        .round()
        .clamp(1, 200);
    fieldTokens += drop;
    _permTokenCarry += drop * 0.28;
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

  ActiveMutant? _pickMostThreateningMutant(Vec2 origin, {required double maxRange}) {
    ActiveMutant? best;
    double bestDistToVillage = 999999;
    for (final m in mutants) {
      if (m.pos.distanceTo(origin) > maxRange) continue;
      final dVillage = m.pos.distanceTo(CampaignCatalog.villageCenter);
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
      final dist = m.pos.distanceTo(l.pos);
      if (dist > maxR || dist < minR) continue;
      double score = 600.0 - m.pos.distanceTo(CampaignCatalog.villageCenter);
      if (m.isInfiltrator) {
        score += 110.0; // 길 밖에서 직선 기습하는 월담·땅굴 침투조 우선 요격!
      }
      if (l.type == LauncherType.heavy && (m.kind.isBoss || m.kind.toughnessRating >= 4)) {
        score += 185;
      } else if (l.type == LauncherType.curveSpin && m.kind.frontShieldReduction >= 0.25) {
        score += 185;
      } else if (l.type == LauncherType.frostField && m.freezeTimer <= 0) {
        score += 130 + (m.kind.speedRating >= 4 ? 70 : 0);
      } else if (l.type == LauncherType.rapid && m.kind.speedRating >= 4 && !m.kind.isBoss) {
        score += 45;
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
    for (int i = callouts.length - 1; i >= 0; i--) {
      callouts[i].ttlSec -= dt;
      callouts[i].pos = callouts[i].pos + const Vec2(0, -14 * 0.016);
      if (callouts[i].ttlSec <= 0) callouts.removeAt(i);
    }
    for (int i = bursts.length - 1; i >= 0; i--) {
      bursts[i].ttlSec -= dt;
      if (bursts[i].ttlSec <= 0) bursts.removeAt(i);
    }
  }

  void _checkWinLoseCondition() {
    if (shieldHp <= 0 && towerHp <= 0) {
      isFinished = true;
      isVictory = false;
      granaryHealth = 0.0;
      cropsHealth = 0.0;
      livestockHealth = 0.0;
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
      earnedElixirs += stage.clearElixirBonus;
      earnedPermanentTokens += 20 + stage.chapterNumber * 8;
      pendingSounds.add(SoundCue.dawnPurify);
    }
  }

  BattleSummary buildSummary() {
    final ecoAvg = (granaryHealth + cropsHealth + livestockHealth) / 3.0;
    int stars = 0;
    if (isVictory) {
      if (shieldHp > 0 && ecoAvg >= 0.88) {
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

    final contribList = _contribMap.values.toList()
      ..sort((a, b) => b.totalDamage.compareTo(a.totalDamage));

    String tip;
    if (isVictory) {
      tip = stars == 3
          ? '완벽한 수호 진법입니다! 식량 창고·논밭·외양간 모두 온전히 지켜냈습니다!'
          : '승리했습니다! 초소 조합 시너지와 돌파 비급·합치기 진화를 활용하면 ★3 만점 수호가 쉬워집니다.';
    } else if (launchers.isEmpty) {
      tip = '길목 초소가 0곳이라 본진이 돌파당했습니다! 초반 군수 기력(⚡)으로 반드시 빈 초소에 발사대를 세우거나 운빨 소환(35⚡)을 실행하세요!';
    } else if (shieldYachaBlocks >= 6) {
      tip = '뼈방패 야차에게 정면 탄이 막혔습니다! 거점에 「곡사 회전기」를 세우거나 「파갑 멸마송」 비급을 선택해보세요.';
    } else if (heavyHitsOnShield >= 3) {
      tip = '중갑 돌진 변이체가 방어막을 부쉈습니다! 「중포 탄지기 + 한빙 역장기(쇄빙 파쇄진)」 조합을 배치해보세요.';
    } else if (swarmHitsOnShield >= 5) {
      tip = '빠른 무리에 포위되었습니다! 「속사 탄지기」 건설과 「쌍탄 분열비급 · 홍련 폭렬파」 비급을 활용해보세요.';
    } else {
      tip = '기명 심법 수련에서 혈자리를 개통하고, 전장의 화약통과 ×2 복제 마법진을 중앙탑 수동 탄지로 노려보세요!';
    }

    return BattleSummary(
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
      encounteredMutants: Set<MutantKind>.from(encounteredMutants),
    );
  }
}
