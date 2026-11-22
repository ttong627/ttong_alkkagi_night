import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'stage_and_county_transitions.dart';

typedef ConvoySerendipityScreen = ConvoyAndSerendipityScreen;

/// 물자 호송 · 심야 탐색 · 보름달 길조 기연 & 암행어사 출두 지원패 수급소.
class ConvoyAndSerendipityScreen extends StatelessWidget {
  const ConvoyAndSerendipityScreen({
    super.key,
    required this.controller,
    this.embeddedInShell = false,
  });

  final GameController controller;
  final bool embeddedInShell;

  Widget _buildRewardLine({
    required String assetPath,
    required IconData fallbackIcon,
    required String text,
    Color textColor = NightPalette.textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          NightSpriteIcon(
            assetPath: assetPath,
            fallbackIcon: fallbackIcon,
            size: 22,
            borderRadius: 6,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showClaimDialog(BuildContext context, DispatchClaimResult res) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NightPalette.bgPanel,
        title: Row(
          children: [
            const NightSpriteIcon(
              assetPath: NightArtRegistry.nightSerendipity,
              fallbackIcon: Icons.auto_awesome_rounded,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                res.title,
                style: const TextStyle(color: NightPalette.accentGold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (res.wasCritical)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '⚡ 크리티컬 대풍년 기연 발동! (보상 2배 폭발!)',
                  style: TextStyle(color: NightPalette.accentGold),
                ),
              ),
            if (res.wasEncoreOneMore)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '🔁 한 번 더 기연 발동! (뒤따라온 보너스 마차 합류!)',
                  style: TextStyle(color: NightPalette.jadeGreen),
                ),
              ),
            const SizedBox(height: 6),
            _buildRewardLine(
              assetPath: NightArtRegistry.nightToken,
              fallbackIcon: Icons.generating_tokens_rounded,
              text: '변이 토벌 증표: +${res.gainedTokens}',
            ),
            _buildRewardLine(
              assetPath: NightArtRegistry.nightElixir,
              fallbackIcon: Icons.science_rounded,
              text: '신비 영약: +${res.gainedElixirs}',
            ),
            if (res.gainedSupportTokens > 0)
              _buildRewardLine(
                assetPath: NightArtRegistry.nightSupportSeal,
                fallbackIcon: Icons.campaign_rounded,
                text: '무림수호단 지원패: +${res.gainedSupportTokens}개!',
                textColor: NightPalette.accentGold,
              ),
            if (res.gainedShards > 0)
              _buildRewardLine(
                assetPath: NightArtRegistry.stoneAsset(StoneMaterial.taegeuk),
                fallbackIcon: Icons.auto_awesome_mosaic_rounded,
                text: '신물 수호석 조각: +${res.gainedShards}개',
                textColor: NightPalette.jadeShield,
              ),
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

  Widget _buildVillageEcoBadge({
    required String assetPath,
    required IconData fallbackIcon,
    required String label,
    required String roleText,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: NightPalette.bgDeep.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NightPalette.jadeGreen.withValues(alpha: 0.42)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NightSpriteIcon(
              assetPath: assetPath,
              fallbackIcon: fallbackIcon,
              size: 40,
              borderRadius: 8,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: NightPalette.accentGold,
              ),
            ),
            Text(
              roleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: NightPalette.jadeGreen),
            ),
          ],
        ),
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
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: !embeddedInShell,
            title: const Text('보급 호송 · 심야 탐색 · 기연각'),
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
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                // 상단 주인공: 마차 호위 무사·구르미 대 변이 들개 격전 원화 + 원터치 일괄 수령/재파견
                HeroVsMutantShowcaseBanner(
                  sceneAsset: NightArtRegistry.cardSupplyConvoy,
                  badgeText: '보유 지원패(무림수호단 출두): ${p.supportTokens}개',
                  title: '협곡 군량 호송대 & 심야 봉화 탐색',
                  subtitle:
                      '마차 호송·심야 탐색·보름달 기연 보상을 한 번에 수령하고 자동 재출발합니다.',
                  leftHeroAsset: NightArtRegistry.charAttack('banDal'),
                  leftHeroLabel: '반달 호위',
                  rightMutantAsset:
                      NightArtRegistry.mutantAttackAsset(MutantKind.sickHound),
                  rightMutantLabel: '습격 변이군',
                  artHeight: 112,
                  actionRow: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton.icon(
                      key: const Key('convoy_batch_claim_btn'),
                      style: FilledButton.styleFrom(
                        backgroundColor: NightPalette.hanjiInk,
                        foregroundColor: NightPalette.accentGold,
                      ),
                      onPressed: () {
                        final s = controller.claimAllReadyRewards();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: NightPalette.bgCard,
                            content: Text(
                              s.hasAnyAction
                                  ? '보급 일괄 정리 완료! 증표 +${s.gainedTokens} · 영약 +${s.gainedElixirs} · 지원패 +${s.gainedSupportTokens}'
                                  : '모든 마차·탐색대가 운행 중이거나 수령할 보상이 없습니다.',
                              style: const TextStyle(
                                color: NightPalette.accentGold,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.redeem_rounded, size: 18),
                      label: const Text(
                        '도착 보상 일괄 수령 & 재파견',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 1) 보름달 길조 게이지 (기연 경로 — 첫 화면에서 스크롤 없이 즉시 개봉!)
                MurimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const NightSpriteIcon(
                            assetPath: NightArtRegistry.nightSerendipity,
                            fallbackIcon: Icons.auto_awesome_rounded,
                            size: 44,
                            showFrame: true,
                            frameColor: NightPalette.accentGold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🌕 보름달 길조 게이지 (${p.moonOmenGauge} / 100)',
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: (p.moonOmenGauge / 100.0).clamp(0.0, 1.0),
                                  minHeight: 10,
                                  borderRadius: BorderRadius.circular(6),
                                  color: NightPalette.accentGold,
                                  backgroundColor: NightPalette.bgDeep,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '보름달(100)이 차오르면 영약·신물 조각·지원패 특급 기연이 100% 확정 발동합니다.',
                        style: TextStyle(fontSize: 12.2, color: NightPalette.textMuted),
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
                          icon: const NightSpriteIcon(
                            assetPath: NightArtRegistry.nightSerendipity,
                            fallbackIcon: Icons.auto_awesome_rounded,
                            size: 18,
                          ),
                          label: const Text('보름달 특급 기연 열기'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 지원패 보유 현황 및 마을 생태 3요소 안내
                MurimCard(
                  borderColor: NightPalette.accentGold,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const NightSpriteIcon(
                            assetPath: NightArtRegistry.nightSupportSeal,
                            fallbackIcon: Icons.campaign_rounded,
                            size: 46,
                            showFrame: true,
                            frameColor: NightPalette.accentGold,
                          ),
                          const SizedBox(width: 10),
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
                          const SizedBox(width: 6),
                          const NightSpriteIcon(
                            assetPath: NightArtRegistry.fxChuldu,
                            fallbackIcon: Icons.bolt_rounded,
                            size: 36,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '전장 위기 시 태평소 풍악과 함께 아군 기마·수호알 대열이 온 길목의 돌연변이를 한데 싹 몰아 전멸시키고 떠납니다!\n'
                        '수급 3대 경로: ① 조건 달성(물자 호송 완수 · 마을 3요소 무피해 ★3 첫 달성) · ② 설렘 기연(전투·깨달음 보름달 길조) · ③ 심야 탐색(산채 봉화대)',
                        style: TextStyle(fontSize: 12.5, color: NightPalette.textMuted, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildVillageEcoBadge(
                            assetPath: NightArtRegistry.villageGranary,
                            fallbackIcon: Icons.warehouse_rounded,
                            label: '식량창고',
                            roleText: '호송 군량 비축',
                          ),
                          const SizedBox(width: 6),
                          _buildVillageEcoBadge(
                            assetPath: NightArtRegistry.villageCrops,
                            fallbackIcon: Icons.grass_rounded,
                            label: '논밭',
                            roleText: '영약 약초 재배',
                          ),
                          const SizedBox(width: 6),
                          _buildVillageEcoBadge(
                            assetPath: NightArtRegistry.villageLivestock,
                            fallbackIcon: Icons.pets_rounded,
                            label: '가축 우리',
                            roleText: '수레 우마 보급',
                          ),
                        ],
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
                      Row(
                        children: [
                          NightSpriteIcon(
                            assetPath: NightArtRegistry.nightConvoyCart,
                            fallbackIcon: Icons.local_shipping_rounded,
                            size: 48,
                            dimmed: !convoyUnlocked,
                            showFrame: true,
                            frameColor: NightPalette.jadeGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '🐎 구출 마을 물자 호송 마차 ${p.convoySupplyBuffBattles > 0 ? "(풍년 군자금 +20% 버프 ${p.convoySupplyBuffBattles}판 남음)" : ""}',
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: NightPalette.jadeGreen,
                              ),
                            ),
                          ),
                        ],
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
                      Row(
                        children: [
                          NightSpriteIcon(
                            assetPath: NightArtRegistry.charFace('gurumi'),
                            fallbackAssetPath: NightArtRegistry.iconCampaign,
                            fallbackIcon: Icons.explore_rounded,
                            size: 46,
                            borderRadius: 23,
                            fit: BoxFit.cover,
                            dimmed: !exploreUnlocked,
                            showFrame: true,
                            frameColor: NightPalette.elixirPurple,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              '🧭 산야 봉화대 심야 탐색 파견',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: NightPalette.elixirPurple,
                              ),
                            ),
                          ),
                        ],
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 1~10현(각 현 10마을 = 총 100판) 코덱스 대륙도 · 현내 10마을 이동 지도 & 현간 대행군 영상 캠페인 화면.
class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  // true: 현내 10개 마을 행군 지도(마을마다 이동), false: 10대 현 대륙도
  bool _showVillageRouteMap = true;

  GameController get controller => widget.controller;

  // 코덱스 대륙 지도(world_map_murim_night.webp) 실제 10대 현 정규화 좌표 (남단 1현 -> 북단 10현)
  static const List<Offset> _chapterMapCoords = <Offset>[
    Offset(0.50, 0.87), // 1현 청산 흙먼지현
    Offset(0.43, 0.68), // 2현 통통 객잔현
    Offset(0.66, 0.59), // 3현 청옥 거북장터현
    Offset(0.20, 0.49), // 4현 쿠비 봉화산현
    Offset(0.80, 0.44), // 5현 황동 기관학당현
    Offset(0.50, 0.39), // 6현 만년설 백옥무림현
    Offset(0.20, 0.31), // 7현 적월 열사사막현
    Offset(0.80, 0.27), // 8현 창파 등대함대현
    Offset(0.38, 0.25), // 9현 흑요 적염화산현
    Offset(0.62, 0.15), // 10현 천상 태극신전현
  ];

  Widget _buildInteractiveCountyVillageMap({
    required BuildContext context,
    required PlayerProgress progress,
    required ChapterSpec chSpec,
    required List<StageSpec> stages,
    required StageSpec currentOrderStage,
    required bool allCampaignCleared,
  }) {
    final villageCoords = stages
        .map((s) => Offset(s.villageMapCoord.x, s.villageMapCoord.y))
        .toList();
    int clearedInCounty = 0;
    for (final s in stages) {
      if (s.globalIndex <= progress.highestClearedGlobalStage) {
        clearedInCounty++;
      }
    }

    return SizedBox(
      height: 196,
      child: LayoutBuilder(
        builder: (ctx, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                chSpec.bgAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  NightArtRegistry.bgNightLobby,
                  fit: BoxFit.cover,
                ),
              ),
              Container(color: const Color(0x6E070E1B)),
              CustomPaint(
                painter: _CountyVillageRoutePainter(
                  coords: villageCoords,
                  clearedCountInCounty: clearedInCounty,
                ),
              ),
              for (int i = 0; i < stages.length; i++)
                Builder(
                  builder: (_) {
                    final st = stages[i];
                    final unlocked = progress.isStageUnlocked(st);
                    final cleared =
                        st.globalIndex <= progress.highestClearedGlobalStage;
                    final isCurrent = !allCampaignCleared &&
                        st.globalIndex == currentOrderStage.globalIndex;
                    final norm = villageCoords[i];
                    final px = (norm.dx * w).clamp(32.0, w - 32.0);
                    final py = (norm.dy * h).clamp(18.0, h - 24.0);

                    final Color bgCol = isCurrent
                        ? NightPalette.accentGold
                        : (cleared
                            ? const Color(0xEE164B41)
                            : (unlocked
                                ? const Color(0xEE8E2A2A)
                                : const Color(0xCC101929)));
                    final Color fgCol = isCurrent
                        ? NightPalette.hanjiInk
                        : (unlocked
                            ? NightPalette.textPrimary
                            : NightPalette.textMuted);

                    return Positioned(
                      left: px - 29,
                      top: py - 13,
                      width: 58,
                      height: 26,
                      child: GestureDetector(
                        key: Key('village_node_${st.code}'),
                        onTap: unlocked
                            ? () {
                                Navigator.of(context).push(
                                  buildSmoothBattleRoute(
                                    controller: controller,
                                    stage: st,
                                  ),
                                );
                              }
                            : null,
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: bgCol,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.white
                                  : (st.isBossStage
                                      ? NightPalette.crimsonMoon
                                      : (unlocked
                                          ? NightPalette.accentGold
                                          : NightPalette.borderGold
                                              .withValues(alpha: 0.3))),
                              width: isCurrent ? 2.0 : 1.1,
                            ),
                          ),
                          child: Text(
                            '${unlocked ? (isCurrent ? "⚔️" : (cleared ? "✓" : "▶")) : "🔒"}${st.stageNumber}판${st.stageNumber == 10 ? "👑" : ""}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.2,
                              fontWeight: FontWeight.bold,
                              color: fgCol,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              Positioned(
                left: 8,
                bottom: 6,
                right: 8,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE00C1526),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: NightPalette.accentGold.withValues(alpha: 0.65),
                      ),
                    ),
                    child: Text(
                      '🏘️ ${chSpec.countyName} ($clearedInCounty/10판 · 마을 터치 시 즉시 진입)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
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
    );
  }

  Widget _buildInteractiveWorldMap({
    required BuildContext context,
    required PlayerProgress progress,
    required int selectedChapterNumber,
  }) {
    return SizedBox(
      height: 204,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
        child: LayoutBuilder(
          builder: (ctx, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  NightArtRegistry.worldMapLiveMotion,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => Image.asset(
                    NightArtRegistry.worldMapMurimNight,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      NightArtRegistry.bgNightLobby,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                CustomPaint(
                  painter: _WorldMapRoutePainter(
                    coords: _chapterMapCoords,
                    unlockedChapter: progress.highestUnlockedChapter,
                    selectedChapter: selectedChapterNumber,
                  ),
                ),
                for (int i = 0; i < CampaignCatalog.chapters.length; i++)
                  Builder(
                    builder: (_) {
                      final chNum = i + 1;
                      final allDone = progress.highestClearedGlobalStage >=
                          CampaignCatalog.allStages.length;
                      final unlocked = chNum <= progress.highestUnlockedChapter;
                      final selected = chNum == selectedChapterNumber;
                      final cleared = chNum < progress.highestUnlockedChapter ||
                          (chNum == 10 && allDone);
                      final norm = _chapterMapCoords[i];
                      final px = (norm.dx * w).clamp(28.0, w - 28.0);
                      final py = (norm.dy * h).clamp(20.0, h - 22.0);

                      final Color pinBg = selected
                          ? NightPalette.accentGold
                          : (cleared
                              ? const Color(0xEE184E44)
                              : (unlocked
                                  ? const Color(0xEE8C2D2D)
                                  : const Color(0xCC121B2C)));
                      final Color pinFg = selected
                          ? NightPalette.hanjiInk
                          : (unlocked
                              ? NightPalette.textPrimary
                              : NightPalette.textMuted);

                      return Positioned(
                        left: px - 26,
                        top: py - 14,
                        width: 52,
                        height: 28,
                        child: GestureDetector(
                          onTap: unlocked
                              ? () => controller.setSelectedChapter(chNum)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: pinBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : (unlocked
                                        ? NightPalette.accentGold
                                        : NightPalette.borderGold
                                            .withValues(alpha: 0.35)),
                                width: selected ? 2.0 : 1.2,
                              ),
                            ),
                            child: Text(
                              '${unlocked ? (cleared ? "✓" : "🔥") : "🔒"}$chNum장',
                              style: TextStyle(
                                fontSize: 10.6,
                                fontWeight: FontWeight.bold,
                                color: pinFg,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                Positioned(
                  right: 10,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xE00E1728),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: NightPalette.accentGold.withValues(alpha: 0.7),
                      ),
                    ),
                    child: const Text(
                      '🗺️ 탄지무림 10대 거점 심야 수호 대륙도 (거점 터치 이동)',
                      style: TextStyle(
                        fontSize: 10.8,
                        fontWeight: FontWeight.bold,
                        color: NightPalette.accentGold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.progress;
        final allCampaignCleared =
            p.highestClearedGlobalStage >= CampaignCatalog.allStages.length;
        final nextGlobal = (p.highestClearedGlobalStage + 1)
            .clamp(1, CampaignCatalog.allStages.length);
        final currentOrderStage = CampaignCatalog.allStages[nextGlobal - 1];
        final nextRescue = p.nextRescueStage;
        final safeChapter = controller.selectedChapter
            .clamp(1, p.highestUnlockedChapter.clamp(1, 10));
        final chSpec = CampaignCatalog.chapterOf(safeChapter);
        final stages = CampaignCatalog.stagesOfChapter(chSpec.number);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '탄지무림 10현·100판 수호록 (${p.highestClearedGlobalStage}/${CampaignCatalog.allStages.length}판)',
            ),
            actions: [
              TextButton.icon(
                key: const Key('campaign_open_county_video_btn'),
                onPressed: () {
                  Navigator.of(context).push(
                    buildSmoothScreenRoute(
                      CountyTransitionScreen(
                        controller: controller,
                        fromChapter: chSpec.number.clamp(1, 9),
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.movie_filter_rounded,
                  size: 18,
                  color: NightPalette.accentGold,
                ),
                label: const Text(
                  '현 이동 영상',
                  style: TextStyle(
                    fontSize: 12.2,
                    color: NightPalette.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: NightSceneBackdrop(
            assetPath: chSpec.bgAsset,
            fallbackAssetPath: NightArtRegistry.bgNightLobby,
            overlayOpacity: 0.80,
            child: Column(
              children: [
                // 1) 10현 대륙도 ↔ 현내 10마을 행군 지도 전환형 지령대
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: NightPalette.bgPanel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: NightPalette.accentGold,
                        width: 1.8,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: const Color(0xF00E1728),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  key: const Key('campaign_toggle_village_map'),
                                  visualDensity: VisualDensity.compact,
                                  selected: _showVillageRouteMap,
                                  label: Text(
                                    '🏘️ 제${chSpec.number}현 10마을 지도',
                                    style: const TextStyle(fontSize: 11.4),
                                  ),
                                  onSelected: (_) => setState(
                                    () => _showVillageRouteMap = true,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ChoiceChip(
                                  key: const Key('campaign_toggle_world_map'),
                                  visualDensity: VisualDensity.compact,
                                  selected: !_showVillageRouteMap,
                                  label: const Text(
                                    '🌏 10대 현 대륙도',
                                    style: TextStyle(fontSize: 11.4),
                                  ),
                                  onSelected: (_) => setState(
                                    () => _showVillageRouteMap = false,
                                  ),
                                ),
                                if (chSpec.number < 10 &&
                                    (chSpec.number < p.highestUnlockedChapter ||
                                        allCampaignCleared)) ...[
                                  const SizedBox(width: 6),
                                  ActionChip(
                                    key: const Key('campaign_quick_next_county_btn'),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: const Color(0xFF283A18),
                                    label: Text(
                                      '🎬 ${chSpec.number}현➔${chSpec.number + 1}현 대행군',
                                      style: const TextStyle(
                                        fontSize: 11.2,
                                        color: NightPalette.accentGold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        buildSmoothScreenRoute(
                                          CountyTransitionScreen(
                                            controller: controller,
                                            fromChapter: chSpec.number,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_showVillageRouteMap)
                          _buildInteractiveCountyVillageMap(
                            context: context,
                            progress: p,
                            chSpec: chSpec,
                            stages: stages,
                            currentOrderStage: currentOrderStage,
                            allCampaignCleared: allCampaignCleared,
                          )
                        else
                          _buildInteractiveWorldMap(
                            context: context,
                            progress: p,
                            selectedChapterNumber: chSpec.number,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                          child: Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: CampaignCatalog.chapters.map((c) {
                                    final unlocked =
                                        c.number <= p.highestUnlockedChapter;
                                    final selected = c.number == chSpec.number;
                                    final chCleared =
                                        c.number < p.highestUnlockedChapter ||
                                            (c.number == 10 &&
                                                allCampaignCleared);
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        selected: selected,
                                        label: Text(
                                          '${unlocked ? (chCleared ? "✓" : "▶") : "🔒"}${c.number}현 ${c.shortCountyName} (10판)',
                                        ),
                                        onSelected: unlocked
                                            ? (_) => controller
                                                .setSelectedChapter(c.number)
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SegmentedButton<DefenseDifficulty>(
                                    segments: DefenseDifficulty.values
                                        .map((d) => ButtonSegment(
                                              value: d,
                                              label: Text(
                                                  d.name.split(' · ').first),
                                            ))
                                        .toList(),
                                    selected: {controller.selectedDifficulty},
                                    onSelectionChanged: (s) =>
                                        controller.setDifficulty(s.first),
                                    style: const ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                  if (nextRescue != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xDD11353B),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: NightPalette.jadeGreen),
                                      ),
                                      child: Text(
                                        '🆘 다음 구출: ${nextRescue.code} ${nextRescue.rescueBadgeText}',
                                        style: const TextStyle(
                                          fontSize: 11.2,
                                          color: NightPalette.jadeGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: NightPalette.hanjiLight,
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              NightSpriteIcon(
                                assetPath: chSpec.floorAsset,
                                fallbackAssetPath: NightArtRegistry.charMotion(
                                    chSpec.bossPortraitPrefix),
                                fallbackIcon: Icons.map_rounded,
                                size: 52,
                                borderRadius: 10,
                                fit: BoxFit.cover,
                                showFrame: true,
                                frameColor: NightPalette.hanjiInk,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${chSpec.countyName} — ${chSpec.villageName}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 15.0,
                                        color: NightPalette.hanjiInk,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '🗺️ ${chSpec.routeTopologyTag} · ✨ ${chSpec.chapterTraitTitle} (${chSpec.chapterTraitDesc})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.2,
                                        color: Color(0xFF164E63),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      allCampaignCleared
                                          ? '🏆 전 100판(10현×10마을) 완전 정화 달성! 원하는 판을 자유 재도전하세요.'
                                          : '현재 수호 차례: ${currentOrderStage.title} (초소 ${currentOrderStage.maxMountCount}곳 개방)',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.8,
                                        color: NightPalette.hanjiSubInk,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              NightSpriteIcon(
                                assetPath: NightArtRegistry.mutantMotionAsset(
                                  MutantKind.chapterOverlord,
                                ),
                                fallbackAssetPath:
                                    NightArtRegistry.showcaseBossChapter,
                                fallbackIcon: Icons.whatshot_rounded,
                                size: 46,
                                borderRadius: 10,
                                fit: BoxFit.cover,
                                showFrame: true,
                                frameColor: NightPalette.crimsonMoon,
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(94, 42),
                                  backgroundColor: NightPalette.hanjiInk,
                                  foregroundColor: NightPalette.accentGold,
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    buildSmoothBattleRoute(
                                      controller: controller,
                                      stage: currentOrderStage,
                                    ),
                                  );
                                },
                                child: Text(
                                  allCampaignCleared ? '최종 관문 재출정' : '이번 차례 출정',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 순차 행군 관문 목록 (정화 완료 → ▶이번 수호 차례 강조 → 🔒순서 대기 간결 표시)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: stages.length,
                    itemBuilder: (ctx, idx) {
                      final st = stages[idx];
                      final unlocked = p.isStageUnlocked(st);
                      final isCleared =
                          st.globalIndex <= p.highestClearedGlobalStage;
                      final isCurrentOrder = !allCampaignCleared &&
                          st.globalIndex == currentOrderStage.globalIndex;
                      final stars = p.stageStars[st.code] ?? 0;

                      // 아직 순서가 오지 않은 미래 관문은 혼란스럽지 않도록 한 줄 행군 노드로 간결하게 표시!
                      if (!unlocked) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: NightPalette.bgPanel.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: NightPalette.borderGold.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                  color: NightPalette.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '순서 대기 · ${st.title}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.2,
                                      color: NightPalette.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '초소 ${st.maxMountCount}곳${st.hasRescueReward ? " · 🆘구출" : ""}',
                                  style: TextStyle(
                                    fontSize: 11.2,
                                    color: st.hasRescueReward
                                        ? NightPalette.jadeGreen
                                        : NightPalette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final invadingBosses = <MutantKind>{
                        for (final wave in st.waves)
                          for (final grp in wave)
                            if (grp.kind.isBoss) grp.kind,
                      }.toList();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MurimCard(
                          borderColor: isCurrentOrder
                              ? NightPalette.accentGold
                              : (st.isBossStage
                                  ? NightPalette.crimsonMoon
                                  : NightPalette.jadeGreen.withValues(alpha: 0.45)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrentOrder
                                          ? NightPalette.accentGold
                                          : const Color(0xCC16382E),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isCurrentOrder
                                          ? '▶ 이번 수호 차례!'
                                          : (isCleared ? '✓ 정화 완료' : '출정 가능'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentOrder
                                            ? Colors.black
                                            : NightPalette.jadeGreen,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xCC122238),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: NightPalette.jadeShield
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    child: Text(
                                      '초소 ${st.maxMountCount}곳 개방',
                                      style: const TextStyle(
                                        fontSize: 10.8,
                                        color: NightPalette.jadeShield,
                                      ),
                                    ),
                                  ),
                                  if (st.hasRescueReward)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xDD143D38),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: NightPalette.jadeGreen,
                                        ),
                                      ),
                                      child: Text(
                                        '🆘 ${st.rescueBadgeText}',
                                        style: const TextStyle(
                                          fontSize: 10.8,
                                          color: NightPalette.jadeGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  NightSpriteIcon(
                                    assetPath: st.isBossStage
                                        ? NightArtRegistry.mutantAsset(
                                            MutantKind.chapterOverlord,
                                          )
                                        : NightArtRegistry.stoneAsset(
                                            st.recommendedStone,
                                          ),
                                    fallbackIcon: st.isBossStage
                                        ? Icons.whatshot_rounded
                                        : Icons.circle_rounded,
                                    size: 38,
                                    showFrame: true,
                                    frameColor: isCurrentOrder
                                        ? NightPalette.accentGold
                                        : Color(st.recommendedStone.colorHex),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      st.title,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentOrder
                                            ? NightPalette.accentGold
                                            : NightPalette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      3,
                                      (i) => Icon(
                                        i < stars
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 18,
                                        color: NightPalette.accentGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                st.subtitle,
                                style: const TextStyle(
                                  fontSize: 12.2,
                                  color: NightPalette.textMuted,
                                ),
                              ),
                              if (invadingBosses.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: invadingBosses.map((bk) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: NightPalette.bgDeep
                                            .withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Color(bk.colorHex)
                                              .withValues(alpha: 0.72),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          NightSpriteIcon(
                                            assetPath:
                                                NightArtRegistry.mutantAttackAsset(
                                              bk,
                                            ),
                                            fallbackAssetPath:
                                                NightArtRegistry.mutantAsset(bk),
                                            fallbackIcon: Icons.whatshot_rounded,
                                            size: 18,
                                            borderRadius: 4,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              '${bk.name} (${bk.roleTag})',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: NightPalette.accentGold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      controller.applyRecommendedLoadoutForStage(
                                        st,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${st.code} 맞춤 추천 진법을 자동 장착했습니다!',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.auto_fix_high_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('맞춤 진법 적용'),
                                  ),
                                  FilledButton.icon(
                                    style: isCurrentOrder
                                        ? FilledButton.styleFrom(
                                            backgroundColor:
                                                NightPalette.accentGold,
                                            foregroundColor: Colors.black,
                                          )
                                        : null,
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        buildSmoothBattleRoute(
                                          controller: controller,
                                          stage: st,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.shield_moon_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isCurrentOrder ? '이번 차례 출정!' : '재수련 출정',
                                    ),
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
          ),
        );
      },
    );
  }
}

class _CountyVillageRoutePainter extends CustomPainter {
  const _CountyVillageRoutePainter({
    required this.coords,
    required this.clearedCountInCounty,
  });

  final List<Offset> coords;
  final int clearedCountInCounty;

  @override
  void paint(Canvas canvas, Size size) {
    if (coords.length < 2) return;
    final clearedGlow = Paint()
      ..color = const Color(0x554EE3C0)
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final clearedLine = Paint()
      ..color = const Color(0xEEFFD166)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final nextLine = Paint()
      ..color = const Color(0xAAFF7B54)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final lockedLine = Paint()
      ..color = const Color(0x558D99AE)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < coords.length - 1; i++) {
      final p1 = Offset(coords[i].dx * size.width, coords[i].dy * size.height);
      final p2 =
          Offset(coords[i + 1].dx * size.width, coords[i + 1].dy * size.height);
      if (i + 1 <= clearedCountInCounty) {
        canvas.drawLine(p1, p2, clearedGlow);
        canvas.drawLine(p1, p2, clearedLine);
      } else if (i == clearedCountInCounty) {
        canvas.drawLine(p1, p2, nextLine);
      } else {
        canvas.drawLine(p1, p2, lockedLine);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CountyVillageRoutePainter oldDelegate) =>
      oldDelegate.clearedCountInCounty != clearedCountInCounty;
}

class _WorldMapRoutePainter extends CustomPainter {
  const _WorldMapRoutePainter({
    required this.coords,
    required this.unlockedChapter,
    required this.selectedChapter,
  });

  final List<Offset> coords;
  final int unlockedChapter;
  final int selectedChapter;

  @override
  void paint(Canvas canvas, Size size) {
    if (coords.length < 2) return;
    final activePaint = Paint()
      ..color = const Color(0xDDF4CC6A)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final lockedPaint = Paint()
      ..color = const Color(0x558D99AE)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < coords.length - 1; i++) {
      final p1 = Offset(coords[i].dx * size.width, coords[i].dy * size.height);
      final p2 =
          Offset(coords[i + 1].dx * size.width, coords[i + 1].dy * size.height);
      final isOpen = (i + 2) <= unlockedChapter;
      canvas.drawLine(p1, p2, isOpen ? activePaint : lockedPaint);
    }

    if (selectedChapter >= 1 && selectedChapter <= coords.length) {
      final sel = coords[selectedChapter - 1];
      final sc = Offset(sel.dx * size.width, sel.dy * size.height);
      canvas.drawCircle(
        sc,
        22,
        Paint()
          ..color = const Color(0x44FFD166)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapRoutePainter oldDelegate) =>
      oldDelegate.unlockedChapter != unlockedChapter ||
      oldDelegate.selectedChapter != selectedChapter;
}
