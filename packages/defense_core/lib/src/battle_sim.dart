import 'dart:math';

import 'allies.dart';
import 'campaign.dart';
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

  double get progress => (1.0 - ttlSec / durationSec).clamp(0.0, 1.0);
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
  });

  final int slotIndex;
  final Vec2 pos;
  LauncherType type;
  final int permanentLevel;
  int tier = 1;
  double cooldown = 0.25;
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

  late final CentralGuardianSpec centralSpec;
  late double shieldHp;
  late double towerHp;
  double centralFireTimer = 0.35;
  double centralGearAngle = 0.0;

  /// 마을 생태계 3대 지표 (1.0 = 평온/풍요, 0.0 = 황폐/폐사).
  double granaryHealth = 1.0;
  double cropsHealth = 1.0;
  double livestockHealth = 1.0;

  /// 현장 보유 증표(실시간 발사대 버전 업그레이드용) 및 정산 누적 보상.
  int fieldTokens = 0;
  int earnedPermanentTokens = 0;
  int earnedElixirs = 0;

  /// 내공 게이지 (0.0 ~ 3.0칸).
  double qiBars = 0.0;
  double jeonggakHasteTimer = 0.0;
  double cheonghakBuffTimer = 0.0;

  /// 지원패(암행어사 출두) 슬롯 및 연출 타이머.
  int supportChargesLeft = 0;
  int usedSupportCount = 0;
  bool pendingFreeEncoreChuldu = false;
  double chulduSweepAnimTimer = 0.0;
  double dawnPurifyAnimTimer = 0.0;
  bool mukhyeonTriggered = false;

  /// 재미 지표 카운터.
  int pporokCount = 0;
  int bankShotCount = 0;
  int chainShatterCount = 0;
  int serendipityCount = 0;
  int heavyHitsOnShield = 0;
  int shieldYachaBlocks = 0;
  int swarmHitsOnShield = 0;

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

  late double beastCooldown;
  final Map<CompanionHero, double> companionCooldowns = {};
  final Map<String, ContributionEntry> _contribMap = {};

  void _initBattle() {
    centralSpec = CentralGuardianSpec.fromLevels(
      centralLevel: progress.centralGuardianLevel,
      realmDefenseMult: progress.realm.defenseMult,
      meridianShieldBonus: progress.meridianShieldHpBonus,
      meridianReloadBonus: progress.meridianCentralReloadBonus,
      coreFortitudeBonus: progress.coreFortitudeBonus,
      coreFirepowerBonus: progress.coreFirepowerBonus,
    );
    shieldHp = centralSpec.shieldMaxHp;
    towerHp = centralSpec.coreMaxHp;

    final buffMult = progress.convoySupplyBuffBattles > 0 ? 1.20 : 1.0;
    fieldTokens = (stage.startingFieldTokens * buffMult).round();
    qiBars = (progress.realm.startQiBars + progress.meridianStartQiBonus).clamp(0.0, 3.0);

    if (allowSupportTokens) {
      supportChargesLeft = min(preset.supportSlotCount, progress.supportTokens);
    }

    for (int i = 0; i < chapter.mounts.length; i++) {
      final slot = chapter.mounts[i];
      final chosenType = i < preset.mountTypes.length ? preset.mountTypes[i] : slot.recommendedType;
      final unlockedType = chosenType.unlockChapter <= progress.highestUnlockedChapter + 1
          ? chosenType
          : slot.recommendedType;
      final permLv = progress.launcherPermanentLevels[unlockedType] ?? 1;
      launchers.add(
        ActiveLauncher(
          slotIndex: slot.slotIndex,
          pos: slot.pos,
          type: unlockedType,
          permanentLevel: permLv,
        ),
      );
    }

    for (final _ in chapter.pillars) {
      pillarAngles.add(0.0);
    }

    beastCooldown = 1.8;
    for (final hero in preset.companions) {
      if ((progress.companionLevels[hero] ?? 0) > 0) {
        companionCooldowns[hero] = 2.0 + companionCooldowns.length * 0.9;
      }
    }

    _enqueueWave(0);
  }

  void _enqueueWave(int waveIdx) {
    _spawnQueue.clear();
    if (waveIdx >= stage.waves.length) return;
    final groups = stage.waves[waveIdx];
    for (final g in groups) {
      for (int i = 0; i < g.count; i++) {
        _spawnQueue.add(
          _PendingSpawn(
            delaySec: 0.35 + i * g.intervalSec,
            kind: g.kind,
            laneIndex: g.laneIndex % chapter.lanes.length,
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
    if (l.tier == 3 && progress.highestUnlockedChapter < 4) {
      // 4형 극의는 중반 이후에도 여유 시 개방 허용하되 기본 비용 지불
    }
    final cost = l.type.inBattleUpgradeCost(l.tier);
    if (fieldTokens < cost) return false;
    fieldTokens -= cost;
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

  /// 플레이어가 원할 때 즉시 또는 위기 조건 시 자동으로 「무림수호단 출두야~~!!」 발동!
  bool triggerSupportChuldu({bool isFreeEncore = false}) {
    if (!isFreeEncore) {
      if (supportChargesLeft <= 0) return false;
      supportChargesLeft--;
      usedSupportCount++;
    }

    chulduSweepAnimTimer = 1.35;
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
    if (isFinished) return;
    elapsedSec += dt;
    centralGearAngle += dt * 1.8;

    if (jeonggakHasteTimer > 0) jeonggakHasteTimer = max(0, jeonggakHasteTimer - dt);
    if (cheonghakBuffTimer > 0) cheonghakBuffTimer = max(0, cheonghakBuffTimer - dt);
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

    // 자동 버전 업그레이드 켜짐 시 현장 증표가 충분하면 가장 낮은 버전 거점부터 자동 승급!
    if (preset.autoUpgradeInBattle) {
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
        currentWaveIndex++;
        wavePauseTimer = 1.0;
        _enqueueWave(currentWaveIndex);
        // 한 번 더 출두 기연 예약이 있으면 새 웨이브 돌입 직후 자동 공짜 출두!
        if (pendingFreeEncoreChuldu && _spawnQueue.isNotEmpty) {
          // 첫 스폰 후 터지도록 약간 대기 후 처리
        }
      }
    }

    if (pendingFreeEncoreChuldu && mutants.length >= 3) {
      pendingFreeEncoreChuldu = false;
      triggerSupportChuldu(isFreeEncore: true);
    }
  }

  void _spawnMutant(_PendingSpawn item) {
    final lane = chapter.lanes[item.laneIndex % chapter.lanes.length];
    final chScale = 1.0 + (stage.chapterNumber - 1) * 0.24 + (stage.stageNumber - 1) * 0.045;
    final maxHp = item.kind.baseHp * chScale * difficulty.hpMult;
    final spd = item.kind.speed * (1.0 + (stage.chapterNumber - 1) * 0.02) * difficulty.speedMult;

    mutants.add(
      ActiveMutant(
        uid: _nextMutantUid++,
        kind: item.kind,
        laneIndex: item.laneIndex,
        waypoints: lane,
        pos: lane.first + Vec2((rng.nextDouble() - 0.5) * 14, 0),
        maxHp: maxHp,
        speed: spd,
        customName: item.customTitle,
        customPortrait: item.customPortrait,
      ),
    );
  }

  void _stepMutants(double dt) {
    for (int i = mutants.length - 1; i >= 0; i--) {
      final m = mutants[i];
      if (m.freezeTimer > 0) m.freezeTimer = max(0, m.freezeTimer - dt);
      if (m.slowTimer > 0) m.slowTimer = max(0, m.slowTimer - dt);
      if (m.oilSlipTimer > 0) m.oilSlipTimer = max(0, m.oilSlipTimer - dt);

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

      // 전진 이동
      if (m.freezeTimer <= 0) {
        final slowFactor = m.slowTimer > 0 ? 0.58 : 1.0;
        final targetWp = m.waypoints[m.waypointIndex.clamp(0, m.waypoints.length - 1)];
        final toWp = targetWp - m.pos;
        if (toWp.length < 12 && m.waypointIndex + 1 < m.waypoints.length) {
          m.waypointIndex++;
        }
        final dir = (m.waypoints[m.waypointIndex.clamp(0, m.waypoints.length - 1)] - m.pos).normalized;
        m.pos = m.pos + dir * (m.speed * slowFactor * dt);
      }

      // 독안개 오라가 마을 가까이에 오면 논밭 농산물이 서서히 시듦
      final distToCenter = m.pos.distanceTo(CampaignCatalog.villageCenter);
      if (m.kind.poisonAura && distToCenter < 220) {
        cropsHealth = (cropsHealth - 0.018 * dt).clamp(0.0, 1.0);
      }

      // 외곽 기공 방어막 충돌 처리
      if (shieldHp > 0 && distToCenter <= CampaignCatalog.outerShieldRadius + m.kind.radius * 0.5) {
        shieldHp = max(0, shieldHp - m.kind.shieldDamage);
        if (m.kind == MutantKind.ironBoar) heavyHitsOnShield++;
        if (m.kind == MutantKind.swarmRat || m.kind == MutantKind.sickHound) swarmHitsOnShield++;

        // 방어막 반동 충격파로 변이체 후방 밀침!
        final pushDir = (m.pos - CampaignCatalog.villageCenter).normalized;
        m.knockbackVel = pushDir * (centralSpec.shieldWavePush * 2.2 / sqrt(m.kind.mass));
        pendingSounds.add(SoundCue.shieldWave);
        bursts.add(FxBurst(pos: m.pos, colorHex: 0xFF4CC9F0, maxRadius: 28));

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
          distToCenter <= CampaignCatalog.centralTowerRadius + m.kind.radius * 0.6) {
        // 방어막이 깨진 상태에서 중앙 자동 보호 장치 직접 타격 → 식량·논밭·가축 급속 피해!
        towerHp = max(0, towerHp - m.kind.shieldDamage * 0.95);
        granaryHealth = (granaryHealth - 0.08).clamp(0.0, 1.0);
        cropsHealth = (cropsHealth - 0.08).clamp(0.0, 1.0);
        livestockHealth = (livestockHealth - 0.09).clamp(0.0, 1.0);

        final pushDir = (m.pos - CampaignCatalog.villageCenter).normalized;
        m.knockbackVel = pushDir * 115.0;
        pendingSounds.add(SoundCue.villageWarning);
      }
    }
  }

  void _stepCentralGuardian(double dt) {
    if (towerHp <= 0) return;
    centralFireTimer -= dt;
    if (centralFireTimer > 0 || mutants.isEmpty) return;

    final target = _pickMostThreateningMutant(CampaignCatalog.villageCenter, maxRange: 460);
    if (target == null) return;

    centralFireTimer = centralSpec.fireIntervalSec;
    pendingSounds.add(SoundCue.gearMotion);

    // 3칸 완충 시 자동 어기어석 궁극 편대 발동!
    if (qiBars >= 2.95) {
      qiBars = 0.0;
      _fireAutoEogieoseok(target);
      return;
    }

    // 2칸 이상이고 밀집 시 흡성탄지 발동!
    if (qiBars >= 2.0 && _countMutantsNear(target.pos, 75) >= 4) {
      qiBars -= 1.5;
      _spawnStoneShot(
        sourceKey: 'central_tower',
        sourceLabel: '중앙 기명 수호탑 (흡성탄지)',
        origin: CampaignCatalog.villageCenter,
        target: target,
        baseDamage: centralSpec.baseDamage * 1.45,
        speed: 330,
        pullsEnemies: true,
        aoeRadius: 68,
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
      origin: CampaignCatalog.villageCenter,
      target: target,
      baseDamage: centralSpec.baseDamage * (useSectTech ? 1.38 : 1.0),
      speed: 345,
      sectTech: useSectTech ? preset.sectTechnique : null,
    );
  }

  void _fireAutoEogieoseok(ActiveMutant primaryTarget) {
    final count = progress.realm.eogieoseokCount + 1;
    callouts.add(
      FloatingCallout(
        pos: CampaignCatalog.villageCenter + const Vec2(0, -68),
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
        origin: CampaignCatalog.villageCenter + Vec2((i - count / 2) * 14, -8),
        target: tgt,
        baseDamage: centralSpec.baseDamage * 1.95,
        speed: 380,
        pierceBonus: 3,
        aoeRadius: 48,
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
    final hasteMult = jeonggakHasteTimer > 0 ? 1.45 : 1.0;

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
          (1.0 + progress.meridianLauncherDmgBonus + progress.coreFirepowerBonus);

      final shotCount = l.type.projectilesPerShot(l.tier);
      for (int s = 0; s < shotCount; s++) {
        final spreadRad = shotCount == 1 ? 0.0 : (s - (shotCount - 1) / 2) * 0.14;
        _spawnStoneShot(
          sourceKey: 'launcher_${l.slotIndex}',
          sourceLabel: '${l.type.name}(${l.slotIndex + 1}거점)',
          origin: l.pos,
          target: target,
          baseDamage: dmg / (shotCount > 1 ? 1.25 : 1.0),
          speed: l.type.projectileSpeed,
          spreadAngleRad: spreadRad,
          extraCrit: ampCrit,
          spinCurve: l.type == LauncherType.curveSpin ? (1.1 + l.tier * 0.25) : 0.0,
          ignoresShield: l.type == LauncherType.curveSpin || (l.type == LauncherType.heavy && l.tier >= 3),
          aoeRadius: l.type == LauncherType.heavy && l.tier >= 4 ? 52.0 : 0.0,
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

    // 이동 예측 조준 보정 (영안 정밀 수련치 반영)
    final leadFactor = (0.18 + progress.corePrecisionBonus * 0.8).clamp(0.18, 0.55);
    final nextWp = target.waypoints[target.waypointIndex.clamp(0, target.waypoints.length - 1)];
    final moveDir = (nextWp - target.pos).normalized;
    final predictedPos = target.pos + moveDir * (target.speed * leadFactor);

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
    final isCrit = p.isGiantCritSerendipity || rng.nextDouble() < p.critChance;
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
    _applyDamageToMutant(
      m,
      p.damage * mult,
      sourceKey: p.sourceKey,
      sourceLabel: p.sourceLabel,
      knockDir: hitDir,
      knockForce: p.knockback,
      isCritical: isCrit,
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
    int chainDepth = 0,
  }) {
    if (!mutants.contains(m)) return;
    final dealt = min(m.hp, dmg);
    m.hp -= dmg;
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

      // 회심 박살 시 3단 연쇄 박살 도미노! (혈독 분열충 분열 원천 봉쇄!)
      if (isCritical && chainDepth < 2) {
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
              dmg * 0.52,
              sourceKey: sourceKey,
              sourceLabel: sourceLabel,
              knockDir: (near.pos - m.pos).normalized,
              knockForce: knockForce * 0.7,
              isCritical: true,
              chainDepth: chainDepth + 1,
            );
          }
        }
      } else if (m.kind.splitsOnDeath) {
        // 회심 박살이 아니면 작은 독쥐 2마리로 분열
        for (final dx in [-10.0, 10.0]) {
          mutants.add(
            ActiveMutant(
              uid: _nextMutantUid++,
              kind: MutantKind.swarmRat,
              laneIndex: m.laneIndex,
              waypoints: m.waypoints,
              pos: m.pos + Vec2(dx, 0),
              maxHp: m.maxHp * 0.28,
              speed: MutantKind.swarmRat.speed * difficulty.speedMult,
            )..waypointIndex = m.waypointIndex,
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
      if (l.type == LauncherType.heavy && (m.kind.isBoss || m.kind == MutantKind.ironBoar)) {
        score += 180;
      } else if (l.type == LauncherType.curveSpin && m.kind == MutantKind.shieldYacha) {
        score += 180;
      } else if (l.type == LauncherType.frostField && m.freezeTimer <= 0) {
        score += 130;
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
    );
  }
}
