import 'dart:math';
import 'dart:ui' as ui;

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/night_audio.dart';
import '../audio/night_haptics.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'battle_painter.dart';
import 'stage_and_county_transitions.dart';

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
  int _lastPersistedSupportUsed = 0;
  int _consumablesUsedThisBattle = 0;

  /// 수동 조준 드래그(꾹 누르면 자동 연속 사격!) 및 비차단 실시간 초소 미니 선택창 타이머!
  bool _draggingManualAim = false;
  bool _draggedFromTower = false;
  double? _manualAimPreviewAngleRad;
  LauncherMountSlot? _panStartSlot;
  Vec2? _panStartArenaPos;
  int? _selectedSlotIndex;
  double _livePadMenuTimer = 0.0;
  static const double _livePadMenuDuration = 4.8;

  /// 전장을 멈추지 않는 상단 실시간 전령·동료·보스 순차 대사 큐 (한 줄당 3.9초 뒤 자동 전환!).
  final List<StoryLine> _storyQueue = [];
  StoryLine? _liveStoryLine;
  double _liveStoryTimer = 0.0;

  /// 광각 대협곡 전체 보기(기본) ↔ 1.4배 정밀 확대 보기 전환 상태 & 비상 위험구역 2.8배 확대 영상 모니터 표시 상태!
  bool _zoomedView = false;
  bool _showCrisisZoomPip = true;
  bool _handedOffBgm = false;
  final TransformationController _zoomController = TransformationController();

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
      activeHeroes: widget.controller.progress.activePreset.companions,
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
    _lastPersistedSupportUsed = 0;
    _consumablesUsedThisBattle = 0;
    _draggingManualAim = false;
    _manualAimPreviewAngleRad = null;
    _panStartSlot = null;
    _panStartArenaPos = null;
    _selectedSlotIndex = null;
    _livePadMenuTimer = 0.0;
    _storyQueue.clear();
    if (showIntroToast && widget.stage.introDialogue.isNotEmpty) {
      _storyQueue.addAll(widget.stage.introDialogue);
      _liveStoryLine = _storyQueue.removeAt(0);
      _liveStoryTimer = 3.9;
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
    if (_sim.pendingStoryLines.isNotEmpty) {
      _storyQueue.addAll(_sim.pendingStoryLines);
      _sim.pendingStoryLines.clear();
    }
    if (_liveStoryTimer > 0) {
      _liveStoryTimer = max(0.0, _liveStoryTimer - rawDt);
      if (_liveStoryTimer <= 0) {
        _liveStoryLine = null;
      }
    }
    if (_liveStoryLine == null && _storyQueue.isNotEmpty && !_sim.isFinished) {
      _liveStoryLine = _storyQueue.removeAt(0);
      _liveStoryTimer = 3.9;
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
    } else if (_sim.dawnPurifyAnimTimer > 0) {
      _sim.dawnPurifyAnimTimer =
          max(0.0, _sim.dawnPurifyAnimTimer - rawDt);
    } else if (_summaryShown) {
      return;
    }

    if (_sim.usedSupportCount > _lastPersistedSupportUsed) {
      _lastPersistedSupportUsed = _sim.usedSupportCount;
      widget.controller.notifySupportUsedInBattle();
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
    double bestDist = 48.0; // 640×1080 광각 전장에서도 손가락 터치 미스가 없도록 넉넉한 반경 확보!
    for (final slot in _sim.activeMounts) {
      final dCenter = slot.pos.distanceTo(arenaPos);
      final dBadge = (slot.pos + const Vec2(0, 24)).distanceTo(arenaPos);
      final d = min(dCenter, dBadge);
      if (d < bestDist) {
        bestDist = d;
        closest = slot;
      }
    }
    return closest;
  }

  /// 전장에서 다단 변이 보스의 빛나는 약점 과녁(🎯)을 직접 터치했는지 판별 (장갑판 또는 타수 마갑 활성 중 52px 정밀 반경)!
  ActiveMutant? _hitMultiPhaseBossTarget(Vec2 arenaPos, {bool bullseyeOnly = false}) {
    ActiveMutant? best;
    double bestDist = bullseyeOnly ? 38.0 : 52.0;
    for (final m in _sim.mutants) {
      if (!m.hasActiveWeakPoint) continue;
      final dWeak = arenaPos.distanceTo(m.weakSpotWorldPos);
      final dBody = bullseyeOnly
          ? double.infinity
          : max(0.0, arenaPos.distanceTo(m.pos) - m.effectiveRadius * 0.55);
      final d = min(dWeak, dBody);
      if (d <= bestDist) {
        bestDist = d;
        best = m;
      }
    }
    return best;
  }

  Future<void> _confirmExitOrRestart({required bool isRestart}) async {
    final hasSpentItems = !_sim.isFinished &&
        (_sim.usedSupportCount > 0 ||
            _consumablesUsedThisBattle > 0 ||
            _sim.hasConsumedConvoyBuff);
    if (hasSpentItems) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: NightPalette.bgCard,
          title: Text(
            isRestart ? '전투 처음부터 재개시' : '본영으로 복귀',
            style: const TextStyle(
              color: NightPalette.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: const Text(
            '이번 전투에서 이미 사용한 지원패(무림수호단 출두)·전술 비약·호송 보급 버프는 복구되지 않습니다. 계속하시겠습니까?',
            style: TextStyle(color: NightPalette.textPrimary, fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('전투 계속'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: NightPalette.crimsonMoon,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(isRestart ? '재개시' : '복귀'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    if (isRestart) {
      NightHaptics.instance.lightTap();
      setState(() => _startNewSim(showIntroToast: false));
    } else {
      Navigator.of(context).pop();
    }
  }

  double _computeAimAngleFromArenaPoint(Vec2 arenaPos, {required bool fromTower}) {
    final tower = _sim.towerPos;
    final dx = arenaPos.x - tower.x;
    final dy = arenaPos.y - tower.y;
    if (dx.abs() < 3.0 && dy.abs() < 3.0) {
      return tower.y < 420.0 ? pi / 2 : -pi / 2;
    }
    // 하단 제단(y >= 820)에서 아래쪽으로 당기면 새총 탄지처럼 위쪽으로 조준, 중앙·상단 제단(4·6·7장)은 360° 전방위 직접 조준!
    if (fromTower && dy > 14.0 && tower.y >= 820.0) {
      return _sim.sanitizeAimAngleForChapter(atan2(-dy, -dx));
    }
    return _sim.sanitizeAimAngleForChapter(atan2(dy, dx));
  }

  /// ★ 멈춤 없는 실시간 전략 거점 반응 처리:
  /// - 마기 침식(`isCorrupted`) 포탑 터치 시: 즉시 마기 정화(`cleanseLauncherAtSlot`) & 연사 각성 발동!
  /// - 전방 마기 암석 봉인(`rubbleBlocked`) 거점 터치 시: 기력이 충분하면 즉시 암석 파쇄 개척(`excavateSlotInBattle`) 후 병종 선택 띠 오픈!
  /// - 개척된 빈 거점 / 설치된 포탑 터치 시: 4.8초 실시간 전략 선택창(체증 건설·승급·유료 연성·교체·철거) 오픈!
  void _handleLiveMountTap(LauncherMountSlot slot) {
    if (_sim.isFinished) return;
    final existing = _sim.launcherAtSlot(slot.slotIndex);
    if (existing != null && existing.isCorrupted) {
      if (_sim.cleanseLauncherAtSlot(slot.slotIndex)) {
        NightHaptics.instance.heavyImpact();
        _frameNotifier.value++;
        setState(() {});
        return;
      }
    }
    if (existing == null &&
        _sim.isSlotWaveUnlocked(slot.slotIndex) &&
        !_sim.isSlotExcavated(slot.slotIndex) &&
        _sim.fieldTokens >= _sim.excavationCostForSlot(slot)) {
      if (_sim.excavateSlotInBattle(slot.slotIndex)) {
        NightHaptics.instance.heavyImpact();
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
    bool modalHandled = false;
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
                  // 승리/후퇴 시 영웅 전신 공격 원화 vs 대수괴 결전 배너
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 118,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            summary.victory
                                ? NightArtRegistry.cardGateBattle
                                : NightArtRegistry.cardEndlessAbyss,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const ColoredBox(color: NightPalette.bgPanel),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x38121B2E), Color(0xDC141E33)],
                              ),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(-0.82, 0.9),
                            child: Image.asset(
                              NightArtRegistry.heroAttackAsset(
                                widget.controller.progress.activePreset.companions
                                        .isNotEmpty
                                    ? widget.controller.progress.activePreset
                                        .companions.first
                                    : CompanionHero.seokdu,
                              ),
                              height: 98,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0.82, 0.85),
                            child: NightSpriteIcon(
                              assetPath: NightArtRegistry.showcaseBossChapter,
                              fallbackIcon: Icons.whatshot_rounded,
                              size: 74,
                              borderRadius: 12,
                              fit: BoxFit.cover,
                              showFrame: true,
                              frameColor: NightPalette.crimsonMoon,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summary.victory
                        ? '새벽 정화 승리 (${widget.stage.title})'
                        : '방어선 붕괴 · 마을 후퇴',
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
                  if (summary.victory &&
                      widget.stage.chapterNumber == 10 &&
                      widget.stage.stageNumber == 10) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3D2706), Color(0xFF1A3A34)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: NightPalette.accentGold,
                          width: 2.0,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            '🏆 열 마을 완전 정화 · 태극석 귀향 대단원 달성!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 16.5,
                              color: NightPalette.accentGold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '오염된 태초 탄신의 삼중 마갑을 깨뜨리고 강호 열 마을의 평화를 되찾았습니다! 이제 100물결 무한 혈전에서 진법의 극한에 도전해보세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: NightPalette.textPrimary,
                              height: 1.38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  if (summary.victory &&
                      widget.stage.outroDialogue.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      key: const Key('victory_outro_story_card'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6EBD2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: NightPalette.accentGold,
                          width: 1.6,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📜 새벽 정화 무림 서사록',
                            style: TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 15.5,
                              color: Color(0xFF1B2538),
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (int sIdx = 0;
                              sIdx < widget.stage.outroDialogue.length;
                              sIdx++) ...[
                            if (sIdx > 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Divider(
                                  height: 1,
                                  color: Color(0x281B2538),
                                ),
                              ),
                            Builder(
                              builder: (_) {
                                final line = widget.stage.outroDialogue[sIdx];
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    NightSpriteIcon(
                                      assetPath: NightArtRegistry.charFace(
                                        line.portraitPrefix,
                                      ),
                                      fallbackIcon: Icons.person_rounded,
                                      size: 34,
                                      borderRadius: 17,
                                      showFrame: true,
                                      frameColor: const Color(0xFF2D3C59),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 12.8,
                                            height: 1.42,
                                            color: Color(0xFF222E45),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: '${line.speaker}: ',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF14213D),
                                              ),
                                            ),
                                            TextSpan(text: line.text),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
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
                            if (_sim.precisionHitCount > 0)
                              Text(
                                '약점 파쇄: ${_sim.precisionHitCount}회',
                                style: const TextStyle(
                                  color: NightPalette.accentGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (_sim.bossPhaseBreakCount > 0)
                              Text(
                                '재변이 돌파: ${_sim.bossPhaseBreakCount}단계',
                                style: const TextStyle(
                                  color: NightPalette.jadeGreen,
                                  fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 14),
                  if (summary.victory &&
                      widget.stage.globalIndex >= 1 &&
                      widget.stage.globalIndex <
                          CampaignCatalog.allStages.length)
                    VictoryContinuousMarchCard(
                      controller: widget.controller,
                      clearedStage: widget.stage,
                      nextStage:
                          CampaignCatalog.allStages[widget.stage.globalIndex],
                      onAdvanceNow: () {
                        if (modalHandled || !ctx.mounted || !mounted) return;
                        modalHandled = true;
                        Navigator.of(ctx).pop();
                        final nextStage =
                            CampaignCatalog.allStages[widget.stage.globalIndex];
                        if (nextStage.chapterNumber !=
                            widget.stage.chapterNumber) {
                          widget.controller
                              .setSelectedChapter(nextStage.chapterNumber);
                          Navigator.of(context).pushReplacement(
                            buildSmoothScreenRoute(
                              CountyTransitionScreen(
                                controller: widget.controller,
                                fromChapter: widget.stage.chapterNumber,
                                openedFromVictory: true,
                              ),
                            ),
                          );
                        } else {
                          _handedOffBgm = true;
                          Navigator.of(context).pushReplacement(
                            buildSmoothBattleRoute(
                              controller: widget.controller,
                              stage: nextStage,
                              previousStage: widget.stage,
                            ),
                          );
                        }
                      },
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (modalHandled) return;
                            modalHandled = true;
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
                            if (modalHandled) return;
                            modalHandled = true;
                            Navigator.of(ctx).pop();
                            if (summary.victory &&
                                widget.stage.globalIndex >= 1 &&
                                widget.stage.globalIndex <
                                    CampaignCatalog.allStages.length) {
                              final nextStage = CampaignCatalog
                                  .allStages[widget.stage.globalIndex];
                              if (nextStage.chapterNumber !=
                                  widget.stage.chapterNumber) {
                                // 현(縣) 10판 마무리 완료! 다음 현 고유 대행군 이동 영상 화면으로 진입!
                                widget.controller
                                    .setSelectedChapter(nextStage.chapterNumber);
                                Navigator.of(context).pushReplacement(
                                  buildSmoothScreenRoute(
                                    CountyTransitionScreen(
                                      controller: widget.controller,
                                      fromChapter: widget.stage.chapterNumber,
                                      openedFromVictory: true,
                                    ),
                                  ),
                                );
                              } else {
                                _handedOffBgm = true;
                                Navigator.of(context).pushReplacement(
                                  buildSmoothBattleRoute(
                                    controller: widget.controller,
                                    stage: nextStage,
                                    previousStage: widget.stage,
                                  ),
                                );
                              }
                            } else if (summary.victory &&
                                ((widget.stage.chapterNumber == 10 &&
                                        widget.stage.stageNumber == 10) ||
                                    widget.stage.globalIndex >= 900)) {
                              Navigator.of(context).pop();
                            } else {
                              setState(_startNewSim);
                            }
                          },
                          icon: Icon(
                            summary.victory
                                ? ((widget.stage.chapterNumber == 10 &&
                                            widget.stage.stageNumber == 10) ||
                                        widget.stage.globalIndex >= 900
                                    ? Icons.emoji_events_rounded
                                    : (widget.stage.stageNumber == 10
                                        ? Icons.movie_filter_rounded
                                        : Icons.skip_next_rounded))
                                : Icons.refresh_rounded,
                          ),
                          label: Text(
                            summary.victory &&
                                    widget.stage.globalIndex >= 1 &&
                                    widget.stage.globalIndex <
                                        CampaignCatalog.allStages.length
                                ? (widget.stage.stageNumber == 10
                                    ? '🎬 제${widget.stage.chapterNumber + 1}현 대행군 출발!'
                                    : '다음 마을 진군 (${CampaignCatalog.allStages[widget.stage.globalIndex].code})')
                                : (summary.victory &&
                                        widget.stage.globalIndex >= 900
                                    ? '🏆 100물결 제패 · 본영 금의환향'
                                    : (summary.victory &&
                                            widget.stage.chapterNumber == 10 &&
                                            widget.stage.stageNumber == 10
                                        ? '🌅 100판 완승 · 본영 금의환향'
                                        : '다시 도전하기')),
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
    _zoomController.dispose();
    if (!_handedOffBgm) {
      NightAudioController.instance.playBgm('bgm_lobby.ogg');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapter = CampaignCatalog.chapterOf(widget.stage.chapterNumber);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmExitOrRestart(isRestart: false);
        }
      },
      child: ScaffoldMessenger(
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
                final nextMount =
                    nextSlot != null ? _sim.mountSlotByIndex(nextSlot) : null;
                final needExcavateFirst =
                    nextSlot != null && !_sim.isSlotExcavated(nextSlot);
                final nextTargetCost = nextMount == null
                    ? _sim.buildCostForType(LauncherType.rapid)
                    : (needExcavateFirst
                        ? _sim.excavationCostForSlot(nextMount)
                        : _sim.buildCostForType(
                            _sim.preferredBuildTypeForSlot(nextMount),
                          ));
                final qiFill =
                    (_sim.fieldTokens / max(1, nextTargetCost)).clamp(0.0, 1.0);
                final canBuildAny =
                    nextSlot != null && _sim.fieldTokens >= nextTargetCost;

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
                            onPressed: () =>
                                _confirmExitOrRestart(isRestart: false),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          IconButton(
                            key: const Key('battle_quick_restart_btn'),
                            visualDensity: VisualDensity.compact,
                            tooltip: '멈춤 없이 즉시 처음부터 재개시',
                            onPressed: () =>
                                _confirmExitOrRestart(isRestart: true),
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
                                  )
                                else if (widget.stage.globalIndex >= 1 &&
                                    widget.stage.globalIndex <
                                        CampaignCatalog.allStages.length)
                                  Text(
                                    widget.stage.stageNumber < 10
                                        ? '🏘️ 현재 [${widget.stage.villageNodeName}] ➔ 다음 인근 마을: [${CampaignCatalog.allStages[widget.stage.globalIndex].villageNodeName}]'
                                        : '🏯 현 결전 [${widget.stage.villageNodeName}] ➔ 완수 시 제${widget.stage.chapterNumber + 1}현 대행군!',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.8,
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
                              final nextSpd = s.first.clamp(1, 4);
                              widget.controller.setBattleSpeed(nextSpd);
                              setState(() => _speedMultiplier = nextSpd);
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.selected)
                                    ? const Color(0xFF1F3647)
                                    : NightPalette.bgDeep,
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.selected)
                                    ? NightPalette.accentGold
                                    : NightPalette.textMuted,
                              ),
                              side: const WidgetStatePropertyAll(
                                BorderSide(color: Color(0x5572EFDD)),
                              ),
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              ),
                              minimumSize: const WidgetStatePropertyAll(Size(28, 30)),
                              textStyle: const WidgetStatePropertyAll(
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
                                  ? '전 거점 가동/대기'
                                  : (needExcavateFirst
                                      ? (canBuildAny
                                          ? '⛏️거점 개척 가능($nextTargetCost⚡)!'
                                          : '🪨개척 필요 $nextTargetCost⚡')
                                      : (canBuildAny
                                          ? '🔨포대 축조 가능($nextTargetCost⚡)!'
                                          : '체증건설 $nextTargetCost⚡')),
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

                      // ★ 행동대장(100+타) · 중간보스(300+타) · 장 보스(1,000+타) 실시간 계급·다단페이즈·누적타수 안내 바!
                      Builder(
                        builder: (_) {
                          final boss = _sim.activeMultiPhaseBoss ??
                              _sim.mutants
                                  .where((m) => m.kind.isBoss || m.maxHitShield > 0)
                                  .firstOrNull;
                          if (boss == null) return const SizedBox.shrink();
                          final pRatio = boss.currentMaxHp > 0
                              ? (boss.hp / boss.currentMaxHp).clamp(0.0, 1.0)
                              : 0.0;
                          final hitRatio = boss.maxHitShield > 0
                              ? (boss.hitShieldLeft / boss.maxHitShield)
                                  .clamp(0.0, 1.0)
                              : 0.0;
                          final remPhases =
                              (boss.totalPhases - boss.currentPhase + 1).clamp(1, 3);
                          final gems = boss.totalPhases > 1
                              ? '${'◆' * remPhases}${'◇' * (boss.totalPhases - remPhases)} '
                              : '';
                          final hitSummary = boss.maxHitShield > 0
                              ? '🔥${boss.totalHitsTaken}HIT · 🛡️남은 ${boss.hitShieldLeft}/${boss.maxHitShield}타'
                              : '🔥누적 ${boss.totalHitsTaken}HIT';
                          final statusLabel = boss.phaseTransitionTimer > 0
                              ? '⚡재변이 각성 중! · $hitSummary'
                              : (boss.carapacePlatesLeft > 0
                                  ? '🛡️장갑${boss.carapacePlatesLeft}겹 🎯약점터치! · $hitSummary'
                                  : (boss.groggyExposeTimer > 0
                                      ? '💥무방비(×1.85) · $hitSummary'
                                      : hitSummary));
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Container(
                              key: const Key('battle_boss_hit_hud'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF280B18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: boss.carapacePlatesLeft > 0
                                      ? const Color(0xFFFFD166)
                                      : const Color(0xFFFF4D6D),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '👹 [${boss.hierarchyRank}] ${boss.displayName} [$gems${boss.phaseTitleBadge}]',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.0,
                                            fontWeight: FontWeight.bold,
                                            color: NightPalette.accentGold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          statusLabel,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10.4,
                                            fontWeight: FontWeight.bold,
                                            color: boss.groggyExposeTimer > 0
                                                ? const Color(0xFF80ED99)
                                                : const Color(0xFFFFD166),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pRatio,
                                      minHeight: 5,
                                      backgroundColor: Colors.white12,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        boss.currentPhase >= 3
                                            ? const Color(0xFFFF006E)
                                            : (boss.currentPhase == 2
                                                ? const Color(0xFFC77DFF)
                                                : const Color(0xFFFF4D6D)),
                                      ),
                                    ),
                                  ),
                                  if (boss.maxHitShield > 0) ...[
                                    const SizedBox(height: 2),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: hitRatio,
                                        minHeight: 3.5,
                                        backgroundColor: Colors.white10,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF48CAE4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

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
                            text:
                                '내공 ${_sim.qiBars.toStringAsFixed(1)}/${_sim.maxQiBars.round()}칸',
                            color: NightPalette.jadeGreen,
                          ),
                          _HudStatBadge(
                            assetPath: chapter.floorAsset,
                            fallbackIcon: Icons.route_rounded,
                            text:
                                '${chapter.routeTopologyTag} · ${chapter.chapterTraitTitle}',
                            color: const Color(0xFF90E0EF),
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
                          if (widget.stage.globalIndex >= 1 &&
                              widget.stage.globalIndex <=
                                  CampaignCatalog.allStages.length)
                            GestureDetector(
                              key: const Key('battle_continuous_march_chip'),
                              onTap: () {
                                widget.controller.setContinuousVillageMarch(
                                  !widget.controller.continuousVillageMarch,
                                );
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.controller.continuousVillageMarch
                                      ? const Color(0xFF143C34)
                                      : NightPalette.bgDeep,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        widget.controller.continuousVillageMarch
                                            ? NightPalette.jadeGreen
                                            : Colors.white24,
                                  ),
                                ),
                                child: Text(
                                  widget.controller.continuousVillageMarch
                                      ? '🏃연속수호 ON'
                                      : '⏸️연속수호 OFF',
                                  style: TextStyle(
                                    fontSize: 10.6,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        widget.controller.continuousVillageMarch
                                            ? NightPalette.jadeGreen
                                            : NightPalette.textMuted,
                                  ),
                                ),
                              ),
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
                  ClipRect(
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Image.asset(
                        chapter.bgAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                          NightArtRegistry.bgNightLobby,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: NightPalette.bgDeep),
                        ),
                      ),
                    ),
                  ),
                  const ColoredBox(color: Color(0x9E060C18)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x18141F33),
                          Color(0x2218253D),
                          Color(0x2E121C2E),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: InteractiveViewer(
                      transformationController: _zoomController,
                      panEnabled: _zoomedView,
                      scaleEnabled: _zoomedView,
                      minScale: 1.0,
                      maxScale: 2.2,
                      child: AspectRatio(
                        aspectRatio: CampaignCatalog.arenaWidth /
                            CampaignCatalog.arenaHeight,
                        child: LayoutBuilder(
                          builder: (ctx, arenaConstraints) {
                            final allowArenaPan = !_zoomedView;
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

                                // 0) 장전 완료 상태에서 보스 약점 과녁(🎯 반경 38px) 정중앙 터치 시 초소·제단보다 최우선 파갑 저격!
                                if (_sim.isPrecisionStrikeReady) {
                                  final bullseyeBoss = _hitMultiPhaseBossTarget(
                                    tapPos,
                                    bullseyeOnly: true,
                                  );
                                  if (bullseyeBoss != null &&
                                      _sim.firePrecisionStrikeAt(
                                        tapPos,
                                        targetBossUid: bullseyeBoss.uid,
                                      )) {
                                    NightHaptics.instance.heavyImpact();
                                    _frameNotifier.value++;
                                    return;
                                  }
                                }

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

                                // 2) 각 장의 실제 수호 제단(중앙 기명 수호탑) 터치 처리 → 자동/수동 전환!
                                if (tapPos.distanceTo(
                                      _sim.towerPos,
                                    ) <=
                                    44.0) {
                                  _sim.toggleCentralManualMode();
                                  NightHaptics.instance.lightTap();
                                  _frameNotifier.value++;
                                  setState(() {});
                                  return;
                                }

                                // 3) 다단 변이 보스 본체/약점 터치 → 재사용 대기시간이 찼을 때 정밀 파갑 신궁탄 격발!
                                final bossTarget = _hitMultiPhaseBossTarget(tapPos);
                                if (bossTarget != null &&
                                    _sim.firePrecisionStrikeAt(
                                      tapPos,
                                      targetBossUid: bossTarget.uid,
                                    )) {
                                  NightHaptics.instance.heavyImpact();
                                  _frameNotifier.value++;
                                  return;
                                }

                                // 4) 수동 탄지 모드에서 전장 허공 터치 → 해당 지점으로 3갈래 수동 산탄 발사!
                                if (_sim.centralManualMode) {
                                  if (_sim.fireCentralManualAt(tapPos)) {
                                    NightHaptics.instance.lightTap();
                                    _frameNotifier.value++;
                                  }
                                }
                              },
                              onPanStart: !allowArenaPan
                                  ? null
                                  : (details) {
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
                                      // 중앙탑에서 시작한 드래그가 아닐 때만 다단 변이 보스 약점 즉시 저격!
                                      final panBoss =
                                          _hitMultiPhaseBossTarget(startPos);
                                      if (startPos.distanceTo(_sim.towerPos) >
                                              48.0 &&
                                          panBoss != null &&
                                          _sim.firePrecisionStrikeAt(
                                            startPos,
                                            targetBossUid: panBoss.uid,
                                          )) {
                                        NightHaptics.instance.heavyImpact();
                                        _frameNotifier.value++;
                                        return;
                                      }
                                      _panStartSlot = null;
                                      _panStartArenaPos = null;

                                      final nearTower = startPos.distanceTo(
                                            _sim.towerPos,
                                          ) <=
                                          68.0;
                                      if (!nearTower &&
                                          !_sim.centralManualMode) {
                                        return;
                                      }
                                      if (nearTower &&
                                          !_sim.centralManualMode) {
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
                              onPanUpdate: !allowArenaPan
                                  ? null
                                  : (details) {
                                      if (_panStartSlot != null &&
                                          _panStartArenaPos != null) {
                                        final curPos = _toArenaCoords(
                                          details.localPosition,
                                          arenaConstraints,
                                        );
                                        if (curPos.distanceTo(
                                              _panStartArenaPos!,
                                            ) >
                                            32.0) {
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
                              onPanEnd: !allowArenaPan
                                  ? null
                                  : (_) {
                                      if (_panStartSlot != null) {
                                        final tappedSlot = _panStartSlot!;
                                        _panStartSlot = null;
                                        _panStartArenaPos = null;
                                        _handleLiveMountTap(tappedSlot);
                                        return;
                                      }
                                      if (!_draggingManualAim) return;
                                      final fireAngle =
                                          _manualAimPreviewAngleRad;
                                      _draggingManualAim = false;
                                      _manualAimPreviewAngleRad = null;
                                      if (fireAngle != null) {
                                        if (_sim.fireCentralManualAngle(
                                          fireAngle,
                                        )) {
                                          NightHaptics.instance.lightTap();
                                        }
                                      }
                                      _frameNotifier.value++;
                                    },
                              onPanCancel: !allowArenaPan
                                  ? null
                                  : () {
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
                  ),

                  // 아직 배치한 초소가 0곳일 때 상단 친절 배치 유도 배지
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (_, _, _) {
                      if (_sim.launchers.isNotEmpty ||
                          _sim.bossInvasionAlertTimer > 0 ||
                          _sim.pendingPerkChoices.isNotEmpty) {
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

                  // 중간보스·3페이즈 대수괴 각성 시 무정지(0.00초 멈춤) 영웅 대 보스 실전 컷인 배너
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (_, _, _) {
                      final alert = _sim.bossInvasionAlertText;
                      if (alert == null ||
                          _sim.bossInvasionAlertTimer <= 0 ||
                          _sim.pendingPerkChoices.isNotEmpty) {
                        return const SizedBox.shrink();
                      }
                      final opacity =
                          (_sim.bossInvasionAlertTimer / 0.45).clamp(0.0, 1.0);
                      final activeBoss = _sim.mutants
                          .where((m) => m.kind.isBoss)
                          .map((m) => m.kind)
                          .firstOrNull;
                      final leadHero = _sim.preset.companions.isNotEmpty
                          ? _sim.preset.companions.first
                          : CompanionHero.seokdu;
                      return Positioned(
                        top: 8,
                        left: 10,
                        right: 10,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: opacity,
                            child: Center(
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 500),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xEE18263E),
                                      Color(0xEE4A161A),
                                      Color(0xEE18263E),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: NightPalette.accentGold,
                                    width: 1.6,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    NightSpriteIcon(
                                      assetPath:
                                          NightArtRegistry.heroAttackAsset(
                                        leadHero,
                                      ),
                                      fallbackIcon: Icons.shield_rounded,
                                      size: 40,
                                      borderRadius: 10,
                                      showFrame: true,
                                      frameColor: NightPalette.accentGold,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        alert,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.2,
                                          fontWeight: FontWeight.bold,
                                          color: NightPalette.accentGold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    NightSpriteIcon(
                                      assetPath: NightArtRegistry
                                          .mutantShowcaseAsset(
                                        activeBoss ??
                                            MutantKind.chapterOverlord,
                                      ),
                                      fallbackAssetPath:
                                          NightArtRegistry.fxBreachGate,
                                      fallbackIcon:
                                          Icons.warning_amber_rounded,
                                      size: 40,
                                      borderRadius: 10,
                                      fit: BoxFit.cover,
                                      showFrame: true,
                                      frameColor: NightPalette.crimsonMoon,
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
                      if (_sim.pendingPerkChoices.isNotEmpty ||
                          (!showCombo && !canEarly && _sim.feverGauge < 15)) {
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

                  // 🚨 위험 비상 알림 & 실시간 2.8배 공격 지점 확대 영상 모니터(PIP)
                  ValueListenableBuilder<int>(
                    valueListenable: _frameNotifier,
                    builder: (_, _, _) {
                      final crisis = _sim.activeCrisis;
                      if (crisis == null ||
                          _sim.isFinished ||
                          _sim.pendingPerkChoices.isNotEmpty) {
                        return const SizedBox.shrink();
                      }
                      final sirenPulse =
                          0.5 + 0.5 * sin(_sim.elapsedSec * 10.0);
                      final borderCol = Color.lerp(
                        const Color(0xFFFF1E56),
                        const Color(0xFFFFD166),
                        sirenPulse,
                      )!;
                      final dockRightForTopMounts = _sim.chapter.number == 7;
                      final hasRightTopHud = _sim.comboCount >= 3 ||
                          _sim.feverTimer > 0 ||
                          _sim.canCallNextWaveEarly ||
                          _sim.feverGauge >= 15;
                      return Positioned(
                        top: dockRightForTopMounts
                            ? (hasRightTopHud ? 124 : 88)
                            : 44,
                        left: dockRightForTopMounts ? null : 10,
                        right: dockRightForTopMounts ? 10 : null,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 214),
                          child: Column(
                            crossAxisAlignment: dockRightForTopMounts
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1) 비상 경보 사이렌 헤더 띠 (접기/펼치기 가능)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: const Key('battle_crisis_alert_banner'),
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(() {
                                    _showCrisisZoomPip = !_showCrisisZoomPip;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xEE590D22),
                                          Color.lerp(
                                            const Color(0xEE800F2F),
                                            const Color(0xEEA4133C),
                                            sirenPulse,
                                          )!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: borderCol,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF1E56)
                                              .withValues(
                                            alpha: 0.25 + sirenPulse * 0.30,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.crisis_alert_rounded,
                                          size: 15,
                                          color: borderCol,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            crisis.headline,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10.2,
                                              height: 1.2,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          _showCrisisZoomPip
                                              ? Icons.videocam_rounded
                                              : Icons.videocam_off_rounded,
                                          size: 14,
                                          color: NightPalette.accentGold,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // 2) 실시간 2.8배 위험구역 공격 확대 영상 모니터 + 3D 모션 시트 + 원터치 정밀 타격!
                              if (_showCrisisZoomPip) ...[
                                const SizedBox(height: 5),
                                GestureDetector(
                                  key: const Key('battle_crisis_zoom_pip'),
                                  onTap: () {
                                    if (_sim.firePrecisionStrikeAt(
                                      crisis.rawTargetPos,
                                    )) {
                                      NightHaptics.instance.heavyImpact();
                                      _frameNotifier.value++;
                                    }
                                  },
                                  child: Container(
                                    width: 196,
                                    height: 132,
                                    decoration: BoxDecoration(
                                      color: const Color(0xF2080E1A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: borderCol,
                                        width: 1.8,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x99000000),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // 실시간 전장 2.8배 확대 라이브 카메라 렌더링
                                          CustomPaint(
                                            size: Size.infinite,
                                            painter: NightBattlePainter(
                                              sim: _sim,
                                              repaintTick: _frameNotifier,
                                              zoomFocusPos: crisis.focusPos,
                                              zoomScale: 2.8,
                                            ),
                                          ),
                                          // 상단 LIVE 위치 표시 바
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 3,
                                              ),
                                              color: const Color(0xCC1A0610),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: sirenPulse > 0.45
                                                          ? const Color(
                                                              0xFFFF1E56,
                                                            )
                                                          : const Color(
                                                              0x55FF1E56,
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'LIVE 2.8× [${crisis.zoneName}]',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 9.6,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFFFFD166,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // 우하단 공격 변이 3D 애니메이션 루프 인셋
                                          Positioned(
                                            right: 4,
                                            bottom: 22,
                                            child: NightSpriteIcon(
                                              assetPath: NightArtRegistry
                                                  .mutantMotionAsset(
                                                crisis.attackerKind,
                                              ),
                                              fallbackAssetPath:
                                                  NightArtRegistry
                                                      .mutantShowcaseAsset(
                                                crisis.attackerKind,
                                              ),
                                              fallbackIcon:
                                                  Icons.warning_rounded,
                                              size: 36,
                                              borderRadius: 8,
                                              fit: BoxFit.cover,
                                              showFrame: true,
                                              frameColor: borderCol,
                                            ),
                                          ),
                                          // 하단 타수·즉시 정밀타격 안내 띠
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 3,
                                              ),
                                              color: const Color(0xDD0B1324),
                                              child: Text(
                                                crisis.maxHitShield > 0
                                                    ? '🎯터치 즉시타격 · 🛡️${crisis.hitShieldLeft}/${crisis.maxHitShield}타'
                                                    : '🎯터치 → 위험구역 즉시 타격!',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 9.2,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF80ED99),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
                      final hasTopGuideOrAlert = _sim.launchers.isEmpty ||
                          _sim.bossInvasionAlertTimer > 0;
                      return Positioned(
                        top: hasTopGuideOrAlert ? 46 : 8,
                        left: 12,
                        right: 12,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
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
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.2,
                                        color: NightPalette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => setState(() {
                                      if (_storyQueue.isNotEmpty) {
                                        _liveStoryLine =
                                            _storyQueue.removeAt(0);
                                        _liveStoryTimer = 3.9;
                                      } else {
                                        _liveStoryLine = null;
                                        _liveStoryTimer = 0.0;
                                      }
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
                                              .setAutoChoosePerks(nextVal);
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
                                              ? '${selIdx + 1}번 ${slot.terrainType.shortBadge} (${slot.terrainType.bonusSummary}) · ⏱${_livePadMenuTimer.toStringAsFixed(1)}초'
                                              : '${selIdx + 1}번 ${slot.terrainType.shortBadge} · ${existing.type.name} ${existing.tier}형 (${slot.terrainType.bonusSummary})',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.4,
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
                                  else if (cond.state ==
                                      PadConditionState.rubbleBlocked)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cond.detailReason,
                                            style: const TextStyle(
                                              fontSize: 11.1,
                                              color: NightPalette.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ActionChip(
                                          key: const Key('excavate_slot_btn'),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor: _sim.fieldTokens >=
                                                  cond.excavationCost
                                              ? const Color(0xFF3D2812)
                                              : Colors.white10,
                                          side: BorderSide(
                                            color: _sim.fieldTokens >=
                                                    cond.excavationCost
                                                ? NightPalette.accentGold
                                                : Colors.white24,
                                          ),
                                          label: Text(
                                            '⛏️암석개척 ${cond.excavationCost}⚡',
                                            style: TextStyle(
                                              fontSize: 11.2,
                                              fontWeight: FontWeight.bold,
                                              color: _sim.fieldTokens >=
                                                      cond.excavationCost
                                                  ? NightPalette.accentGold
                                                  : NightPalette.textMuted,
                                            ),
                                          ),
                                          onPressed: _sim.fieldTokens >=
                                                  cond.excavationCost
                                              ? () {
                                                  if (_sim.excavateSlotInBattle(
                                                    selIdx,
                                                  )) {
                                                    NightHaptics.instance
                                                        .heavyImpact();
                                                    setState(() {
                                                      _livePadMenuTimer =
                                                          _livePadMenuDuration;
                                                    });
                                                  }
                                                }
                                              : null,
                                        ),
                                      ],
                                    )
                                  else
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          if (existing == null) ...[
                                            Builder(
                                              builder: (_) {
                                                final recType = _sim
                                                    .preferredBuildTypeForSlot(
                                                  slot,
                                                );
                                                final recCost = _sim
                                                    .buildCostForType(recType);
                                                final canRec = _sim
                                                        .fieldTokens >=
                                                    recCost;
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    right: 6,
                                                  ),
                                                  child: ActionChip(
                                                    key: const Key(
                                                      'place_recommended_slot_btn',
                                                    ),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    backgroundColor: canRec
                                                        ? const Color(
                                                            0xFF14382E,
                                                          )
                                                        : Colors.white10,
                                                    side: BorderSide(
                                                      color: canRec
                                                          ? const Color(
                                                              0xFF80ED99,
                                                            )
                                                          : Colors.white24,
                                                    ),
                                                    label: Text(
                                                      '★추천[${recType.name.split(" ").first}] $recCost⚡',
                                                      style: TextStyle(
                                                        fontSize: 11.2,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: canRec
                                                            ? const Color(
                                                                0xFF80ED99,
                                                              )
                                                            : NightPalette
                                                                .textMuted,
                                                      ),
                                                    ),
                                                    onPressed: canRec
                                                        ? () {
                                                            if (_sim
                                                                .placeLauncherInBattle(
                                                              selIdx,
                                                              recType,
                                                            )) {
                                                              NightHaptics
                                                                  .instance
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
                                              },
                                            ),
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
                                                        _sim.currentLuckySummonCost
                                                    ? const Color(0xFF2B1E4E)
                                                    : Colors.white10,
                                                side: const BorderSide(
                                                  color:
                                                      NightPalette.accentGold,
                                                ),
                                                label: Text(
                                                  '🎲도박 ${_sim.currentLuckySummonCost}⚡',
                                                  style: const TextStyle(
                                                    fontSize: 11.2,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        NightPalette.accentGold,
                                                  ),
                                                ),
                                                onPressed: _sim.fieldTokens >=
                                                        _sim.currentLuckySummonCost
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
                                            if (existing.isCorrupted)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                child: ActionChip(
                                                  key: const Key(
                                                    'cleanse_slot_btn',
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  backgroundColor:
                                                      const Color(0xFF3A184D),
                                                  side: const BorderSide(
                                                    color: Color(0xFFE0AAFF),
                                                  ),
                                                  label: const Text(
                                                    '✨마기정화(0⚡)',
                                                    style: TextStyle(
                                                      fontSize: 11.2,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFFE0AAFF),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    if (_sim
                                                        .cleanseLauncherAtSlot(
                                                      selIdx,
                                                    )) {
                                                      NightHaptics.instance
                                                          .heavyImpact();
                                                      setState(() {});
                                                    }
                                                  },
                                                ),
                                              ),
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
                                                      const Color(0xFF3A2810),
                                                  side: const BorderSide(
                                                    color:
                                                        NightPalette.accentGold,
                                                  ),
                                                  label: Text(
                                                    '☯️연성합체(${_sim.mergeCostForSlot(selIdx)}⚡)',
                                                    style: const TextStyle(
                                                      fontSize: 11.2,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: NightPalette
                                                          .accentGold,
                                                    ),
                                                  ),
                                                  onPressed: _sim.fieldTokens >=
                                                          _sim.mergeCostForSlot(
                                                            selIdx,
                                                          )
                                                      ? () {
                                                          if (_sim
                                                              .mergeLauncherAtSlot(
                                                            selIdx,
                                                          )) {
                                                            NightHaptics
                                                                .instance
                                                                .heavyImpact();
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
                                                      const Color(0xFF14362E),
                                                  side: const BorderSide(
                                                    color:
                                                        NightPalette.jadeGreen,
                                                  ),
                                                  label: Text(
                                                    '▲${existing.tier + 1}형(${_sim.upgradeCostForLauncher(existing)}⚡)',
                                                    style: const TextStyle(
                                                      fontSize: 11.2,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: NightPalette
                                                          .jadeGreen,
                                                    ),
                                                  ),
                                                  onPressed: !existing
                                                              .isConstructing &&
                                                          _sim.fieldTokens >=
                                                              _sim
                                                                  .upgradeCostForLauncher(
                                                                existing,
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
                                            final reqCost = existing == null
                                                ? _sim.buildCostForType(lt)
                                                : (_sim.chapter
                                                            .buildCostMultiplier *
                                                        lt.progressiveBuildCost(
                                                          max(
                                                            0,
                                                            _sim.launchers
                                                                    .length -
                                                                1,
                                                          ),
                                                        ))
                                                    .round();
                                            final canAfford = unlocked &&
                                                (_sim.fieldTokens + refund) >=
                                                    reqCost;
                                            final netCost = max(
                                              0,
                                              reqCost - refund,
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

            // ★ 멈춤 없는 하단 전략 지휘 바: 마기 암석 개척 · 체증 도박소환 · 전군 실시간 업그레이드 4종 · 전술 비약!
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (_, _, _) {
                final p = widget.controller.progress;
                final readyEmptySlot = _sim.nextExcavatedEmptySlotIndex();
                LauncherMountSlot? unexcavatedFound;
                for (final m in _sim.activeMounts) {
                  if (_sim.isSlotWaveUnlocked(m.slotIndex) &&
                      !_sim.isSlotExcavated(m.slotIndex)) {
                    unexcavatedFound = m;
                    break;
                  }
                }
                final unexcavatedSlot = unexcavatedFound;
                final luckyCost = _sim.currentLuckySummonCost;
                final canQuickLucky =
                    readyEmptySlot != null && _sim.fieldTokens >= luckyCost;
                final LauncherMountSlot? readySlotObj = readyEmptySlot != null
                    ? _sim.activeMounts
                        .where((m) => m.slotIndex == readyEmptySlot)
                        .firstOrNull
                    : null;
                final LauncherType? recDirectType = readySlotObj != null
                    ? _sim.preferredBuildTypeForSlot(readySlotObj)
                    : null;
                final int recDirectCost = recDirectType != null
                    ? _sim.buildCostForType(recDirectType)
                    : 0;
                final bool canQuickDirect = readyEmptySlot != null &&
                    recDirectType != null &&
                    _sim.fieldTokens >= recDirectCost;
                final unexcavatedCost = unexcavatedSlot != null
                    ? _sim.excavationCostForSlot(unexcavatedSlot)
                    : 0;
                final canExcavateNext = unexcavatedSlot != null &&
                    _sim.fieldTokens >= unexcavatedCost;
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
                      // 1열: 거점 암석 개척 · 도박 소환 · 유료 연성 합체 · 전군 실시간 강화 4종!
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (unexcavatedSlot != null) ...[
                              ActionChip(
                                key: const Key('quick_excavate_next_btn'),
                                visualDensity: VisualDensity.compact,
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                backgroundColor: canExcavateNext
                                    ? const Color(0xFF3A2510)
                                    : NightPalette.bgDeep,
                                side: BorderSide(
                                  color: canExcavateNext
                                      ? NightPalette.accentGold
                                      : Colors.white24,
                                ),
                                label: Text(
                                  '⛏️${unexcavatedSlot.slotIndex + 1}번거점개척($unexcavatedCost⚡)',
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                    color: canExcavateNext
                                        ? NightPalette.accentGold
                                        : NightPalette.textMuted,
                                  ),
                                ),
                                onPressed: canExcavateNext
                                    ? () {
                                        final targetIdx =
                                            unexcavatedSlot.slotIndex;
                                        if (_sim.excavateSlotInBattle(
                                          targetIdx,
                                        )) {
                                          NightHaptics.instance.heavyImpact();
                                          setState(() {
                                            _selectedSlotIndex = targetIdx;
                                            _livePadMenuTimer =
                                                _livePadMenuDuration;
                                          });
                                        }
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (readyEmptySlot != null &&
                                recDirectType != null) ...[
                              ActionChip(
                                key: const Key('quick_direct_build_btn'),
                                visualDensity: VisualDensity.compact,
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                backgroundColor: canQuickDirect
                                    ? const Color(0xFF14382E)
                                    : NightPalette.bgDeep,
                                side: BorderSide(
                                  color: canQuickDirect
                                      ? const Color(0xFF80ED99)
                                      : Colors.white24,
                                ),
                                label: Text(
                                  '🔨추천축조[${recDirectType.name.split(" ").first}]($recDirectCost⚡)',
                                  style: TextStyle(
                                    fontSize: 11.0,
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
                              const SizedBox(width: 4),
                            ],
                            ActionChip(
                              key: const Key('quick_lucky_summon_btn'),
                              visualDensity: VisualDensity.compact,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              backgroundColor: canQuickLucky
                                  ? const Color(0xFF1E3252)
                                  : NightPalette.bgDeep,
                              side: BorderSide(
                                color: canQuickLucky
                                    ? NightPalette.accentGold
                                    : Colors.white24,
                              ),
                              label: Text(
                                readyEmptySlot != null
                                    ? '🎲도박소환($luckyCost⚡)'
                                    : (unexcavatedSlot != null
                                        ? '🪨개척후소환'
                                        : '🎲초소만석'),
                                style: TextStyle(
                                  fontSize: 11.0,
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
                            if (mergePair != null) ...[
                              const SizedBox(width: 4),
                              ActionChip(
                                key: const Key('quick_merge_any_btn'),
                                visualDensity: VisualDensity.compact,
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                backgroundColor: const Color(0xFF3A2810),
                                side: const BorderSide(
                                  color: NightPalette.accentGold,
                                ),
                                label: Text(
                                  '☯️연성합체(${_sim.mergeCostForSlot(mergePair.$1)}⚡)',
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                    color: NightPalette.accentGold,
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
                            const SizedBox(width: 4),
                            ActionChip(
                              key: const Key('live_upg_firepower_btn'),
                              visualDensity: VisualDensity.compact,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 3),
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
                                  fontSize: 10.8,
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
                            const SizedBox(width: 4),
                            ActionChip(
                              key: const Key('live_upg_reload_btn'),
                              visualDensity: VisualDensity.compact,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 3),
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
                                  fontSize: 10.8,
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
                            const SizedBox(width: 4),
                            ActionChip(
                              key: const Key('live_upg_range_btn'),
                              visualDensity: VisualDensity.compact,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 3),
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
                                  fontSize: 10.8,
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
                            const SizedBox(width: 4),
                            ActionChip(
                              key: const Key('live_upg_barrier_btn'),
                              visualDensity: VisualDensity.compact,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 3),
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
                                  fontSize: 10.8,
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

                      // 2열: 사격모드 · 1.4배확대 · 자동승급 · 자동비급 (360dp 화면에서도 가로 스크롤 없이 한눈에!)
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
                                  fontSize: 11.0,
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
                            ActionChip(
                              key: const Key('battle_toggle_zoom_view_btn'),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: _zoomedView
                                  ? const Color(0xFF16324A)
                                  : NightPalette.bgDeep,
                              side: BorderSide(
                                color: _zoomedView
                                    ? NightPalette.jadeShield
                                    : Colors.white24,
                              ),
                              avatar: Icon(
                                _zoomedView
                                    ? Icons.zoom_out_map_rounded
                                    : Icons.zoom_in_map_rounded,
                                size: 15,
                                color: NightPalette.jadeShield,
                              ),
                              label: Text(
                                _zoomedView ? '🔍광각전체' : '🔍1.4배확대',
                                style: const TextStyle(
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.bold,
                                  color: NightPalette.jadeShield,
                                ),
                              ),
                              onPressed: () {
                                NightHaptics.instance.lightTap();
                                final mq = MediaQuery.sizeOf(context);
                                final txRatio = (_sim.towerPos.x /
                                        CampaignCatalog.arenaWidth)
                                    .clamp(0.15, 0.85);
                                final tyRatio = (_sim.towerPos.y /
                                        CampaignCatalog.arenaHeight)
                                    .clamp(0.15, 0.85);
                                final focusDx = -(mq.width * 0.40 * txRatio);
                                final focusDy = -(mq.height * 0.34 * tyRatio);
                                setState(() {
                                  _zoomedView = !_zoomedView;
                                  if (_zoomedView) {
                                    _zoomController.value = Matrix4.identity()
                                      ..translateByDouble(
                                        focusDx,
                                        focusDy,
                                        0.0,
                                        1.0,
                                      )
                                      ..scaleByDouble(1.4, 1.4, 1.0, 1.0);
                                  } else {
                                    _zoomController.value = Matrix4.identity();
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 5),
                            FilterChip(
                              visualDensity: VisualDensity.compact,
                              selected: _sim.preset.autoUpgradeInBattle,
                              selectedColor: const Color(0xFF1A343B),
                              backgroundColor: NightPalette.bgDeep,
                              checkmarkColor: NightPalette.jadeGreen,
                              side: BorderSide(
                                color: _sim.preset.autoUpgradeInBattle
                                    ? NightPalette.jadeGreen
                                    : Colors.white24,
                              ),
                              label: Text(
                                '자동승급',
                                style: TextStyle(
                                  fontSize: 10.8,
                                  color: _sim.preset.autoUpgradeInBattle
                                      ? NightPalette.jadeGreen
                                      : NightPalette.textMuted,
                                ),
                              ),
                              onSelected: (v) {
                                widget.controller.updatePreset(
                                  (pr) => pr.autoUpgradeInBattle = v,
                                );
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 5),
                            FilterChip(
                              key: const Key('battle_auto_perk_chip'),
                              visualDensity: VisualDensity.compact,
                              selected: _sim.autoChoosePerks,
                              selectedColor: const Color(0xFF332610),
                              backgroundColor: NightPalette.bgDeep,
                              checkmarkColor: NightPalette.accentGold,
                              side: BorderSide(
                                color: _sim.autoChoosePerks
                                    ? NightPalette.accentGold
                                    : Colors.white24,
                              ),
                              label: Text(
                                '자동비급',
                                style: TextStyle(
                                  fontSize: 10.8,
                                  color: _sim.autoChoosePerks
                                      ? NightPalette.accentGold
                                      : NightPalette.textMuted,
                                ),
                              ),
                              onSelected: (v) {
                                _sim.autoChoosePerks = v;
                                widget.controller.setAutoChoosePerks(v);
                                if (v && _sim.pendingPerkChoices.isNotEmpty) {
                                  final rec = _sim.recommendedPerkChoice() ??
                                      _sim.pendingPerkChoices.first;
                                  _sim.chooseRoguePerk(rec);
                                }
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),

                      // 3열: 전술 비약 3종(기공단·수리패·극광부) + 우측 고정 [무림수호단 출두!] (전 기기 무스크롤 즉시 클릭 보장!)
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: TacticalConsumable.values.map((item) {
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
                                        size: 15,
                                        color: cnt > 0
                                            ? Color(item.colorHex)
                                            : Colors.grey.shade600,
                                        dimmed: cnt <= 0,
                                        borderRadius: 4,
                                      ),
                                      label: Text(
                                        '$shortLabel($cnt)',
                                        style: TextStyle(
                                          fontSize: 10.6,
                                          color: cnt > 0
                                              ? NightPalette.textPrimary
                                              : NightPalette.textMuted,
                                        ),
                                      ),
                                      onPressed: cnt > 0
                                          ? () {
                                              if (_sim.activateConsumable(item)) {
                                                _consumablesUsedThisBattle++;
                                                widget.controller
                                                    .notifyConsumableUsedInBattle();
                                                setState(() {});
                                              }
                                            }
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          OutlinedButton.icon(
                            key: const Key('battle_chuldu_btn'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 5,
                              ),
                              backgroundColor: _sim.supportChargesLeft > 0
                                  ? const Color(0xFF332410)
                                  : NightPalette.bgDeep,
                              foregroundColor: _sim.supportChargesLeft > 0
                                  ? NightPalette.accentGold
                                  : NightPalette.textMuted,
                              side: BorderSide(
                                color: _sim.supportChargesLeft > 0
                                    ? NightPalette.accentGold
                                    : Colors.white24,
                                width: 1.3,
                              ),
                            ),
                            onPressed: _sim.supportChargesLeft > 0
                                ? () {
                                    if (_sim.triggerSupportChuldu()) {
                                      _lastPersistedSupportUsed =
                                          _sim.usedSupportCount;
                                      widget.controller
                                          .notifySupportUsedInBattle();
                                    }
                                    setState(() {});
                                  }
                                : null,
                            icon: NightSpriteIcon(
                              assetPath: NightArtRegistry.fxChuldu,
                              fallbackAssetPath:
                                  NightArtRegistry.nightSupportSeal,
                              fallbackIcon: Icons.campaign_rounded,
                              size: 16,
                              color: _sim.supportChargesLeft > 0
                                  ? NightPalette.accentGold
                                  : Colors.white54,
                              dimmed: _sim.supportChargesLeft <= 0,
                              borderRadius: 4,
                            ),
                            label: Text(
                              '무림수호단 출두!(${_sim.supportChargesLeft})',
                              style: const TextStyle(
                                fontSize: 10.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Row(
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
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.4, color: color),
            ),
          ),
        ],
      ),
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
