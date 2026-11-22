import 'dart:math';

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../audio/night_audio.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'battle_screen.dart';
import 'codex_and_endless_screens.dart';
import 'convoy_campaign_screens.dart';
import 'daily_quests_screen.dart';
import 'loadout_upgrade_screens.dart';
import 'settings_and_credits_screen.dart';
import 'splash_and_tutorial.dart';
import 'training_screen.dart';

/// 수호 본영 통합 5탭 메인 쉘 화면:
/// 1) 출정 본영: 영웅 대 3페이즈 돌연변이 결전 지령대 + 원터치 일괄 보상 수령 + 6대 실전 전각 카드 덱
/// 2) 영웅 · 진법: 전신 영웅 쇼케이스 + 원터치 최적 진법 자동 편성
/// 3) 대장간 · 영약: 화포 대장간·영약각 + 원터치 추천 일괄 강화
/// 4) 수련 · 보급: 10회 연속 단전 수련 · 호송/탐색 · 출석/임무/비약 통합 허브
/// 5) 변이 도감: 12종 돌연변이 정밀 해부 도감 & 100물결 무한 혈전 직통 출정
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientAnim;
  int _selectedNavIndex = 0;
  int _supplySubTab = 0;

  @override
  void initState() {
    super.initState();
    NightAudioController.instance.playBgm('bgm_lobby.ogg');
    _ambientAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientAnim.dispose();
    super.dispose();
  }

  void _handleBatchClaimAll() {
    final summary = widget.controller.claimAllReadyRewards();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: NightPalette.bgCard,
          content: Text(
            summary.hasAnyAction
                ? '일괄 정리 완료 (${summary.sources.isEmpty ? "자동 재파견" : summary.sources.join(" · ")}) — 증표 +${summary.gainedTokens} · 영약 +${summary.gainedElixirs} · 지원패 +${summary.gainedSupportTokens}'
                : '현재 수령할 보상이나 대기 중인 호송·탐색대가 없습니다.',
            style: const TextStyle(color: NightPalette.accentGold),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final p = widget.controller.progress;
        final readySupplyOrQuest = p.hasAnyReadyAction();
        final meridianReady = p.canOpenNextMeridian();

        return Scaffold(
          body: switch (_selectedNavIndex) {
            0 => _buildCommandHomeTab(context, p),
            1 => LoadoutScreen(
                controller: widget.controller,
                embeddedInShell: true,
              ),
            2 => UpgradeScreen(
                controller: widget.controller,
                embeddedInShell: true,
              ),
            3 => _buildUnifiedSupplyTrainingHub(p),
            _ => CodexScreen(
                controller: widget.controller,
                embeddedInShell: true,
                initialTab: 4,
              ),
          },
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: NightPalette.borderGold.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedNavIndex,
              onDestinationSelected: (idx) {
                NightAudioController.instance.playAsset('ui_tap.ogg');
                setState(() => _selectedNavIndex = idx);
              },
              destinations: [
                const NavigationDestination(
                  key: Key('nav_tab_home'),
                  icon: Icon(Icons.shield_moon_outlined),
                  selectedIcon: Icon(
                    Icons.shield_moon_rounded,
                    color: NightPalette.accentGold,
                  ),
                  label: '출정 본영',
                ),
                const NavigationDestination(
                  key: Key('nav_tab_loadout'),
                  icon: Icon(Icons.groups_2_outlined),
                  selectedIcon: Icon(
                    Icons.groups_2_rounded,
                    color: NightPalette.accentGold,
                  ),
                  label: '영웅·진법',
                ),
                const NavigationDestination(
                  key: Key('nav_tab_forge'),
                  icon: Icon(Icons.precision_manufacturing_outlined),
                  selectedIcon: Icon(
                    Icons.precision_manufacturing_rounded,
                    color: NightPalette.accentGold,
                  ),
                  label: '대장간·영약',
                ),
                NavigationDestination(
                  key: const Key('nav_tab_supply'),
                  icon: Badge(
                    isLabelVisible: readySupplyOrQuest || meridianReady,
                    backgroundColor: NightPalette.accentGold,
                    child: const Icon(Icons.self_improvement_outlined),
                  ),
                  selectedIcon: const Icon(
                    Icons.self_improvement_rounded,
                    color: NightPalette.accentGold,
                  ),
                  label: '수련·보급',
                ),
                const NavigationDestination(
                  key: Key('nav_tab_codex'),
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(
                    Icons.menu_book_rounded,
                    color: NightPalette.accentGold,
                  ),
                  label: '변이 도감',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnifiedSupplyTrainingHub(PlayerProgress p) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xF5202E48),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('단전·경맥 수련')),
                    ButtonSegment(value: 1, label: Text('호송·탐색·기연')),
                    ButtonSegment(value: 2, label: Text('출석·임무·비약')),
                  ],
                  selected: {_supplySubTab},
                  onSelectionChanged: (s) =>
                      setState(() => _supplySubTab = s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                FilledButton.icon(
                  key: const Key('supply_hub_claim_all_btn'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(118, 38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    backgroundColor: NightPalette.accentGold,
                    foregroundColor: NightPalette.hanjiInk,
                  ),
                  onPressed: _handleBatchClaimAll,
                  icon: const Icon(Icons.done_all_rounded, size: 17),
                  label: const Text('일괄 수령·파견'),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_supplySubTab) {
              0 => TrainingScreen(
                  controller: widget.controller,
                  embeddedInShell: true,
                ),
              1 => ConvoyAndSerendipityScreen(
                  controller: widget.controller,
                  embeddedInShell: true,
                ),
              _ => DailyAndQuestsScreen(
                  controller: widget.controller,
                  embeddedInShell: true,
                ),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommandHomeTab(BuildContext context, PlayerProgress p) {
    final nextGlobal =
        (p.highestClearedGlobalStage + 1).clamp(1, CampaignCatalog.allStages.length);
    final nextStage = CampaignCatalog.allStages[nextGlobal - 1];
    final chSpec = CampaignCatalog.chapterOf(nextStage.chapterNumber);
    final preset = p.activePreset;
    final hasQuestReward = p.hasClaimableRewards();
    final hasReadyAction = p.hasAnyReadyAction();
    final nextRescue = p.nextRescueStage;

    return NightSceneBackdrop(
      assetPath: NightArtRegistry.bgNightLobby,
      fallbackAssetPath: NightArtRegistry.bgLobbyFallback,
      overlayOpacity: 0.78,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final isWide = viewport.maxWidth >= 820;
            final gridColumns = viewport.maxWidth >= 900 ? 3 : 2;
            final gridAspect = viewport.maxWidth < 360
                ? 1.24
                : (viewport.maxWidth >= 900 ? 1.62 : 1.48);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1020),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1) 상단 게임 타이틀 & 재화 요약 & 도감·설정 빠른 아이콘 바
                      Row(
                        children: [
                          const NightSpriteIcon(
                            assetPath: NightArtRegistry.appLogo,
                            fallbackAssetPath: NightArtRegistry.towerGuardian,
                            fallbackIcon: Icons.shield_moon_rounded,
                            size: 42,
                            borderRadius: 10,
                            showFrame: true,
                            frameColor: NightPalette.accentGold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '수호알까기 · 탄지무림 심야기습',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'BlackHanSans',
                                    fontSize: 19.5,
                                    color: NightPalette.accentGold,
                                  ),
                                ),
                                Text(
                                  '경지 [${p.realm.name}] · 수호 ${p.highestClearedGlobalStage}/${CampaignCatalog.allStages.length}관문 · 영웅 ${p.unlockedCompanionCount}/14 · 신수 ${p.unlockedBeastCount}/5',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.8,
                                    color: NightPalette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: const Key('home_codex_btn'),
                            visualDensity: VisualDensity.compact,
                            tooltip: '수호 도감 및 확률 공개',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CodexScreen(
                                    controller: widget.controller,
                                  ),
                                ),
                              );
                            },
                            icon: const NightSpriteIcon(
                              assetPath: NightArtRegistry.iconCodex,
                              fallbackIcon: Icons.auto_stories_rounded,
                              size: 28,
                              showFrame: true,
                              frameColor: NightPalette.jadeShield,
                            ),
                          ),
                          IconButton(
                            key: const Key('home_settings_btn'),
                            visualDensity: VisualDensity.compact,
                            tooltip: '환경 설정 · 백업 · 만든 이 · 제작노트',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SettingsScreen(
                                    controller: widget.controller,
                                  ),
                                ),
                              );
                            },
                            icon: const NightSpriteIcon(
                              assetPath: NightArtRegistry.iconSettings,
                              fallbackIcon: Icons.settings_rounded,
                              size: 28,
                              showFrame: true,
                              frameColor: NightPalette.accentGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 보유 재화 HUD 바
                      Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        children: [
                          ResourcePill(
                            iconAsset: NightArtRegistry.nightToken,
                            icon: Icons.toll_rounded,
                            label: '증표',
                            value: '${p.tokens}',
                            color: NightPalette.accentGold,
                          ),
                          ResourcePill(
                            iconAsset: NightArtRegistry.nightElixir,
                            icon: Icons.science_rounded,
                            label: '영약',
                            value: '${p.elixirs}',
                            color: NightPalette.jadeShield,
                          ),
                          ResourcePill(
                            iconAsset: NightArtRegistry.nightSupportSeal,
                            icon: Icons.campaign_rounded,
                            label: '지원패',
                            value: '${p.supportTokens}개',
                            color: NightPalette.jadeGreen,
                          ),
                          ResourcePill(
                            iconAsset: NightArtRegistry.nightSerendipity,
                            icon: Icons.brightness_2_rounded,
                            label: '보름달',
                            value: '${p.moonOmenGauge}%',
                            color: NightPalette.accentGold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 입문 교범 미열람 시 1회 안내 배너
                      if (!p.tutorialSeen) ...[
                        MurimCard(
                          borderColor: NightPalette.borderGold,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                '12굽이 지형 초소 건설과 3페이즈 대수괴 약점 저격 비급을 30초 만에 확인하세요.',
                                style: TextStyle(
                                  fontSize: 12.2,
                                  color: NightPalette.textMuted,
                                ),
                              ),
                              OutlinedButton.icon(
                                key: const Key('home_open_tutorial_btn'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(110, 38),
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: NightPalette.accentGold,
                                  side: BorderSide(
                                    color: NightPalette.borderGold
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                                onPressed: () => showTutorialGuideDialog(
                                  context,
                                  widget.controller,
                                ),
                                icon: const Icon(Icons.school_rounded, size: 15),
                                label: const Text('수호 교범 열기'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // 2) 제1 주인공: 영웅 대 3페이즈 대수괴 결전 출정 지령대 (시선 1순위 압도적 주인공!)
                      _HeroVsBossCommandBanner(
                        controller: widget.controller,
                        chSpec: chSpec,
                        nextStage: nextStage,
                        preset: preset,
                        hasReadyAction: hasReadyAction,
                        onBatchClaimAll: _handleBatchClaimAll,
                        artHeight: isWide ? 186 : 124,
                      ),
                      const SizedBox(height: 10),

                      // 3) 제2 받침 묶음: 성채 앞 영웅 대 변이 교전 디오라마 + 실전 전각 카드 6종 통합 석판
                      MurimCard(
                        backgroundColor: const Color(0xFF2B3D5D),
                        borderColor: NightPalette.borderGold,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FortressDioramaStage(
                              ambientAnim: _ambientAnim,
                              progress: p,
                              preset: preset,
                              nextRescue: nextRescue,
                              height: isWide ? 184 : 138,
                              onOpenRescueMap: () {
                                if (nextRescue != null) {
                                  widget.controller.setSelectedChapter(
                                    nextRescue.chapterNumber,
                                  );
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CampaignScreen(
                                      controller: widget.controller,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _FacilityCardMatrix(
                              columns: gridColumns,
                              aspectRatio: gridAspect,
                              spacing: 10,
                              children: [
                                _GameImageFacilityCard(
                                  tileKey: const Key('menu_training_btn'),
                                  sceneAsset: NightArtRegistry.cardTrainingHall,
                                  emblemAsset: NightArtRegistry.nightMeridian,
                                  fallbackIcon: Icons.self_improvement_rounded,
                                  title: '기명 심법 수련관',
                                  tagLine:
                                      '10회 연속 운기 · 경맥 ${p.openedMeridianStep}/10단',
                                  accent: NightPalette.accentGold,
                                  badge:
                                      p.canOpenNextMeridian() ? '개통 가능' : null,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TrainingScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  ),
                                ),
                                _GameImageFacilityCard(
                                  tileKey: const Key('menu_loadout_btn'),
                                  sceneAsset: NightArtRegistry.cardAllyPavilion,
                                  emblemAsset: NightArtRegistry.beastAsset(
                                    preset.equippedBeast,
                                  ),
                                  fallbackIcon: Icons.groups_rounded,
                                  title: '수호 진법 · 영웅각',
                                  tagLine:
                                      '원터치 최적 편성 · 영웅 ${p.unlockedCompanionCount}/14',
                                  accent: NightPalette.accentGold,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => LoadoutScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  ),
                                ),
                                _GameImageFacilityCard(
                                  tileKey: const Key('menu_forge_btn'),
                                  sceneAsset: NightArtRegistry.cardForgeSanctum,
                                  emblemAsset: NightArtRegistry.towerGuardian,
                                  fallbackIcon:
                                      Icons.precision_manufacturing_rounded,
                                  title: '증표 대장간 · 영약각',
                                  tagLine:
                                      '수호탑 ${p.centralGuardianLevel}단 · 추천 일괄 강화',
                                  accent: NightPalette.accentGold,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => UpgradeScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  ),
                                ),
                                _GameImageFacilityCard(
                                  tileKey: const Key('menu_convoy_btn'),
                                  sceneAsset: NightArtRegistry.cardSupplyConvoy,
                                  emblemAsset: NightArtRegistry.nightConvoyCart,
                                  fallbackIcon: Icons.local_shipping_rounded,
                                  title: '물자 호송 · 지원패',
                                  tagLine:
                                      '호송 전투 · 심야 탐색 · 출두 ${p.supportTokens}패',
                                  accent: NightPalette.accentGold,
                                  badge: (p.moonOmenGauge >= 100 ||
                                          (p.convoyActive &&
                                              p.convoyBattlesRemaining == 0) ||
                                          (p.exploreActive &&
                                              p.exploreBattlesRemaining == 0))
                                      ? '보상 도착'
                                      : null,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ConvoyAndSerendipityScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  ),
                                ),
                                _GameImageFacilityCard(
                                  tileKey: const Key('menu_daily_btn'),
                                  sceneAsset: NightArtRegistry.cardRescueBeacon,
                                  emblemAsset: NightArtRegistry.iconAttendance,
                                  fallbackIcon: Icons.event_available_rounded,
                                  title: '출석 · 임무 · 비약방',
                                  tagLine: '7일 출석 · 수호 임무 · 전술 비약 제조',
                                  accent: NightPalette.accentGold,
                                  badge: hasQuestReward ? '수령 가능' : null,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DailyAndQuestsScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  ),
                                ),
                                _GameImageFacilityCard(
                                  tileKey: const Key('menu_endless_btn'),
                                  sceneAsset: NightArtRegistry.cardEndlessAbyss,
                                  emblemAsset: NightArtRegistry.nightEndless,
                                  fallbackIcon:
                                      Icons.local_fire_department_rounded,
                                  title: '심야 무한 혈전장',
                                  tagLine:
                                      '최고 ${p.bestEndlessWave}물결 돌파 · 100물결 혈전',
                                  accent: NightPalette.accentGold,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EndlessSurvivalScreen(
                                        controller: widget.controller,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 본영 상단 제1주인공: 영웅 대 3페이즈 대수괴 결전 일러스트 + 한지 출정 지령판 + 원터치 일괄 수령.
class _HeroVsBossCommandBanner extends StatelessWidget {
  const _HeroVsBossCommandBanner({
    required this.controller,
    required this.chSpec,
    required this.nextStage,
    required this.preset,
    required this.hasReadyAction,
    required this.onBatchClaimAll,
    required this.artHeight,
  });

  final GameController controller;
  final ChapterSpec chSpec;
  final StageSpec nextStage;
  final LoadoutPreset preset;
  final bool hasReadyAction;
  final VoidCallback onBatchClaimAll;
  final double artHeight;

  @override
  Widget build(BuildContext context) {
    final leadHero = preset.companions.isNotEmpty
        ? preset.companions.first
        : CompanionHero.seokdu;

    return Container(
      decoration: BoxDecoration(
        color: NightPalette.hanjiLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NightPalette.accentGold, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x48000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1) 상단: 기명·검황 대 3페이즈 대수괴 정면 격돌 원화 무대 (선명한 실전 원화!)
          SizedBox(
            height: artHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  NightArtRegistry.homeCommandLoop,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  alignment: const Alignment(0, -0.1),
                  errorBuilder: (_, _, _) => Image.asset(
                    NightArtRegistry.cardGateBattle,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: NightPalette.bgPanel),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.55, 1.0],
                      colors: [
                        Color(0x32141F33),
                        Color(0x14141F33),
                        Color(0xCC162238),
                      ],
                    ),
                  ),
                ),
                // 좌하단 출전 선봉 영웅 3D 모션 배지
                Align(
                  alignment: const Alignment(-0.88, 0.92),
                  child: NightSpriteIcon(
                    assetPath: NightArtRegistry.heroMotionAsset(leadHero),
                    fallbackAssetPath: NightArtRegistry.heroAttackAsset(leadHero),
                    fallbackIcon: Icons.person_rounded,
                    size: (artHeight * 0.58).clamp(72.0, 110.0),
                    borderRadius: 14,
                    fit: BoxFit.cover,
                    showFrame: true,
                    frameColor: NightPalette.accentGold,
                  ),
                ),
                // 우하단 침공 3페이즈 보스 3D 모션 배지
                Align(
                  alignment: const Alignment(0.88, 0.92),
                  child: NightSpriteIcon(
                    assetPath: NightArtRegistry.mutantMotionAsset(
                      MutantKind.chapterOverlord,
                    ),
                    fallbackAssetPath: NightArtRegistry.showcaseBossChapter,
                    fallbackIcon: Icons.whatshot_rounded,
                    size: (artHeight * 0.58).clamp(72.0, 110.0),
                    borderRadius: 14,
                    fit: BoxFit.cover,
                    showFrame: true,
                    frameColor: NightPalette.crimsonMoon,
                  ),
                ),
                // 상단 진행 단계 & 초소/구출 정보 배지
                Positioned(
                  left: 12,
                  right: 12,
                  top: 10,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xE8162238),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: NightPalette.accentGold.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Text(
                          '이번 수호 차례 (${nextStage.globalIndex}/${CampaignCatalog.allStages.length}) · 초소 ${nextStage.maxMountCount}곳 · ${nextStage.waves.length}물결',
                          style: const TextStyle(
                            fontSize: 11.4,
                            fontWeight: FontWeight.bold,
                            color: NightPalette.accentGold,
                          ),
                        ),
                      ),
                      if (nextStage.hasRescueReward)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xE8162238),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: NightPalette.jadeGreen),
                          ),
                          child: Text(
                            '구출 목표: ${nextStage.rescueBadgeText}',
                            style: const TextStyle(
                              fontSize: 11.2,
                              fontWeight: FontWeight.bold,
                              color: NightPalette.jadeGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2) 하단: 고대비 한지 출정 명패 + 대형 출정 단추 & 원터치 일괄 수령
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    NightSpriteIcon(
                      assetPath:
                          NightArtRegistry.charFace(chSpec.bossPortraitPrefix),
                      fallbackIcon: Icons.shield_rounded,
                      size: 48,
                      borderRadius: 24,
                      fit: BoxFit.cover,
                      showFrame: true,
                      frameColor: NightPalette.hanjiInk,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${chSpec.title} · ${chSpec.villageName}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.0,
                              color: NightPalette.hanjiSubInk,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            nextStage.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 22.5,
                              color: NightPalette.hanjiInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      key: const Key('home_quick_battle_btn'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 52),
                        backgroundColor: NightPalette.hanjiInk,
                        foregroundColor: NightPalette.accentGold,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BattleScreen(
                              controller: controller,
                              stage: nextStage,
                            ),
                          ),
                        );
                      },
                      icon: const NightSpriteIcon(
                        assetPath: NightArtRegistry.towerGuardian,
                        fallbackIcon: Icons.play_arrow_rounded,
                        size: 22,
                      ),
                      label: const Text(
                        '즉시 야간 수호 출정',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const Key('home_campaign_map_btn'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(146, 48),
                        backgroundColor: const Color(0xFFE6D4B0),
                        foregroundColor: NightPalette.hanjiInk,
                        side: const BorderSide(color: Color(0xFF2F3F5C)),
                      ),
                      onPressed: () {
                        controller.setSelectedChapter(nextStage.chapterNumber);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CampaignScreen(
                              controller: controller,
                            ),
                          ),
                        );
                      },
                      icon: const NightSpriteIcon(
                        assetPath: NightArtRegistry.iconCampaign,
                        fallbackIcon: Icons.map_rounded,
                        size: 18,
                      ),
                      label: const Text('1~10장 행군 지도'),
                    ),
                    if (hasReadyAction)
                      OutlinedButton.icon(
                        key: const Key('home_batch_claim_btn'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(164, 48),
                          backgroundColor: const Color(0xFF24344F),
                          foregroundColor: NightPalette.jadeGreen,
                          side: const BorderSide(color: NightPalette.jadeGreen),
                        ),
                        onPressed: onBatchClaimAll,
                        icon: const Icon(Icons.redeem_rounded, size: 18),
                        label: const Text('도착 보상 일괄 수령·파견'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 수호 본영 라이브 성채 교전 디오라마 무대 (`lobby_stage_fortress.webp` + 전신 공격 영웅단·영수·수호탑).
class _FortressDioramaStage extends StatelessWidget {
  const _FortressDioramaStage({
    required this.ambientAnim,
    required this.progress,
    required this.preset,
    required this.nextRescue,
    required this.onOpenRescueMap,
    this.height = 168,
  });

  final Animation<double> ambientAnim;
  final PlayerProgress progress;
  final LoadoutPreset preset;
  final StageSpec? nextRescue;
  final VoidCallback onOpenRescueMap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final heroes = preset.companions
        .where((h) => (progress.companionLevels[h] ?? 0) > 0)
        .take(3)
        .toList();
    if (heroes.isEmpty) {
      heroes.add(CompanionHero.seokdu);
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NightPalette.borderGold.withValues(alpha: 0.42),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) 코덱스 10대 거점 심야 대륙 월드맵 라이브 3D 모션 파노라마 (청람·황금 색조 조화로 색 가짓수 ≤ 5)
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.82, 0.10, 0.08, 0, 0,
                0.08, 0.84, 0.08, 0, 0,
                0.06, 0.10, 0.90, 0, 0,
                0,    0,    0,    1, 0,
              ]),
              child: Image.asset(
                NightArtRegistry.worldMapLiveMotion,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Image.asset(
                  NightArtRegistry.worldMapMurimNight,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    NightArtRegistry.lobbyStageFortress,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // 2) 상·하단 글자 명패만 받쳐주는 가벼운 비네트 스크림
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.48, 1.0],
                  colors: [
                    Color(0x78141F33),
                    Color(0x241B2942),
                    Color(0xD8162238),
                  ],
                ),
              ),
            ),

            // 3) 실시간 떠오르는 불티 & 구출 영웅 전신 공격 스탠딩
            AnimatedBuilder(
              animation: ambientAnim,
              builder: (context, _) {
                final phase = ambientAnim.value * 2 * pi;
                final hoverA = sin(phase) * 3.2;
                final hoverB = cos(phase + 1.2) * 3.0;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _DioramaEmbersPainter(progress: ambientAnim.value),
                    ),
                    if (heroes.isNotEmpty)
                      Align(
                        alignment: const Alignment(-0.68, 0.34),
                        child: Transform.translate(
                          offset: Offset(0, hoverA * 0.6),
                          child: _DioramaHeroStandee(
                            hero: heroes[0],
                            level: progress.companionLevels[heroes[0]] ?? 1,
                            height: 82,
                          ),
                        ),
                      ),
                    if (heroes.length >= 2)
                      Align(
                        alignment: const Alignment(-0.18, 0.38),
                        child: Transform.translate(
                          offset: Offset(0, hoverB * 0.6),
                          child: _DioramaHeroStandee(
                            hero: heroes[1],
                            level: progress.companionLevels[heroes[1]] ?? 1,
                            height: 78,
                          ),
                        ),
                      ),
                    if (heroes.length >= 3)
                      Align(
                        alignment: const Alignment(0.32, 0.36),
                        child: Transform.translate(
                          offset: Offset(0, -hoverA * 0.5),
                          child: _DioramaHeroStandee(
                            hero: heroes[2],
                            level: progress.companionLevels[heroes[2]] ?? 1,
                            height: 76,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

            // 4) 상단 진법 문패 & 우상단 다음 동료·영수 구출 목표 배지
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xDC141F33),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: NightPalette.borderGold.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NightSpriteIcon(
                          assetPath: NightArtRegistry.stoneAsset(
                            preset.primaryStone,
                          ),
                          fallbackIcon: Icons.circle,
                          size: 18,
                          color: Color(preset.primaryStone.colorHex),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '방어 전선 · ${preset.primaryStone.grade}단 ${preset.primaryStone.name}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.4,
                              color: NightPalette.accentGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (nextRescue != null)
                    InkWell(
                      onTap: onOpenRescueMap,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xE01A2942),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: NightPalette.jadeGreen.withValues(alpha: 0.75),
                          ),
                        ),
                        child: Text(
                          '다음 구출: ${nextRescue!.code} ${nextRescue!.rescueBadgeText}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.2,
                            color: NightPalette.jadeGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 5) 하단 수호진 요약 바
            Positioned(
              left: 12,
              right: 12,
              bottom: 7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '성문 결사항전 진형 (${preset.name} · ${preset.equippedBeast.name})',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: NightPalette.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '도감 가호 +${(progress.codexPowerBonus * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11.2,
                      color: NightPalette.accentGold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DioramaHeroStandee extends StatelessWidget {
  const _DioramaHeroStandee({
    required this.hero,
    required this.level,
    this.height = 84,
  });

  final CompanionHero hero;
  final int level;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          NightArtRegistry.heroAttackAsset(hero),
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Image.asset(
            NightArtRegistry.heroIdleAsset(hero),
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => NightSpriteIcon(
              assetPath: NightArtRegistry.heroFaceAsset(hero),
              fallbackIcon: Icons.person_rounded,
              size: 44,
              borderRadius: 22,
              showFrame: true,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xDC121B2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: NightPalette.accentGold.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            '${hero.name} Lv.$level',
            style: const TextStyle(
              fontSize: 10.2,
              color: NightPalette.accentGold,
            ),
          ),
        ),
      ],
    );
  }
}

class _DioramaEmbersPainter extends CustomPainter {
  const _DioramaEmbersPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final emberPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 16; i++) {
      final seed = i * 1.618;
      final t = (progress + seed * 0.23) % 1.0;
      final x = ((sin(seed * 7.3) * 0.5 + 0.5) * size.width +
              sin(t * 2 * pi + i) * 14.0)
          .clamp(8.0, size.width - 8.0);
      final y = size.height * (0.92 - t * 0.78);
      final alpha = sin(t * pi) * 0.58;
      final radius = 1.4 + (i % 3) * 0.85;
      emberPaint.color = (i.isEven
              ? const Color(0xFFFFD166)
              : const Color(0xFF72EFDD))
          .withValues(alpha: alpha.clamp(0.0, 0.7));
      canvas.drawCircle(Offset(x, y), radius, emberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DioramaEmbersPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 영웅 대 돌연변이 실전 액션 일러스트가 선명하게 빛나는 전각 카드.
class _GameImageFacilityCard extends StatelessWidget {
  const _GameImageFacilityCard({
    this.tileKey,
    required this.sceneAsset,
    required this.emblemAsset,
    required this.fallbackIcon,
    required this.title,
    required this.tagLine,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final Key? tileKey;
  final String sceneAsset;
  final String emblemAsset;
  final IconData fallbackIcon;
  final String title;
  final String tagLine;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: tileKey,
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: NightPalette.borderGold.withValues(alpha: 0.36),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1) 전면 영웅 대 변이 실전 전투 일러스트 (기존 뿌연 암막을 걷어내 상단 전투화 선명 노출!)
                Image.asset(
                  sceneAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: NightPalette.bgPanel),
                ),

                // 2) 하단 제목 가독성만 확실히 잡아주는 비네트 그라데이션
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.46, 1.0],
                      colors: [
                        Color(0x2E141F33),
                        Color(0x5818263E),
                        Color(0xEE152036),
                      ],
                    ),
                  ),
                ),

                // 3) 좌상단 미니 엠블럼 아이콘
                Positioned(
                  left: 9,
                  top: 8,
                  child: NightSpriteIcon(
                    assetPath: emblemAsset,
                    fallbackIcon: fallbackIcon,
                    size: 28,
                    borderRadius: 7,
                    showFrame: true,
                    frameColor: NightPalette.borderGold,
                  ),
                ),

                // 4) 우상단 실시간 알림 배지
                if (badge != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: NightPalette.accentGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: NightPalette.hanjiInk,
                        ),
                      ),
                    ),
                  ),

                // 5) 하단 선명한 게임 전각 명패
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'BlackHanSans',
                          fontSize: 15.2,
                          color: accent,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tagLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.2,
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
      ),
    );
  }
}

/// 반응형 전각 카드 격자 레이아웃.
class _FacilityCardMatrix extends StatelessWidget {
  const _FacilityCardMatrix({
    required this.columns,
    required this.aspectRatio,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double aspectRatio;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += columns) {
      if (i > 0) {
        rows.add(SizedBox(height: spacing));
      }
      final slice = <Widget>[];
      for (int c = 0; c < columns; c++) {
        if (c > 0) {
          slice.add(SizedBox(width: spacing));
        }
        final idx = i + c;
        if (idx < children.length) {
          slice.add(
            Expanded(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: children[idx],
              ),
            ),
          );
        } else {
          slice.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      rows.add(Row(children: slice));
    }
    return Column(children: rows);
  }
}
