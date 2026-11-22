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
    widget.controller.applyRecommendedLoadoutForStage(nextFirstStage);
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
        final maxUnlockedTransition =
            (p.highestUnlockedChapter - 1).clamp(1, 9);
        final maxViewable = widget.fromChapter > maxUnlockedTransition
            ? widget.fromChapter.clamp(1, 9)
            : maxUnlockedTransition;

        return Scaffold(
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
                              final unlocked = fromCh <= maxViewable ||
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
                                              color: const Color(0xDD11353B),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: NightPalette.jadeGreen,
                                              ),
                                            ),
                                            child: Text(
                                              '✓ 제${spec.fromChapter}현 10판 정화 완수!',
                                              style: const TextStyle(
                                                fontSize: 11.8,
                                                fontWeight: FontWeight.bold,
                                                color: NightPalette.jadeGreen,
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
                              onPressed: () {
                                if (p.isStageUnlocked(nextFirstStage)) {
                                  _launchNextCountyFirstVillage();
                                } else {
                                  _didNavigate = true;
                                  _autoEnterAnim.stop();
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(Icons.rocket_launch_rounded),
                              label: Text(
                                '제${spec.toChapter}현 1판 [${nextFirstStage.villageNodeName}] 출정!',
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
    Navigator.of(context).push(buildSmoothScreenRoute(builder()));
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
                    minimumSize: const Size(124, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
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
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: Text(
                    allDone
                        ? '바로 재출정 (${nextStage.code})'
                        : '바로 출정 (${nextStage.code} ${nextStage.villageNodeName})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  key: Key('quick_bar_map_$currentSection'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(106, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    side: BorderSide(
                      color: NightPalette.accentGold.withValues(alpha: 0.72),
                    ),
                  ),
                  onPressed: () {
                    NightAudioController.instance.playAsset('ui_tap.ogg');
                    Navigator.of(context).push(
                      buildSmoothScreenRoute(
                        CampaignScreen(controller: controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 15),
                  label: Text(
                    '10현·100판 (${p.highestClearedGlobalStage}/$totalStages)',
                    style: const TextStyle(fontSize: 11.6),
                  ),
                ),
                if (currentSection != 'endless') ...[
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    key: Key('quick_bar_endless_$currentSection'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(86, 34),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      side: BorderSide(
                        color: NightPalette.jadeGreen.withValues(alpha: 0.72),
                      ),
                    ),
                    onPressed: () {
                      NightAudioController.instance.playAsset('ui_tap.ogg');
                      Navigator.of(context).push(
                        buildSmoothScreenRoute(
                          EndlessSurvivalScreen(controller: controller),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.all_inclusive_rounded,
                      size: 15,
                      color: NightPalette.jadeGreen,
                    ),
                    label: const Text(
                      '무한혈전',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: NightPalette.jadeGreen,
                      ),
                    ),
                  ),
                ],
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
                      contOn ? '🏃연속이동 ON (터치시 정지)' : '⏸️연속이동 일시정지됨',
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
