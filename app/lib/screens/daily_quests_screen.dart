import 'dart:async';

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'stage_and_county_transitions.dart';

/// 7일 순환 출석부 · 일일/주간/월간 수호 임무 · 전술 비약 제조 · 영구 업적 통합 화면.
class DailyAndQuestsScreen extends StatefulWidget {
  const DailyAndQuestsScreen({
    super.key,
    required this.controller,
    this.initialTab = 0,
    this.embeddedInShell = false,
  });

  final GameController controller;
  final int initialTab;
  final bool embeddedInShell;

  @override
  State<DailyAndQuestsScreen> createState() => _DailyAndQuestsScreenState();
}

class _DailyAndQuestsScreenState extends State<DailyAndQuestsScreen> {
  Timer? _midnightRefreshTimer;
  int _lastObservedDayKey = 0;

  GameController get controller => widget.controller;
  int get initialTab => widget.initialTab;
  bool get embeddedInShell => widget.embeddedInShell;

  static int _localDayKey(DateTime dt) =>
      dt.year * 10000 + dt.month * 100 + dt.day;

  @override
  void initState() {
    super.initState();
    _lastObservedDayKey = _localDayKey(DateTime.now());
    _midnightRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final nowDay = _localDayKey(DateTime.now());
      if (nowDay != _lastObservedDayKey && mounted) {
        setState(() {
          _lastObservedDayKey = nowDay;
        });
      }
    });
  }

  @override
  void dispose() {
    _midnightRefreshTimer?.cancel();
    super.dispose();
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final p = controller.progress;
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: !embeddedInShell,
              title: const Text('출석 · 수호 임무 · 전술 비약'),
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: NightPalette.accentGold,
                labelColor: NightPalette.accentGold,
                unselectedLabelColor: NightPalette.textMuted,
                tabs: [
                  Tab(text: '7일 출석'),
                  Tab(text: '수호 임무'),
                  Tab(text: '비약 제조'),
                  Tab(text: '영구 업적'),
                ],
              ),
            ),
            body: NightSceneBackdrop(
              child: Column(
                children: [
                  if (!embeddedInShell)
                    QuickPlayAndMenuBar(
                      controller: controller,
                      currentSection: 'supply',
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAttendanceTab(context, p),
                        _buildMissionsTab(context, p),
                        _buildCraftingTab(context, p),
                        _buildAchievementsTab(context, p),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context, PlayerProgress p) {
    final canClaim = p.canClaimAttendance();
    final curIdx = p.currentAttendanceDayIndex;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MurimCard(
          borderColor: NightPalette.accentGold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const NightSpriteIcon(
                    assetPath: NightArtRegistry.iconAttendance,
                    fallbackIcon: Icons.calendar_month,
                    size: 46,
                    showFrame: true,
                    frameColor: NightPalette.accentGold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '7일 순환 수호 출석부',
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 19,
                            color: NightPalette.accentGold,
                          ),
                        ),
                        Text(
                          '누적 출석 ${p.attendanceStepCount}일 · 하루 빠져도 초기화되지 않고 이어집니다.',
                          style: const TextStyle(fontSize: 12.5, color: NightPalette.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('claim_attendance_btn'),
                  style: FilledButton.styleFrom(
                    backgroundColor: canClaim ? NightPalette.accentGold : Colors.grey.shade800,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: canClaim
                      ? () {
                          final reward = controller.claimAttendance();
                          if (reward != null) {
                            _toast(context, '🎁 출석 보상 수령! ${reward.toSummaryText()}');
                          }
                        }
                      : null,
                  icon: Icon(canClaim ? Icons.card_giftcard_rounded : Icons.check_circle_rounded),
                  label: Text(
                    canClaim
                        ? '오늘(${curIdx + 1}일차) 수호 보급품 받기'
                        : '오늘 출석 보상을 이미 수령했습니다',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(NightAttendance.sevenDayRewards.length, (i) {
          final r = NightAttendance.sevenDayRewards[i];
          final isCurrent = i == curIdx;
          final isDoneInCycle = i < curIdx;
          final dayIconAsset = i == 6
              ? NightArtRegistry.nightSupportSeal
              : (i.isOdd ? NightArtRegistry.nightElixir : NightArtRegistry.nightToken);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MurimCard(
              borderColor: isCurrent
                  ? NightPalette.accentGold
                  : (isDoneInCycle ? NightPalette.jadeGreen : NightPalette.borderGold),
              child: Row(
                children: [
                  NightSpriteIcon(
                    assetPath: dayIconAsset,
                    fallbackIcon: Icons.redeem_rounded,
                    size: 40,
                    showFrame: true,
                    frameColor: isCurrent
                        ? NightPalette.accentGold
                        : (isDoneInCycle ? NightPalette.jadeGreen : NightPalette.borderGold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i == 6 ? '7일차 대보급 상자 (특급 보상!)' : '${i + 1}일차 수호 군량 보급',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: i == 6 ? NightPalette.accentGold : NightPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r.toSummaryText(),
                          style: const TextStyle(fontSize: 12.5, color: NightPalette.jadeShield),
                        ),
                      ],
                    ),
                  ),
                  if (isDoneInCycle)
                    const Icon(Icons.verified_rounded, color: NightPalette.jadeGreen)
                  else if (isCurrent && canClaim)
                    const Chip(
                      label: Text('수령 가능', style: TextStyle(fontSize: 11, color: Colors.black)),
                      backgroundColor: NightPalette.accentGold,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMissionsTab(BuildContext context, PlayerProgress p) {
    final dailies = p.todayDailyMissions();
    final allClearReady = p.canClaimDailyAllClear();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MurimCard(
          borderColor: allClearReady ? NightPalette.accentGold : NightPalette.jadeGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const NightSpriteIcon(
                    assetPath: NightArtRegistry.iconChest,
                    fallbackIcon: Icons.inventory_2_rounded,
                    size: 44,
                    showFrame: true,
                    frameColor: NightPalette.accentGold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '오늘의 일일 임무 완수 상자',
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 17,
                            color: NightPalette.accentGold,
                          ),
                        ),
                        Text(
                          NightQuestCatalog.dailyAllClearBonus.toSummaryText(),
                          style: const TextStyle(fontSize: 12.5, color: NightPalette.jadeGreen),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('claim_daily_allclear_btn'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          allClearReady ? NightPalette.accentGold : Colors.grey.shade800,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: allClearReady
                        ? () {
                            final b = controller.claimDailyAllClear();
                            if (b != null) {
                              _toast(context, '🎉 일일 완수 보물상자 개방! ${b.toSummaryText()}');
                            }
                          }
                        : null,
                    child: Text(p.dailyAllClearClaimed ? '수령 완료' : '상자 열기'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '☀️ 오늘의 일일 수호 임무 (3종)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NightPalette.accentGold),
        ),
        const SizedBox(height: 8),
        ...dailies.map((m) => _buildMissionTile(context, p, m)),
        const SizedBox(height: 14),
        const Text(
          '🌙 이번 주 주간 수호 임무',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NightPalette.jadeShield),
        ),
        const SizedBox(height: 8),
        ...NightQuestCatalog.weeklyMissions.map((m) => _buildMissionTile(context, p, m)),
        const SizedBox(height: 14),
        const Text(
          '🌕 이번 달 월간 대수호 임무',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NightPalette.elixirPurple),
        ),
        const SizedBox(height: 8),
        ...NightQuestCatalog.monthlyMissions.map((m) => _buildMissionTile(context, p, m)),
      ],
    );
  }

  Widget _buildMissionTile(BuildContext context, PlayerProgress p, NightMissionSpec m) {
    final cur = p.deedProgress(m);
    final claimed = p.isMissionClaimed(m);
    final canClaim = p.canClaimMission(m);
    final ratio = (cur / m.goal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MurimCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const NightSpriteIcon(
                  assetPath: NightArtRegistry.iconMission,
                  fallbackIcon: Icons.assignment_turned_in_rounded,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m.title,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$cur / ${m.goal}',
                  style: const TextStyle(fontSize: 13, color: NightPalette.accentGold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              borderRadius: BorderRadius.circular(4),
              color: claimed ? NightPalette.jadeGreen : NightPalette.accentGold,
              backgroundColor: NightPalette.bgDeep,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '보상: ${m.reward.toSummaryText()}',
                  style: const TextStyle(fontSize: 12.5, color: NightPalette.jadeGreen),
                ),
                FilledButton.tonal(
                  onPressed: canClaim
                      ? () {
                          final b = controller.claimMission(m);
                          if (b != null) {
                            _toast(context, '보상 획득! ${b.toSummaryText()}');
                          }
                        }
                      : null,
                  child: Text(claimed ? '완료됨' : (canClaim ? '보상 받기' : '진행 중')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCraftingTab(BuildContext context, PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MurimCard(
          borderColor: NightPalette.jadeGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NightSpriteIcon(
                    assetPath: NightArtRegistry.materialAsset(CraftMaterial.moonHerb),
                    fallbackIcon: Icons.eco_rounded,
                    size: 36,
                    showFrame: true,
                    frameColor: NightPalette.jadeGreen,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '🧪 보유 수호 약재 · 광석 창고',
                      style: TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 18,
                        color: NightPalette.jadeGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '야간 방어 승리, 출석, 수호 임무, 물자 호송을 통해 재료가 저절로 모입니다.',
                style: TextStyle(fontSize: 12.5, color: NightPalette.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CraftMaterial.values.map((m) {
                  final cnt = p.materials[m] ?? 0;
                  return Chip(
                    avatar: NightSpriteIcon(
                      assetPath: NightArtRegistry.materialAsset(m),
                      fallbackIcon: Icons.diamond_rounded,
                      size: 22,
                      color: Color(m.colorHex),
                    ),
                    label: Text('${m.label} $cnt개', style: const TextStyle(fontSize: 12.5)),
                    backgroundColor: NightPalette.bgDeep,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '⚡ 전장 원터치 전술 비약 · 수리패 제조',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NightPalette.accentGold),
        ),
        const SizedBox(height: 8),
        ...TacticalConsumable.values.map((item) {
          final owned = p.consumables[item] ?? 0;
          final canCraft = p.canCraftConsumable(item);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MurimCard(
              borderColor: Color(item.colorHex),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NightSpriteIcon(
                        assetPath: NightArtRegistry.consumableAsset(item),
                        fallbackIcon: Icons.medication_liquid_rounded,
                        size: 54,
                        showFrame: true,
                        frameColor: Color(item.colorHex),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 18,
                                    color: Color(item.colorHex),
                                  ),
                                ),
                                Chip(
                                  label: Text('보유 $owned개', style: const TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.effectSummary,
                              style: const TextStyle(fontSize: 13.5, color: NightPalette.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.recipe.entries.map((e) {
                      final have = p.materials[e.key] ?? 0;
                      final enough = have >= e.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: NightPalette.bgDeep,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: enough
                                ? NightPalette.jadeGreen.withValues(alpha: 0.65)
                                : NightPalette.borderGold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.materialAsset(e.key),
                              fallbackIcon: Icons.diamond_rounded,
                              size: 18,
                              color: Color(e.key.colorHex),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${e.key.label} ${e.value}개 (보유 $have)',
                              style: TextStyle(
                                fontSize: 12,
                                color: enough ? NightPalette.jadeGreen : NightPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      key: Key('craft_${item.name}_btn'),
                      style: FilledButton.styleFrom(
                        backgroundColor: canCraft ? NightPalette.accentGold : Colors.grey.shade800,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: canCraft
                          ? () {
                              if (controller.craftConsumable(item)) {
                                _toast(context, '✨ [${item.label}] 1개 제조 완료! 전장 하단에서 즉시 쓸 수 있습니다.');
                              }
                            }
                          : null,
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: const Text('1개 제조하기'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAchievementsTab(BuildContext context, PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: NightAchievementSpec.all.map((a) {
        final claimed = p.claimedAchievements.contains(a.id);
        final met = p.isAchievementMet(a);
        final canClaim = p.canClaimAchievement(a);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MurimCard(
            borderColor: canClaim
                ? NightPalette.accentGold
                : (claimed ? NightPalette.jadeGreen : NightPalette.borderGold),
            child: Row(
              children: [
                NightSpriteIcon(
                  assetPath: NightArtRegistry.iconMedal,
                  fallbackIcon: claimed
                      ? Icons.workspace_premium_rounded
                      : (met ? Icons.emoji_events_rounded : Icons.lock_outline_rounded),
                  size: 40,
                  dimmed: !met && !claimed,
                  showFrame: true,
                  frameColor: claimed
                      ? NightPalette.jadeGreen
                      : (met ? NightPalette.accentGold : NightPalette.borderGold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: NightPalette.accentGold,
                        ),
                      ),
                      Text(
                        a.subtitle,
                        style: const TextStyle(fontSize: 12.5, color: NightPalette.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '보상: ${a.reward.toSummaryText()}',
                        style: const TextStyle(fontSize: 12, color: NightPalette.jadeShield),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: canClaim
                      ? () {
                          final b = controller.claimAchievement(a);
                          if (b != null) {
                            _toast(context, '🏆 칭호 [${a.title}] 달성! ${b.toSummaryText()}');
                          }
                        }
                      : null,
                  child: Text(claimed ? '수령됨' : (canClaim ? '받기' : '미달성')),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
