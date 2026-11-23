import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../audio/night_audio.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'battle_screen.dart';
import 'codex_and_endless_screens.dart';
import 'convoy_campaign_screens.dart';
import 'loadout_upgrade_screens.dart';
import 'training_screen.dart';

/// 일반 메뉴 화면 간 부드러운 페이드·슬라이드 전환 라우트.
Route<T> buildSmoothScreenRoute<T>(Widget child, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, page) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.025),
            end: Offset.zero,
          ).animate(curved),
          child: page,
        ),
      );
    },
  );
}

/// 판(마을) 진입 및 다음 판 연속 진군 시 자연스럽게 이어지는 전장 진입 라우트.
Route<void> buildSmoothBattleRoute({
  required GameController controller,
  required StageSpec stage,
  StageSpec? previousStage,
}) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 480),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _VillageMarchIntroHost(
        stage: stage,
        previousStage: previousStage,
        child: BattleScreen(
          key: ValueKey('battle_${stage.code}'),
          controller: controller,
          stage: stage,
        ),
      );
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return ColoredBox(
        color: NightPalette.bgDeep,
        child: FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.968, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// 전장 진입 직후 상단에 1.15초간 자연스럽게 떠올랐다 사라지는 비차단(IgnorePointer) 마을 진군 배너.
class _VillageMarchIntroHost extends StatefulWidget {
  const _VillageMarchIntroHost({
    required this.stage,
    required this.child,
    this.previousStage,
  });

  final StageSpec stage;
  final StageSpec? previousStage;
  final Widget child;

  @override
  State<_VillageMarchIntroHost> createState() => _VillageMarchIntroHostState();
}

class _VillageMarchIntroHostState extends State<_VillageMarchIntroHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bannerAnim;

  @override
  void initState() {
    super.initState();
    _bannerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..forward();
  }

  @override
  void dispose() {
    _bannerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chSpec = CampaignCatalog.chapterOf(widget.stage.chapterNumber);
    final prev = widget.previousStage;
    final isSameCountyAdvance =
        prev != null && prev.chapterNumber == widget.stage.chapterNumber;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: true,
          child: AnimatedBuilder(
            animation: _bannerAnim,
            builder: (context, _) {
              final t = _bannerAnim.value;
              if (t >= 0.995) return const SizedBox.shrink();
              double opacity;
              if (t < 0.18) {
                opacity = (t / 0.18).clamp(0.0, 1.0);
              } else if (t > 0.72) {
                opacity = ((1.0 - t) / 0.28).clamp(0.0, 1.0);
              } else {
                opacity = 1.0;
              }
              final dy = (1.0 - opacity) * -14.0;

              return SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(0, 52 + dy),
                    child: Opacity(
                      opacity: opacity,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xEB0E1728),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: NightPalette.accentGold,
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x88000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isSameCountyAdvance
                                    ? '🏮 마을 진군 · [${prev.villageNodeName}] 정화 ➔ [${widget.stage.villageNodeName}] (${widget.stage.code})'
                                    : '⚔️ ${chSpec.countyName} · ${widget.stage.stageNumber}판 [${widget.stage.villageNodeName}] 입성',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'DoHyeon',
                                  fontSize: 13.5,
                                  color: NightPalette.accentGold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(10, (i) {
                                  final stNum = i + 1;
                                  final passed = stNum < widget.stage.stageNumber;
                                  final current =
                                      stNum == widget.stage.stageNumber;
                                  return Container(
                                    width: current ? 18 : 8,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: current
                                          ? NightPalette.accentGold
                                          : (passed
                                              ? NightPalette.jadeGreen
                                              : NightPalette.borderGold
                                                  .withValues(alpha: 0.28)),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 현(縣 · 10판) 마무리 후 다른 현으로 이동할 때 재생되는 전용 대행군 시네마틱 영상 화면 (1→2현 ~ 9→10현 9종 고유 영상 탑재!).
class CountyTransitionScreen extends StatefulWidget {
  const CountyTransitionScreen({
    super.key,
    required this.controller,
    required this.fromChapter,
    this.openedFromVictory = false,
  });

  final GameController controller;
  final int fromChapter;
  final bool openedFromVictory;

  @override
  State<CountyTransitionScreen> createState() => _CountyTransitionScreenState();
}

class _CountyTransitionScreenState extends State<CountyTransitionScreen>
    with TickerProviderStateMixin {
  late int _selectedFromChapter;
  late final AnimationController _routePulse;
  late final AnimationController _autoEnterAnim;
  bool _autoEnterPaused = false;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _selectedFromChapter = widget.fromChapter.clamp(1, 9);
    _routePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _autoEnterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            mounted &&
            !_autoEnterPaused &&
            !_didNavigate &&
            widget.openedFromVictory &&
            widget.controller.continuousVillageMarch) {
          _launchNextCountyFirstVillage();
        }
      });
    if (widget.openedFromVictory && widget.controller.continuousVillageMarch) {
      _autoEnterAnim.forward();
    }
  }

  void _launchNextCountyFirstVillage() {
    if (_didNavigate || !mounted) return;
    final spec = CampaignCatalog.countyTransitionAfter(_selectedFromChapter) ??
        CampaignCatalog.countyTransitions.first;
    final nextFirstStage = CampaignCatalog.stageAt(spec.toChapter, 1);
    if (!widget.controller.progress.isStageUnlocked(nextFirstStage)) return;
    _didNavigate = true;
    _autoEnterAnim.stop();
    widget.controller.setSelectedChapter(spec.toChapter);
    Navigator.of(context).pushReplacement(
      buildSmoothBattleRoute(
        controller: widget.controller,
        stage: nextFirstStage,
      ),
    );
  }

  @override
  void dispose() {
    _autoEnterAnim.dispose();
    _routePulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final p = widget.controller.progress;
        final spec = CampaignCatalog.countyTransitionAfter(_selectedFromChapter) ??
            CampaignCatalog.countyTransitions.first;
        final nextChapterSpec = CampaignCatalog.chapterOf(spec.toChapter);
        final nextFirstStage = CampaignCatalog.stageAt(spec.toChapter, 1);
        final highestClearedCounty =
            (p.highestClearedGlobalStage ~/ 10).clamp(0, 10);
        final isFromCountyCleared = spec.fromChapter <= highestClearedCounty;
        final clearedInFromCounty =
            (p.highestClearedGlobalStage - (spec.fromChapter - 1) * 10)
                .clamp(0, 10);

        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            _didNavigate = true;
            _autoEnterAnim.stop();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.openedFromVictory
                    ? '현(縣) 완전 정화 · 다음 현 대행군'
                    : '10대 현 대행군 이동 영상록',
              ),
            ),
          body: NightSceneBackdrop(
            assetPath: nextChapterSpec.bgAsset,
            fallbackAssetPath: NightArtRegistry.bgNightLobby,
            overlayOpacity: 0.84,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1) 해금된 현 이동 구간 선택 바 (1→2현 ~ 9→10현 모두 다른 영상 확인 가능!)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(9, (idx) {
                              final fromCh = idx + 1;
                              final toCh = fromCh + 1;
                              final unlocked =
                                  fromCh <= highestClearedCounty ||
                                  (widget.openedFromVictory &&
                                      fromCh == widget.fromChapter) ||
                                  p.highestClearedGlobalStage >=
                                      CampaignCatalog.allStages.length;
                              final selected = fromCh == _selectedFromChapter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  key: Key('county_travel_chip_$fromCh'),
                                  selected: selected,
                                  label: Text(
                                    '${unlocked ? "🎬" : "🔒"} $fromCh현➔$toCh현',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                      onSelected: unlocked
                                      ? (_) {
                                          NightAudioController.instance
                                              .playAsset('ui_tap.ogg');
                                          _autoEnterAnim.stop();
                                          setState(() {
                                            _autoEnterPaused = true;
                                            _selectedFromChapter = fromCh;
                                          });
                                        }
                                      : null,
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 2) 현간 이동 16:9 고유 시네마틱 모션 영상 프레임
                        Container(
                          decoration: BoxDecoration(
                            color: NightPalette.bgPanel,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: NightPalette.accentGold,
                              width: 2.2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x99000000),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      NightArtRegistry.countyTravelMotionAsset(
                                        spec.fromChapter,
                                      ),
                                      key: ValueKey(spec.motionAssetKey),
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, _, _) => Image.asset(
                                        nextChapterSpec.bgAsset,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      top: 10,
                                      right: 10,
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        alignment: WrapAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xDD0B1324),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: NightPalette.accentGold,
                                              ),
                                            ),
                                            child: Text(
                                              spec.travelVehicleBadge,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: NightPalette.accentGold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isFromCountyCleared
                                                  ? const Color(0xDD11353B)
                                                  : const Color(0xDD282238),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isFromCountyCleared
                                                    ? NightPalette.jadeGreen
                                                    : NightPalette.accentGold,
                                              ),
                                            ),
                                            child: Text(
                                              isFromCountyCleared
                                                  ? '✓ 제${spec.fromChapter}현 10판 정화 완수!'
                                                  : '⏳ 제${spec.fromChapter}현 수호 중 ($clearedInFromCounty/10판)',
                                              style: TextStyle(
                                                fontSize: 11.8,
                                                fontWeight: FontWeight.bold,
                                                color: isFromCountyCleared
                                                    ? NightPalette.jadeGreen
                                                    : NightPalette.accentGold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          20,
                                          12,
                                          10,
                                        ),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Color(0xEB09101E),
                                            ],
                                          ),
                                        ),
                                        child: AnimatedBuilder(
                                          animation: _routePulse,
                                          builder: (context, _) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        spec.fromCountyName,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 12.2,
                                                          color: NightPalette
                                                              .jadeGreen,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .double_arrow_rounded,
                                                        size: 18,
                                                        color: NightPalette
                                                            .accentGold,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        spec.toCountyName,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 13.0,
                                                          color: NightPalette
                                                              .accentGold,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  child:
                                                      LinearProgressIndicator(
                                                    value: 0.25 +
                                                        0.75 *
                                                            _routePulse.value,
                                                    minHeight: 7,
                                                    color:
                                                        NightPalette.accentGold,
                                                    backgroundColor:
                                                        const Color(0x66283B5B),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 2.5) 10대 현 대륙도 실제 도로 행군 실시간 연동 스트립
                              Container(
                                color: const Color(0xFF070F1D),
                                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                child: AnimatedBuilder(
                                  animation: _routePulse,
                                  builder: (context, _) {
                                    return ContinentalRealRoadMapWidget(
                                      key: const Key(
                                        'county_transition_continental_map',
                                      ),
                                      controller: widget.controller,
                                      selectedChapterNumber: spec.toChapter,
                                      interactive: false,
                                      compact: true,
                                      maxHeight: 162,
                                      marchFromChapter: spec.fromChapter,
                                      externalMarchProgress:
                                          0.08 + 0.92 * _routePulse.value,
                                    );
                                  },
                                ),
                              ),

                              // 3) 한지 서사 두루마리 & 새 현 개방 특전 안내
                              Container(
                                color: NightPalette.hanjiLight,
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      spec.travelTitle,
                                      style: const TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 17.5,
                                        color: NightPalette.hanjiInk,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    for (final line in spec.narrationLines)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 5),
                                        child: Text(
                                          '• $line',
                                          style: const TextStyle(
                                            fontSize: 13.2,
                                            height: 1.42,
                                            color: NightPalette.hanjiInk,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF152238),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: NightPalette.accentGold,
                                        ),
                                      ),
                                      child: Text(
                                        '✨ 새 현 개방 특전: ${spec.unlockHighlight}',
                                        style: const TextStyle(
                                          fontSize: 12.4,
                                          color: NightPalette.accentGold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 4) 연속 수호 행군 자동 입성 안내 바 (승리 후 다음 현 이동 시 5.2초 감상 후 다음 현 1번 마을로 쭉 이어짐!)
                        if (widget.openedFromVictory &&
                            widget.controller.continuousVillageMarch &&
                            !_autoEnterPaused) ...[
                          AnimatedBuilder(
                            animation: _autoEnterAnim,
                            builder: (context, _) {
                              final remainSec = ((1.0 - _autoEnterAnim.value) *
                                      5.2)
                                  .ceil()
                                  .clamp(1, 6);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xEE102432),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: NightPalette.jadeGreen,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          '🏃 연속 마을 수호 중 · $remainSec초 뒤 제${spec.toChapter}현 첫 마을 [${nextFirstStage.villageNodeName}] 자동 입성!',
                                          style: const TextStyle(
                                            fontSize: 12.2,
                                            fontWeight: FontWeight.bold,
                                            color: NightPalette.jadeGreen,
                                          ),
                                        ),
                                        TextButton.icon(
                                          key: const Key(
                                            'county_trans_pause_auto_btn',
                                          ),
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          onPressed: () {
                                            _autoEnterAnim.stop();
                                            setState(() {
                                              _autoEnterPaused = true;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.pause_circle_outline_rounded,
                                            size: 16,
                                            color: NightPalette.accentGold,
                                          ),
                                          label: const Text(
                                            '자동입성 멈춤',
                                            style: TextStyle(
                                              fontSize: 11.8,
                                              color: NightPalette.accentGold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _autoEnterAnim.value,
                                        minHeight: 6,
                                        color: NightPalette.jadeGreen,
                                        backgroundColor: Colors.white12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],

                        // 5) 하단 행군 도착 행동 단추 (현내 10마을 지도 열람 or 다음 현 1판 즉시 출정)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              key: const Key('county_trans_map_btn'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(210, 46),
                                side: const BorderSide(
                                  color: NightPalette.accentGold,
                                  width: 1.4,
                                ),
                              ),
                              onPressed: () {
                                _didNavigate = true;
                                _autoEnterAnim.stop();
                                widget.controller
                                    .setSelectedChapter(spec.toChapter);
                                if (widget.openedFromVictory) {
                                  Navigator.of(context).pushReplacement(
                                    buildSmoothScreenRoute(
                                      CampaignScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(Icons.map_rounded),
                              label: Text(
                                '제${spec.toChapter}현 10마을 지도 보기',
                              ),
                            ),
                            FilledButton.icon(
                              key: const Key('county_trans_battle_btn'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(240, 46),
                                backgroundColor: NightPalette.accentGold,
                                foregroundColor: NightPalette.hanjiInk,
                              ),
                              onPressed: p.isStageUnlocked(nextFirstStage)
                                  ? _launchNextCountyFirstVillage
                                  : null,
                              icon: Icon(
                                p.isStageUnlocked(nextFirstStage)
                                    ? Icons.rocket_launch_rounded
                                    : Icons.lock_outline_rounded,
                              ),
                              label: Text(
                                p.isStageUnlocked(nextFirstStage)
                                    ? '제${spec.toChapter}현 1판 [${nextFirstStage.villageNodeName}] 출정!'
                                    : '제${spec.fromChapter}현 10판 정화 시 개방',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}

/// 어느 메뉴(진법·대장간·수련·보급·도감·무한혈전)에 있든 탭 복귀 없이 즉시 다음 판 출정·10현 100판 지도·타 메뉴로 점프하는 공용 상단 바.
class QuickPlayAndMenuBar extends StatelessWidget {
  const QuickPlayAndMenuBar({
    super.key,
    required this.controller,
    required this.currentSection,
    this.embeddedInShell = false,
    this.onSwitchShellTab,
  });

  final GameController controller;
  final String currentSection; // 'loadout', 'forge', 'supply', 'codex', 'endless'
  final bool embeddedInShell;
  final ValueChanged<int>? onSwitchShellTab;

  void _jumpOrSwitch(
    BuildContext context, {
    required int shellTabIndex,
    required Widget Function() builder,
  }) {
    NightAudioController.instance.playAsset('ui_tap.ogg');
    if (embeddedInShell && onSwitchShellTab != null) {
      onSwitchShellTab!(shellTabIndex);
      return;
    }
    final route = buildSmoothScreenRoute(builder());
    if (embeddedInShell) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.progress;
        final totalStages = CampaignCatalog.allStages.length;
        final nextIdx =
            (p.highestClearedGlobalStage + 1).clamp(1, totalStages);
        final nextStage = CampaignCatalog.allStages[nextIdx - 1];
        final allDone = p.highestClearedGlobalStage >= totalStages;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xF2141F34),
            border: Border(
              bottom: BorderSide(
                color: NightPalette.borderGold.withValues(alpha: 0.34),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilledButton.icon(
                  key: Key('quick_bar_battle_$currentSection'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(118, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    backgroundColor: NightPalette.accentGold,
                    foregroundColor: NightPalette.hanjiInk,
                  ),
                  onPressed: () {
                    NightAudioController.instance.playAsset('ui_tap.ogg');
                    Navigator.of(context).push(
                      buildSmoothBattleRoute(
                        controller: controller,
                        stage: nextStage,
                      ),
                    );
                  },
                  icon: const Icon(Icons.flash_on_rounded, size: 15),
                  label: Text(
                    allDone
                        ? '바로 재출정 (${nextStage.code})'
                        : '바로 출정 (${nextStage.code})',
                    style: const TextStyle(
                      fontSize: 11.8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  key: Key('quick_bar_map_$currentSection'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(102, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    side: BorderSide(
                      color: NightPalette.accentGold.withValues(alpha: 0.72),
                    ),
                  ),
                  onPressed: () {
                    NightAudioController.instance.playAsset('ui_tap.ogg');
                    final route = buildSmoothScreenRoute(
                      CampaignScreen(controller: controller),
                    );
                    if (embeddedInShell) {
                      Navigator.of(context).push(route);
                    } else {
                      Navigator.of(context).pushReplacement(route);
                    }
                  },
                  icon: const Icon(Icons.map_rounded, size: 14),
                  label: Text(
                    '10현·100판 (${p.highestClearedGlobalStage}/$totalStages)',
                    style: const TextStyle(fontSize: 11.4),
                  ),
                ),
                if (currentSection != 'endless') ...[
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    key: Key('quick_bar_endless_$currentSection'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(82, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      side: BorderSide(
                        color: NightPalette.jadeGreen.withValues(alpha: 0.72),
                      ),
                    ),
                    onPressed: () {
                      NightAudioController.instance.playAsset('ui_tap.ogg');
                      final route = buildSmoothScreenRoute(
                        EndlessSurvivalScreen(controller: controller),
                      );
                      if (embeddedInShell) {
                        Navigator.of(context).push(route);
                      } else {
                        Navigator.of(context).pushReplacement(route);
                      }
                    },
                    icon: const Icon(
                      Icons.all_inclusive_rounded,
                      size: 14,
                      color: NightPalette.jadeGreen,
                    ),
                    label: const Text(
                      '무한혈전',
                      style: TextStyle(
                        fontSize: 11.2,
                        color: NightPalette.jadeGreen,
                      ),
                    ),
                  ),
                ],
                if (embeddedInShell) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NightPalette.bgDeep,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: NightPalette.borderGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '🪙${p.tokens} · 🧪${p.elixirs} · 🎺${p.supportTokens}',
                      style: const TextStyle(
                        fontSize: 11.2,
                        fontWeight: FontWeight.bold,
                        color: NightPalette.accentGold,
                      ),
                    ),
                  ),
                ] else ...[
                  if (currentSection != 'loadout') ...[
                    const SizedBox(width: 6),
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: const Text(
                        '🛡️진법',
                        style: TextStyle(fontSize: 11.4),
                      ),
                      onPressed: () => _jumpOrSwitch(
                        context,
                        shellTabIndex: 1,
                        builder: () => LoadoutScreen(controller: controller),
                      ),
                    ),
                  ],
                  if (currentSection != 'forge') ...[
                    const SizedBox(width: 6),
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: const Text(
                        '⚒️대장간',
                        style: TextStyle(fontSize: 11.4),
                      ),
                      onPressed: () => _jumpOrSwitch(
                        context,
                        shellTabIndex: 2,
                        builder: () => UpgradeScreen(controller: controller),
                      ),
                    ),
                  ],
                  if (currentSection != 'supply') ...[
                    const SizedBox(width: 6),
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: const Text(
                        '🧘수련',
                        style: TextStyle(fontSize: 11.4),
                      ),
                      onPressed: () => _jumpOrSwitch(
                        context,
                        shellTabIndex: 3,
                        builder: () => TrainingScreen(controller: controller),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 마을 수호 승리 시 인근 다음 마을(또는 다음 현 대행군)로 끊김 없이 이어 주는 연속 마을 수호 행군 카드.
class VictoryContinuousMarchCard extends StatefulWidget {
  const VictoryContinuousMarchCard({
    super.key,
    required this.controller,
    required this.clearedStage,
    required this.nextStage,
    required this.onAdvanceNow,
  });

  final GameController controller;
  final StageSpec clearedStage;
  final StageSpec nextStage;
  final VoidCallback onAdvanceNow;

  @override
  State<VictoryContinuousMarchCard> createState() =>
      _VictoryContinuousMarchCardState();
}

class _VictoryContinuousMarchCardState extends State<VictoryContinuousMarchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdownAnim;
  bool _pausedHere = false;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _countdownAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            mounted &&
            !_pausedHere &&
            !_triggered &&
            widget.controller.continuousVillageMarch) {
          _triggered = true;
          widget.onAdvanceNow();
        }
      });
    if (widget.controller.continuousVillageMarch) {
      _countdownAnim.forward();
    }
  }

  @override
  void dispose() {
    _countdownAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final contOn =
            widget.controller.continuousVillageMarch && !_pausedHere;
        final isCountyFinale =
            widget.nextStage.chapterNumber != widget.clearedStage.chapterNumber;
        final chSpec =
            CampaignCatalog.chapterOf(widget.clearedStage.chapterNumber);
        final countyStages =
            CampaignCatalog.stagesOfChapter(widget.clearedStage.chapterNumber);

        return Container(
          key: const Key('victory_continuous_march_card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF102234),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCountyFinale
                  ? NightPalette.accentGold
                  : NightPalette.jadeGreen,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    isCountyFinale
                        ? '🏯 ${chSpec.shortCountyName} 10개 마을 전부 수호 완료! ➔ 제${widget.nextStage.chapterNumber}현 대행군'
                        : '🏘️ [${widget.clearedStage.villageNodeName}] 수호 완료 ➔ 인근 마을 [${widget.nextStage.villageNodeName}] 이동',
                    style: TextStyle(
                      fontSize: 12.6,
                      fontWeight: FontWeight.bold,
                      color: isCountyFinale
                          ? NightPalette.accentGold
                          : NightPalette.jadeGreen,
                    ),
                  ),
                  ActionChip(
                    key: const Key('victory_toggle_continuous_btn'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: contOn
                        ? const Color(0xFF1A463B)
                        : const Color(0xFF2B3548),
                    label: Text(
                      contOn
                          ? '🏃연속이동 ON (터치시 정지)'
                          : (!widget.controller.continuousVillageMarch
                              ? '⏸️연속수호 OFF (터치시 켜기)'
                              : '⏸️이번 판 정지됨 (터치시 재개)'),
                      style: TextStyle(
                        fontSize: 11.0,
                        color: contOn
                            ? NightPalette.jadeGreen
                            : NightPalette.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (contOn) {
                        _countdownAnim.stop();
                        setState(() => _pausedHere = true);
                      } else {
                        widget.controller.setContinuousVillageMarch(true);
                        setState(() => _pausedHere = false);
                        _countdownAnim.forward(from: 0.0);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!isCountyFinale) ...[
                AnimatedBuilder(
                  animation: _countdownAnim,
                  builder: (context, _) {
                    return CountyRealRoadMapWidget(
                      key: const Key('victory_live_road_map'),
                      controller: widget.controller,
                      chSpec: chSpec,
                      stages: countyStages,
                      currentOrderStage: widget.nextStage,
                      allCampaignCleared: false,
                      interactive: false,
                      compact: true,
                      maxHeight: 158,
                      marchFromStage: widget.clearedStage.stageNumber,
                      externalMarchProgress:
                          contOn ? _countdownAnim.value : 0.45,
                    );
                  },
                ),
                const SizedBox(height: 8),
              ] else ...[
                AnimatedBuilder(
                  animation: _countdownAnim,
                  builder: (context, _) {
                    return ContinentalRealRoadMapWidget(
                      key: const Key('victory_live_continental_map'),
                      controller: widget.controller,
                      selectedChapterNumber: widget.nextStage.chapterNumber,
                      interactive: false,
                      compact: true,
                      maxHeight: 162,
                      marchFromChapter: widget.clearedStage.chapterNumber,
                      externalMarchProgress:
                          contOn ? _countdownAnim.value : 0.48,
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              // 현내 1~10번 마을 징검다리 행군 표시줄
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(countyStages.length, (i) {
                    final st = countyStages[i];
                    final done =
                        st.stageNumber <= widget.clearedStage.stageNumber;
                    final isNextTarget = !isCountyFinale &&
                        st.stageNumber == widget.nextStage.stageNumber;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isNextTarget
                                ? NightPalette.accentGold
                                : (done
                                    ? const Color(0xFF174A40)
                                    : const Color(0xFF1A253A)),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: isNextTarget
                                  ? Colors.white
                                  : (done
                                      ? NightPalette.jadeGreen
                                      : Colors.white24),
                            ),
                          ),
                          child: Text(
                            '${done ? "✓" : (isNextTarget ? "🏃" : "")}${st.stageNumber}.${st.villageNodeName}',
                            style: TextStyle(
                              fontSize: 10.4,
                              fontWeight: FontWeight.bold,
                              color: isNextTarget
                                  ? NightPalette.hanjiInk
                                  : (done
                                      ? NightPalette.jadeGreen
                                      : NightPalette.textMuted),
                            ),
                          ),
                        ),
                        if (i < countyStages.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: done
                                  ? NightPalette.accentGold
                                  : Colors.white24,
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
              if (contOn) ...[
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _countdownAnim,
                  builder: (context, _) {
                    final remSec = ((1.0 - _countdownAnim.value) * 3.2)
                        .ceil()
                        .clamp(1, 4);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isCountyFinale
                              ? '🎬 $remSec초 뒤 제${widget.nextStage.chapterNumber}현 대행군 이동 영상이 자동 시작됩니다...'
                              : '🏃 $remSec초 뒤 인근 마을 [${widget.nextStage.villageNodeName} (${widget.nextStage.code})] 수호전으로 자동 진입합니다...',
                          style: const TextStyle(
                            fontSize: 11.4,
                            color: NightPalette.accentGold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _countdownAnim.value,
                            minHeight: 6,
                            color: NightPalette.accentGold,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 제1현~제10현 전용 코덱스 실측 지형·도로 조감도(`county_map_ch1..10.webp`, 16:9) 위에서
/// 실제 등불 돌길·운하교·잔도·무지개운교 곡선을 따라 마을마다 행군하는 고해상도 지도 위젯.
class CountyRealRoadMapWidget extends StatefulWidget {
  const CountyRealRoadMapWidget({
    super.key,
    required this.controller,
    required this.chSpec,
    required this.stages,
    required this.currentOrderStage,
    required this.allCampaignCleared,
    this.interactive = true,
    this.compact = false,
    this.maxHeight = 320,
    this.marchFromStage,
    this.externalMarchProgress,
  });

  final GameController controller;
  final ChapterSpec chSpec;
  final List<StageSpec> stages;
  final StageSpec currentOrderStage;
  final bool allCampaignCleared;
  final bool interactive;
  final bool compact;
  final double maxHeight;
  final int? marchFromStage;
  final double? externalMarchProgress;

  @override
  State<CountyRealRoadMapWidget> createState() =>
      _CountyRealRoadMapWidgetState();
}

class _CountyRealRoadMapWidgetState extends State<CountyRealRoadMapWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _patrolAnim;

  @override
  void initState() {
    super.initState();
    if (widget.externalMarchProgress == null) {
      _patrolAnim = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3600),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant CountyRealRoadMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalMarchProgress == null && _patrolAnim == null) {
      _patrolAnim = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3600),
      )..repeat();
    } else if (widget.externalMarchProgress != null && _patrolAnim != null) {
      _patrolAnim!.dispose();
      _patrolAnim = null;
    }
  }

  @override
  void dispose() {
    _patrolAnim?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.progress;
    int clearedInCounty = 0;
    for (final s in widget.stages) {
      if (s.globalIndex <= progress.highestClearedGlobalStage) {
        clearedInCounty++;
      }
    }

    final int activeFromStage = (widget.marchFromStage ??
            (clearedInCounty >= 10
                ? 9
                : (clearedInCounty <= 0 ? 1 : clearedInCounty)))
        .clamp(1, 9);

    final smoothedSegments = List<List<Offset>>.generate(9, (idx) {
      return widget.chSpec
          .smoothedCountyRoadSegment(idx)
          .map((v) => Offset(v.x, v.y))
          .toList(growable: false);
    }, growable: false);

    Widget buildMapFrame(double animPhase) {
      final double rawT = widget.externalMarchProgress ?? animPhase;
      final double effectiveMarchT = (clearedInCounty == 0 &&
              widget.marchFromStage == null &&
              !widget.allCampaignCleared)
          ? (0.04 + 0.18 * (0.5 - 0.5 * math.cos(rawT * math.pi * 2.0)))
          : rawT.clamp(0.0, 1.0);
      final marchVec = widget.chSpec.sampleCountyRoadMarch(
        activeFromStage,
        effectiveMarchT,
      );

      final StageSpec focusStage = widget.marchFromStage != null
          ? widget.stages[activeFromStage.clamp(1, widget.stages.length - 1)]
          : (clearedInCounty >= 10
              ? widget.stages.last
              : widget.stages[clearedInCounty.clamp(0, widget.stages.length - 1)]);

      return Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        decoration: BoxDecoration(
          color: const Color(0xFF08101E),
          borderRadius: widget.compact
              ? BorderRadius.circular(12)
              : BorderRadius.zero,
          border: widget.compact
              ? Border.all(
                  color: NightPalette.accentGold.withValues(alpha: 0.65),
                  width: 1.2,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 와이드 태블릿 여백에도 중복 건물 없이 은은하게 이어지는 블러 야경 배경
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Opacity(
                  opacity: 0.42,
                  child: Image.asset(
                    NightArtRegistry.countyRegionalMapAsset(
                      widget.chSpec.number,
                    ),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: ColoredBox(color: Color(0x66060C18)),
            ),
            // 1344:768 (16:9) 정비율 고정 실측 지도 프레임 (모든 해상도에서 도로 좌표 1:1 완전 일치!)
            Center(
              child: AspectRatio(
                aspectRatio: 1344.0 / 768.0,
                child: LayoutBuilder(
                  builder: (ctx, box) {
                    final w = box.maxWidth;
                    final h = box.maxHeight;
                    final heroPx = (marchVec.x * w).clamp(18.0, w - 18.0);
                    final heroPy = (marchVec.y * h).clamp(18.0, h - 18.0);
                    final double avatarSize = widget.compact ? 22.0 : 28.0;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          NightArtRegistry.countyRegionalMapAsset(
                            widget.chSpec.number,
                          ),
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => Image.asset(
                            widget.chSpec.bgAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // 원화 등불과 물결 색감을 살리는 가장자리 미세 비네팅
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.96,
                              colors: [
                                Colors.transparent,
                                const Color(0x52050B16),
                              ],
                              stops: const [0.64, 1.0],
                            ),
                          ),
                        ),
                        // 실제 지형 도로 곡선 · 등불 발자국 · 행군 궤적 페인터
                        CustomPaint(
                          painter: _CountyRealRoadPainter(
                            segments: smoothedSegments,
                            clearedCountInCounty: clearedInCounty,
                            activeSegmentIndex: activeFromStage - 1,
                            marchProgress: effectiveMarchT,
                            dashPhase: animPhase,
                            compact: widget.compact,
                          ),
                        ),
                        // 1~10번 마을 거점 명패 노드
                        for (int i = 0; i < widget.stages.length; i++)
                          _buildVillagePin(
                            context: context,
                            st: widget.stages[i],
                            progress: progress,
                            mapW: w,
                            mapH: h,
                          ),
                        // 실제 도로 곡선을 따라 마을에서 다음 마을로 걸어가는 수호대 행군 마커!
                        Positioned(
                          left: heroPx - avatarSize * 0.5,
                          top: heroPy - avatarSize * 0.65,
                          width: avatarSize,
                          height: avatarSize,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10243A),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.8,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xCCFFD166),
                                    blurRadius: 10,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                NightArtRegistry.charFace('seokdu'),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.directions_run_rounded,
                                  size: 14,
                                  color: NightPalette.accentGold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 하단 현·마을 도로 안내 명패 (말줄임 잘림 없는 깔끔한 지도 범례)
                        if (!widget.compact)
                          Positioned(
                            left: 8,
                            bottom: 6,
                            right: 8,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xE60A1324),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: NightPalette.accentGold
                                        .withValues(alpha: 0.72),
                                  ),
                                ),
                                child: Text(
                                  '🗺️ ${widget.chSpec.countyName} ($clearedInCounty/10마을) · 현재 가도: [${focusStage.villageNodeName}] · 마을 터치 즉시 출정',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.6,
                                    fontWeight: FontWeight.bold,
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_patrolAnim != null) {
      return AnimatedBuilder(
        animation: _patrolAnim!,
        builder: (context, _) => buildMapFrame(_patrolAnim!.value),
      );
    }
    return buildMapFrame(widget.externalMarchProgress ?? 0.5);
  }

  Widget _buildVillagePin({
    required BuildContext context,
    required StageSpec st,
    required PlayerProgress progress,
    required double mapW,
    required double mapH,
  }) {
    final unlocked = progress.isStageUnlocked(st);
    final cleared = st.globalIndex <= progress.highestClearedGlobalStage;
    final isCurrent = !widget.allCampaignCleared &&
        st.globalIndex == widget.currentOrderStage.globalIndex;
    final isNextMarchTarget = widget.marchFromStage != null &&
        st.stageNumber == widget.marchFromStage! + 1;
    final norm = st.villageMapCoord;

    final double pinW = widget.compact
        ? (st.stageNumber == 10 ? 40.0 : 32.0)
        : (st.stageNumber == 10 ? 58.0 : 46.0);
    final double pinH = widget.compact ? 18.0 : 23.0;
    final px = (norm.x * mapW).clamp(pinW * 0.52, mapW - pinW * 0.52);
    final py = (norm.y * mapH).clamp(pinH * 0.55, mapH - (widget.compact ? 12.0 : 26.0));

    final bool highlightGold = isCurrent || isNextMarchTarget;
    final Color bgCol = highlightGold
        ? NightPalette.accentGold
        : (cleared
            ? const Color(0xEA14493E)
            : (unlocked
                ? const Color(0xEA8B2929)
                : const Color(0xCF0E1728)));
    final Color fgCol = highlightGold
        ? NightPalette.hanjiInk
        : (unlocked ? NightPalette.textPrimary : NightPalette.textMuted);

    final String prefix = unlocked
        ? (highlightGold ? '⚔️' : (cleared ? '✓' : '▶'))
        : '🔒';
    final String labelText = widget.compact
        ? '$prefix${st.stageNumber}'
        : (st.stageNumber == 10
            ? '${prefix}10성👑'
            : '$prefix${st.stageNumber}판');

    final badge = Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightGold
              ? Colors.white
              : (st.isBossStage
                  ? NightPalette.crimsonMoon
                  : (unlocked
                      ? NightPalette.accentGold
                      : NightPalette.borderGold.withValues(alpha: 0.35))),
          width: highlightGold ? 1.9 : 1.15,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          labelText,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: widget.compact ? 9.4 : 10.6,
            fontWeight: FontWeight.w800,
            color: fgCol,
          ),
        ),
      ),
    );

    return Positioned(
      left: px - pinW * 0.5,
      top: py - pinH * 0.5,
      width: pinW,
      height: pinH,
      child: widget.interactive
          ? GestureDetector(
              key: Key('village_node_${st.code}'),
              onTap: unlocked
                  ? () {
                      Navigator.of(context).push(
                        buildSmoothBattleRoute(
                          controller: widget.controller,
                          stage: st,
                        ),
                      );
                    }
                  : null,
              child: badge,
            )
          : badge,
    );
  }
}

class _CountyRealRoadPainter extends CustomPainter {
  const _CountyRealRoadPainter({
    required this.segments,
    required this.clearedCountInCounty,
    required this.activeSegmentIndex,
    required this.marchProgress,
    required this.dashPhase,
    required this.compact,
  });

  final List<List<Offset>> segments;
  final int clearedCountInCounty;
  final int activeSegmentIndex;
  final double marchProgress;
  final double dashPhase;
  final bool compact;

  Path _buildScaledPath(List<Offset> pts, Size size) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx * size.width, pts.first.dy * size.height);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }
    return path;
  }

  void _drawSteppingStones(
    Canvas canvas,
    List<Offset> pts,
    Size size, {
    required Color color,
    required double radius,
    int stride = 3,
  }) {
    final dotPaint = Paint()..color = color;
    for (int i = stride; i < pts.length - 1; i += stride) {
      canvas.drawCircle(
        Offset(pts[i].dx * size.width, pts[i].dy * size.height),
        radius,
        dotPaint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final casingPaint = Paint()
      ..color = const Color(0xB508111F)
      ..strokeWidth = compact ? 4.4 : 5.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final clearedGlowPaint = Paint()
      ..color = const Color(0x58FFD166)
      ..strokeWidth = compact ? 7.0 : 9.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final clearedRoadPaint = Paint()
      ..color = const Color(0xF2FFD166)
      ..strokeWidth = compact ? 2.2 : 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final activeWalkedGlow = Paint()
      ..color = const Color(0x884EE3C0)
      ..strokeWidth = compact ? 7.5 : 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final activeWalkedLine = Paint()
      ..color = const Color(0xFF4EE3C0)
      ..strokeWidth = compact ? 2.5 : 3.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final lockedCasingPaint = Paint()
      ..color = const Color(0x9908111F)
      ..strokeWidth = compact ? 3.0 : 3.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final lockedRoadPaint = Paint()
      ..color = const Color(0x68CBD5E1)
      ..strokeWidth = compact ? 1.4 : 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (int segIdx = 0; segIdx < segments.length; segIdx++) {
      final pts = segments[segIdx];
      if (pts.length < 2) continue;
      final fullPath = _buildScaledPath(pts, size);
      final bool isSegmentCleared = (segIdx + 2) <= clearedCountInCounty;
      final bool isActiveMarch = segIdx == activeSegmentIndex;

      if (isSegmentCleared && !(isActiveMarch && clearedCountInCounty < 10)) {
        canvas.drawPath(fullPath, clearedGlowPaint);
        canvas.drawPath(fullPath, casingPaint);
        canvas.drawPath(fullPath, clearedRoadPaint);
        _drawSteppingStones(
          canvas,
          pts,
          size,
          color: const Color(0xEEFFF6CC),
          radius: compact ? 1.2 : 1.6,
          stride: 4,
        );
      } else if (isActiveMarch) {
        canvas.drawPath(fullPath, casingPaint);
        final int splitIdx =
            ((pts.length - 1) * marchProgress.clamp(0.0, 1.0)).round();
        if (splitIdx >= 1) {
          final walkedPts = pts.sublist(0, splitIdx + 1);
          final walkedPath = _buildScaledPath(walkedPts, size);
          canvas.drawPath(walkedPath, activeWalkedGlow);
          canvas.drawPath(walkedPath, activeWalkedLine);
        }
        // 전방 이동 예정 도로 위에 흐르는 등불 발자국 점선 표시
        final aheadDotPaint = Paint()..color = const Color(0xEEFF9F43);
        final phaseShift = ((dashPhase * 6.0).floor()) % 3;
        for (int i = math.max(1, splitIdx); i < pts.length - 1; i++) {
          if ((i + phaseShift) % 3 == 0) {
            canvas.drawCircle(
              Offset(pts[i].dx * size.width, pts[i].dy * size.height),
              compact ? 1.6 : 2.2,
              aheadDotPaint,
            );
          }
        }
      } else {
        canvas.drawPath(fullPath, lockedCasingPaint);
        canvas.drawPath(fullPath, lockedRoadPaint);
        _drawSteppingStones(
          canvas,
          pts,
          size,
          color: const Color(0x7794A3B8),
          radius: compact ? 1.0 : 1.3,
          stride: 5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CountyRealRoadPainter oldDelegate) =>
      oldDelegate.clearedCountInCounty != clearedCountInCounty ||
      oldDelegate.activeSegmentIndex != activeSegmentIndex ||
      (oldDelegate.marchProgress - marchProgress).abs() > 0.004 ||
      (oldDelegate.dashPhase - dashPhase).abs() > 0.01;
}

/// 10대 현 대륙도(`world_map_murim_night.webp` 1440×960 / `world_map_live.webp` 768×512) 위에서
/// 제1현~제10현을 잇는 실제 황금 등불 가도·석교·횃불 산길·백옥교·해상장교·운해계단을 따라
/// 수호대 영웅이 마을 지도처럼 실시간 행군 및 터치 이동하는 대륙 실측 도로 위젯.
class ContinentalRealRoadMapWidget extends StatefulWidget {
  const ContinentalRealRoadMapWidget({
    super.key,
    required this.controller,
    required this.selectedChapterNumber,
    this.interactive = true,
    this.compact = false,
    this.maxHeight = 340,
    this.marchFromChapter,
    this.externalMarchProgress,
  });

  final GameController controller;
  final int selectedChapterNumber;
  final bool interactive;
  final bool compact;
  final double maxHeight;
  final int? marchFromChapter;
  final double? externalMarchProgress;

  @override
  State<ContinentalRealRoadMapWidget> createState() =>
      _ContinentalRealRoadMapWidgetState();
}

class _ContinentalRealRoadMapWidgetState
    extends State<ContinentalRealRoadMapWidget> with TickerProviderStateMixin {
  AnimationController? _patrolAnim;
  late final AnimationController _journeyAnim;
  int? _journeyFromChapter;
  int? _journeyToChapter;

  @override
  void initState() {
    super.initState();
    _journeyAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _journeyFromChapter = null;
            _journeyToChapter = null;
          });
        }
      });

    if (widget.externalMarchProgress == null) {
      _patrolAnim = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3400),
      )..repeat();
    }
  }

  void _triggerRealRoadJourney(int fromCh, int toCh) {
    final safeFrom = fromCh.clamp(1, 10);
    final safeTo = toCh.clamp(1, 10);
    if (safeFrom == safeTo || widget.externalMarchProgress != null) return;
    final hopCount = (safeTo - safeFrom).abs();
    _journeyAnim.duration = Duration(
      milliseconds: (780 + hopCount * 145).clamp(900, 1950),
    );
    setState(() {
      _journeyFromChapter = safeFrom;
      _journeyToChapter = safeTo;
    });
    _journeyAnim.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant ContinentalRealRoadMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalMarchProgress == null && _patrolAnim == null) {
      _patrolAnim = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3400),
      )..repeat();
    } else if (widget.externalMarchProgress != null && _patrolAnim != null) {
      _patrolAnim!.dispose();
      _patrolAnim = null;
    }

    if (widget.externalMarchProgress == null &&
        oldWidget.selectedChapterNumber != widget.selectedChapterNumber) {
      final startCh = _journeyToChapter ?? oldWidget.selectedChapterNumber;
      if (startCh != widget.selectedChapterNumber) {
        _triggerRealRoadJourney(startCh, widget.selectedChapterNumber);
      }
    }
  }

  @override
  void dispose() {
    _patrolAnim?.dispose();
    _journeyAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.progress;
    final allDone =
        progress.highestClearedGlobalStage >= CampaignCatalog.allStages.length;
    final unlockedChapter = progress.highestUnlockedChapter.clamp(1, 10);
    final selCh = widget.selectedChapterNumber.clamp(1, 10);

    final smoothedSegments = List<List<Offset>>.generate(9, (idx) {
      return CampaignCatalog.smoothedContinentalRoadSegment(idx)
          .map((v) => Offset(v.x, v.y))
          .toList(growable: false);
    }, growable: false);

    Widget buildContinentalFrame(double patrolPhase, double journeyT) {
      final bool isJourneyActive = widget.externalMarchProgress == null &&
          _journeyFromChapter != null &&
          _journeyToChapter != null &&
          _journeyAnim.isAnimating;

      late final Vec2 heroVec;
      int activeSegmentIndex = -1;
      double segmentMarchProgress = 0.0;
      List<Offset>? customJourneyPts;
      double customJourneyProgress = 0.0;

      if (widget.marchFromChapter != null) {
        final fromCh = widget.marchFromChapter!.clamp(1, 9);
        activeSegmentIndex = fromCh - 1;
        segmentMarchProgress =
            (widget.externalMarchProgress ?? patrolPhase).clamp(0.0, 1.0);
        heroVec = CampaignCatalog.sampleContinentalRoadMarch(
          fromCh,
          segmentMarchProgress,
        );
      } else if (isJourneyActive) {
        final easedT = Curves.easeInOutCubic.transform(journeyT.clamp(0.0, 1.0));
        customJourneyProgress = easedT;
        customJourneyPts = CampaignCatalog.continentalJourneyPolyline(
          _journeyFromChapter!,
          _journeyToChapter!,
        ).map((v) => Offset(v.x, v.y)).toList(growable: false);
        heroVec = CampaignCatalog.sampleContinentalJourney(
          _journeyFromChapter!,
          _journeyToChapter!,
          easedT,
        );
      } else {
        final int patrolFromCh =
            selCh <= 1 ? 1 : (selCh - 1).clamp(1, 9);
        activeSegmentIndex = patrolFromCh - 1;
        if (selCh == 1 && unlockedChapter <= 1 && !allDone) {
          segmentMarchProgress =
              0.04 + 0.24 * (0.5 - 0.5 * math.cos(patrolPhase * math.pi * 2.0));
        } else {
          segmentMarchProgress = patrolPhase.clamp(0.0, 1.0);
        }
        heroVec = CampaignCatalog.sampleContinentalRoadMarch(
          patrolFromCh,
          segmentMarchProgress,
        );
      }

      final chSpec = CampaignCatalog.chapterOf(selCh);
      final String legendText = isJourneyActive
          ? '🗺️ 탄지무림 10대 거점 심야 수호 대륙도 · 제$_journeyFromChapter현➔제$_journeyToChapter현 실도로 행군 중!'
          : '🗺️ 탄지무림 10대 거점 심야 수호 대륙도 · ${chSpec.shortCountyName} (거점 터치 이동)';

      return Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        decoration: BoxDecoration(
          color: const Color(0xFF08101E),
          borderRadius:
              widget.compact ? BorderRadius.circular(12) : BorderRadius.zero,
          border: widget.compact
              ? Border.all(
                  color: NightPalette.accentGold.withValues(alpha: 0.68),
                  width: 1.2,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Opacity(
                  opacity: 0.42,
                  child: Image.asset(
                    NightArtRegistry.worldMapMurimNight,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: ColoredBox(color: Color(0x66060C18)),
            ),
            Center(
              child: AspectRatio(
                aspectRatio: 1440.0 / 960.0,
                child: LayoutBuilder(
                  builder: (ctx, box) {
                    final w = box.maxWidth;
                    final h = box.maxHeight;
                    final heroPx = (heroVec.x * w).clamp(16.0, w - 16.0);
                    final heroPy = (heroVec.y * h).clamp(16.0, h - 16.0);
                    final double avatarSize = widget.compact ? 22.0 : 29.0;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          NightArtRegistry.worldMapLiveMotion,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => Image.asset(
                            NightArtRegistry.worldMapMurimNight,
                            fit: BoxFit.fill,
                            errorBuilder: (_, _, _) => Image.asset(
                              NightArtRegistry.bgNightLobby,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.96,
                              colors: const [
                                Colors.transparent,
                                Color(0x4D050B16),
                              ],
                              stops: const [0.66, 1.0],
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: _ContinentalRealRoadPainter(
                            segments: smoothedSegments,
                            unlockedChapter: unlockedChapter,
                            allCampaignCleared: allDone,
                            selectedChapter: selCh,
                            activeSegmentIndex: activeSegmentIndex,
                            marchProgress: segmentMarchProgress,
                            dashPhase: patrolPhase,
                            compact: widget.compact,
                            customJourneyPts: customJourneyPts,
                            customJourneyProgress: customJourneyProgress,
                          ),
                        ),
                        for (int i = 0; i < CampaignCatalog.chapters.length; i++)
                          _buildCountyPin(
                            chNum: i + 1,
                            unlockedChapter: unlockedChapter,
                            selectedChapter: selCh,
                            allDone: allDone,
                            mapW: w,
                            mapH: h,
                          ),
                        // 실제 대륙 도로와 다리 곡선을 따라 실시간으로 걸어가는 수호대 영웅 마커!
                        Positioned(
                          left: heroPx - avatarSize * 0.5,
                          top: heroPy - avatarSize * 0.65,
                          width: avatarSize,
                          height: avatarSize,
                          child: IgnorePointer(
                            child: Container(
                              key: const Key('world_map_hero_marker'),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10243A),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.9,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xDD4EE3C0),
                                    blurRadius: 10,
                                    spreadRadius: 1.5,
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                NightArtRegistry.charFace('sabu'),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.directions_walk_rounded,
                                  size: 14,
                                  color: NightPalette.accentGold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!widget.compact)
                          Positioned(
                            right: 8,
                            left: 8,
                            bottom: 5,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xE80A1324),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: NightPalette.accentGold
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    legendText,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontSize: 10.4,
                                      fontWeight: FontWeight.bold,
                                      color: NightPalette.accentGold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    final listenables = <Listenable>[
      ?_patrolAnim,
      _journeyAnim,
    ];
    if (listenables.isNotEmpty) {
      return AnimatedBuilder(
        animation: Listenable.merge(listenables),
        builder: (context, _) => buildContinentalFrame(
          _patrolAnim?.value ?? (widget.externalMarchProgress ?? 0.5),
          _journeyAnim.value,
        ),
      );
    }
    return buildContinentalFrame(widget.externalMarchProgress ?? 0.5, 0.0);
  }

  Widget _buildCountyPin({
    required int chNum,
    required int unlockedChapter,
    required int selectedChapter,
    required bool allDone,
    required double mapW,
    required double mapH,
  }) {
    final unlocked = chNum <= unlockedChapter;
    final bool isMarchNextTarget =
        widget.marchFromChapter != null && chNum == widget.marchFromChapter! + 1;
    final selected = chNum == selectedChapter || isMarchNextTarget;
    final cleared = chNum < unlockedChapter || (chNum == 10 && allDone);
    final norm = CampaignCatalog.continentalCountyCoordAt(chNum);

    final double pinW = widget.compact
        ? (chNum == 10 ? 40.0 : 34.0)
        : (chNum == 10 ? 56.0 : 48.0);
    final double pinH = widget.compact ? 18.0 : 24.0;
    final px = (norm.x * mapW).clamp(pinW * 0.52, mapW - pinW * 0.52);
    final py = (norm.y * mapH)
        .clamp(pinH * 0.55, mapH - (widget.compact ? 11.0 : 24.0));

    final Color pinBg = selected
        ? NightPalette.accentGold
        : (cleared
            ? const Color(0xEE184E44)
            : (unlocked
                ? const Color(0xEE8C2D2D)
                : const Color(0xCC121B2C)));
    final Color pinFg = selected
        ? NightPalette.hanjiInk
        : (unlocked ? NightPalette.textPrimary : NightPalette.textMuted);

    final String statusMark = unlocked ? (cleared ? '✓' : '🔥') : '🔒';
    final String labelText =
        widget.compact ? '$statusMark$chNum' : '$statusMark$chNum현';

    final badge = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: pinBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? Colors.white
              : (unlocked
                  ? NightPalette.accentGold
                  : NightPalette.borderGold.withValues(alpha: 0.35)),
          width: selected ? 1.9 : 1.15,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 4,
            offset: Offset(0, 1.5),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          labelText,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontSize: widget.compact ? 9.2 : 10.5,
            fontWeight: FontWeight.w800,
            color: pinFg,
          ),
        ),
      ),
    );

    return Positioned(
      left: px - pinW * 0.5,
      top: py - pinH * 0.5,
      width: pinW,
      height: pinH,
      child: widget.interactive
          ? GestureDetector(
              key: Key('world_map_pin_$chNum'),
              onTap: unlocked
                  ? () {
                      final prevCh = _journeyToChapter ?? selectedChapter;
                      if (prevCh != chNum) {
                        _triggerRealRoadJourney(prevCh, chNum);
                      }
                      widget.controller.setSelectedChapter(chNum);
                    }
                  : null,
              child: badge,
            )
          : badge,
    );
  }
}

class _ContinentalRealRoadPainter extends CustomPainter {
  const _ContinentalRealRoadPainter({
    required this.segments,
    required this.unlockedChapter,
    required this.allCampaignCleared,
    required this.selectedChapter,
    required this.activeSegmentIndex,
    required this.marchProgress,
    required this.dashPhase,
    required this.compact,
    this.customJourneyPts,
    this.customJourneyProgress = 0.0,
  });

  final List<List<Offset>> segments;
  final int unlockedChapter;
  final bool allCampaignCleared;
  final int selectedChapter;
  final int activeSegmentIndex;
  final double marchProgress;
  final double dashPhase;
  final bool compact;
  final List<Offset>? customJourneyPts;
  final double customJourneyProgress;

  Path _buildScaledPath(List<Offset> pts, Size size) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx * size.width, pts.first.dy * size.height);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }
    return path;
  }

  void _drawSteppingStones(
    Canvas canvas,
    List<Offset> pts,
    Size size, {
    required Color color,
    required double radius,
    int stride = 5,
  }) {
    final dotPaint = Paint()..color = color;
    for (int i = stride; i < pts.length - 1; i += stride) {
      canvas.drawCircle(
        Offset(pts[i].dx * size.width, pts[i].dy * size.height),
        radius,
        dotPaint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final casingPaint = Paint()
      ..color = const Color(0xB808111F)
      ..strokeWidth = compact ? 4.4 : 5.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final clearedGlowPaint = Paint()
      ..color = const Color(0x55FFD166)
      ..strokeWidth = compact ? 7.0 : 9.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final clearedRoadPaint = Paint()
      ..color = const Color(0xF0FFD166)
      ..strokeWidth = compact ? 2.2 : 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final activeWalkedGlow = Paint()
      ..color = const Color(0x904EE3C0)
      ..strokeWidth = compact ? 7.8 : 10.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final activeWalkedLine = Paint()
      ..color = const Color(0xFF4EE3C0)
      ..strokeWidth = compact ? 2.6 : 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final lockedCasingPaint = Paint()
      ..color = const Color(0x9908111F)
      ..strokeWidth = compact ? 3.0 : 3.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final lockedRoadPaint = Paint()
      ..color = const Color(0x68CBD5E1)
      ..strokeWidth = compact ? 1.4 : 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final bool hasCustomJourney =
        customJourneyPts != null && customJourneyPts!.length >= 2;

    for (int segIdx = 0; segIdx < segments.length; segIdx++) {
      final pts = segments[segIdx];
      if (pts.length < 2) continue;
      final fullPath = _buildScaledPath(pts, size);
      final bool isSegmentUnlocked =
          allCampaignCleared || (segIdx + 2) <= unlockedChapter;
      final bool isActiveSegment =
          !hasCustomJourney && segIdx == activeSegmentIndex;

      if (isActiveSegment) {
        if (isSegmentUnlocked) {
          canvas.drawPath(fullPath, clearedGlowPaint);
        }
        canvas.drawPath(fullPath, casingPaint);
        if (isSegmentUnlocked) {
          canvas.drawPath(fullPath, clearedRoadPaint);
        }
        final int splitIdx =
            ((pts.length - 1) * marchProgress.clamp(0.0, 1.0)).round();
        if (splitIdx >= 1) {
          final walkedPts = pts.sublist(0, splitIdx + 1);
          final walkedPath = _buildScaledPath(walkedPts, size);
          canvas.drawPath(walkedPath, activeWalkedGlow);
          canvas.drawPath(walkedPath, activeWalkedLine);
        }
        final aheadDotPaint = Paint()..color = const Color(0xF0FF9F43);
        final phaseShift = ((dashPhase * 8.0).floor()) % 4;
        for (int i = math.max(1, splitIdx); i < pts.length - 1; i++) {
          if ((i + phaseShift) % 4 == 0) {
            canvas.drawCircle(
              Offset(pts[i].dx * size.width, pts[i].dy * size.height),
              compact ? 1.6 : 2.2,
              aheadDotPaint,
            );
          }
        }
      } else if (isSegmentUnlocked) {
        canvas.drawPath(fullPath, clearedGlowPaint);
        canvas.drawPath(fullPath, casingPaint);
        canvas.drawPath(fullPath, clearedRoadPaint);
        _drawSteppingStones(
          canvas,
          pts,
          size,
          color: const Color(0xEEFFF6CC),
          radius: compact ? 1.2 : 1.55,
          stride: 5,
        );
      } else {
        canvas.drawPath(fullPath, lockedCasingPaint);
        canvas.drawPath(fullPath, lockedRoadPaint);
        _drawSteppingStones(
          canvas,
          pts,
          size,
          color: const Color(0x7794A3B8),
          radius: compact ? 1.0 : 1.3,
          stride: 6,
        );
      }
    }

    // 현 터치 이동 시 출발 현부터 도착 현까지 실제 도로 굴곡 전체를 따라 흐르는 실시간 행군 궤적!
    if (hasCustomJourney) {
      final jPts = customJourneyPts!;
      final int splitIdx =
          ((jPts.length - 1) * customJourneyProgress.clamp(0.0, 1.0)).round();
      if (splitIdx >= 1) {
        final walkedPath = _buildScaledPath(jPts.sublist(0, splitIdx + 1), size);
        canvas.drawPath(walkedPath, activeWalkedGlow);
        canvas.drawPath(walkedPath, activeWalkedLine);
      }
      final aheadDotPaint = Paint()..color = const Color(0xFFFF9F43);
      final phaseShift = ((dashPhase * 10.0).floor()) % 4;
      for (int i = math.max(1, splitIdx); i < jPts.length - 1; i++) {
        if ((i + phaseShift) % 4 == 0) {
          canvas.drawCircle(
            Offset(jPts[i].dx * size.width, jPts[i].dy * size.height),
            compact ? 1.7 : 2.3,
            aheadDotPaint,
          );
        }
      }
    }

    if (selectedChapter >= 1 && selectedChapter <= 10) {
      final sel = CampaignCatalog.continentalCountyCoordAt(selectedChapter);
      canvas.drawCircle(
        Offset(sel.x * size.width, sel.y * size.height),
        compact ? 14 : 20,
        Paint()
          ..color = const Color(0x4DFFD166)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ContinentalRealRoadPainter oldDelegate) =>
      oldDelegate.unlockedChapter != unlockedChapter ||
      oldDelegate.allCampaignCleared != allCampaignCleared ||
      oldDelegate.selectedChapter != selectedChapter ||
      oldDelegate.activeSegmentIndex != activeSegmentIndex ||
      (oldDelegate.marchProgress - marchProgress).abs() > 0.004 ||
      (oldDelegate.dashPhase - dashPhase).abs() > 0.01 ||
      oldDelegate.customJourneyPts != customJourneyPts ||
      (oldDelegate.customJourneyProgress - customJourneyProgress).abs() > 0.004;
}
