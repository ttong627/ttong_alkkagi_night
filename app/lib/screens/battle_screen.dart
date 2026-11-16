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
  bool _paused = false;
  bool _summaryShown = false;

  /// 수동 조준 드래그 상태 및 실시간 반사 예측선 각도.
  bool _draggingManualAim = false;
  bool _draggedFromTower = false;
  double? _manualAimPreviewAngleRad;

  @override
  void initState() {
    super.initState();
    _startNewSim();
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
    _draggingManualAim = false;
    _manualAimPreviewAngleRad = null;
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
      final rescueBanner = widget.controller.progress.lastRescueBanner;
      final rescuedHero = widget.controller.progress.lastRescuedCompanion;
      final rescuedBeast = widget.controller.progress.lastRescuedBeast;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        if (summary.victory && widget.stage.outroDialogue.isNotEmpty) {
          await _showStoryDialogueModal(
            widget.stage.outroDialogue,
            isOutro: true,
          );
        }
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
    double bestDist = 30.0;
    for (final slot in _sim.activeMounts) {
      final d = slot.pos.distanceTo(arenaPos);
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

  Future<void> _openMountBuildOrManageSheet(LauncherMountSlot slot) async {
    if (_sim.isFinished) return;
    final wasPaused = _paused;
    setState(() => _paused = true);
    NightAudioController.instance.playAsset('ui_tap.ogg');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NightPalette.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final existing = _sim.launcherAtSlot(slot.slotIndex);
            final recType = slot.recommendedType;
            final orderedTypes = <LauncherType>[
              recType,
              ...LauncherType.values.where((t) => t != recType),
            ];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          NightSpriteIcon(
                            assetPath: existing != null
                                ? NightArtRegistry.launcherAsset(existing.type)
                                : NightArtRegistry.launcherAsset(recType),
                            fallbackIcon: Icons.fort_rounded,
                            size: 38,
                            showFrame: true,
                            frameColor: NightPalette.accentGold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existing == null
                                      ? '길목 ${slot.slotIndex + 1}번 빈 초소 · 발사대 직접 배치'
                                      : '길목 ${slot.slotIndex + 1}번 초소 · ${existing.type.name} (${existing.tier}형)',
                                  style: const TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 17,
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                                Text(
                                  '현장 보유 증표: ${_sim.fieldTokens}개 · 개방 초소 ${_sim.launchers.length}/${_sim.activeMounts.length}곳 가동중',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: NightPalette.jadeGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (existing != null) ...[
                        MurimCard(
                          borderColor: NightPalette.jadeGreen,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${existing.type.name} (${existing.tier}형 / 최대 4형) — ${existing.type.roleSummary}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: NightPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.icon(
                                    key: const Key('upgrade_slot_btn'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: NightPalette.jadeGreen,
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: existing.tier < 4 &&
                                            _sim.fieldTokens >=
                                                existing.type.inBattleUpgradeCost(
                                                  existing.tier,
                                                )
                                        ? () {
                                            if (_sim.upgradeLauncherAtSlot(
                                              slot.slotIndex,
                                            )) {
                                              NightHaptics.instance.lightTap();
                                              setSheetState(() {});
                                              _frameNotifier.value++;
                                            }
                                          }
                                        : null,
                                    icon: const Icon(
                                      Icons.upgrade_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      existing.tier >= 4
                                          ? '최고 4형 달성 완료'
                                          : '${existing.tier + 1}형 승급 (증표 ${existing.type.inBattleUpgradeCost(existing.tier)})',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    key: const Key('dismantle_slot_btn'),
                                    onPressed: () {
                                      final refund = _sim.dismantleLauncherInBattle(
                                        slot.slotIndex,
                                      );
                                      if (refund > 0) {
                                        NightHaptics.instance.lightTap();
                                        _frameNotifier.value++;
                                        Navigator.of(ctx).pop();
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.recycling_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      '철거 (+${(existing.investedTokens * 0.80).round()} 환급)',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '다른 종류의 수호 발사대로 교체 배치 (기존 증표 80% 자동 차감 반영)',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: NightPalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      ...orderedTypes.map((lt) {
                        if (existing != null && existing.type == lt) {
                          return const SizedBox.shrink();
                        }
                        final unlocked = _sim.isLauncherTypeUnlocked(lt);
                        final isRec = lt == recType;
                        final refund = existing != null
                            ? (existing.investedTokens * 0.80).round()
                            : 0;
                        final netCost = max(0, lt.buildCostTokens - refund);
                        final canAfford = unlocked &&
                            (_sim.fieldTokens + refund) >= lt.buildCostTokens;
                        final permLv =
                            widget.controller.progress.launcherPermanentLevels[lt] ??
                                1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            key: Key('place_launcher_${EnumName(lt).name}'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: canAfford
                                ? () {
                                    final ok = existing == null
                                        ? _sim.placeLauncherInBattle(
                                            slot.slotIndex,
                                            lt,
                                          )
                                        : _sim.replaceLauncherInBattle(
                                            slot.slotIndex,
                                            lt,
                                          );
                                    if (ok) {
                                      NightHaptics.instance.lightTap();
                                      _frameNotifier.value++;
                                      Navigator.of(ctx).pop();
                                    }
                                  }
                                : null,
                            child: MurimCard(
                              borderColor: isRec
                                  ? NightPalette.accentGold
                                  : Color(lt.colorHex).withValues(
                                      alpha: unlocked ? 0.60 : 0.25,
                                    ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  NightSpriteIcon(
                                    assetPath: NightArtRegistry.launcherAsset(lt),
                                    fallbackIcon: Icons.gps_fixed_rounded,
                                    size: 44,
                                    color: Color(lt.colorHex),
                                    dimmed: !unlocked,
                                    showFrame: true,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              '${lt.name} (영구 $permLv단)',
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.bold,
                                                color: unlocked
                                                    ? Color(lt.colorHex)
                                                    : NightPalette.textMuted,
                                              ),
                                            ),
                                            if (isRec)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: NightPalette.accentGold,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  '★ 이 길목 추천',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          unlocked
                                              ? lt.roleSummary
                                              : '제${lt.unlockChapter}장 도달 시 개방되는 기관 발사대입니다.',
                                          style: const TextStyle(
                                            fontSize: 11.8,
                                            color: NightPalette.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: isRec && canAfford
                                          ? NightPalette.accentGold
                                          : null,
                                      foregroundColor: isRec && canAfford
                                          ? Colors.black
                                          : null,
                                    ),
                                    onPressed: canAfford
                                        ? () {
                                            final ok = existing == null
                                                ? _sim.placeLauncherInBattle(
                                                    slot.slotIndex,
                                                    lt,
                                                  )
                                                : _sim.replaceLauncherInBattle(
                                                    slot.slotIndex,
                                                    lt,
                                                  );
                                            if (ok) {
                                              NightHaptics.instance.lightTap();
                                              _frameNotifier.value++;
                                              Navigator.of(ctx).pop();
                                            }
                                          }
                                        : null,
                                    child: Text(
                                      !unlocked
                                          ? '${lt.unlockChapter}장 해금'
                                          : (existing == null
                                              ? '증표 ${lt.buildCostTokens}'
                                              : '교체 $netCost'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted && !_sim.isFinished) {
      setState(() => _paused = wasPaused);
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
          '현재 무대: ${widget.stage.title}\n'
          '개방 초소: ${_sim.launchers.length}/${_sim.activeMounts.length}곳 배치됨\n'
          '중앙 수호탑: ${_sim.centralManualMode ? "수동 조준 탄지 모드" : "자동 조준 발사 모드"}\n'
          '전술 조언: ${widget.stage.tacticalHint}',
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 전장 상태 막대
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (_, _, _) {
                final shieldPct = _sim.centralSpec.shieldMaxHp > 0
                    ? (_sim.shieldHp / _sim.centralSpec.shieldMaxHp * 100)
                        .round()
                    : 0;
                final towerPct = _sim.centralSpec.coreMaxHp > 0
                    ? (_sim.towerHp / _sim.centralSpec.coreMaxHp * 100).round()
                    : 0;
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
                            tooltip: '일시정지 및 전술 확인',
                            onPressed: _showPauseSheet,
                            icon: const Icon(Icons.pause_circle_outline_rounded),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.stage.title} · 물결 ${_sim.currentWaveIndex + 1}/${widget.stage.waves.length}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.8,
                                    color: NightPalette.accentGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.stage.hasRescueReward)
                                  Text(
                                    '🆘 구출 목표: ${widget.stage.rescueBadgeText}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.2,
                                      color: NightPalette.jadeGreen,
                                    ),
                                  ),
                              ],
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
                            assetPath: NightArtRegistry.nightToken,
                            fallbackIcon: Icons.toll_rounded,
                            text: '현장증표 ${_sim.fieldTokens}',
                            color: Colors.amberAccent,
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

                              // 1) 개방된 빈 초소 또는 설치된 발사대 터치 → 직접 배치 / 승급·교체·철거 시트 오픈!
                              final hitSlot = _hitMountSlot(tapPos);
                              if (hitSlot != null) {
                                _openMountBuildOrManageSheet(hitSlot);
                                return;
                              }

                              // 2) 맨 아래 중앙 기명 수호탑 터치 → 자동 발사 ↔ 수동 탄지 즉시 전환!
                              if (tapPos.distanceTo(
                                    CampaignCatalog.centralTowerPos,
                                  ) <=
                                  34.0) {
                                _sim.toggleCentralManualMode();
                                NightHaptics.instance.lightTap();
                                _frameNotifier.value++;
                                setState(() {});
                                return;
                              }

                              // 3) 수동 탄지 모드에서 전장 위쪽 허공 터치 → 해당 지점으로 수동 강화 탄지 발사!
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
                ],
              ),
            ),

            // 하단 전술 비약 3종 · 중앙탑 자동/수동 전환 · 자동 승급 · 무림수호단 출두 바
            ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (_, _, _) {
                final p = widget.controller.progress;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  color: NightPalette.bgPanel,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        alignment: WrapAlignment.center,
                        children: [
                          ActionChip(
                            key: const Key('battle_toggle_central_mode_btn'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: _sim.centralManualMode
                                ? NightPalette.accentGold.withValues(alpha: 0.24)
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
                              size: 16,
                              color: _sim.centralManualMode
                                  ? NightPalette.accentGold
                                  : NightPalette.jadeGreen,
                            ),
                            label: Text(
                              _sim.centralManualMode
                                  ? '중앙탑: 수동탄지'
                                  : '중앙탑: 자동발사',
                              style: TextStyle(
                                fontSize: 11.5,
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
                          ...TacticalConsumable.values.map((item) {
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
                                assetPath:
                                    NightArtRegistry.consumableAsset(item),
                                fallbackIcon: Icons.local_pharmacy_rounded,
                                size: 17,
                                color: cnt > 0
                                    ? Color(item.colorHex)
                                    : Colors.grey.shade600,
                                dimmed: cnt <= 0,
                                borderRadius: 4,
                              ),
                              label: Text(
                                '$shortLabel($cnt)',
                                style: TextStyle(
                                  fontSize: 11.2,
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
                            );
                          }),
                        ],
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
                              '배치초소 자동승급(1→4형)',
                              style: TextStyle(fontSize: 11.5),
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
                              fallbackAssetPath:
                                  NightArtRegistry.nightSupportSeal,
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
                              style: const TextStyle(fontSize: 12.2),
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
