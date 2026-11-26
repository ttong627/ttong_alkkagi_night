import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart' hide Text;

import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'stage_and_county_transitions.dart';
import '../i18n/tr_text.dart';
import '../i18n/l10n.dart';

/// 수호 도감(초정밀 돌연변이 해부 · 전신 영웅 갤러리 · 세트 도감력) · 확률 100% 공개 · 심야 무한 혈전.
class CodexScreen extends StatelessWidget {
  const CodexScreen({
    super.key,
    required this.controller,
    this.embeddedInShell = false,
    this.initialTab = 0,
    this.onSwitchShellTab,
  });

  final GameController controller;
  final bool embeddedInShell;
  final int initialTab;
  final ValueChanged<int>? onSwitchShellTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: initialTab.clamp(0, 4),
      length: 5,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final p = controller.progress;
          final bonusPct = (p.codexPowerBonus * 100).toStringAsFixed(1);

          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: !embeddedInShell,
              centerTitle: false,
              title: const Text('수호 도감 · 세트 도감력'),
              actions: [
                TextButton.icon(
                  key: const Key('codex_open_odds_btn'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OddsScreen()),
                    );
                  },
                  icon: const NightSpriteIcon(
                    assetPath: NightArtRegistry.iconOdds,
                    fallbackIcon: Icons.fact_check_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    '확률 공개',
                    style: TextStyle(color: NightPalette.jadeGreen),
                  ),
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: NightPalette.accentGold,
                labelColor: NightPalette.accentGold,
                unselectedLabelColor: NightPalette.textMuted,
                tabs: [
                  Tab(text: tr('수호석(13)')),
                  Tab(text: tr('발사대(5)')),
                  Tab(text: tr('영수(5)')),
                  Tab(text: tr('동료(14)')),
                  Tab(text: tr('변이체(14)')),
                ],
              ),
            ),
            body: NightSceneBackdrop(
              child: Column(
                children: [
                  QuickPlayAndMenuBar(
                    controller: controller,
                    currentSection: 'codex',
                    embeddedInShell: embeddedInShell,
                    onSwitchShellTab: onSwitchShellTab,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    color: NightPalette.bgPanel.withValues(alpha: 0.94),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const NightSpriteIcon(
                              assetPath: NightArtRegistry.iconCodex,
                              fallbackIcon: Icons.menu_book_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '수집 ${p.codexCollectedCount}/${p.codexTotalCount}종 · 공방 가호 +$bonusPct%',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: NightPalette.accentGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          key: const Key('codex_open_endless_btn'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(132, 38),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            backgroundColor: NightPalette.accentGold,
                            foregroundColor: NightPalette.hanjiInk,
                          ),
                          onPressed: () {
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
                            Icons.local_fire_department_rounded,
                            size: 17,
                          ),
                          label: Text('무한혈전(${p.bestEndlessWave}파)'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStoneList(p),
                        _buildLauncherList(p),
                        _buildBeastList(context, p),
                        _buildCompanionList(context, p),
                        _buildMutantList(context, p),
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

  Widget _buildStoneList(PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: StoneMaterial.values.map((s) {
        final owned = p.unlockedStones.contains(s);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MurimCard(
            borderColor: owned ? Color(s.colorHex) : NightPalette.borderGold,
            child: Row(
              children: [
                NightSpriteIcon(
                  assetPath: NightArtRegistry.stoneAsset(s),
                  fallbackIcon: Icons.circle_rounded,
                  size: 56,
                  dimmed: !owned,
                  showFrame: true,
                  frameColor: Color(s.colorHex),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.grade}단 ${s.name} ${owned ? "· 해금 완료" : "· 미해금"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: owned
                              ? NightPalette.accentGold
                              : NightPalette.textMuted,
                        ),
                      ),
                      Text(
                        s.specialDesc,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: NightPalette.textPrimary,
                        ),
                      ),
                      Text(
                        '밀도 ${s.density.toStringAsFixed(2)} · 반발계수 ${s.restitution.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: NightPalette.jadeShield,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLauncherList(PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MurimCard(
            borderColor: NightPalette.jadeShield,
            child: Row(
              children: [
                const NightSpriteIcon(
                  assetPath: NightArtRegistry.towerGuardian,
                  fallbackIcon: Icons.account_balance_rounded,
                  size: 58,
                  showFrame: true,
                  frameColor: NightPalette.jadeShield,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '중앙 기명 수호탑 (현재 ${p.centralGuardianLevel}단)',
                        style: const TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 16.5,
                          color: NightPalette.accentGold,
                        ),
                      ),
                      const Text(
                        '마을 3요소(식량·논밭·가축)의 심장부. 전방위로 회전 조준하며 변이 대군에 자동 응사합니다.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: NightPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ...LauncherType.values.map((t) {
          final unlocked = t.unlockChapter <= p.effectiveArsenalChapter;
          final permLv = p.launcherPermanentLevels[t] ?? 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MurimCard(
              borderColor: Color(t.colorHex),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NightSpriteIcon(
                    assetPath: NightArtRegistry.launcherAsset(t),
                    fallbackIcon: Icons.gps_fixed_rounded,
                    size: 58,
                    dimmed: !unlocked,
                    showFrame: true,
                    frameColor: Color(t.colorHex),
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
                              '${t.name} (영구 $permLv단)',
                              style: TextStyle(
                                fontFamily: 'BlackHanSans',
                                fontSize: 16.5,
                                color: Color(t.colorHex),
                              ),
                            ),
                            Text(
                              unlocked ? '운용 가능' : '제${t.unlockChapter}장 해금',
                              style: const TextStyle(
                                fontSize: 12,
                                color: NightPalette.jadeGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.roleSummary,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '전장 승급 계보: ${t.tierNames.join(" → ")}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: NightPalette.textMuted,
                          ),
                        ),
                      ],
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

  Widget _buildBeastList(BuildContext context, PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: SpiritBeast.values.map((b) {
        final lv = p.beastLevels[b] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MurimCard(
            borderColor: lv > 0 ? Color(b.colorHex) : NightPalette.borderGold,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showCodexCharacterSheetDialog(
                context,
                title: '${b.name} · 코덱스 수호 영수 시트',
                subtitle: b.skillSummary,
                motionAssetPath: NightArtRegistry.beastMotionAsset(b),
                sheetAssetPath: NightArtRegistry.beastSheetAsset(b),
                fallbackAssetPath: NightArtRegistry.beastAsset(b),
                frameLabels: const ['① 영기 부유', '② 기운 응축', '③ 수호 탄 발사', '④ 신수 포효'],
                accentColor: Color(b.colorHex),
              ),
              child: Row(
                children: [
                  NightSpriteIcon(
                    assetPath: NightArtRegistry.beastMotionAsset(b),
                    fallbackAssetPath: NightArtRegistry.beastAsset(b),
                    fallbackIcon: Icons.pets_rounded,
                    size: 72,
                    borderRadius: 14,
                    fit: BoxFit.cover,
                    dimmed: lv == 0,
                    showFrame: true,
                    frameColor: Color(b.colorHex),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${b.name} ${lv > 0 ? "(영약 강화 $lv단)" : "(미영입 · 제${b.unlockChapter}장)"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: lv > 0
                                ? NightPalette.accentGold
                                : NightPalette.textMuted,
                          ),
                        ),
                        Text(
                          b.skillSummary,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '🎬 터치하여 코덱스 4프레임 캐릭터 시트 · 3D 모션 확대 보기',
                          style: TextStyle(
                            fontSize: 11.2,
                            color: NightPalette.jadeGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompanionList(BuildContext context, PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: HeroVsMutantShowcaseBanner(
            sceneAsset: NightArtRegistry.homeCommandLoop,
            badgeText: '구출 동료 ${p.unlockedCompanionCount} / 14인 집결 · 코덱스 시트 완비',
            title: '탄지무림 14대 영웅 3D 모션 · 캐릭터 시트 열전',
            subtitle:
                '각 영웅 카드를 누르면 코덱스로 제작한 4단계 연속 무공 캐릭터 시트와 3D 애니메이션을 감상할 수 있습니다.',
            leftHeroAsset: NightArtRegistry.charMotion('geomhwang'),
            leftHeroLabel: '검황 3D모션',
            rightMutantAsset:
                NightArtRegistry.mutantMotionAsset(MutantKind.chapterOverlord),
            rightMutantLabel: '대수괴 3D모션',
            artHeight: 192,
          ),
        ),
        ...CompanionHero.values.map((h) {
          final lv = p.companionLevels[h] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MurimCard(
              borderColor:
                  lv > 0 ? NightPalette.accentGold : NightPalette.borderGold,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showCodexCharacterSheetDialog(
                  context,
                  title: '${h.name} · ${h.title}',
                  subtitle: h.skillDesc,
                  motionAssetPath: NightArtRegistry.heroMotionAsset(h),
                  sheetAssetPath: NightArtRegistry.heroSheetAsset(h),
                  fallbackAssetPath: NightArtRegistry.heroAttackAsset(h),
                  frameLabels: const [
                    '① 전신 호위 대기',
                    '② 내공 응축 장전',
                    '③ 탄지·절기 사출',
                    '④ 필살 오의 폭발',
                  ],
                ),
                child: Row(
                  children: [
                    NightSpriteIcon(
                      assetPath: NightArtRegistry.heroMotionAsset(h),
                      fallbackAssetPath: NightArtRegistry.heroAttackAsset(h),
                      fallbackIcon: Icons.person_rounded,
                      size: 80,
                      borderRadius: 14,
                      fit: BoxFit.cover,
                      dimmed: lv == 0,
                      showFrame: true,
                      frameColor: NightPalette.accentGold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${h.name} · ${h.title} ${lv > 0 ? "(동행 $lv단)" : "(제${h.unlockChapter}장 구출 대기)"}',
                            style: TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 15.8,
                              color: lv > 0
                                  ? NightPalette.accentGold
                                  : NightPalette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            h.skillDesc,
                            style: const TextStyle(
                              fontSize: 12.6,
                              color: NightPalette.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            '🎬 캐릭터 시트(4컷) & 3D 애니메이션 보기 ▶',
                            style: TextStyle(
                              fontSize: 11.4,
                              fontWeight: FontWeight.bold,
                              color: NightPalette.jadeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatRatingBadge({
    required String label,
    required int rating,
    required Color activeColor,
  }) {
    final stars = List.generate(5, (i) => i < rating ? '★' : '☆').join();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: NightPalette.bgDeep.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: activeColor.withValues(alpha: 0.55)),
      ),
      child: Text(
        '$label $stars',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: activeColor,
        ),
      ),
    );
  }

  Widget _buildMutantList(BuildContext context, PlayerProgress p) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 상단 초정밀 돌연변이 생태 & 3페이즈 보스 라이브 3D 모션 주인공 배너 (높이 204px 로 주인공 힘 확보!)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: HeroVsMutantShowcaseBanner(
            sceneAsset: NightArtRegistry.mutantPackBanner,
            badgeText:
                '코덱스 변이 시트 ${MutantKind.values.length}종 완비 · 조우 ${p.seenMutants.length}/${MutantKind.values.length}종',
            title: '돌연변이 디테일 해부 시트 & 비행·다단보스 3D 모션록',
            subtitle:
                '각 변이체 카드를 누르면 1→2→3페이즈 외형 탈피 시트와 실시간 3D 모션 영상을 확대하여 확인할 수 있습니다.',
            leftHeroAsset: NightArtRegistry.charMotion('sabu'),
            leftHeroLabel: '기명 탄지',
            rightMutantAsset:
                NightArtRegistry.mutantMotionAsset(MutantKind.chapterOverlord),
            rightMutantLabel: '3페이즈 진화',
            artHeight: 204,
          ),
        ),
        ...MutantKind.values.map((m) {
          final seen = p.seenMutants.contains(m);
          final accent = m.isBoss
              ? NightPalette.crimsonMoon
              : NightPalette.jadeShield;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MurimCard(
              borderColor: seen ? accent : NightPalette.borderGold,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showCodexCharacterSheetDialog(
                  context,
                  title: '${m.name} (${m.roleTag})',
                  subtitle: m.traitDesc,
                  motionAssetPath: NightArtRegistry.mutantMotionAsset(m),
                  sheetAssetPath: NightArtRegistry.mutantSheetAsset(m),
                  fallbackAssetPath: NightArtRegistry.mutantShowcaseAsset(m),
                  frameLabels: m.isBoss
                      ? (m.isMidBoss
                          ? const [
                              '① 선봉 지휘 돌격',
                              '② 2차 흉폭 재변이',
                              '③ 마갑 연타 저항',
                              '④ 진영 돌파 강타',
                            ]
                          : const [
                              '① 1페이즈 중갑 강림',
                              '② 2페이즈 외피 변이',
                              '③ 3페이즈 심연 폭주',
                              '④ 파성 필살 강타',
                            ])
                      : const [
                          '① 포식 배회',
                          '② 질주 도약',
                          '③ 발톱·독기 강타',
                          '④ 광폭 돌진',
                        ],
                  accentColor: accent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NightSpriteIcon(
                          assetPath: NightArtRegistry.mutantMotionAsset(m),
                          fallbackAssetPath:
                              NightArtRegistry.mutantShowcaseAsset(m),
                          fallbackIcon: m.isBoss
                              ? Icons.whatshot_rounded
                              : Icons.pest_control_rounded,
                          size: 86,
                          borderRadius: 14,
                          fit: BoxFit.cover,
                          dimmed: !seen,
                          showFrame: true,
                          frameColor:
                              m.isBoss ? NightPalette.accentGold : accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    m.name,
                                    style: TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 16.5,
                                      color: seen
                                          ? NightPalette.accentGold
                                          : NightPalette.textMuted,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.65),
                                      ),
                                    ),
                                    child: Text(
                                      m.roleTag,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: NightPalette.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '전투력 ${m.combatPower}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: NightPalette.jadeGreen,
                                    ),
                                  ),
                                  if (m.isFlying)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x3348CAE4),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF90E0EF),
                                        ),
                                      ),
                                      child: const Text(
                                        '🪽공중 비행',
                                        style: TextStyle(
                                          fontSize: 10.2,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF90E0EF),
                                        ),
                                      ),
                                    ),
                                  if (m.baseHitShield > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0x33FF006E),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFFFD166),
                                        ),
                                      ),
                                      child: Text(
                                        '🛡️${m.baseHitShield}타+ 마갑',
                                        style: const TextStyle(
                                          fontSize: 10.2,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFFD166),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '체력 ${m.baseHp.round()} · 속도 ${m.speed.round()} · 공격력 ${m.attackPower.round()} · 증표 +${m.dropTokens}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: NightPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _buildStatRatingBadge(
                                    label: '스피드',
                                    rating: m.speedRating,
                                    activeColor: NightPalette.accentGold,
                                  ),
                                  _buildStatRatingBadge(
                                    label: '맷집',
                                    rating: m.toughnessRating,
                                    activeColor: NightPalette.jadeShield,
                                  ),
                                  _buildStatRatingBadge(
                                    label: '공격력',
                                    rating: m.attackRating,
                                    activeColor: NightPalette.crimsonMoon,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      m.traitDesc,
                      style: const TextStyle(
                        fontSize: 12.2,
                        height: 1.36,
                        color: NightPalette.jadeShield,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      m.isBoss
                          ? '🎬 터치하여 1·2·3페이즈 진화 해부 시트 & 3D 모션 보기 ▶'
                          : '🎬 터치하여 4단계 생체 돌격 시트 & 3D 모션 보기 ▶',
                      style: const TextStyle(
                        fontSize: 11.3,
                        fontWeight: FontWeight.bold,
                        color: NightPalette.accentGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// 게임 내 확률 및 물리 수치 100% 투명 공개 화면.
class OddsScreen extends StatelessWidget {
  const OddsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('확률 및 물리 수치 100% 공개')),
      body: NightSceneBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MurimCard(
              borderColor: NightPalette.jadeGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NightSpriteIcon(
                        assetPath: NightArtRegistry.iconOdds,
                        fallbackIcon: Icons.fact_check_rounded,
                        size: 40,
                        showFrame: true,
                        frameColor: NightPalette.jadeGreen,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '유료 무작위 상자 0건 · 결제 0건 · 광고 0건',
                          style: TextStyle(
                            fontFamily: 'BlackHanSans',
                            fontSize: 18,
                            color: NightPalette.jadeGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '《수호알까기 · 탄지무림 심야기습》에는 유료 확률형 아이템이 전혀 존재하지 않습니다. '
                    '전장의 즐거움을 더하는 절벽 뽀록, 어부지리 도탄, 설렘 기연의 실제 작동 수치를 코드 그대로 투명하게 공개합니다.',
                    style: TextStyle(fontSize: 13.5, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...OddsDisclosureRow.all.map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MurimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            '[${row.category}] ${row.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: NightPalette.accentGold,
                            ),
                          ),
                          Text(
                            row.rateText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: NightPalette.jadeGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row.detail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: NightPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 심야 무한 혈전(생존 투기장) 출정 준비 화면.
class EndlessSurvivalScreen extends StatefulWidget {
  const EndlessSurvivalScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<EndlessSurvivalScreen> createState() => _EndlessSurvivalScreenState();
}

class _EndlessSurvivalScreenState extends State<EndlessSurvivalScreen> {
  int _selectedWaves = 30;
  int _selectedThemeChapter = 1;

  @override
  void initState() {
    super.initState();
    _selectedThemeChapter = widget.controller.progress.effectiveArsenalChapter;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final p = widget.controller.progress;
        final maxCh = p.effectiveArsenalChapter.clamp(1, 10);
        final selectedChapter =
            CampaignCatalog.chapterOf(_selectedThemeChapter.clamp(1, maxCh));

        return Scaffold(
          appBar: AppBar(title: const Text('심야 무한 혈전 · 한계 시험장')),
          body: NightSceneBackdrop(
            assetPath: selectedChapter.bgAsset,
            fallbackAssetPath: NightArtRegistry.bgNightLobby,
            overlayOpacity: 0.76,
            child: Column(
              children: [
                QuickPlayAndMenuBar(
                  controller: widget.controller,
                  currentSection: 'endless',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    children: [
                // 1) 상단 시네마틱 주인공: 황금 기마대 대 뿔 괴수 해일 결전 배너
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 740),
                    child: HeroVsMutantShowcaseBanner(
                      sceneAsset: NightArtRegistry.cardEndlessAbyss,
                      badgeText:
                          '전체 최고: ${p.bestEndlessWave}물결 · ${widget.controller.selectedDifficulty.name.split(" · ").first}: ${p.bestEndlessByDifficulty[widget.controller.selectedDifficulty.id] ?? 0}물결 · 토벌: ${p.totalMutantKills}마리',
                      title: '100물결 심야 무한 혈전 결사항전',
                      subtitle:
                          '3물결마다 재변이 두목이 침공하고 5물결마다 3페이즈 대수괴가 난입합니다. 무림수호단 기마대와 함께 끝없는 괴수 해일을 격파하세요.',
                      leftHeroAsset: NightArtRegistry.heroAttackAsset(
                        CompanionHero.geomhwang,
                      ),
                      leftHeroLabel: '검황 출격',
                      rightMutantAsset: NightArtRegistry.showcaseBossCrimson,
                      rightMutantLabel: '적염 파성귀',
                      artHeight: 176,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2) 물결 · 지형 선택 및 출정 통합 제어반
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 740),
                    child: MurimCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. 도전 목표 물결 선택',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: NightPalette.accentGold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [15, 30, 50, 100].map((w) {
                              return ChoiceChip(
                                visualDensity: VisualDensity.compact,
                                selected: _selectedWaves == w,
                                label: Text('$w물결 연속 수호'),
                                onSelected: (_) =>
                                    setState(() => _selectedWaves = w),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            '2. 난이도 선택 (난이도별 최고 돌파 기록 별도 집계)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: NightPalette.accentGold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<DefenseDifficulty>(
                            segments: DefenseDifficulty.values
                                .map(
                                  (d) => ButtonSegment(
                                    value: d,
                                    label: Text(
                                      '${d.name.split(" · ").first} (최고 ${p.bestEndlessByDifficulty[d.id] ?? 0})',
                                    ),
                                  ),
                                )
                                .toList(),
                            selected: {widget.controller.selectedDifficulty},
                            onSelectionChanged: (s) {
                              widget.controller.setDifficulty(s.first);
                              setState(() {});
                            },
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            '3. 전장 지형 선택 (해금된 장 기준)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: NightPalette.accentGold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            key: ValueKey(
                              'endless_ch_${maxCh}_${_selectedThemeChapter.clamp(1, maxCh)}',
                            ),
                            isExpanded: true,
                            initialValue: _selectedThemeChapter.clamp(1, maxCh),
                            items: List.generate(maxCh, (idx) {
                              final ch = CampaignCatalog.chapterOf(idx + 1);
                              return DropdownMenuItem<int>(
                                value: ch.number,
                                child: Text(
                                  '제${ch.number}장 · ${ch.villageName} (${ch.title})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedThemeChapter = v);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              key: const Key('start_endless_battle_btn'),
                              style: FilledButton.styleFrom(
                                backgroundColor: NightPalette.accentGold,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                final stage =
                                    EndlessWaveBuilder.buildEndlessStage(
                                  waveCount: _selectedWaves,
                                  chapterTheme: _selectedThemeChapter,
                                );
                                Navigator.of(context).push(
                                  buildSmoothBattleRoute(
                                    controller: widget.controller,
                                    stage: stage,
                                  ),
                                );
                              },
                              icon: const NightSpriteIcon(
                                assetPath: NightArtRegistry.nightEndless,
                                fallbackIcon: Icons.bolt_rounded,
                                size: 22,
                              ),
                              label: Text(
                                '심야 무한 혈전 ($_selectedWaves물결) 출정!',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
