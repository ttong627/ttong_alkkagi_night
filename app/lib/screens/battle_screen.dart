import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/night_audio.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'battle_painter.dart';

/// 실시간 자동 수호 전장 화면 (1·2·3배속 · 거점 버전 승급 · 전술 비약 3종 · 암행어사 출두 · 기여도 분석표).
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
  bool _paused = false;
  bool _summaryShown = false;

  @override
  void initState() {
    super.initState();
    _startNewSim();
    final chapter = CampaignCatalog.chapterOf(widget.stage.chapterNumber);
    final bgm = widget.stage.isBossStage ? 'bgm_boss.ogg' : chapter.bgmAsset;
    NightAudioController.instance.playBgm(bgm);

    // 전장 코덱스 스프라이트 비동기 예열 (미존재/테스트 환경에서도 예외 없이 안전 동작)
    NightBattleSprites.instance.warmUpForChapter(
      chapter,
      onSpritesUpdated: () {
        if (mounted) {
          _frameNotifier.value++;
        }
      },
    );

    _ticker = createTicker(_onTick)..start();

    if (widget.stage.introDialogue.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStoryDialogueModal(widget.stage.introDialogue, isOutro: false);
      });
    }
  }

  void _startNewSim() {
    _sim = DefenseBattleSim(
      stage: widget.stage,
      difficulty: widget.controller.selectedDifficulty,
      progress: widget.controller.progress,
      seed: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
    );
    _summaryShown = false;
    _lastTick = null;
  }

  void _onTick(Duration elapsed) {
    if (_paused) {
      _lastTick = elapsed;
      return;
    }
    final prev = _lastTick;
    _lastTick = elapsed;
    if (prev == null) return;

    double rawDt = (elapsed - prev).inMicroseconds / 1e6;
    rawDt = rawDt.clamp(0.0, 0.05);

    for (int s = 0; s < _speedMultiplier; s++) {
      if (!_sim.isFinished) {
        _sim.step(rawDt);
      }
    }

    NightAudioController.instance.flushBattleCues(_sim.pendingSounds);
    _frameNotifier.value++;

    if (_sim.isFinished && !_summaryShown) {
      _summaryShown = true;
      final summary = _sim.buildSummary();
      widget.controller.recordBattleSummary(widget.stage, summary);
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (summary.victory && widget.stage.outroDialogue.isNotEmpty) {
          await _showStoryDialogueModal(widget.stage.outroDialogue, isOutro: true);
        }
        if (mounted) {
          _showResultModal(summary);
        }
      });
    }
  }

  Future<void> _showPauseSheet() async {
    setState(() => _paused = true);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NightPalette.bgPanel,
        title: Row(
          children: [
            const NightSpriteIcon(
              assetPath: NightArtRegistry.towerGuardian,
              fallbackIcon: Icons.pause_circle_filled_rounded,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '야간 수호 일시정지',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: NightPalette.accentGold),
              ),
            ),
          ],
        ),
        content: Text(
          '현재 무대: ${widget.stage.title}\n전술 조언: ${widget.stage.tacticalHint}',
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('본영으로 후퇴'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _startNewSim();
                _paused = false;
              });
            },
            child: const Text('처음부터 재배치'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: NightPalette.accentGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('계속 수호하기'),
          ),
        ],
      ),
    );
    if (mounted && !_sim.isFinished) {
      setState(() => _paused = false);
    }
  }

  Future<void> _showStoryDialogueModal(
    List<StoryLine> lines, {
    required bool isOutro,
  }) async {
    setState(() => _paused = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int idx = 0;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final line = lines[idx];
            return Dialog(
              backgroundColor: NightPalette.bgPanel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: NightPalette.borderGold, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        NightSpriteIcon(
                          assetPath: NightArtRegistry.charFace(line.portraitPrefix),
                          fallbackIcon: Icons.person_rounded,
                          size: 58,
                          borderRadius: 29,
                          fit: BoxFit.cover,
                          showFrame: true,
                          frameColor: NightPalette.borderGold,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOutro ? '🌅 새벽 정화 이야기' : '🌙 심야 기습 전령',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: NightPalette.jadeGreen,
                                ),
                              ),
                              Text(
                                line.speaker,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19,
                                  color: NightPalette.accentGold,
                                  fontFamily: 'BlackHanSans',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      line.text,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.45,
                        color: NightPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          NightAudioController.instance.playAsset('ui_tap.ogg');
                          if (idx + 1 < lines.length) {
                            setModalState(() => idx++);
                          } else {
                            Navigator.of(ctx).pop();
                          }
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: Text(idx + 1 < lines.length ? '다음 대화' : '전장 개시'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) {
      setState(() => _paused = false);
    }
  }

  void _showResultModal(BattleSummary summary) {
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
            : summary.contributions.first.totalDamage.clamp(1.0, double.infinity);

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
                      fontSize: 22,
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
                            Text('토벌 수: ${summary.killCount}마리',
                                style: const TextStyle(color: NightPalette.textPrimary)),
                            Text('절벽 뽀록: ${summary.pporokCount}회',
                                style: const TextStyle(color: NightPalette.jadeGreen)),
                            Text('어부지리 도탄: ${summary.bankShotCount}회',
                                style: const TextStyle(color: NightPalette.jadeShield)),
                            Text('연쇄 박살: ${summary.chainShatterCount}회',
                                style: const TextStyle(color: Colors.orangeAccent)),
                            if (summary.serendipityCount > 0)
                              Text('설렘 기연 발동: ${summary.serendipityCount}회!',
                                  style: const TextStyle(color: NightPalette.accentGold)),
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
                              label: '식량 ${(summary.granaryRatio * 100).round()}%',
                            ),
                            _MiniVillageStatBadge(
                              assetPath: NightArtRegistry.villageCrops,
                              fallbackIcon: Icons.grass_rounded,
                              label: '논밭 ${(summary.cropsRatio * 100).round()}%',
                            ),
                            _MiniVillageStatBadge(
                              assetPath: NightArtRegistry.villageLivestock,
                              fallbackIcon: Icons.pets_rounded,
                              label: '가축 ${(summary.livestockRatio * 100).round()}%',
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Text(
                          '💡 군사 조언: ${summary.coachingTip}',
                          style: const TextStyle(fontSize: 14, color: NightPalette.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📊 자동 발사대 · 동료 처치 기여도 분석',
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
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (summary.victory &&
                                widget.stage.globalIndex < CampaignCatalog.allStages.length) {
                              final nextStage =
                                  CampaignCatalog.allStages[widget.stage.globalIndex];
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
                                ? '다음 밤 수호'
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 전장 상태 막대 (코덱스 전용 아이콘 적용)
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (_, _, _) {
                final shieldPct = _sim.centralSpec.shieldMaxHp > 0
                    ? (_sim.shieldHp / _sim.centralSpec.shieldMaxHp * 100).round()
                    : 0;
                final towerPct = _sim.centralSpec.coreMaxHp > 0
                    ? (_sim.towerHp / _sim.centralSpec.coreMaxHp * 100).round()
                    : 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: NightPalette.bgPanel,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            key: const Key('battle_pause_btn'),
                            visualDensity: VisualDensity.compact,
                            tooltip: '일시정지 및 전술 확인',
                            onPressed: _showPauseSheet,
                            icon: const Icon(Icons.pause_circle_outline_rounded),
                          ),
                          Expanded(
                            child: Text(
                              '${widget.stage.title} · 물결 ${_sim.currentWaveIndex + 1}/${widget.stage.waves.length}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: NightPalette.accentGold,
                              ),
                            ),
                          ),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1배')),
                              ButtonSegment(value: 2, label: Text('2배')),
                              ButtonSegment(value: 3, label: Text('3배')),
                            ],
                            selected: {_speedMultiplier},
                            onSelectionChanged: (s) {
                              setState(() => _speedMultiplier = s.first);
                            },
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
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
                          _HudStatBadge(
                            assetPath: NightArtRegistry.nightToken,
                            fallbackIcon: Icons.toll_rounded,
                            text: '현장증표 ${_sim.fieldTokens}',
                            color: Colors.amberAccent,
                          ),
                          _HudStatBadge(
                            assetPath: NightArtRegistry.nightSupportSeal,
                            fallbackIcon: Icons.campaign_rounded,
                            text: '지원패 ${_sim.supportChargesLeft}',
                            color: NightPalette.elixirPurple,
                          ),
                          if (_sim.auroraCritTimer > 0)
                            _HudStatBadge(
                              assetPath: NightArtRegistry.fxCritical,
                              fallbackIcon: Icons.auto_awesome_rounded,
                              text: '극광회심 ${_sim.auroraCritTimer.toStringAsFixed(1)}초',
                              color: Colors.orangeAccent,
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // 중앙 60프레임 심야 전장 화면 (배경 bg_night_ch* 전폭 파노라마 + 정비율 전술 전장 캔버스)
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
                      color: NightPalette.bgDeep.withValues(alpha: 0.42),
                    ),
                  ),
                  Center(
                    child: AspectRatio(
                      aspectRatio:
                          CampaignCatalog.arenaWidth / CampaignCatalog.arenaHeight,
                      child: LayoutBuilder(
                        builder: (ctx, arenaConstraints) {
                          return GestureDetector(
                            onTapUp: (details) {
                              if (arenaConstraints.maxWidth <= 0 ||
                                  arenaConstraints.maxHeight <= 0) {
                                return;
                              }
                              final lx = details.localPosition.dx /
                                  arenaConstraints.maxWidth *
                                  CampaignCatalog.arenaWidth;
                              final ly = details.localPosition.dy /
                                  arenaConstraints.maxHeight *
                                  CampaignCatalog.arenaHeight;
                              final tapPos = Vec2(lx, ly);
                              for (int i = 0; i < _sim.launchers.length; i++) {
                                if (_sim.launchers[i].pos.distanceTo(tapPos) < 28) {
                                  _sim.upgradeLauncherInBattle(i);
                                  break;
                                }
                              }
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.symmetric(
                                  vertical: BorderSide(
                                    color: NightPalette.borderGold.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                              child: ClipRect(
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: NightBattlePainter(
                                    sim: _sim,
                                    repaintTick: _frameNotifier,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
                                constraints: const BoxConstraints(maxWidth: 460),
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
                ],
              ),
            ),

            // 하단 전술 비약 3종(potion_*.webp) & 자동 승급 & 무림수호단 출두(fx_chuldu.webp) 바
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (_, _, _) {
                final p = widget.controller.progress;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  color: NightPalette.bgPanel,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: TacticalConsumable.values.map((item) {
                          final cnt = p.consumables[item] ?? 0;
                          final shortLabel = switch (item) {
                            TacticalConsumable.qiSurgePill => '기공단',
                            TacticalConsumable.guardianRepairSeal => '수리패',
                            TacticalConsumable.auroraCritCharm => '극광부',
                          };
                          return ActionChip(
                            key: Key('use_consumable_${item.name}'),
                            visualDensity: VisualDensity.compact,
                            avatar: NightSpriteIcon(
                              assetPath: NightArtRegistry.consumableAsset(item),
                              fallbackIcon: Icons.local_pharmacy_rounded,
                              size: 18,
                              color: cnt > 0 ? Color(item.colorHex) : Colors.grey.shade600,
                              dimmed: cnt <= 0,
                              borderRadius: 4,
                            ),
                            label: Text(
                              '$shortLabel($cnt)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: cnt > 0
                                    ? NightPalette.textPrimary
                                    : NightPalette.textMuted,
                              ),
                            ),
                            onPressed: cnt > 0
                                ? () {
                                    if (_sim.activateConsumable(item)) {
                                      widget.controller.notifyConsumableUsedInBattle();
                                      setState(() {});
                                    }
                                  }
                                : null,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilterChip(
                            visualDensity: VisualDensity.compact,
                            selected: _sim.preset.autoUpgradeInBattle,
                            label: const Text(
                              '자동 승급(1→4형)',
                              style: TextStyle(fontSize: 12),
                            ),
                            onSelected: (v) {
                              widget.controller.updatePreset(
                                (pr) => pr.autoUpgradeInBattle = v,
                              );
                              setState(() {});
                            },
                          ),
                          FilledButton.icon(
                            key: const Key('battle_chuldu_btn'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
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
                              fallbackAssetPath: NightArtRegistry.nightSupportSeal,
                              fallbackIcon: Icons.campaign_rounded,
                              size: 20,
                              color: _sim.supportChargesLeft > 0
                                  ? Colors.black
                                  : Colors.white54,
                              dimmed: _sim.supportChargesLeft <= 0,
                              borderRadius: 4,
                            ),
                            label: Text(
                              '무림수호단 출두! (${_sim.supportChargesLeft})',
                              style: const TextStyle(fontSize: 12.5),
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
          style: TextStyle(fontSize: 12, color: color),
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
            style: const TextStyle(fontSize: 12, color: NightPalette.textPrimary),
          ),
        ],
      ),
    );
  }
}
