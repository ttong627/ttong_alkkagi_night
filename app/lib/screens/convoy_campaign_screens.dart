import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import 'battle_screen.dart';

/// 물자 호송 · 심야 탐색 · 보름달 길조 기연 & 암행어사 출두 지원패 수급소.
class ConvoyAndSerendipityScreen extends StatelessWidget {
  const ConvoyAndSerendipityScreen({super.key, required this.controller});
  final GameController controller;

  void _showClaimDialog(BuildContext context, DispatchClaimResult res) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NightPalette.bgPanel,
        title: Text(
          res.title,
          style: const TextStyle(color: NightPalette.accentGold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (res.wasCritical)
              const Text('⚡ 크리티컬 대풍년 기연 발동! (보상 2배 폭발!)',
                  style: TextStyle(color: NightPalette.accentGold)),
            if (res.wasEncoreOneMore)
              const Text('🔁 한 번 더 기연 발동! (뒤따라온 보너스 마차 합류!)',
                  style: TextStyle(color: NightPalette.jadeGreen)),
            const SizedBox(height: 8),
            Text('• 변이 토벌 증표: +${res.gainedTokens}'),
            Text('• 신비 영약: +${res.gainedElixirs}'),
            if (res.gainedSupportTokens > 0)
              Text('• 무림수호단 지원패: +${res.gainedSupportTokens}개!',
                  style: const TextStyle(color: NightPalette.accentGold)),
            if (res.gainedShards > 0)
              Text('• 신물 수호석 조각: +${res.gainedShards}개'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('기쁘게 수령'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.progress;
        final convoyUnlocked = p.highestUnlockedChapter >= 2;
        final exploreUnlocked = p.highestUnlockedChapter >= 4;

        return Scaffold(
          appBar: AppBar(title: const Text('보급 호송 · 심야 탐색 · 기연각')),
          body: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // 지원패 보유 현황 및 3대 획득 경로 안내
              MurimCard(
                borderColor: NightPalette.accentGold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign_rounded, color: NightPalette.accentGold, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '보유 지원패(무림수호단 출두야~~!!): ${p.supportTokens}개',
                            style: const TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 18,
                              color: NightPalette.accentGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '전장 위기 시 태평소 풍악과 함께 아군 기마·수호알 대열이 온 길목의 돌연변이를 한데 싹 몰아 전멸시키고 떠납니다!\n'
                      '수급 3대 경로: ① 조건 달성(물자 호송 완수 · 마을 3요소 무피해 ★3 수호) · ② 설렘 기연(보름달 길조) · ③ 심야 탐색(산채 봉화대)',
                      style: TextStyle(fontSize: 12.5, color: NightPalette.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 1) 보름달 길조 게이지 (기연 경로)
              MurimCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌕 보름달 길조 게이지 (${p.moonOmenGauge} / 100)',
                      style: const TextStyle(fontSize: 16.5, color: NightPalette.accentGold),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: p.moonOmenGauge / 100.0,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(6),
                      color: NightPalette.accentGold,
                      backgroundColor: NightPalette.bgDeep,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '야간 수호와 단전 운기를 할 때마다 달이 차오르며, 보름달(100)이 되면 영약·신물 조각·지원패가 담긴 특급 기연이 100% 확정 발동합니다!',
                      style: TextStyle(fontSize: 12.5, color: NightPalette.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: p.moonOmenGauge >= 100
                            ? () {
                                final res = controller.claimFullMoon();
                                if (res != null) _showClaimDialog(context, res);
                              }
                            : null,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('보름달 특급 기연 열기'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2) 물자 호송 시스템 (2장 통통 객잔 구출 시 개통)
              MurimCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🐎 구출 마을 물자 호송 마차 ${p.convoySupplyBuffBattles > 0 ? "(풍년 군자금 +20% 버프 ${p.convoySupplyBuffBattles}판 남음)" : ""}',
                      style: const TextStyle(fontSize: 16.5, color: NightPalette.jadeGreen),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      !convoyUnlocked
                          ? '제2장 통통 객잔 식량 창고로 가는 길을 열면 물자 호송이 개통됩니다!'
                          : p.convoyActive
                              ? (p.convoyBattlesRemaining > 0
                                  ? '식량·영약 수레가 이동 중입니다. 야간 수호 ${p.convoyBattlesRemaining}판 승리 시 도착!'
                                  : '호송 마차가 무사히 마을에 도착했습니다! 지원패와 보급품을 수령하세요!')
                              : '구출한 이웃 마을에서 식량·영약·증표와 의용대 지원패를 실어 나릅니다.',
                      style: const TextStyle(fontSize: 13, color: NightPalette.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: !p.convoyActive
                          ? FilledButton.icon(
                              onPressed: convoyUnlocked ? controller.startConvoy : null,
                              icon: const Icon(Icons.local_shipping_rounded),
                              label: Text(convoyUnlocked ? '호송 마차 출발' : '2장 개방 시 사용'),
                            )
                          : FilledButton.icon(
                              onPressed: p.convoyBattlesRemaining == 0
                                  ? () {
                                      final res = controller.claimConvoy();
                                      if (res != null) _showClaimDialog(context, res);
                                    }
                                  : null,
                              icon: const Icon(Icons.redeem_rounded),
                              label: Text(
                                p.convoyBattlesRemaining == 0
                                    ? '호송 물자·지원패 수령!'
                                    : '호송 중 (${p.convoyBattlesRemaining}판 남음)',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3) 심야 탐색 시스템 (4장 쿠비 산채 봉화대 탈환 시 개통)
              MurimCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧭 산야 봉화대 심야 탐색 파견',
                      style: TextStyle(fontSize: 16.5, color: NightPalette.elixirPurple),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      !exploreUnlocked
                          ? '제4장 쿠비 산채 봉화대를 탈환하면 대기 동료 심야 탐색이 개통됩니다!'
                          : p.exploreActive
                              ? (p.exploreBattlesRemaining > 0
                                  ? '정찰대가 밤산을 수색 중입니다. 야간 수호 ${p.exploreBattlesRemaining}판 승리 시 귀환!'
                                  : '탐색대가 영약·신물 조각·지원패를 찾아 귀환했습니다!')
                              : '대기 중인 동료와 정찰대를 산길 봉화대로 보내 영약·신물 조각·지원패를 발굴합니다.',
                      style: const TextStyle(fontSize: 13, color: NightPalette.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: !p.exploreActive
                          ? FilledButton.icon(
                              onPressed: exploreUnlocked ? controller.startExplore : null,
                              icon: const Icon(Icons.explore_rounded),
                              label: Text(exploreUnlocked ? '심야 탐색 파견' : '4장 개방 시 사용'),
                            )
                          : FilledButton.icon(
                              onPressed: p.exploreBattlesRemaining == 0
                                  ? () {
                                      final res = controller.claimExplore();
                                      if (res != null) _showClaimDialog(context, res);
                                    }
                                  : null,
                              icon: const Icon(Icons.inventory_2_rounded),
                              label: Text(
                                p.exploreBattlesRemaining == 0
                                    ? '탐색 발굴품 수령!'
                                    : '탐색 중 (${p.exploreBattlesRemaining}판 남음)',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 1~10장(총 111단계) 강호 수호 캠페인 지도 화면.
class CampaignScreen extends StatelessWidget {
  const CampaignScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.progress;
        final chSpec = CampaignCatalog.chapterOf(controller.selectedChapter);
        final stages = CampaignCatalog.stagesOfChapter(chSpec.number);

        return Scaffold(
          appBar: AppBar(title: const Text('탄지무림 10장 심야 수호록')),
          body: Column(
            children: [
              // 상단 장 선택 가로 스크롤 & 난이도 선택
              Container(
                color: NightPalette.bgPanel,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: CampaignCatalog.chapters.map((c) {
                          final unlocked = c.number <= p.highestUnlockedChapter;
                          final selected = c.number == controller.selectedChapter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              selected: selected,
                              label: Text('${unlocked ? "🌙" : "🔒"}${c.number}장 ${c.villageName}'),
                              onSelected: (_) => controller.setSelectedChapter(c.number),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<DefenseDifficulty>(
                      segments: DefenseDifficulty.values
                          .map((d) => ButtonSegment(
                                value: d,
                                label: Text(d.name.split(' · ').first),
                              ))
                          .toList(),
                      selected: {controller.selectedDifficulty},
                      onSelectionChanged: (s) => controller.setDifficulty(s.first),
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ),

              // 선택된 장 줄거리 및 보상 요약 배너
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: MurimCard(
                  borderColor: NightPalette.jadeShield,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${chSpec.actLabel} ${chSpec.title} — ${chSpec.villageName}',
                        style: const TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 17,
                          color: NightPalette.accentGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chSpec.storySummary,
                        style: const TextStyle(fontSize: 13, color: NightPalette.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '✨ 장 완료 해금: ${chSpec.unlockNotice}',
                        style: const TextStyle(fontSize: 12, color: NightPalette.jadeGreen),
                      ),
                    ],
                  ),
                ),
              ),

              // 단계 목록
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: stages.length,
                  itemBuilder: (ctx, idx) {
                    final st = stages[idx];
                    final unlocked = p.isStageUnlocked(st);
                    final stars = p.stageStars[st.code] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MurimCard(
                        borderColor: st.isBossStage
                            ? NightPalette.crimsonMoon
                            : NightPalette.borderGold.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    st.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: unlocked
                                          ? (st.isBossStage
                                              ? NightPalette.accentGold
                                              : NightPalette.textPrimary)
                                          : NightPalette.textMuted,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    3,
                                    (i) => Icon(
                                      i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                                      size: 18,
                                      color: NightPalette.accentGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              st.subtitle,
                              style: const TextStyle(fontSize: 12.5, color: NightPalette.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '💡 추천 구성: ${st.tacticalHint}',
                              style: const TextStyle(fontSize: 12, color: NightPalette.jadeShield),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: unlocked
                                      ? () {
                                          controller.applyRecommendedLoadoutForStage(st);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${st.code} 맞춤 추천 진법을 자동 장착했습니다!'),
                                            ),
                                          );
                                        }
                                      : null,
                                  icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                                  label: const Text('맞춤 진법 자동 적용'),
                                ),
                                FilledButton.icon(
                                  onPressed: unlocked
                                      ? () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => BattleScreen(
                                                controller: controller,
                                                stage: st,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                                  icon: const Icon(Icons.shield_moon_rounded, size: 18),
                                  label: Text(unlocked ? '수호 출정' : '이전 밤 수호 필요'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
