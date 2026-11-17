import 'dart:math';

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/night_audio.dart';
import '../audio/night_haptics.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'battle_painter.dart';

/// 실시간 수호 전장 화면:
/// - 초기 길목 무배치(0기) → 개방된 빈 초소(`2~10곳`) 터치 직접 배치·승급·교체·철거
/// - 맨 아래 중앙 마을 본진 + 중앙 기명 수호탑 `자동 발사 ↔ 수동 탄지(도탄 예측선)` 겸용
/// - 동료·영수 구출 축하 연출 및 1·2·3배속 · 전술 비약 · 무림수호단 출두 지원.
class BattleScreen extends StatefulWidget {
  const BattleScreen({
    super.key,
    required this.controller,
    required this.stage,
  });

  final GameController controller;
  final StageSpec stage;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with SingleTickerProviderStateMixin {
  late DefenseBattleSim _sim;
  late final Ticker _ticker;
  final ValueNotifier<int> _frameNotifier = ValueNotifier<int>(0);

  Duration? _lastTick;
  int _speedMultiplier = 1;
  bool _summaryShown = false;

  /// 수동 조준 드래그(꾹 누르면 자동 연속 사격!) 및 비차단 실시간 초소 미니 선택창 타이머!
  bool _draggingManualAim = false;
  bool _draggedFromTower = false;
  double? _manualAimPreviewAngleRad;
  LauncherMountSlot? _panStartSlot;
  Vec2? _panStartArenaPos;
  int? _selectedSlotIndex;
  double _livePadMenuTimer = 0.0;
  static const double _livePadMenuDuration = 4.8;

  /// 전장을 멈추지 않는 상단 실시간 전령 대사 토스트 (4.5초 뒤 자동 소멸!).
  StoryLine? _liveStoryLine;
  double _liveStoryTimer = 0.0;

  @override
  void initState() {
    super.initState();
    _speedMultiplier = widget.controller.battleSpeedMultiplier.clamp(1, 4);
    _startNewSim(showIntroToast: true);
    final chapter = CampaignCatalog.chapterOf(widget.stage.chapterNumber);
    final bgm = widget.stage.isBossStage ? 'bgm_boss.ogg' : chapter.bgmAsset;
    NightAudioController.instance.playBgm(bgm);

    NightBattleSprites.instance.warmUpForChapter(
      chapter,
      onSpritesUpdated: () {
        if (mounted) {
          _frameNotifier.value++;
        }
      },
    );

    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
      }
    });
  }

  void _startNewSim({bool showIntroToast = false}) {
    _sim = DefenseBattleSim(
      stage: widget.stage,
      difficulty: widget.controller.selectedDifficulty,
      progress: widget.controller.progress,
      seed: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
    )..autoChoosePerks = widget.controller.autoChooseBattlePerks;
    _summaryShown = false;
    _draggingManualAim = false;
    _manualAimPreviewAngleRad = null;
    _panStartSlot = null;
    _panStartArenaPos = null;
    _selectedSlotIndex = null;
    _livePadMenuTimer = 0.0;
    if (showIntroToast && widget.stage.introDialogue.isNotEmpty) {
      _liveStoryLine = widget.stage.introDialogue.last;
      _liveStoryTimer = 4.8;
    } else {
      _liveStoryLine = null;
      _liveStoryTimer = 0.0;
    }
    _lastTick = null;
  }

  void _onTick(Duration elapsed) {
    // ★ 핵심 원칙: 전투 시작부터 종료까지 단 0.01초도 게임을 멈추지 않는다!
    final prev = _lastTick;
    _lastTick = elapsed;
    if (prev == null) return;

    double rawDt = (elapsed - prev).inMicroseconds / 1e6;
    rawDt = rawDt.clamp(0.0, 0.05);

    if (_livePadMenuTimer > 0) {
      _livePadMenuTimer = max(0.0, _livePadMenuTimer - rawDt);
      if (_livePadMenuTimer <= 0) {
        _selectedSlotIndex = null;
      }
    }
    if (_liveStoryTimer > 0) {
      _liveStoryTimer = max(0.0, _liveStoryTimer - rawDt);
      if (_liveStoryTimer <= 0) {
        _liveStoryLine = null;
      }
    }

    // 수동 탄지 모드에서 손가락을 누르고 조준 중이면 장전될 때마다 자동 연속 산탄 발사!
    if (!_sim.isFinished &&
        _draggingManualAim &&
        _manualAimPreviewAngleRad != null &&
        _sim.isCentralReadyToFire) {
      if (_sim.fireCentralManualAngle(_manualAimPreviewAngleRad!)) {
        NightHaptics.instance.lightTap();
      }
    }

    // 2~4배속 고속 진행 중에도 돌파 비급 3택 1 반응 시간은 실제 벽시계 기준 6.5초를 온전히 보장!
    if (_speedMultiplier > 1 &&
        _sim.pendingPerkChoices.isNotEmpty &&
        !_sim.autoChoosePerks) {
      _sim.perkChoiceTimer += rawDt * (_speedMultiplier - 1);
    }
    if (!_sim.isFinished) {
      _sim.step(rawDt * _speedMultiplier);
    }

    NightAudioController.instance.flushBattleCues(_sim.pendingSounds);
    _frameNotifier.value++;

    if (_sim.isFinished && !_summaryShown) {
      _summaryShown = true;
      _selectedSlotIndex = null;
      _livePadMenuTimer = 0.0;
      final summary = _sim.buildSummary();
      widget.controller.recordBattleSummary(widget.stage, summary);
      final rescueBanner = widget.controller.progress.lastRescueBanner;
      final rescuedHero = widget.controller.progress.lastRescuedCompanion;
      final rescuedBeast = widget.controller.progress.lastRescuedBeast;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showResultModal(
            summary,
            rescueBanner: rescueBanner,
            rescuedHero: rescuedHero,
            rescuedBeast: rescuedBeast,
          );
        }
      });
    }
  }

  Vec2 _toArenaCoords(Offset localPos, BoxConstraints constraints) {
    final lx = (localPos.dx / constraints.maxWidth) * CampaignCatalog.arenaWidth;
    final ly = (localPos.dy / constraints.maxHeight) * CampaignCatalog.arenaHeight;
    return Vec2(
      lx.clamp(0.0, CampaignCatalog.arenaWidth),
      ly.clamp(0.0, CampaignCatalog.arenaHeight),
    );
  }

  LauncherMountSlot? _hitMountSlot(Vec2 arenaPos) {
    LauncherMountSlot? closest;
    double bestDist = 42.0; // 배지 영역까지 넉넉히 포함하여 손가락 터치 미스 원천 차단!
    for (final slot in _sim.activeMounts) {
      final dCenter = slot.pos.distanceTo(arenaPos);
      final dBadge = (slot.pos + const Vec2(0, 18)).distanceTo(arenaPos);
      final d = min(dCenter, dBadge);
      if (d < bestDist) {
        bestDist = d;
        closest = slot;
      }
    }
    return closest;
  }

  double _computeAimAngleFromArenaPoint(Vec2 arenaPos, {required bool fromTower}) {
    final tower = CampaignCatalog.centralTowerPos;
    final dx = arenaPos.x - tower.x;
    final dy = arenaPos.y - tower.y;
    if (dx.abs() < 3.0 && dy.abs() < 3.0) {
      return -pi / 2;
    }
    // 탑 아래쪽으로 당기면 새총 탄지처럼 반대 방향(위쪽)으로 조준, 위쪽 전장을 가리키면 가리킨 지점으로 조준!
    if (fromTower && dy > 14.0) {
      return DefenseBattleSim.sanitizeManualAimAngle(atan2(-dy, -dx));
    }
    return DefenseBattleSim.sanitizeManualAimAngle(atan2(dy, dx));
  }

  /// ★ 멈춤 없는 실시간 초소 원터치 반응 처리:
  /// - 이미 지어진 초소 터치 시: 무료 합체가 가능하면 즉시 합체! 아니면 기력이 될 때 즉시 +1형 실시간 승급!
  ///   동시에 화면 하단 가장자리에 4.2초짜리 얇은 반투명 보조 띠(교체·철거용)를 띄웠다가 안 누르면 자동 소멸!
  /// - 빈 초소 터치 시: 전장을 가리지 않는 4.8초 실시간 고속 배치 띠를 띄웠다가 안 누르면 자동 소멸!
  void _handleLiveMountTap(LauncherMountSlot slot) {
    if (_sim.isFinished) return;
    final existing = _sim.launcherAtSlot(slot.slotIndex);
    if (existing != null) {
      if (_sim.mergeLauncherAtSlot(slot.slotIndex)) {
        NightHaptics.instance.heavyImpact();
        _selectedSlotIndex = null;
        _livePadMenuTimer = 0.0;
        _frameNotifier.value++;
        setState(() {});
        return;
      }
      if (_sim.upgradeLauncherAtSlot(slot.slotIndex)) {
        NightHaptics.instance.lightTap();
        _selectedSlotIndex = slot.slotIndex;
        _livePadMenuTimer = 3.2;
        _frameNotifier.value++;
        setState(() {});
        return;
      }
    }
    NightAudioController.instance.playAsset('ui_tap.ogg');
    setState(() {
      _selectedSlotIndex = slot.slotIndex;
      _livePadMenuTimer = _livePadMenuDuration;
    });
    _frameNotifier.value++;
  }

  void _showResultModal(
    BattleSummary summary, {
    String? rescueBanner,
    CompanionHero? rescuedHero,
    SpiritBeast? rescuedBeast,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: NightPalette.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final maxDmg = summary.contributions.isEmpty
            ? 1.0
            : summary.contributions.first.totalDamage
                .clamp(1.0, double.infinity);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    summary.victory
                        ? '🌅 새벽 정화 승리! (${widget.stage.title})'
                        : '🌑 방어선 붕괴 · 마을 후퇴',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 21,
                      color: summary.victory
                          ? NightPalette.accentGold
                          : NightPalette.crimsonMoon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (summary.victory)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => Icon(
                          i < summary.stars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: NightPalette.accentGold,
                          size: 32,
                        ),
                      ),
                    ),
                  if (summary.victory && rescueBanner != null) ...[
                    const SizedBox(height: 10),
                    MurimCard(
                      borderColor: NightPalette.jadeGreen,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (rescuedHero != null)
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.heroIdleAsset(
                                rescuedHero,
                              ),
                              fallbackAssetPath: NightArtRegistry.heroFaceAsset(
                                rescuedHero,
                              ),
                              fallbackIcon: Icons.person_add_alt_1_rounded,
                              size: 52,
                              showFrame: true,
                              frameColor: NightPalette.jadeGreen,
                            )
                          else if (rescuedBeast != null)
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.beastAsset(
                                rescuedBeast,
                              ),
                              fallbackIcon: Icons.pets_rounded,
                              size: 52,
                              showFrame: true,
                              frameColor: NightPalette.jadeGreen,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              rescueBanner,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: NightPalette.jadeGreen,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  MurimCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            ResourcePill(
                              iconAsset: NightArtRegistry.nightToken,
                              icon: Icons.toll_rounded,
                              label: '획득 증표',
                              value: '+${summary.earnedTokens}',
                              color: NightPalette.accentGold,
                            ),
                            ResourcePill(
                              iconAsset: NightArtRegistry.nightElixir,
                              icon: Icons.science_rounded,
                              label: '획득 영약',
                              value: '+${summary.earnedElixirs}',
                              color: NightPalette.elixirPurple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Text(
                              '토벌 수: ${summary.killCount}마리',
                              style: const TextStyle(
                                color: NightPalette.textPrimary,
                              ),
                            ),
                            Text(
                              '절벽 뽀록: ${summary.pporokCount}회',
                              style: const TextStyle(
                                color: NightPalette.jadeGreen,
                              ),
                            ),
                            Text(
                              '어부지리 도탄: ${summary.bankShotCount}회',
                              style: const TextStyle(
                                color: NightPalette.jadeShield,
                              ),
                            ),
                            Text(
                              '연쇄 박살: ${summary.chainShatterCount}회',
                              style: const TextStyle(color: Colors.orangeAccent),
                            ),
                            if (summary.serendipityCount > 0)
                              Text(
                                '설렘 기연 발동: ${summary.serendipityCount}회!',
                                style: const TextStyle(
                                  color: NightPalette.accentGold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            _MiniVillageStatBadge(
                              assetPath: NightArtRegistry.villageGranary,
                              fallbackIcon: Icons.storefront_rounded,
                              label:
                                  '식량 ${(summary.granaryRatio * 100).round()}%',
                            ),
                            _MiniVillageStatBadge(
                              assetPath: NightArtRegistry.villageCrops,
                              fallbackIcon: Icons.grass_rounded,
                              label: '논밭 ${(summary.cropsRatio * 100).round()}%',
                            ),
                            _MiniVillageStatBadge(
                              assetPath: NightArtRegistry.villageLivestock,
                              fallbackIcon: Icons.pets_rounded,
                              label:
                                  '가축 ${(summary.livestockRatio * 100).round()}%',
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(
                          '💡 군사 조언: ${summary.coachingTip}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: NightPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📊 수호 발사대 · 동료 처치 기여도 분석',
                    style: TextStyle(fontSize: 15, color: NightPalette.jadeGreen),
                  ),
                  const SizedBox(height: 6),
                  ...summary.contributions.take(5).map((c) {
                    final ratio = (c.totalDamage / maxDmg).clamp(0.05, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  c.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '정화 ${c.kills}마리 · 피해 ${c.totalDamage.round()}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: NightPalette.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          LinearProgressIndicator(
                            value: ratio,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(4),
                            color: NightPalette.jadeShield,
                            backgroundColor: NightPalette.bgDeep,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('본영 복귀'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: NightPalette.accentGold,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (summary.victory &&
                                widget.stage.globalIndex <
                                    CampaignCatalog.allStages.length) {
                              final nextStage = CampaignCatalog
                                  .allStages[widget.stage.globalIndex];
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => BattleScreen(
                                    controller: widget.controller,
                                    stage: nextStage,
                                  ),
                                ),
                              );
                            } else {
                              setState(_startNewSim);
                            }
                          },
                          icon: Icon(
                            summary.victory
                                ? Icons.skip_next_rounded
                                : Icons.refresh_rounded,
                          ),
                          label: Text(
                            summary.victory &&
                                    widget.stage.globalIndex <
                                        CampaignCatalog.allStages.length
                                ? '다음 수호 차례 진군'
                                : '다시 도전하기',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameNotifier.dispose();
    NightAudioController.instance.playBgm('bgm_lobby.ogg');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapter = CampaignCatalog.chapterOf(widget.stage.chapterNumber);
    return ScaffoldMessenger(
      child: Scaffold(
        body: SafeArea(
        child: Column(
          children: [
            // 상단 전장 상태 막대 + 실시간 초소 건설 기력(⚡) 충전 게이지 바
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (_, _, _) {
                final shieldPct = _sim.shieldMaxHpDynamic > 0
                    ? (_sim.shieldHp / _sim.shieldMaxHpDynamic * 100).round()
                    : 0;
                final towerPct = _sim.centralSpec.coreMaxHp > 0
                    ? (_sim.towerHp / _sim.centralSpec.coreMaxHp * 100).round()
                    : 0;
                final nextSlot = _sim.nextRecommendedSlotIndex();
                final nextDirectCost = nextSlot != null
                    ? (_sim
                            .mountSlotByIndex(nextSlot)
                            ?.recommendedType
                            .buildCostTokens ??
                        45)
                    : 45;
                final qiFill =
                    (_sim.fieldTokens / nextDirectCost).clamp(0.0, 1.0);
                final canBuildAny =
                    _sim.fieldTokens >= DefenseBattleSim.luckySummonCostTokens &&
                        nextSlot != null;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  color: NightPalette.bgPanel,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            key: const Key('battle_pause_btn'),
                            visualDensity: VisualDensity.compact,
                            tooltip: '본영으로 즉시 복귀',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          IconButton(
                            key: const Key('battle_quick_restart_btn'),
                            visualDensity: VisualDensity.compact,
                            tooltip: '멈춤 없이 즉시 처음부터 재개시',
                            onPressed: () {
                              NightHaptics.instance.lightTap();
                              setState(() => _startNewSim(showIntroToast: false));
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.stage.title} · 물결 ${_sim.currentWaveIndex + 1}/${widget.stage.waves.length}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: NightPalette.accentGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.stage.hasRescueReward)
                                  Text(
                                    '🆘 구출 목표: ${widget.stage.rescueBadgeText}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.0,
                                      color: NightPalette.jadeGreen,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1배')),
                              ButtonSegment(value: 2, label: Text('2배')),
                              ButtonSegment(value: 3, label: Text('3배')),
                              ButtonSegment(value: 4, label: Text('4배')),
                            ],
                            selected: {_speedMultiplier},
                            onSelectionChanged: (s) {
                              widget.controller.battleSpeedMultiplier = s.first.clamp(1, 4);
                              setState(() => _speedMultiplier = s.first.clamp(1, 4));
                            },
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              ),
                              minimumSize: WidgetStatePropertyAll(Size(28, 30)),
                              textStyle: WidgetStatePropertyAll(
                                TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // ★ 한눈에 보이는 「초소 건설 기력(⚡) 충전 바 & 조건 표시」
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: NightPalette.bgDeep,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: canBuildAny
                                ? const Color(0xFF80ED99)
                                : NightPalette.jadeShield.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          children: [
                            const NightSpriteIcon(
                              assetPath: NightArtRegistry.iconLuckyDice,
                              fallbackIcon: Icons.bolt_rounded,
                              size: 18,
                              borderRadius: 4,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '군수기력 ⚡${_sim.fieldTokens}',
                              style: TextStyle(
                                fontSize: 11.8,
                                fontWeight: FontWeight.bold,
                                color: canBuildAny
                                    ? const Color(0xFF80ED99)
                                    : NightPalette.accentGold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: qiFill,
                                  minHeight: 7,
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    canBuildAny
                                        ? const Color(0xFF80ED99)
                                        : NightPalette.accentGold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              nextSlot == null
                                  ? '전 초소 가동/대기'
                                  : (canBuildAny
                                      ? '🔨초소 건설 가능!'
                                      : '운빨35⚡/지정$nextDirectCost⚡'),
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: canBuildAny
                                    ? const Color(0xFF80ED99)
                                    : NightPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),

                      // ★ 실시간 긴급 현상수배 미션 바 (달성 즉시 자동으로 대박 기력 지급!)
                      Builder(
                        builder: (_) {
                          final q = _sim.currentBountyQuest;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10192D),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: NightPalette.accentGold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    q.allCleared
                                        ? '🏆 현상수배 전 단계 완수! (전군 대박 보급 완료)'
                                        : '🏆 현상수배(${q.stepIndex}/4): ${q.title} [${q.current}/${q.goal}]',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.8,
                                      fontWeight: FontWeight.bold,
                                      color: NightPalette.jadeGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '보상 ${q.bonusLabel}',
                                  style: const TextStyle(
                                    fontSize: 10.6,
                                    fontWeight: FontWeight.bold,
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 3),

                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _HudStatBadge(
                            assetPath: NightArtRegistry.launcherAsset(
                              LauncherType.rapid,
                            ),
                            fallbackIcon: Icons.add_location_alt_rounded,
                            text:
                                '초소 ${_sim.launchers.length}/${_sim.activeMounts.length}곳',
                            color: _sim.launchers.isEmpty
                                ? NightPalette.accentGold
                                : NightPalette.jadeGreen,
                          ),
                          _HudStatBadge(
                            assetPath: NightArtRegistry.fxBarrier,
                            fallbackIcon: Icons.shield_rounded,
                            text: '방어막 $shieldPct%',
                            color: NightPalette.jadeShield,
                          ),
                          _HudStatBadge(
                            assetPath: NightArtRegistry.towerGuardian,
                            fallbackIcon: Icons.fort_rounded,
                            text: '수호탑 $towerPct%',
                            color: NightPalette.accentGold,
                          ),
                          _HudStatBadge(
                            assetPath: NightArtRegistry.fxQi,
                            fallbackIcon: Icons.bolt_rounded,
                            text: '내공 ${_sim.qiBars.toStringAsFixed(1)}/3칸',
                            color: NightPalette.jadeGreen,
                          ),
                          if (_sim.activePerks.isNotEmpty)
                            _HudStatBadge(
                              assetPath: NightArtRegistry.iconRogueScroll,
                              fallbackIcon: Icons.menu_book_rounded,
                              text:
                                  '비급 ${_sim.activePerks.values.fold<int>(0, (a, b) => a + b)}권',
                              color: NightPalette.accentGold,
                            ),
                          if (_sim.auroraCritTimer > 0)
                            _HudStatBadge(
                              assetPath: NightArtRegistry.fxCritical,
                              fallbackIcon: Icons.auto_awesome_rounded,
                              text:
                                  '극광회심 ${_sim.auroraCritTimer.toStringAsFixed(1)}초',
                              color: Colors.orangeAccent,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // 중앙 60프레임 심야 전장 화면
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    chapter.bgAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      NightArtRegistry.bgNightLobby,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: NightPalette.bgDeep),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: NightPalette.bgDeep.withValues(alpha: 0.40),
                    ),
                  ),
                  Center(
                    child: AspectRatio(
                      aspectRatio: CampaignCatalog.arenaWidth /
                          CampaignCatalog.arenaHeight,
                      child: LayoutBuilder(
                        builder: (ctx, arenaConstraints) {
                          return GestureDetector(
                            key: const Key('battle_arena_gesture'),
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              if (arenaConstraints.maxWidth <= 0 ||
                                  arenaConstraints.maxHeight <= 0) {
                                return;
                              }
                              final tapPos = _toArenaCoords(
                                details.localPosition,
                                arenaConstraints,
                              );

                              // 1) 빈 초소 또는 설치된 발사대 터치 → 게임 멈춤 없이 실시간 배치 띠 / 즉시 승급·합체!
                              final hitSlot = _hitMountSlot(tapPos);
                              if (hitSlot != null) {
                                _handleLiveMountTap(hitSlot);
                                return;
                              }

                              // 다른 허공 터치 시 열려 있던 실시간 초소 미니 띠 닫기
                              if (_selectedSlotIndex != null) {
                                setState(() {
                                  _selectedSlotIndex = null;
                                  _livePadMenuTimer = 0.0;
                                });
                              }

                              // 2) 맨 아래 중앙 기명 수호탑 터치 → 자동 발사 ↔ 수동 탄지 즉시 전환!
                              if (tapPos.distanceTo(
                                    CampaignCatalog.centralTowerPos,
                                  ) <=
                                  36.0) {
                                _sim.toggleCentralManualMode();
                                NightHaptics.instance.lightTap();
                                _frameNotifier.value++;
                                setState(() {});
                                return;
                              }

                              // 3) 수동 탄지 모드에서 전장 위쪽 허공 터치 → 해당 지점으로 3갈래 수동 산탄 발사!
                              if (_sim.centralManualMode) {
                                if (_sim.fireCentralManualAt(tapPos)) {
                                  NightHaptics.instance.lightTap();
                                  _frameNotifier.value++;
                                }
                              }
                            },
                            onPanStart: (details) {
                              if (arenaConstraints.maxWidth <= 0 ||
                                  arenaConstraints.maxHeight <= 0) {
                                return;
                              }
                              final startPos = _toArenaCoords(
                                details.localPosition,
                                arenaConstraints,
                              );
                              // 초소 위에서 시작한 손가락 터치는 드래그가 삼키지 않도록 보호!
                              final startHit = _hitMountSlot(startPos);
                              if (startHit != null) {
                                _panStartSlot = startHit;
                                _panStartArenaPos = startPos;
                                return;
                              }
                              _panStartSlot = null;
                              _panStartArenaPos = null;

                              final nearTower = startPos.distanceTo(
                                    CampaignCatalog.centralTowerPos,
                                  ) <=
                                  56.0;
                              if (!nearTower && !_sim.centralManualMode) {
                                return;
                              }
                              if (nearTower && !_sim.centralManualMode) {
                                _sim.setCentralManualMode(true);
                              }
                              _draggingManualAim = true;
                              _draggedFromTower = nearTower;
                              _manualAimPreviewAngleRad =
                                  _computeAimAngleFromArenaPoint(
                                startPos,
                                fromTower: nearTower,
                              );
                              _frameNotifier.value++;
                            },
                            onPanUpdate: (details) {
                              if (_panStartSlot != null && _panStartArenaPos != null) {
                                final curPos = _toArenaCoords(
                                  details.localPosition,
                                  arenaConstraints,
                                );
                                if (curPos.distanceTo(_panStartArenaPos!) > 26.0) {
                                  _panStartSlot = null;
                                  _panStartArenaPos = null;
                                }
                                return;
                              }
                              if (!_draggingManualAim) return;
                              final curPos = _toArenaCoords(
                                details.localPosition,
                                arenaConstraints,
                              );
                              _manualAimPreviewAngleRad =
                                  _computeAimAngleFromArenaPoint(
                                curPos,
                                fromTower: _draggedFromTower,
                              );
                              _sim.centralAimAngleRad =
                                  _manualAimPreviewAngleRad!;
                              _frameNotifier.value++;
                            },
                            onPanEnd: (_) {
                              if (_panStartSlot != null) {
                                final tappedSlot = _panStartSlot!;
                                _panStartSlot = null;
                                _panStartArenaPos = null;
                                _handleLiveMountTap(tappedSlot);
                                return;
                              }
                              if (!_draggingManualAim) return;
                              final fireAngle = _manualAimPreviewAngleRad;
                              _draggingManualAim = false;
                              _manualAimPreviewAngleRad = null;
                              if (fireAngle != null) {
                                if (_sim.fireCentralManualAngle(fireAngle)) {
                                  NightHaptics.instance.lightTap();
                                }
                              }
                              _frameNotifier.value++;
                            },
                            onPanCancel: () {
                              _panStartSlot = null;
                              _panStartArenaPos = null;
                              _draggingManualAim = false;
                              _manualAimPreviewAngleRad = null;
                              _frameNotifier.value++;
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.symmetric(
                                  vertical: BorderSide(
                                    color: NightPalette.borderGold
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                              child: ClipRect(
                                child: ValueListenableBuilder<int>(
                                  valueListenable: _frameNotifier,
                                  builder: (_, _, _) {
                                    return CustomPaint(
                                      size: Size.infinite,
                                      painter: NightBattlePainter(
                                        sim: _sim,
                                        repaintTick: _frameNotifier,
                                        manualAimPreviewAngleRad:
                                            _manualAimPreviewAngleRad,
                                        selectedSlotIndex: _selectedSlotIndex,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 아직 배치한 초소가 0곳일 때 상단 친절 배치 유도 배지
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (_, _, _) {
                      if (_sim.launchers.isNotEmpty ||
                          _sim.bossInvasionAlertTimer > 0) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        top: 8,
                        left: 12,
                        right: 12,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xE00C1526),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: NightPalette.accentGold,
                                  width: 1.3,
                                ),
                              ),
                              child: Text(
                                '👆 빛나는 길목 빈 초소(${_sim.activeMounts.length}곳)를 눌러 발사대를 직접 배치하세요!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: NightPalette.accentGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 중간보스·우두머리 동반 침략 긴급 경보 배너
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (_, _, _) {
                      final alert = _sim.bossInvasionAlertText;
                      if (alert == null || _sim.bossInvasionAlertTimer <= 0) {
                        return const SizedBox.shrink();
                      }
                      final opacity =
                          (_sim.bossInvasionAlertTimer / 0.45).clamp(0.0, 1.0);
                      return Positioned(
                        top: 10,
                        left: 12,
                        right: 12,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: opacity,
                            child: Center(
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 460),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xEE3A0812),
                                      Color(0xEE5E0B1E),
                                      Color(0xEE3A0812),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: NightPalette.accentGold,
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x88E63946),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const NightSpriteIcon(
                                      assetPath: NightArtRegistry.fxBreachGate,
                                      fallbackIcon: Icons.warning_amber_rounded,
                                      size: 22,
                                      borderRadius: 11,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        alert,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: NightPalette.accentGold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 우측 상단 연타 콤보 · 🔥 피버 타임 게이지 & ⚡ 다음 물결 조기 호출 버튼!
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (_, _, _) {
                      final showCombo =
                          _sim.comboCount >= 3 || _sim.feverTimer > 0;
                      final canEarly = _sim.canCallNextWaveEarly;
                      if (!showCombo && !canEarly && _sim.feverGauge < 15) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        top: 42,
                        right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (showCombo || _sim.feverGauge >= 15)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _sim.feverTimer > 0
                                      ? const Color(0xEE5E1908)
                                      : const Color(0xCC0D1628),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _sim.feverTimer > 0
                                        ? NightPalette.accentGold
                                        : NightPalette.jadeShield,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    NightSpriteIcon(
                                      assetPath: _sim.feverTimer > 0
                                          ? NightArtRegistry.fxFeverAura
                                          : NightArtRegistry.fxCombo,
                                      fallbackIcon:
                                          Icons.local_fire_department_rounded,
                                      size: 18,
                                      borderRadius: 9,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _sim.feverTimer > 0
                                          ? '🔥피버 무쌍 ${_sim.feverTimer.toStringAsFixed(1)}초!'
                                          : (_sim.killStreak >= 5
                                              ? '💀${_sim.killStreak}연속 격살 · 열기 ${_sim.feverGauge.round()}%'
                                              : '${_sim.comboCount}연타 · 열기 ${_sim.feverGauge.round()}%'),
                                      style: TextStyle(
                                        fontSize: 11.4,
                                        fontWeight: FontWeight.bold,
                                        color: _sim.feverTimer > 0
                                            ? NightPalette.accentGold
                                            : NightPalette.jadeGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (canEarly) ...[
                              const SizedBox(height: 6),
                              FilledButton.icon(
                                key: const Key('call_early_wave_btn'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xEE183A37),
                                  foregroundColor: NightPalette.accentGold,
                                  side: const BorderSide(
                                    color: NightPalette.accentGold,
                                    width: 1.3,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () {
                                  if (_sim.callNextWaveEarly()) {
                                    NightHaptics.instance.lightTap();
                                    _frameNotifier.value++;
                                    setState(() {});
                                  }
                                },
                                icon: const Icon(
                                  Icons.fast_forward_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  '⚡조기호출(+18⚡·비급)',
                                  style: TextStyle(
                                    fontSize: 11.2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  // 🌙 비차단 실시간 전령 대사 알림 (전투 멈춤 0초 · 4.8초 뒤 자동 소멸!)
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (_, _, _) {
                      final line = _liveStoryLine;
                      if (line == null ||
                          _liveStoryTimer <= 0 ||
                          _sim.pendingPerkChoices.isNotEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        top: 38,
                        left: 12,
                        right: 12,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xD80B1324),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: NightPalette.borderGold,
                                ),
                              ),
                              child: Row(
                                children: [
                                  NightSpriteIcon(
                                    assetPath: NightArtRegistry.charFace(
                                      line.portraitPrefix,
                                    ),
                                    fallbackIcon: Icons.person_rounded,
                                    size: 28,
                                    borderRadius: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${line.speaker}: ${line.text}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.2,
                                        color: NightPalette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => setState(() {
                                      _liveStoryLine = null;
                                      _liveStoryTimer = 0.0;
                                    }),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: NightPalette.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 📜 전장을 가리지 않고 게임이 멈추지 않는 「6.5초 타임어택 실시간 돌파 비급 3택 1 바」!
                  // (빠르게 클릭하면 즉시 발동, 6.5초 안에 못 누르면 그대로 통과!)
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (_, _, _) {
                      if (_sim.pendingPerkChoices.isEmpty || _sim.isFinished) {
                        return const SizedBox.shrink();
                      }
                      final choices =
                          List<RoguePerk>.from(_sim.pendingPerkChoices);
                      final recPerk = _sim.recommendedPerkChoice();
                      final timeRatio = (_sim.perkChoiceTimer /
                              DefenseBattleSim.perkWindowDurationSec)
                          .clamp(0.0, 1.0);

                      return Positioned(
                        top: 6,
                        left: 8,
                        right: 8,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 580),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
                              decoration: BoxDecoration(
                                color: const Color(0xDF091122),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: NightPalette.accentGold,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const NightSpriteIcon(
                                        assetPath:
                                            NightArtRegistry.iconRogueScroll,
                                        fallbackIcon:
                                            Icons.auto_stories_rounded,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '📜 심야 돌파 비급 선택 (3택 1) · ⏱${_sim.perkChoiceTimer.toStringAsFixed(1)}초 내 클릭(미클릭 시 통과)',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.8,
                                            fontWeight: FontWeight.bold,
                                            color: NightPalette.accentGold,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          final nextVal = !_sim.autoChoosePerks;
                                          _sim.autoChoosePerks = nextVal;
                                          widget.controller
                                              .autoChooseBattlePerks = nextVal;
                                          if (nextVal &&
                                              _sim.pendingPerkChoices
                                                  .isNotEmpty) {
                                            _sim.chooseRoguePerk(
                                              recPerk ?? choices.first,
                                            );
                                          }
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _sim.autoChoosePerks
                                                ? NightPalette.jadeGreen
                                                : Colors.white12,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _sim.autoChoosePerks
                                                ? '자동선택 ON'
                                                : '자동선택',
                                            style: TextStyle(
                                              fontSize: 10.2,
                                              fontWeight: FontWeight.bold,
                                              color: _sim.autoChoosePerks
                                                  ? Colors.black
                                                  : NightPalette.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: timeRatio,
                                      minHeight: 4,
                                      backgroundColor: Colors.white12,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        NightPalette.accentGold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      for (int idx = 0;
                                          idx < choices.length;
                                          idx++) ...[
                                        if (idx > 0) const SizedBox(width: 6),
                                        Expanded(
                                          child: Builder(
                                            builder: (_) {
                                              final perk = choices[idx];
                                              final isRec = perk == recPerk;
                                              final rarityCol =
                                                  Color(perk.rarity.colorHex);
                                              return InkWell(
                                                key: Key(
                                                  'rogue_perk_${perk.id}',
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                onTap: () {
                                                  if (_sim.chooseRoguePerk(
                                                    perk,
                                                  )) {
                                                    NightHaptics.instance
                                                        .lightTap();
                                                    _frameNotifier.value++;
                                                    setState(() {});
                                                  }
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(7),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xEE141E36,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                    border: Border.all(
                                                      color: isRec
                                                          ? NightPalette
                                                              .accentGold
                                                          : rarityCol,
                                                      width: isRec ? 1.8 : 1.1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        isRec
                                                            ? '★추천 · ${perk.title}'
                                                            : perk.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11.4,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                            perk.colorHex,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        perk.badge,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 10.2,
                                                          color: NightPalette
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 🔨 전장을 가리지 않는 하단 반투명 「4.8초 실시간 초소 빠른 선택 띠」 (안 누르면 자동 소멸!)
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (_, _, _) {
                      final selIdx = _selectedSlotIndex;
                      if (selIdx == null ||
                          _livePadMenuTimer <= 0 ||
                          _sim.isFinished) {
                        return const SizedBox.shrink();
                      }
                      final slot = _sim.mountSlotByIndex(selIdx);
                      if (slot == null) return const SizedBox.shrink();
                      final existing = _sim.launcherAtSlot(selIdx);
                      final cond = _sim.padConditionOf(selIdx);
                      final padRatio =
                          (_livePadMenuTimer / _livePadMenuDuration)
                              .clamp(0.0, 1.0);

                      return Positioned(
                        bottom: 6,
                        left: 8,
                        right: 8,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 580),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 7),
                              decoration: BoxDecoration(
                                color: const Color(0xE0091224),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: NightPalette.jadeShield,
                                  width: 1.3,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          existing == null
                                              ? '길목 ${selIdx + 1}번 빈 초소 · 발사대 직접 배치 (⏱${_livePadMenuTimer.toStringAsFixed(1)}초)'
                                              : '길목 ${selIdx + 1}번 초소 · ${existing.type.name} ${existing.tier}형 관리 (⏱${_livePadMenuTimer.toStringAsFixed(1)}초)',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: NightPalette.accentGold,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => setState(() {
                                          _selectedSlotIndex = null;
                                          _livePadMenuTimer = 0.0;
                                        }),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: NightPalette.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: padRatio,
                                      minHeight: 3,
                                      backgroundColor: Colors.white12,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        NightPalette.jadeGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  if (cond.state ==
                                      PadConditionState.waveLocked)
                                    Text(
                                      cond.detailReason,
                                      style: const TextStyle(
                                        fontSize: 11.2,
                                        color: NightPalette.textPrimary,
                                      ),
                                    )
                                  else
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          if (existing == null) ...[
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: ActionChip(
                                                key: const Key(
                                                  'lucky_summon_btn',
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                backgroundColor: _sim
                                                            .fieldTokens >=
                                                        DefenseBattleSim
                                                            .luckySummonCostTokens
                                                    ? const Color(0xFF2B1E4E)
                                                    : Colors.white10,
                                                side: const BorderSide(
                                                  color:
                                                      NightPalette.accentGold,
                                                ),
                                                label: const Text(
                                                  '🎲운빨 35⚡',
                                                  style: TextStyle(
                                                    fontSize: 11.2,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        NightPalette.accentGold,
                                                  ),
                                                ),
                                                onPressed: _sim.fieldTokens >=
                                                        DefenseBattleSim
                                                            .luckySummonCostTokens
                                                    ? () {
                                                        if (_sim.summonLuckyLauncherInBattle(
                                                              selIdx,
                                                            ) !=
                                                            null) {
                                                          NightHaptics.instance
                                                              .lightTap();
                                                          setState(() {
                                                            _selectedSlotIndex =
                                                                null;
                                                            _livePadMenuTimer =
                                                                0.0;
                                                          });
                                                        }
                                                      }
                                                    : null,
                                              ),
                                            ),
                                          ] else ...[
                                            if (_sim.findMergePartnerSlot(
                                                  selIdx,
                                                ) !=
                                                null)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                child: ActionChip(
                                                  key: const Key(
                                                    'merge_slot_btn',
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  backgroundColor:
                                                      NightPalette.accentGold,
                                                  label: const Text(
                                                    '☯️무료합체!',
                                                    style: TextStyle(
                                                      fontSize: 11.2,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    if (_sim
                                                        .mergeLauncherAtSlot(
                                                      selIdx,
                                                    )) {
                                                      NightHaptics.instance
                                                          .heavyImpact();
                                                      setState(() {
                                                        _selectedSlotIndex =
                                                            null;
                                                        _livePadMenuTimer = 0.0;
                                                      });
                                                    }
                                                  },
                                                ),
                                              ),
                                            if (existing.tier < 4)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                child: ActionChip(
                                                  key: const Key(
                                                    'upgrade_slot_btn',
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  backgroundColor:
                                                      NightPalette.jadeGreen,
                                                  label: Text(
                                                    '▲${existing.tier + 1}형(${existing.type.inBattleUpgradeCost(existing.tier)}⚡)',
                                                    style: const TextStyle(
                                                      fontSize: 11.2,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  onPressed: _sim.fieldTokens >=
                                                          existing.type
                                                              .inBattleUpgradeCost(
                                                            existing.tier,
                                                          )
                                                      ? () {
                                                          if (_sim
                                                              .upgradeLauncherAtSlot(
                                                            selIdx,
                                                          )) {
                                                            NightHaptics
                                                                .instance
                                                                .lightTap();
                                                            setState(() {
                                                              _livePadMenuTimer =
                                                                  3.5;
                                                            });
                                                          }
                                                        }
                                                      : null,
                                                ),
                                              ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: ActionChip(
                                                key: const Key(
                                                  'dismantle_slot_btn',
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                label: Text(
                                                  '♻️철거(+${(existing.investedTokens * 0.80).round()}⚡)',
                                                  style: const TextStyle(
                                                    fontSize: 11.0,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  if (_sim
                                                          .dismantleLauncherInBattle(
                                                        selIdx,
                                                      ) >
                                                      0) {
                                                    NightHaptics.instance
                                                        .lightTap();
                                                    setState(() {
                                                      _selectedSlotIndex = null;
                                                      _livePadMenuTimer = 0.0;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                          ...LauncherType.values.map((lt) {
                                            if (existing != null &&
                                                existing.type == lt) {
                                              return const SizedBox.shrink();
                                            }
                                            final unlocked = _sim
                                                .isLauncherTypeUnlocked(lt);
                                            final refund = existing != null
                                                ? (existing.investedTokens *
                                                        0.80)
                                                    .round()
                                                : 0;
                                            final canAfford = unlocked &&
                                                (_sim.fieldTokens + refund) >=
                                                    lt.buildCostTokens;
                                            final netCost = max(
                                              0,
                                              lt.buildCostTokens - refund,
                                            );
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: ActionChip(
                                                key: Key(
                                                  'place_launcher_${EnumName(lt).name}',
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                backgroundColor: canAfford
                                                    ? const Color(0xFF172742)
                                                    : Colors.white10,
                                                side: BorderSide(
                                                  color: canAfford
                                                      ? Color(lt.colorHex)
                                                      : Colors.white24,
                                                ),
                                                label: Text(
                                                  unlocked
                                                      ? '${lt.name.split(" ").first} $netCost⚡'
                                                      : '${lt.name.split(" ").first}(${lt.unlockChapter}장)',
                                                  style: TextStyle(
                                                    fontSize: 11.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: canAfford
                                                        ? Color(lt.colorHex)
                                                        : NightPalette
                                                            .textMuted,
                                                  ),
                                                ),
                                                onPressed: canAfford
                                                    ? () {
                                                        final ok = existing ==
                                                                null
                                                            ? _sim
                                                                .placeLauncherInBattle(
                                                                selIdx,
                                                                lt,
                                                              )
                                                            : _sim
                                                                .replaceLauncherInBattle(
                                                                selIdx,
                                                                lt,
                                                              );
                                                        if (ok) {
                                                          NightHaptics.instance
                                                              .lightTap();
                                                          setState(() {
                                                            _selectedSlotIndex =
                                                                null;
                                                            _livePadMenuTimer =
                                                                0.0;
                                                          });
                                                        }
                                                      }
                                                    : null,
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ★ 멈춤 없는 하단 실시간 원터치 소환 · 실시간 업그레이드 3종 · 기연 돌림판 · 전술 바!
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (_, _, _) {
                final p = widget.controller.progress;
                final nextSlot = _sim.nextRecommendedSlotIndex();
                final nextDirectCost = nextSlot != null
                    ? (_sim
                            .mountSlotByIndex(nextSlot)
                            ?.recommendedType
                            .buildCostTokens ??
                        45)
                    : 45;
                final canQuickLucky = nextSlot != null &&
                    _sim.fieldTokens >= DefenseBattleSim.luckySummonCostTokens;
                final canQuickDirect =
                    nextSlot != null && _sim.fieldTokens >= nextDirectCost;
                final mergePair = _sim.findAnyMergePair();

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  color: NightPalette.bgPanel,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1열: 실시간 원터치 소환/건설/합체 + 전군 실시간 화력·연사·결계 업그레이드 + 🎰돌림판!
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ActionChip(
                              key: const Key('quick_lucky_summon_btn'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: canQuickLucky
                                  ? const Color(0xFF2B1E4E)
                                  : NightPalette.bgDeep,
                              side: BorderSide(
                                color: canQuickLucky
                                    ? NightPalette.accentGold
                                    : Colors.white24,
                              ),
                              label: Text(
                                nextSlot != null
                                    ? '🎲즉시운빨(35⚡)'
                                    : '🎲초소만석',
                                style: TextStyle(
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.bold,
                                  color: canQuickLucky
                                      ? NightPalette.accentGold
                                      : NightPalette.textMuted,
                                ),
                              ),
                              onPressed: canQuickLucky
                                  ? () {
                                      if (_sim.quickLuckySummonNextPad() !=
                                          null) {
                                        NightHaptics.instance.lightTap();
                                        setState(() {});
                                      }
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 5),
                            ActionChip(
                              key: const Key('quick_direct_build_btn'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: canQuickDirect
                                  ? const Color(0xFF14362B)
                                  : NightPalette.bgDeep,
                              side: BorderSide(
                                color: canQuickDirect
                                    ? const Color(0xFF80ED99)
                                    : Colors.white24,
                              ),
                              label: Text(
                                nextSlot != null
                                    ? '🔨추천건설($nextDirectCost⚡)'
                                    : '🔨건설완료',
                                style: TextStyle(
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.bold,
                                  color: canQuickDirect
                                      ? const Color(0xFF80ED99)
                                      : NightPalette.textMuted,
                                ),
                              ),
                              onPressed: canQuickDirect
                                  ? () {
                                      if (_sim.quickDirectBuildNextPad()) {
                                        NightHaptics.instance.lightTap();
                                        setState(() {});
                                      }
                                    }
                                  : null,
                            ),
                            if (mergePair != null) ...[
                              const SizedBox(width: 5),
                              ActionChip(
                                key: const Key('quick_merge_any_btn'),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: NightPalette.accentGold,
                                label: const Text(
                                  '☯️원터치합체!(0⚡)',
                                  style: TextStyle(
                                    fontSize: 11.2,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                onPressed: () {
                                  if (_sim.quickMergeAnyPair()) {
                                    NightHaptics.instance.heavyImpact();
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                            const SizedBox(width: 5),
                            ActionChip(
                              key: const Key('live_upg_firepower_btn'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: _sim.liveFirepowerLv < 5 &&
                                      _sim.fieldTokens >= _sim.liveFirepowerCost
                                  ? const Color(0xFF3A181C)
                                  : NightPalette.bgDeep,
                              side: BorderSide(
                                color: _sim.liveFirepowerLv < 5 &&
                                        _sim.fieldTokens >=
                                            _sim.liveFirepowerCost
                                    ? const Color(0xFFFF6B35)
                                    : Colors.white24,
                              ),
                              label: Text(
                                _sim.liveFirepowerLv >= 5
                                    ? '⚔️화력만땅'
                                    : '⚔️화력업+${_sim.liveFirepowerLv}(${_sim.liveFirepowerCost}⚡)',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: _sim.liveFirepowerLv < 5 &&
                                          _sim.fieldTokens >=
                                              _sim.liveFirepowerCost
                                      ? const Color(0xFFFF6B35)
                                      : NightPalette.textMuted,
                                ),
                              ),
                              onPressed: _sim.liveFirepowerLv < 5 &&
                                      _sim.fieldTokens >= _sim.liveFirepowerCost
                                  ? () {
                                      if (_sim.upgradeLiveFirepower()) {
                                        NightHaptics.instance.lightTap();
                                        setState(() {});
                                      }
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 5),
                            ActionChip(
                              key: const Key('live_upg_reload_btn'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: _sim.liveReloadLv < 5 &&
                                      _sim.fieldTokens >= _sim.liveReloadCost
                                  ? const Color(0xFF122C44)
                                  : NightPalette.bgDeep,
                              side: BorderSide(
                                color: _sim.liveReloadLv < 5 &&
                                        _sim.fieldTokens >= _sim.liveReloadCost
                                    ? const Color(0xFF4CC9F0)
                                    : Colors.white24,
                              ),
                              label: Text(
                                _sim.liveReloadLv >= 5
                                    ? '⚡연사만땅'
                                    : '⚡연사업+${_sim.liveReloadLv}(${_sim.liveReloadCost}⚡)',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: _sim.liveReloadLv < 5 &&
                                          _sim.fieldTokens >=
                                              _sim.liveReloadCost
                                      ? const Color(0xFF4CC9F0)
                                      : NightPalette.textMuted,
                                ),
                              ),
                              onPressed: _sim.liveReloadLv < 5 &&
                                      _sim.fieldTokens >= _sim.liveReloadCost
                                  ? () {
                                      if (_sim.upgradeLiveReload()) {
                                        NightHaptics.instance.lightTap();
                                        setState(() {});
                                      }
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 5),
                            ActionChip(
                              key: const Key('live_upg_range_btn'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: _sim.liveRangeLv < 4 &&
                                      _sim.fieldTokens >= _sim.liveRangeCost
                                  ? const Color(0xFF10343A)
                                  : NightPalette.bgDeep,
                              side: BorderSide(
                                color: _sim.liveRangeLv < 4 &&
                                        _sim.fieldTokens >= _sim.liveRangeCost
                                    ? NightPalette.jadeGreen
                                    : Colors.white24,
                              ),
                              label: Text(
                                _sim.liveRangeLv >= 4
                                    ? '🔭사거리만땅'
                                    : '🔭사거리업+${_sim.liveRangeLv}(${_sim.liveRangeCost}⚡)',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: _sim.liveRangeLv < 4 &&
                                          _sim.fieldTokens >= _sim.liveRangeCost
                                      ? NightPalette.jadeGreen
                                      : NightPalette.textMuted,
                                ),
                              ),
                              onPressed: _sim.liveRangeLv < 4 &&
                                      _sim.fieldTokens >= _sim.liveRangeCost
                                  ? () {
                                      if (_sim.upgradeLiveRange()) {
                                        NightHaptics.instance.lightTap();
                                        setState(() {});
                                      }
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 5),
                            ActionChip(
                              key: const Key('live_upg_barrier_btn'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: _sim.liveBarrierLv < 5 &&
                                      _sim.fieldTokens >= _sim.liveBarrierCost
                                  ? const Color(0xFF123328)
                                  : NightPalette.bgDeep,
                              side: BorderSide(
                                color: _sim.liveBarrierLv < 5 &&
                                        _sim.fieldTokens >= _sim.liveBarrierCost
                                    ? const Color(0xFF80ED99)
                                    : Colors.white24,
                              ),
                              label: Text(
                                _sim.liveBarrierLv >= 5
                                    ? '🛡️결계만땅'
                                    : '🛡️결계업+${_sim.liveBarrierLv}(${_sim.liveBarrierCost}⚡)',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: _sim.liveBarrierLv < 5 &&
                                          _sim.fieldTokens >=
                                              _sim.liveBarrierCost
                                      ? const Color(0xFF80ED99)
                                      : NightPalette.textMuted,
                                ),
                              ),
                              onPressed: _sim.liveBarrierLv < 5 &&
                                      _sim.fieldTokens >= _sim.liveBarrierCost
                                  ? () {
                                      if (_sim.upgradeLiveBarrier()) {
                                        NightHaptics.instance.lightTap();
                                        setState(() {});
                                      }
                                    }
                                  : null,
                            ),
                            if (_sim.rouletteSpinsAvailable > 0) ...[
                              const SizedBox(width: 5),
                              ActionChip(
                                key: const Key('spin_roulette_btn'),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: const Color(0xFF4A2511),
                                side: const BorderSide(
                                  color: NightPalette.accentGold,
                                  width: 1.4,
                                ),
                                label: Text(
                                  '🎰돌림판(${_sim.rouletteSpinsAvailable})',
                                  style: const TextStyle(
                                    fontSize: 11.2,
                                    fontWeight: FontWeight.bold,
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                                onPressed: () {
                                  if (_sim.spinDestinyRoulette() != null) {
                                    NightHaptics.instance.heavyImpact();
                                    setState(() {});
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 2열: 중앙탑 사격 모드(꾹 눌러 연사) · 비약 3종 · 자동승급 · 무림수호단 출두!
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ActionChip(
                              key: const Key('battle_toggle_central_mode_btn'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: _sim.centralManualMode
                                  ? NightPalette.accentGold
                                      .withValues(alpha: 0.24)
                                  : NightPalette.bgDeep,
                              side: BorderSide(
                                color: _sim.centralManualMode
                                    ? NightPalette.accentGold
                                    : NightPalette.jadeGreen,
                              ),
                              avatar: Icon(
                                _sim.centralManualMode
                                    ? Icons.gps_fixed_rounded
                                    : Icons.autorenew_rounded,
                                size: 15,
                                color: _sim.centralManualMode
                                    ? NightPalette.accentGold
                                    : NightPalette.jadeGreen,
                              ),
                              label: Text(
                                _sim.centralManualMode
                                    ? '중앙탑: 수동탄지'
                                    : '중앙탑: 자동발사',
                                style: TextStyle(
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.bold,
                                  color: _sim.centralManualMode
                                      ? NightPalette.accentGold
                                      : NightPalette.jadeGreen,
                                ),
                              ),
                              onPressed: () {
                                _sim.toggleCentralManualMode();
                                NightHaptics.instance.lightTap();
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 5),
                            ...TacticalConsumable.values.map((item) {
                              final cnt = p.consumables[item] ?? 0;
                              final shortLabel = switch (item) {
                                TacticalConsumable.qiSurgePill => '기공단',
                                TacticalConsumable.guardianRepairSeal => '수리패',
                                TacticalConsumable.auroraCritCharm => '극광부',
                              };
                              return Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: ActionChip(
                                  key: Key('use_consumable_${item.name}'),
                                  visualDensity: VisualDensity.compact,
                                  avatar: NightSpriteIcon(
                                    assetPath:
                                        NightArtRegistry.consumableAsset(item),
                                    fallbackIcon: Icons.local_pharmacy_rounded,
                                    size: 16,
                                    color: cnt > 0
                                        ? Color(item.colorHex)
                                        : Colors.grey.shade600,
                                    dimmed: cnt <= 0,
                                    borderRadius: 4,
                                  ),
                                  label: Text(
                                    '$shortLabel($cnt)',
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      color: cnt > 0
                                          ? NightPalette.textPrimary
                                          : NightPalette.textMuted,
                                    ),
                                  ),
                                  onPressed: cnt > 0
                                      ? () {
                                          if (_sim.activateConsumable(item)) {
                                            widget.controller
                                                .notifyConsumableUsedInBattle();
                                            setState(() {});
                                          }
                                        }
                                      : null,
                                ),
                              );
                            }),
                            FilterChip(
                              visualDensity: VisualDensity.compact,
                              selected: _sim.preset.autoUpgradeInBattle,
                              label: const Text(
                                '자동승급',
                                style: TextStyle(fontSize: 11.0),
                              ),
                              onSelected: (v) {
                                widget.controller.updatePreset(
                                  (pr) => pr.autoUpgradeInBattle = v,
                                );
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 6),
                            FilledButton.icon(
                              key: const Key('battle_chuldu_btn'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                backgroundColor: _sim.supportChargesLeft > 0
                                    ? NightPalette.accentGold
                                    : Colors.grey.shade800,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: _sim.supportChargesLeft > 0
                                  ? () {
                                      _sim.triggerSupportChuldu();
                                      setState(() {});
                                    }
                                  : null,
                              icon: NightSpriteIcon(
                                assetPath: NightArtRegistry.fxChuldu,
                                fallbackAssetPath:
                                    NightArtRegistry.nightSupportSeal,
                                fallbackIcon: Icons.campaign_rounded,
                                size: 18,
                                color: _sim.supportChargesLeft > 0
                                    ? Colors.black
                                    : Colors.white54,
                                dimmed: _sim.supportChargesLeft <= 0,
                                borderRadius: 4,
                              ),
                              label: Text(
                                '무림수호단 출두! (${_sim.supportChargesLeft})',
                                style: const TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _HudStatBadge extends StatelessWidget {
  const _HudStatBadge({
    required this.assetPath,
    required this.fallbackIcon,
    required this.text,
    required this.color,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NightSpriteIcon(
          assetPath: assetPath,
          fallbackIcon: fallbackIcon,
          size: 15,
          color: color,
          borderRadius: 3,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11.8, color: color),
        ),
      ],
    );
  }
}

class _MiniVillageStatBadge extends StatelessWidget {
  const _MiniVillageStatBadge({
    required this.assetPath,
    required this.fallbackIcon,
    required this.label,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: NightPalette.bgDeep.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NightPalette.borderGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NightSpriteIcon(
            assetPath: assetPath,
            fallbackIcon: fallbackIcon,
            size: 18,
            borderRadius: 4,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: NightPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
