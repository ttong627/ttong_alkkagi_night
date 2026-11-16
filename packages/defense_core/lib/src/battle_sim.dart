import 'dart:math';

import 'allies.dart';
import 'campaign.dart';
import 'daily_quests_codex.dart';
import 'launchers.dart';
import 'materials.dart';
import 'mutants.dart';
import 'progression.dart';

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
  double dashCooldown = 2.6;
  double spawnPortalTimer = 0.45;

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
  }) : bouncesLeft = shape.maxBounces;

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

  late final CentralGuardianSpec centralSpec;
  late double shieldHp;
  late double towerHp;
  double centralFireTimer = 0.25;
  double centralGearAngle = 0.0;

  /// 맨 아래 중앙 기명 수호탑 `자동 발사` ↔ `수동 탄지` 전환 상태.
  bool centralManualMode = false;
  double centralAimAngleRad = -pi / 2;
  double centralRecoilAnim = 0.0;

  bool get isCentralReadyToFire => !isFinished && towerHp > 0 && centralFireTimer <= 0.04;

  /// 마을 생태계 3대 지표 (1.0 = 평온/풍요, 0.0 = 황폐/폐사).
  double granaryHealth = 1.0;
  double cropsHealth = 1.0;
  double livestockHealth = 1.0;

  /// 현장 보유 증표(실시간 발사대 버전 업그레이드용) 및 정산 누적 보상.
  int fieldTokens = 0;
  int earnedPermanentTokens = 0;
  int earnedElixirs = 0;

  /// 내공 게이지 (0.0 ~ 3.0칸) 및 전술 비약 버프 타이머.
  double qiBars = 0.0;
  double jeonggakHasteTimer = 0.0;
  double cheonghakBuffTimer = 0.0;
  double auroraCritTimer = 0.0;

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

  void _initBattle() {
    centralSpec = CentralGuardianSpec.fromLevels(
      centralLevel: progress.centralGuardianLevel,
      realmDefenseMult: progress.realm.defenseMult,
      meridianShieldBonus: progress.meridianShieldHpBonus,
      meridianReloadBonus: progress.meridianCentralReloadBonus,
      coreFortitudeBonus: progress.coreFortitudeBonus + progress.codexPowerBonus,
      coreFirepowerBonus: progress.coreFirepowerBonus + progress.codexPowerBonus,
    );
    shieldHp = centralSpec.shieldMaxHp;
    towerHp = centralSpec.coreMaxHp;

    final buffMult = progress.convoySupplyBuffBattles > 0 ? 1.20 : 1.0;
    fieldTokens = (stage.startingFieldTokens * buffMult).round();
    qiBars = (progress.realm.startQiBars + progress.meridianStartQiBonus).clamp(0.0, 3.0);

    if (allowSupportTokens) {
      supportChargesLeft = min(preset.supportSlotCount, progress.supportTokens);
    }

    // 실제 플레이 시작 시 길목 발사대는 0개(모두 빈 초소)이며 플레이어가 직접 배치한다!
    // 맨 아래 중앙 기명 수호탑(자동·수동 전환 가능)만 기본 가동된다.
    launchers.clear();

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

  /// 순서대로 정해진 듯 배치를 유도하는 다음 추천 빈 초소 번호 (모두 배치 시 null).
  int? nextRecommendedSlotIndex() {
    for (final m in activeMounts) {
      if (launcherAtSlot(m.slotIndex) == null) {
        return m.slotIndex;
      }
    }
    return null;
  }

  /// 발사대 종류 해금 여부 확인.
  bool isLauncherTypeUnlocked(LauncherType type) =>
      type.unlockChapter <= max(stage.chapterNumber, progress.highestUnlockedChapter) + 1;

  /// 빈 길목 초소에 플레이어가 직접 수호 발사대 신규 배치!
  bool placeLauncherInBattle(int slotIndex, LauncherType type) {
    if (isFinished) return false;
    final slot = mountSlotByIndex(slotIndex);
    if (slot == null) return false;
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
        text: '🛠️ ${type.name} 배치 완료!',
        colorHex: 0xFF72EFDD,
      ),
    );
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
        text: '♻️ 초소 철거 (+$refund 증표 환급)',
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
        text: manual ? '🎯 중앙 탑: 수동 조준 탄지(화력 ×1.38·관통 +2)!' : '⚙️ 중앙 탑: 자동 조준 사격 가동!',
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

  /// 수동 탄지 도탄 궤적 예측선 계산 (벽면 및 회전 기둥 1회 반사 포함).
  List<Vec2> previewCentralManualRay(double rawAngleRad, {double maxDist = 610.0}) {
    final angle = sanitizeManualAimAngle(rawAngleRad);
    final origin = CampaignCatalog.centralTowerPos;
    Vec2 cur = origin;
    Vec2 dir = Vec2(cos(angle), sin(angle)).normalized;
    final pts = <Vec2>[origin];
    double rem = maxDist;
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

  /// 플레이어가 조준한 각도로 중앙 기명 수호탑 수동 강화 탄지 발사!
  bool fireCentralManualAngle(double rawAngleRad) {
    if (!isCentralReadyToFire) return false;
    final angle = sanitizeManualAimAngle(rawAngleRad);
    centralAimAngleRad = angle;
    centralRecoilAnim = 1.0;
    centralFireTimer = auroraCritTimer > 0
        ? (centralSpec.fireIntervalSec * 0.86) / 1.55
        : centralSpec.fireIntervalSec * 0.86;
    pendingSounds.add(SoundCue.gearMotion);

    final origin = CampaignCatalog.centralTowerPos;

    if (qiBars >= 2.95) {
      qiBars = 0.0;
      final count = progress.realm.eogieoseokCount + 2;
      callouts.add(
        FloatingCallout(
          pos: origin + const Vec2(0, -48),
          text: '⚡ 수동 어기어석 일제 탄지! ($count기 관통 파쇄!)',
          colorHex: 0xFFFFD166,
          isBigBanner: true,
        ),
      );
      for (int i = 0; i < count; i++) {
        final spread = (i - (count - 1) / 2.0) * 0.11;
        _spawnManualDirectionalShot(
          origin: origin + Vec2((i - (count - 1) / 2.0) * 8.0, -6),
          angleRad: angle + spread,
          baseDamage: centralSpec.baseDamage * 2.15,
          speed: 410,
          pierceBonus: 4,
          aoeRadius: 52,
          ignoresShield: true,
          knockbackScale: 1.45,
        );
      }
      return true;
    }

    SectTechnique? sectTech;
    double dmgMult = 1.38; // 수동 직접 탄지 정밀 화력 가산!
    if (qiBars >= 1.0) {
      qiBars -= 1.0;
      sectTech = preset.sectTechnique;
      dmgMult *= 1.32;
    }

    _spawnManualDirectionalShot(
      origin: origin + const Vec2(0, -6),
      angleRad: angle,
      baseDamage: centralSpec.baseDamage * dmgMult,
      speed: 390,
      pierceBonus: 2,
      aoeRadius: 28,
      knockbackScale: 1.28,
      sectTech: sectTech,
    );
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
    if (projectiles.length >= 56) {
      projectiles.removeAt(0);
    }
    final stone = preset.primaryStone;
    final shape = preset.primaryShape;
    final finalSpeed = speed *
        shape.speedFactor *
        (cheonghakBuffTimer > 0 ? 1.20 : 1.0) *
        (stone == StoneMaterial.manyeonGiju ? 1.18 : 1.0);
    final vel = Vec2(cos(angleRad) * finalSpeed, sin(angleRad) * finalSpeed);

    final isCritSerendipity =
        allowSerendipity && rng.nextDouble() < (0.12 + progress.meridianSerendipityBonus * 0.6);
    if (isCritSerendipity) {
      serendipityCount++;
    }

    int pierce = pierceBonus + (stone == StoneMaterial.geumgang ? 1 : 0);
    double splash = aoeRadius + (stone == StoneMaterial.obsidian ? 32.0 : 0.0);
    double curve = 0.0;
    bool bypassShield = ignoresShield || stone == StoneMaterial.jageum;

    if (sectTech == SectTechnique.swordQi) pierce += 3;
    if (sectTech == SectTechnique.ironFist) splash = max(splash, 60.0);
    if (sectTech == SectTechnique.taiji) {
      curve = 1.25 * shape.spinCurveFactor;
      bypassShield = true;
      qiBars = (qiBars + 0.25).clamp(0.0, 3.0);
    }

    final finalDamage = baseDamage * stone.damageMultiplier * (isCritSerendipity ? 2.1 : 1.0);
    final finalKnock = 48.0 *
        stone.knockbackMultiplier *
        shape.knockbackFactor *
        knockbackScale *
        (1.0 + progress.meridianKnockbackBonus) *
        (stone == StoneMaterial.yongrin ? 1.35 : 1.0);
    final critChance = (0.16 +
            shape.critBonus +
            progress.meridianCritBonus +
            (cheonghakBuffTimer > 0 ? 0.10 : 0.0) +
            (stone == StoneMaterial.geumgang ? 0.08 : 0.0))
        .clamp(0.05, 0.82);

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
        colorHex: isCritSerendipity ? 0xFFFFD166 : stone.colorHex,
        radius: isCritSerendipity ? 13.5 : 9.2,
        spinCurve: curve,
        pierceLeft: pierce,
        aoeSplashRadius: splash,
        freezesOnHit: stone == StoneMaterial.hancheol,
        ignoresShield: bypassShield,
        isGiantCritSerendipity: isCritSerendipity,
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
          pierceLeft: max(0, pierce - 1),
        ),
      );
    }
  }

  void _enqueueWave(int waveIdx) {
    _spawnQueue.clear();
    if (waveIdx >= stage.waves.length) return;
    final groups = stage.waves[waveIdx];
    for (final g in groups) {
      final lIdx = g.laneIndex % chapter.lanes.length;
      if (lIdx < lanePortalEnergy.length) {
        lanePortalEnergy[lIdx] = max(lanePortalEnergy[lIdx], 0.75);
      }
      for (int i = 0; i < g.count; i++) {
        _spawnQueue.add(
          _PendingSpawn(
            delaySec: 0.35 + i * g.intervalSec,
            kind: g.kind,
            laneIndex: lIdx,
            customTitle: g.customBossTitle,
            customPortrait: g.customPortrait,
          ),
        );
      }
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
        shieldHp = min(centralSpec.shieldMaxHp, shieldHp + centralSpec.shieldMaxHp * 0.45);
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
    shieldHp = (shieldHp + centralSpec.shieldMaxHp * 0.32).clamp(0.0, centralSpec.shieldMaxHp);
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

  /// 물리 1스텝 진행 (표준 dt = 1/60초).
  void step(double dt) {
    if (isFinished || !dt.isFinite || dt <= 0) return;
    elapsedSec += dt;
    centralGearAngle += dt * 1.8;

    if (jeonggakHasteTimer > 0) jeonggakHasteTimer = max(0, jeonggakHasteTimer - dt);
    if (cheonghakBuffTimer > 0) cheonghakBuffTimer = max(0, cheonghakBuffTimer - dt);
    if (auroraCritTimer > 0) auroraCritTimer = max(0, auroraCritTimer - dt);
    if (chulduSweepAnimTimer > 0) chulduSweepAnimTimer = max(0, chulduSweepAnimTimer - dt);
    if (dawnPurifyAnimTimer > 0) dawnPurifyAnimTimer = max(0, dawnPurifyAnimTimer - dt);

    for (int i = 0; i < chapter.pillars.length; i++) {
      pillarAngles[i] += chapter.pillars[i].rotationSpeedRad * dt;
    }

    // 수련 호신 강기에 따른 방어막 미세 자연 회복
    if (shieldHp > 0 && shieldHp < centralSpec.shieldMaxHp) {
      shieldHp = min(
        centralSpec.shieldMaxHp,
        shieldHp + (1.4 + progress.coreFortitudeBonus * 14.0) * dt,
      );
    }

    if (centralRecoilAnim > 0) {
      centralRecoilAnim = max(0, centralRecoilAnim - dt * 4.2);
    }

    // 헤드리스 밸런스 검증(`autoBuildForSimVerify == true`) 시 빈 초소 순차 배치 시뮬레이션
    // 실제 플레이(`autoBuildForSimVerify == false`)에서는 빈 초소에 절대 자동 설치하지 않고 플레이어가 직접 배치!
    if (autoBuildForSimVerify) {
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

    // 이미 배치된 발사대의 자동 버전 업그레이드 (헤드리스 검증에서는 기본 초소 배치 우선 후 승급)
    final allowAutoUpgNow = preset.autoUpgradeInBattle &&
        launchers.isNotEmpty &&
        (!autoBuildForSimVerify ||
            nextRecommendedSlotIndex() == null ||
            launchers.length >= min(4, activeMounts.length) && fieldTokens >= 95);
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
    if (!goldenToadSpawned && elapsedSec > 14.0 && allowSerendipity) {
      goldenToadSpawned = true;
      goldenToad = GoldenSupplyToad(
        pos: const Vec2(28, 260),
        vel: const Vec2(56, 4),
      );
      callouts.add(
        FloatingCallout(
          pos: const Vec2(90, 240),
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
    _stepMutants(dt);
    _stepCentralGuardian(dt);
    _stepPathLaunchers(dt);
    _stepSpiritBeastAndCompanions(dt);
    _stepSupportAutoTrigger();
    _stepProjectiles(dt);
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
    } else if (mutants.isEmpty && currentWaveIndex + 1 < stage.waves.length) {
      wavePauseTimer -= dt;
      if (wavePauseTimer <= 0) {
        wavesClearedCount = max(wavesClearedCount, currentWaveIndex + 1);
        currentWaveIndex++;
        wavePauseTimer = 1.45;
        _enqueueWave(currentWaveIndex);
        // 한 번 더 출두 기연 예약이 있으면 새 웨이브 돌입 직후 자동 공짜 출두!
        if (pendingFreeEncoreChuldu && _spawnQueue.isNotEmpty) {
          // 첫 스폰 후 터지도록 약간 대기 후 처리
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

  void _spawnMutant(_PendingSpawn item) {
    encounteredMutants.add(item.kind);
    final laneIdx = item.laneIndex % chapter.lanes.length;
    final lane = chapter.smoothedLane(laneIdx);
    if (laneIdx < lanePortalEnergy.length) {
      lanePortalEnergy[laneIdx] = 1.0;
    }

    final chScale = stage.globalIndex >= 900
        ? (1.0 + (stage.chapterNumber - 1) * 0.14 + currentWaveIndex * 0.16)
        : (1.0 + (stage.chapterNumber - 1) * 0.23 + (stage.stageNumber - 1) * 0.042);
    final maxHp =
        item.kind.baseHp * item.kind.swarmHpFactor * chScale * difficulty.hpMult;
    final spd = item.kind.speed * (1.0 + (stage.chapterNumber - 1) * 0.02) * difficulty.speedMult;
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

      // 낭떠러지 장외 & 절벽 걸침 35% 뽀록 판정!
      bool fellOff = false;
      for (final cliff in chapter.cliffs) {
        final dist = m.pos.distanceTo(cliff.center);
        if (!m.kind.isBoss && dist < cliff.radius * 0.68) {
          fellOff = true;
          break;
        } else if (!m.kind.isBoss && !m.cliffChecked && dist < cliff.radius) {
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
      if (!m.kind.isBoss &&
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

        // Catmull-Rom 곡선 경로 전방 주시(Look-Ahead Pure Pursuit) + 관성 속도 보간(smoothVel)!
        if (m.waypoints.isNotEmpty) {
          int wpIdx = m.waypointIndex.clamp(0, m.waypoints.length - 1);
          while (wpIdx + 1 < m.waypoints.length &&
              m.pos.distanceTo(m.waypoints[wpIdx]) < 15.0) {
            wpIdx++;
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
          final velBlend = min(1.0, dt * 8.6);
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

      // 외곽 기공 방어막 충돌 처리 (attackPower 비례 타격 & 덮치기 모션)
      if (shieldHp > 0 && distToCenter <= CampaignCatalog.outerShieldRadius + m.kind.radius * 0.5) {
        shieldHp = max(0, shieldHp - m.kind.attackPower);
        m.attackAnimTimer = 1.0;
        if (m.kind.toughnessRating >= 4 || m.kind == MutantKind.crimsonBreakerBoss) {
          heavyHitsOnShield++;
        }
        if (m.kind.speedRating >= 4) {
          swarmHitsOnShield++;
        }

        // 방어막 반동 충격파로 변이체 후방 밀침!
        final pushDir = (m.pos - CampaignCatalog.villageCenter).normalized;
        m.knockbackVel = pushDir * (centralSpec.shieldWavePush * 2.2 / sqrt(m.kind.mass));
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
          (distToCenter <= CampaignCatalog.centralTowerRadius + m.kind.radius * 0.6 ||
              m.pos.distanceTo(CampaignCatalog.centralTowerPos) <=
                  CampaignCatalog.centralTowerRadius + m.kind.radius * 0.6)) {
        // 방어막이 깨진 상태에서 중앙 자동 보호 장치 직접 타격 → attackPower 비례 피해!
        towerHp = max(0, towerHp - m.kind.attackPower * 0.95);
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
        m.knockbackVel = pushDir * 115.0;
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
    final target = _pickMostThreateningMutant(origin, maxRange: 540);
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

    centralFireTimer = auroraCritTimer > 0
        ? centralSpec.fireIntervalSec / 1.5
        : centralSpec.fireIntervalSec;
    centralRecoilAnim = 1.0;
    pendingSounds.add(SoundCue.gearMotion);

    // 3칸 완충 시 자동 어기어석 궁극 편대 발동!
    if (qiBars >= 2.95) {
      qiBars = 0.0;
      _fireAutoEogieoseok(target);
      return;
    }

    // 2칸 이상이고 밀집 시 흡성탄지 발동!
    if (qiBars >= 2.0 && _countMutantsNear(target.pos, 80) >= 4) {
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
      );
      return;
    }

    // 1칸 이상 시 문파 고유 내공탄 자동 발동!
    bool useSectTech = false;
    if (qiBars >= 1.0) {
      qiBars -= 1.0;
      useSectTech = true;
    }

    _spawnStoneShot(
      sourceKey: 'central_tower',
      sourceLabel: '중앙 기명 수호탑',
      origin: origin,
      target: target,
      baseDamage: centralSpec.baseDamage * (useSectTech ? 1.40 : 1.0),
      speed: 360,
      pierceBonus: 1,
      sectTech: useSectTech ? preset.sectTechnique : null,
    );
  }

  void _fireAutoEogieoseok(ActiveMutant primaryTarget) {
    final origin = CampaignCatalog.centralTowerPos;
    final count = progress.realm.eogieoseokCount + 1;
    callouts.add(
      FloatingCallout(
        pos: origin + const Vec2(0, -52),
        text: '✨ 자동 어기어석 발동! 수호 알 $count기 편대 소탕!',
        colorHex: 0xFF72EFDD,
        isBigBanner: true,
      ),
    );
    final sorted = List<ActiveMutant>.from(mutants)
      ..sort(
        (a, b) => a.pos
            .distanceTo(CampaignCatalog.villageCenter)
            .compareTo(b.pos.distanceTo(CampaignCatalog.villageCenter)),
      );
    for (int i = 0; i < count; i++) {
      final tgt = sorted[i % sorted.length];
      _spawnStoneShot(
        sourceKey: 'central_tower',
        sourceLabel: '중앙 기명 수호탑 (어기어석)',
        origin: origin + Vec2((i - count / 2) * 14, -8),
        target: tgt,
        baseDamage: centralSpec.baseDamage * 1.95,
        speed: 390,
        pierceBonus: 3,
        aoeRadius: 52,
        ignoresShield: true,
      );
    }

    // 어기어석 한 번 더! 기연 판정
    if (allowSerendipity && rng.nextDouble() < (0.22 + progress.meridianSerendipityBonus)) {
      serendipityCount++;
      pendingSounds.add(SoundCue.serendipityJackpot);
      qiBars = 2.95; // 다음 턴에 연속 1회 더 발사!
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
    final hasteMult =
        (jeonggakHasteTimer > 0 ? 1.45 : 1.0) * (auroraCritTimer > 0 ? 1.50 : 1.0);

    for (final l in launchers) {
      if (l.recoilAnim > 0) l.recoilAnim = max(0, l.recoilAnim - dt * 4.0);

      // 주변 내공 증폭기 버프 계산
      double ampReload = 1.0;
      double ampDamage = 1.0;
      double ampCrit = 0.0;
      for (final other in launchers) {
        if (other != l &&
            other.type == LauncherType.qiAmplifier &&
            other.pos.distanceTo(l.pos) < 175) {
          ampReload += 0.14 + other.tier * 0.05;
          ampDamage += 0.12 + other.tier * 0.06;
          ampCrit += 0.04 * other.tier;
        }
      }

      if (l.type == LauncherType.qiAmplifier) {
        // 내공 증폭기는 주기적으로 내공 충전 + 4형 시 방어막 미세 회복 + 에너지 탄 발사
        qiBars = (qiBars + (0.08 + l.tier * 0.03) * dt).clamp(0.0, 3.0);
        if (l.tier >= 4 && shieldHp > 0) {
          shieldHp = min(centralSpec.shieldMaxHp, shieldHp + 3.2 * dt);
        }
      }

      l.cooldown -= dt * l.type.tierFireRateMultiplier(l.tier) * hasteMult * ampReload;
      if (l.cooldown > 0 || mutants.isEmpty) continue;

      final target = _pickTargetForLauncher(l);
      if (target == null) continue;

      l.cooldown = l.type.baseCooldownSec / (1.0 + (l.permanentLevel - 1) * 0.04);
      if (allowSerendipity && rng.nextDouble() < (0.11 + progress.meridianSerendipityBonus)) {
        l.cooldown = 0.08;
        serendipityCount++;
      }
      l.recoilAnim = 1.0;
      final dir = (target.pos - l.pos).normalized;
      l.aimAngleRad = atan2(dir.y, dir.x);
      pendingSounds.add(SoundCue.bowMotion);

      final permScale = 1.0 + (l.permanentLevel - 1) * 0.13;
      final dmg = l.type.baseDamage *
          l.type.tierDamageMultiplier(l.tier) *
          permScale *
          ampDamage *
          progress.realm.powerMult *
          (1.0 +
              progress.meridianLauncherDmgBonus +
              progress.coreFirepowerBonus +
              progress.codexPowerBonus);

      final shotCount = l.type.projectilesPerShot(l.tier);
      final launcherPierce = switch (l.type) {
        LauncherType.rapid => l.tier >= 2 ? 1 : 0,
        LauncherType.curveSpin => 1 + (l.tier >= 3 ? 1 : 0),
        _ => 0,
      };
      final launcherSplash = switch (l.type) {
        LauncherType.heavy => 26.0 + l.tier * 7.5,
        LauncherType.frostField => 34.0 + l.tier * 6.0,
        _ => 0.0,
      };
      for (int s = 0; s < shotCount; s++) {
        final spreadRad = shotCount == 1 ? 0.0 : (s - (shotCount - 1) / 2) * 0.14;
        _spawnStoneShot(
          sourceKey: 'launcher_${l.slotIndex}',
          sourceLabel: '${l.type.name}(${l.slotIndex + 1}거점)',
          origin: l.pos,
          target: target,
          baseDamage: dmg / (shotCount > 1 ? 1.22 : 1.0),
          speed: l.type.projectileSpeed,
          spreadAngleRad: spreadRad,
          extraCrit: ampCrit,
          spinCurve: l.type == LauncherType.curveSpin ? (1.1 + l.tier * 0.25) : 0.0,
          pierceBonus: launcherPierce,
          ignoresShield: l.type == LauncherType.curveSpin || (l.type == LauncherType.heavy && l.tier >= 3),
          aoeRadius: launcherSplash,
          freezesOnHit: l.type == LauncherType.frostField,
          knockbackScale: l.type == LauncherType.heavy ? (1.45 + l.tier * 0.18) : 1.0,
        );
      }
    }
  }

  void _stepSpiritBeastAndCompanions(double dt) {
    final cdFactor = 1.0 - progress.meridianAllyCooldownReduction;

    // 1) 영수 조건부 자동 발동
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

    // 2) 편성 동료 3인 조건부 자동 발동
    for (final hero in companionCooldowns.keys.toList()) {
      companionCooldowns[hero] = (companionCooldowns[hero]! - dt);
      final cond = preset.companionConditions[hero] ?? hero.defaultCondition;
      if (companionCooldowns[hero]! <= 0 && _checkConditionMet(cond)) {
        companionCooldowns[hero] = hero.cooldownSec * cdFactor;
        _executeCompanionSkill(hero, progress.companionLevels[hero] ?? 1);
      }
    }

    // 3) 6장 합류 이후 위기 순간 묵현 특별 자동 난입 (판당 1회)
    if (!mukhyeonTriggered &&
        (progress.companionLevels[CompanionHero.mukhyeon] ?? 0) > 0 &&
        shieldHp <= centralSpec.shieldMaxHp * 0.25 &&
        mutants.isNotEmpty) {
      mukhyeonTriggered = true;
      callouts.add(
        FloatingCallout(
          pos: const Vec2(200, 310),
          text: '⚔️ 묵현 긴급 난입! "그 마을을 무너뜨리게 두진 않겠다!"',
          colorHex: 0xFFC77DFF,
          isBigBanner: true,
        ),
      );
      for (final m in List<ActiveMutant>.from(mutants)) {
        if (m.pos.y > 280) {
          _applyDamageToMutant(
            m,
            centralSpec.baseDamage * 3.8,
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
        return shieldHp <= centralSpec.shieldMaxHp * 0.65 || mutants.any((m) => m.pos.y > 410);
      case AutoTriggerCondition.qiFullBurst:
        return qiBars >= 1.2 || mutants.length >= 3;
    }
  }

  void _executeSpiritBeast(SpiritBeast beast, int lv) {
    final target = _pickMostThreateningMutant(CampaignCatalog.villageCenter, maxRange: 520);
    if (target == null) return;
    final power = centralSpec.baseDamage * (1.25 + lv * 0.16) * progress.realm.powerMult;

    switch (beast) {
      case SpiritBeast.nalssaendol:
        _spawnStoneShot(
          sourceKey: 'beast_nalssaendol',
          sourceLabel: '영수 날쌘돌',
          origin: CampaignCatalog.villageCenter + const Vec2(-36, -12),
          target: target,
          baseDamage: power,
          speed: 375,
        );
        break;
      case SpiritBeast.geumgangTurtle:
        shieldHp = min(centralSpec.shieldMaxHp, shieldHp + centralSpec.shieldMaxHp * (0.16 + lv * 0.015));
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
          );
        }
        break;
      case SpiritBeast.geumryong:
        for (int i = 0; i < 4; i++) {
          final tgt = mutants[i % mutants.length];
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
          );
        }
        break;
    }
  }

  void _executeCompanionSkill(CompanionHero hero, int lv) {
    final target = _pickMostThreateningMutant(CampaignCatalog.villageCenter, maxRange: 500);
    if (target == null) return;
    final baseDmg = centralSpec.baseDamage * (1.20 + lv * 0.15) * progress.realm.powerMult;
    final key = 'hero_${hero.id}';
    final label = '동료 ${hero.name}';

    switch (hero) {
      case CompanionHero.seokdu:
        final heavyTgt = mutants.where((m) => m.kind.isBoss || m.kind == MutantKind.ironBoar).firstOrNull ?? target;
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
        for (int i = 0; i < 3; i++) {
          final tgt = mutants[i % mutants.length];
          _spawnStoneShot(
            sourceKey: key,
            sourceLabel: label,
            origin: CampaignCatalog.villageCenter + Vec2((i - 1) * 16.0, -10),
            target: tgt,
            baseDamage: baseDmg * 0.92,
            speed: 415,
            extraCrit: 0.25,
            ignoresShield: true,
          );
        }
        break;
      case CompanionHero.sinseung:
        shieldHp = min(centralSpec.shieldMaxHp, shieldHp + centralSpec.shieldMaxHp * 0.22);
        cropsHealth = min(1.0, cropsHealth + 0.30);
        livestockHealth = min(1.0, livestockHealth + 0.30);
        pendingSounds.add(SoundCue.shieldWave);
        break;
      case CompanionHero.mukhyeon:
        break;
    }
  }

  void _stepSupportAutoTrigger() {
    if (!allowSupportTokens || supportChargesLeft <= 0 || mutants.isEmpty) return;
    final shieldRatio = centralSpec.shieldMaxHp > 0 ? shieldHp / centralSpec.shieldMaxHp : 0.0;
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
  }) {
    if (projectiles.length >= 52) {
      projectiles.removeAt(0);
    }

    final stone = preset.primaryStone;
    final shape = preset.primaryShape;

    // 이동 예측 조준 보정 (곡선 경로 관성 속도 smoothVel 및 영안 정밀 수련치 반영)
    final leadFactor = (0.18 + progress.corePrecisionBonus * 0.8).clamp(0.18, 0.55);
    final nextWp = target.waypoints[target.waypointIndex.clamp(0, target.waypoints.length - 1)];
    final moveVel = target.smoothVel.length > 4.0
        ? target.smoothVel
        : (nextWp - target.pos).normalized * target.speed;
    final predictedPos = target.pos + moveVel * leadFactor;

    final rawDir = (predictedPos - origin).normalized;
    final baseAngle = atan2(rawDir.y, rawDir.x) + spreadAngleRad;
    final finalSpeed =
        speed * shape.speedFactor * (cheonghakBuffTimer > 0 ? 1.20 : 1.0) * (stone == StoneMaterial.manyeonGiju ? 1.18 : 1.0);
    final vel = Vec2(cos(baseAngle) * finalSpeed, sin(baseAngle) * finalSpeed);

    // 크리티컬 기연 거대 황금탄 판정
    final isCritSerendipity =
        allowSerendipity && rng.nextDouble() < (0.07 + progress.meridianSerendipityBonus * 0.5);
    if (isCritSerendipity) {
      serendipityCount++;
    }

    int pierce = pierceBonus + (stone == StoneMaterial.geumgang ? 1 : 0);
    double splash = aoeRadius + (stone == StoneMaterial.obsidian ? 32.0 : 0.0);
    double curve = spinCurve * shape.spinCurveFactor;
    bool bypassShield = ignoresShield || stone == StoneMaterial.jageum;

    if (sectTech == SectTechnique.swordQi) pierce += 3;
    if (sectTech == SectTechnique.ironFist) splash = max(splash, 58.0);
    if (sectTech == SectTechnique.taiji) {
      curve = curve == 0 ? 1.35 : curve * 1.4;
      bypassShield = true;
      qiBars = (qiBars + 0.25).clamp(0.0, 3.0);
    }

    final finalDamage = baseDamage * stone.damageMultiplier * (isCritSerendipity ? 2.1 : 1.0);
    final finalKnock = 46.0 *
        stone.knockbackMultiplier *
        shape.knockbackFactor *
        knockbackScale *
        (1.0 + progress.meridianKnockbackBonus) *
        (stone == StoneMaterial.yongrin ? 1.35 : 1.0);
    final critChance = (0.10 +
            shape.critBonus +
            progress.meridianCritBonus +
            extraCrit +
            (cheonghakBuffTimer > 0 ? 0.10 : 0.0) +
            (stone == StoneMaterial.geumgang ? 0.08 : 0.0))
        .clamp(0.05, 0.75);

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
        colorHex: isCritSerendipity ? 0xFFFFD166 : stone.colorHex,
        radius: isCritSerendipity ? 13.5 : 8.5,
        spinCurve: curve,
        pierceLeft: pierce,
        aoeSplashRadius: splash,
        pullsEnemies: pullsEnemies,
        freezesOnHit: freezesOnHit || stone == StoneMaterial.hancheol,
        oilsOnHit: oilsOnHit,
        ignoresShield: bypassShield,
        isGiantCritSerendipity: isCritSerendipity,
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
        ),
      );
    }
  }

  void _stepProjectiles(double dt) {
    for (int i = projectiles.length - 1; i >= 0; i--) {
      final p = projectiles[i];
      p.lifeSec -= dt;
      if (p.lifeSec <= 0) {
        projectiles.removeAt(i);
        continue;
      }

      if (p.trail.length >= 6) p.trail.removeAt(0);
      p.trail.add(p.pos);

      // 스핀 곡선 휘어 치기 물리
      if (p.spinCurve.abs() > 0.05) {
        final perp = Vec2(-p.vel.y, p.vel.x).normalized;
        p.vel = p.vel + perp * (p.spinCurve * 95.0 * dt);
      }

      p.pos = p.pos + p.vel * dt;

      // 좌우 담장 반사 도탄
      if (p.pos.x < 16 || p.pos.x > CampaignCatalog.arenaWidth - 16) {
        if (p.bouncesLeft > 0) {
          p.pos = Vec2(p.pos.x.clamp(16.0, CampaignCatalog.arenaWidth - 16.0), p.pos.y);
          p.vel = Vec2(-p.vel.x * p.material.bounceKeep, p.vel.y * p.material.bounceKeep);
          p.bouncesLeft--;
          p.bouncedOffObstacle = true;
          p.ignoresShield = true;
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
        pendingSounds.add(SoundCue.serendipityJackpot);
        callouts.add(
          FloatingCallout(
            pos: goldenToad!.pos,
            text: '🐸 황금 두꺼비 포획 대박! 증표 +35 · 영약 +2!',
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
          _resolveProjectileHitMutant(p, m);

          if (p.pierceLeft > 0) {
            p.pierceLeft--;
          } else if (p.bouncesLeft > 0 && p.material.grade >= 6) {
            // 고단수(빙백한옥 이상) 알은 적을 치고 옆으로 한 번 더 도탄!
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
  }

  void _resolveProjectileHitMutant(ActiveStoneProjectile p, ActiveMutant m) {
    final isCrit =
        auroraCritTimer > 0 || p.isGiantCritSerendipity || rng.nextDouble() < p.critChance;
    double mult = isCrit ? (1.65 + progress.corePrecisionBonus) : 1.0;

    // 담장·회전 기둥 도탄 후 적중 시 『어부지리 당구 대박!』 보너스!
    if (p.bouncedOffObstacle) {
      mult *= 1.35;
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

    // 뼈방패 정면 감쇄 판정
    if (m.kind.frontShieldReduction > 0 && !p.ignoresShield && !p.bouncedOffObstacle) {
      mult *= (1.0 - m.kind.frontShieldReduction);
      shieldYachaBlocks++;
    }

    if (p.freezesOnHit) {
      m.freezeTimer = max(m.freezeTimer, 1.35);
      m.slowTimer = max(m.slowTimer, 3.0);
    } else if (p.material == StoneMaterial.bingbaek) {
      m.slowTimer = max(m.slowTimer, 2.5);
    }
    if (p.oilsOnHit) {
      m.oilSlipTimer = 4.0;
    }

    // 타격 사운드 큐
    if (isCrit) {
      pendingSounds.add(SoundCue.criticalShatter);
      qiBars = (qiBars + 0.22).clamp(0.0, 3.0);
    } else if (p.material == StoneMaterial.bingbaek || p.material == StoneMaterial.hancheol) {
      pendingSounds.add(SoundCue.stoneHitIce);
    } else if (p.material == StoneMaterial.manyeonGiju) {
      pendingSounds.add(SoundCue.stoneHitWood);
    } else if (p.material.density >= 2.0) {
      pendingSounds.add(SoundCue.stoneHitHeavy);
    } else {
      pendingSounds.add(SoundCue.stoneHitCheongok);
    }
    qiBars = (qiBars + 0.08).clamp(0.0, 3.0);

    final hitDir = p.vel.normalized;
    final halfPen =
        p.material.density >= 1.35 || p.sourceLabel.contains('중포') || isCrit;
    _applyDamageToMutant(
      m,
      p.damage * mult,
      sourceKey: p.sourceKey,
      sourceLabel: p.sourceLabel,
      knockDir: hitDir,
      knockForce: p.knockback,
      isCritical: isCrit,
      halfArmorPenetration: halfPen,
    );

    // 흡성 결집 효과
    if (p.pullsEnemies) {
      for (final other in mutants) {
        if (other != m && other.pos.distanceTo(m.pos) < 95) {
          other.pos = other.pos + (m.pos - other.pos) * 0.42;
        }
      }
    }

    // 범위 충격파 효과
    if (p.aoeSplashRadius > 0) {
      bursts.add(FxBurst(pos: m.pos, colorHex: p.colorHex, maxRadius: p.aoeSplashRadius));
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
    int chainDepth = 0,
  }) {
    if (!mutants.contains(m)) return;
    m.hitFlashTimer = 1.0;

    // 맷집(armorReduction) 외피 감쇄 및 중량석·중포·회심 50% 장갑 관통 상성
    double armor = m.kind.armorReduction;
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
    m.knockbackVel = m.knockbackVel + knockDir * (knockForce / sqrt(m.kind.mass));

    final entry = _contribMap.putIfAbsent(
      sourceKey,
      () => ContributionEntry(key: sourceKey, label: sourceLabel),
    );
    entry.totalDamage += dealt;

    if (m.hp <= 0) {
      entry.kills++;
      mutants.remove(m);

      // 11단 천년온옥 장착 시 변이체 정화마다 방어막 2.2% 회복!
      if (preset.primaryStone == StoneMaterial.onok && shieldHp > 0) {
        shieldHp = min(centralSpec.shieldMaxHp, shieldHp + centralSpec.shieldMaxHp * 0.022);
      }

      // 회심 박살 시 혈독 분열충 분열 원천 봉쇄 + 최대 3단 연쇄 박살 도미노!
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
        // 회심 박살이 아니면 작은 독쥐 2마리로 분열 (매끄러운 곡선 관성 유지)
        for (final dx in [-10.0, 10.0]) {
          final childSpd = MutantKind.swarmRat.speed * difficulty.speedMult;
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
              laneLateralOffset: dx * 0.7,
            )
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
    final drop = (m.kind.dropTokens *
            bonusTokenMult *
            (1.0 + progress.meridianTokenDropBonus) *
            difficulty.rewardMult)
        .round()
        .clamp(1, 200);
    fieldTokens += drop;
    earnedPermanentTokens += (drop * 0.65).round().clamp(1, 150);
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
    for (final m in mutants) {
      final dist = m.pos.distanceTo(l.pos);
      if (dist > 285) continue;
      double score = 600.0 - m.pos.distanceTo(CampaignCatalog.villageCenter);
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
      // 승리 시 새벽 정화로 논밭과 가축이 소생!
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
          : '승리했습니다! 대장간에서 발사대를 강화하고 한빙·중포 비율을 높이면 ★3 만점 수호가 쉬워집니다.';
    } else if (shieldYachaBlocks >= 6) {
      tip = '뼈방패 야차에게 정면 탄이 막혔습니다! 거점에 「곡사 회전기」나 「태극도문」 무공을 배치해보세요.';
    } else if (heavyHitsOnShield >= 3) {
      tip = '중갑 돌진 변이체가 방어막을 부쉈습니다! 「중포 탄지기」와 「현철/운철」 수호석, 동료 「석두」를 편성해보세요.';
    } else if (swarmHitsOnShield >= 5) {
      tip = '빠른 무리에 포위되었습니다! 앞쪽 거점에 「속사 탄지기」와 「한빙 역장기」를 함께 두면 거뜬히 막아냅니다.';
    } else {
      tip = '기명 심법 수련에서 혈자리를 개통하고 대장간에서 중앙 보호 장치와 주력 발사대를 한 단계 강화해보세요!';
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
