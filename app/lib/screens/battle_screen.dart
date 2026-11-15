import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/night_audio.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import 'battle_painter.dart';

/// 실시간 자동 수호 전장 화면 (1·2·3배속 · 거점 버전 승급 · 암행어사 출두 · 기여도 분석표).
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
    NightAudioController.instance.playBgm(
      CampaignCatalog.chapterOf(widget.stage.chapterNumber).bgmAsset,
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/images/chars/${line.portraitPrefix}_face.webp',
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const CircleAvatar(
                              radius: 29,
                              child: Icon(Icons.person),
                            ),
                          ),
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
                    summary.victory ? '🌅 새벽 정화 승리! (${widget.stage.title})' : '🌑 방어선 붕괴 · 마을 후퇴',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 22,
                      color: summary.victory ? NightPalette.accentGold : NightPalette.crimsonMoon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (summary.victory)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => Icon(
                          i < summary.stars ? Icons.star_rounded : Icons.star_border_rounded,
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
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Text('획득 증표: +${summary.earnedTokens}',
                                style: const TextStyle(color: NightPalette.accentGold)),
                            Text('획득 영약: +${summary.earnedElixirs}',
                                style: const TextStyle(color: NightPalette.elixirPurple)),
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
                              Text(c.label, style: const TextStyle(fontSize: 13)),
                              Text(
                                '정화 ${c.kills}마리 · 피해 ${c.totalDamage.round()}',
                                style: const TextStyle(fontSize: 12, color: NightPalette.textMuted),
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
                              final nextStage = CampaignCatalog.allStages[widget.stage.globalIndex];
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
                          icon: Icon(summary.victory ? Icons.skip_next_rounded : Icons.refresh_rounded),
                          label: Text(summary.victory ? '다음 밤 수호' : '다시 수호하기'),
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
            // 상단 전장 상태 막대
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: NightPalette.bgPanel,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          Expanded(
                            child: Text(
                              '${widget.stage.title} · 물결 ${_sim.currentWaveIndex + 1}/${widget.stage.waves.length}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
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
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: [
                          Text('🛡️방어막 $shieldPct%',
                              style: const TextStyle(fontSize: 12, color: NightPalette.jadeShield)),
                          Text('⚙️수호탑 $towerPct%',
                              style: const TextStyle(fontSize: 12, color: NightPalette.accentGold)),
                          Text('🔥내공 ${_sim.qiBars.toStringAsFixed(1)}/3칸',
                              style: const TextStyle(fontSize: 12, color: NightPalette.jadeGreen)),
                          Text('🪙현장증표 ${_sim.fieldTokens}',
                              style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // 중앙 60프레임 심야 전장 화면
            Expanded(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return GestureDetector(
                    onTapUp: (details) {
                      // 거점 직접 클릭 시 수동 버전 승급도 지원
                      final lx = details.localPosition.dx / constraints.maxWidth * CampaignCatalog.arenaWidth;
                      final ly = details.localPosition.dy / constraints.maxHeight * CampaignCatalog.arenaHeight;
                      final tapPos = Vec2(lx, ly);
                      for (int i = 0; i < _sim.launchers.length; i++) {
                        if (_sim.launchers[i].pos.distanceTo(tapPos) < 28) {
                          _sim.upgradeLauncherInBattle(i);
                          break;
                        }
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          chapter.bgAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(color: NightPalette.bgDeep),
                        ),
                        CustomPaint(
                          painter: NightBattlePainter(
                            sim: _sim,
                            repaintTick: _frameNotifier,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 하단 자동 승급 & 암행어사 출두 지원패 제어 바
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (_, _, _) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: NightPalette.bgPanel,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        visualDensity: VisualDensity.compact,
                        selected: _sim.preset.autoUpgradeInBattle,
                        label: const Text('자동 승급(1→4형)', style: TextStyle(fontSize: 12.5)),
                        onSelected: (v) {
                          widget.controller.updatePreset((p) => p.autoUpgradeInBattle = v);
                          setState(() {});
                        },
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        icon: const Icon(Icons.campaign_rounded, size: 18),
                        label: Text(
                          '무림수호단 출두! (${_sim.supportChargesLeft})',
                          style: const TextStyle(fontSize: 13),
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
    );
  }
}
