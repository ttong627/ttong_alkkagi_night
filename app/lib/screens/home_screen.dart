import 'dart:async';
import 'dart:math';

import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart' hide Text;

import '../audio/night_audio.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'codex_and_endless_screens.dart';
import 'convoy_campaign_screens.dart';
import 'daily_quests_screen.dart';
import 'loadout_upgrade_screens.dart';
import 'settings_and_credits_screen.dart';
import 'splash_and_tutorial.dart';
import 'stage_and_county_transitions.dart';
import 'training_screen.dart';
import '../i18n/tr_text.dart';
import '../i18n/l10n.dart';

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
  Timer? _midnightRefreshTimer;
  int _lastObservedDayKey = 0;
  int _selectedNavIndex = 0;
  int _supplySubTab = 0;

  static int _localDayKey(DateTime dt) =>
      dt.year * 10000 + dt.month * 100 + dt.day;

  @override
  void initState() {
    super.initState();
    NightAudioController.instance.playBgm('bgm_lobby.ogg');
    _lastObservedDayKey = _localDayKey(DateTime.now());
    _midnightRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final nowDay = _localDayKey(DateTime.now());
      if (nowDay != _lastObservedDayKey && mounted) {
        setState(() {
          _lastObservedDayKey = nowDay;
        });
      }
    });
    _ambientAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
  }

  @override
  void dispose() {
    _midnightRefreshTimer?.cancel();
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
                onSwitchShellTab: (idx) =>
                    setState(() => _selectedNavIndex = idx),
              ),
            2 => UpgradeScreen(
                controller: widget.controller,
                embeddedInShell: true,
                onSwitchShellTab: (idx) =>
                    setState(() => _selectedNavIndex = idx),
              ),
            3 => _buildUnifiedSupplyTrainingHub(p),
            _ => CodexScreen(
                controller: widget.controller,
                embeddedInShell: true,
                initialTab: 4,
                onSwitchShellTab: (idx) =>
                    setState(() => _selectedNavIndex = idx),
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
                NavigationDestination(
                  key: Key('nav_tab_home'),
                  icon: Icon(Icons.shield_moon_outlined),
                  selectedIcon: Icon(
                    Icons.shield_moon_rounded,
                    color: NightPalette.accentGold,
                  ),
                  label: tr('출정 본영'),
                ),
                NavigationDestination(
                  key: Key('nav_tab_loadout'),
                  icon: Icon(Icons.groups_2_outlined),
                  selectedIcon: Icon(
                    Icons.groups_2_rounded,
                    color: NightPalette.accentGold,
                  ),
                  label: tr('영웅·진법'),
                ),
                NavigationDestination(
                  key: const Key('nav_tab_forge'),
                  icon: Badge(
                    isLabelVisible: p.tokens >= (30 + p.centralGuardianLevel * 18),
                    backgroundColor: NightPalette.accentGold,
                    child: const Icon(Icons.precision_manufacturing_outlined),
                  ),
                  selectedIcon: const Icon(
                    Icons.precision_manufacturing_rounded,
                    color: NightPalette.accentGold,
                  ),
                  label: tr('대장간·영약'),
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
                  label: tr('수련·보급'),
                ),
                NavigationDestination(
                  key: Key('nav_tab_codex'),
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(
                    Icons.menu_book_rounded,
                    color: NightPalette.accentGold,
                  ),
                  label: tr('변이 도감'),
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
          QuickPlayAndMenuBar(
            controller: widget.controller,
            currentSection: 'supply',
            embeddedInShell: true,
            onSwitchShellTab: (idx) => setState(() => _selectedNavIndex = idx),
          ),
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

            return Column(
              children: [
                // 1) 모바일 상단 고정 재화·경지 HUD 헤더 (스크롤 시에도 증표·영약·지원패·설정이 항상 상단 고정!)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: const Color(0xEB0E182B),
                    border: Border(
                      bottom: BorderSide(
                        color: NightPalette.borderGold.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1020),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const NightSpriteIcon(
                                assetPath: NightArtRegistry.appLogo,
                                fallbackAssetPath:
                                    NightArtRegistry.towerGuardian,
                                fallbackIcon: Icons.shield_moon_rounded,
                                size: 38,
                                borderRadius: 9,
                                showFrame: true,
                                frameColor: NightPalette.accentGold,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '수호알까기 · 탄지무림 심야기습',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 17.8,
                                        color: NightPalette.accentGold,
                                      ),
                                    ),
                                    Text(
                                      p.reincarnationCount > 0
                                          ? '☯️제${p.reincarnationCount}환생(×${p.reincarnationDifficultyMultiplier.round()}배) · 경지 [${p.realm.name}] · ${p.highestClearedGlobalStage}/${CampaignCatalog.allStages.length}판 · 영웅 ${p.unlockedCompanionCount}/14'
                                          : '경지 [${p.realm.name}] · ${p.highestClearedGlobalStage}/${CampaignCatalog.allStages.length}판(10현) · 영웅 ${p.unlockedCompanionCount}/14 · 신수 ${p.unlockedBeastCount}/5',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.2,
                                        color: NightPalette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                key: const Key('home_codex_btn'),
                                visualDensity: VisualDensity.compact,
                                tooltip: tr('수호 도감 및 확률 공개'),
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
                                  size: 26,
                                  showFrame: true,
                                  frameColor: NightPalette.jadeShield,
                                ),
                              ),
                              IconButton(
                                key: const Key('home_settings_btn'),
                                visualDensity: VisualDensity.compact,
                                tooltip: tr('환경 설정 · 백업 · 만든 이 · 제작노트'),
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
                                  size: 26,
                                  showFrame: true,
                                  frameColor: NightPalette.accentGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (p.reincarnationCount > 0) ...[
                                  ResourcePill(
                                    key: const Key('home_reincarnation_pill'),
                                    icon: Icons.autorenew_rounded,
                                    label: '제${p.reincarnationCount}환생',
                                    value:
                                        '×${p.reincarnationDifficultyMultiplier.round()}배',
                                    color: NightPalette.elixirPurple,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                ResourcePill(
                                  iconAsset: NightArtRegistry.nightToken,
                                  icon: Icons.toll_rounded,
                                  label: '증표',
                                  value: '${p.tokens}',
                                  color: NightPalette.accentGold,
                                ),
                                const SizedBox(width: 6),
                                ResourcePill(
                                  iconAsset: NightArtRegistry.nightElixir,
                                  icon: Icons.science_rounded,
                                  label: '영약',
                                  value: '${p.elixirs}',
                                  color: NightPalette.jadeShield,
                                ),
                                const SizedBox(width: 6),
                                ResourcePill(
                                  iconAsset: NightArtRegistry.nightSupportSeal,
                                  icon: Icons.campaign_rounded,
                                  label: '지원패',
                                  value: '${p.supportTokens}개',
                                  color: NightPalette.jadeGreen,
                                ),
                                const SizedBox(width: 6),
                                ResourcePill(
                                  iconAsset: NightArtRegistry.nightSerendipity,
                                  icon: Icons.brightness_2_rounded,
                                  label: '보름달',
                                  value: '${p.moonOmenGauge}%',
                                  color: NightPalette.accentGold,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2) 본영 스크롤 컨텐츠 (모바일 한 손 엄지 출정 지령대 + 성채 디오라마 + 6대 전각 격자)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1020),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                '10장 고유 지형 초소 건설과 3페이즈 대수괴 약점 저격 비급을 30초 만에 확인하세요.',
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
                      if (p.canPerformReincarnation ||
                          p.canChallengeReincarnationBoss ||
                          p.highestClearedGlobalStage >=
                              CampaignCatalog.allStages.length ||
                          p.reincarnationCount > 0) ...[
                        const SizedBox(height: 10),
                        _ReincarnationSanctumCard(
                          controller: widget.controller,
                        ),
                      ],
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
                                  buildSmoothScreenRoute(
                                    CampaignScreen(
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
                                    buildSmoothScreenRoute(
                                      TrainingScreen(
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
                                    buildSmoothScreenRoute(
                                      LoadoutScreen(
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
                                    buildSmoothScreenRoute(
                                      UpgradeScreen(
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
                                    buildSmoothScreenRoute(
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
                                    buildSmoothScreenRoute(
                                      DailyAndQuestsScreen(
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
                                    buildSmoothScreenRoute(
                                      EndlessSurvivalScreen(
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
                    ),
                  ),
                ],
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
                // 좌하단 출전 선봉 영웅 알파 투명 3D 모션 스탠디 (배경 사각 박스 제거!)
                Align(
                  alignment: const Alignment(-0.88, 0.96),
                  child: NightSpriteIcon(
                    assetPath: NightArtRegistry.heroMotionAsset(leadHero),
                    fallbackAssetPath:
                        NightArtRegistry.heroAttackAsset(leadHero),
                    fallbackIcon: Icons.person_rounded,
                    size: (artHeight * 0.68).clamp(80.0, 124.0),
                    borderRadius: 0,
                    fit: BoxFit.contain,
                    showFrame: false,
                  ),
                ),
                // 우하단 침공 3페이즈 보스 알파 투명 3D 모션 스탠디 (배경 사각 박스 제거!)
                Align(
                  alignment: const Alignment(0.88, 0.96),
                  child: NightSpriteIcon(
                    assetPath: NightArtRegistry.mutantMotionAsset(
                      MutantKind.chapterOverlord,
                    ),
                    fallbackAssetPath: NightArtRegistry.showcaseBossChapter,
                    fallbackIcon: Icons.whatshot_rounded,
                    size: (artHeight * 0.68).clamp(80.0, 124.0),
                    borderRadius: 0,
                    fit: BoxFit.contain,
                    showFrame: false,
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
                            color:
                                NightPalette.accentGold.withValues(alpha: 0.8),
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

          // 2) 하단: 모바일 한 손 엄지 출정 도크 (난이도 즉시 선택 + 전폭 출정 버튼 + 지도/일괄수령 2열 + 원터치 진법/강화 정비 바!)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    NightSpriteIcon(
                      assetPath:
                          NightArtRegistry.charFace(chSpec.bossPortraitPrefix),
                      fallbackIcon: Icons.shield_rounded,
                      size: 44,
                      borderRadius: 22,
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
                            '${chSpec.countyName} · ${nextStage.stageNumber}/10번째 마을 [${nextStage.villageNodeName}]',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.4,
                              color: NightPalette.hanjiSubInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            nextStage.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'BlackHanSans',
                              fontSize: 20.0,
                              color: NightPalette.hanjiInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<DefenseDifficulty>(
                      key: const Key('home_difficulty_selector'),
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: DefenseDifficulty.easy,
                          label: Text('쉬움'),
                        ),
                        ButtonSegment(
                          value: DefenseDifficulty.normal,
                          label: Text('보통'),
                        ),
                        ButtonSegment(
                          value: DefenseDifficulty.nightmare,
                          label: Text('악몽'),
                        ),
                      ],
                      selected: {controller.selectedDifficulty},
                      onSelectionChanged: (s) =>
                          controller.setDifficulty(s.first),
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? NightPalette.hanjiInk
                              : const Color(0xFFE5D5B5),
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? NightPalette.accentGold
                              : NightPalette.hanjiInk,
                        ),
                        side: const WidgetStatePropertyAll(
                          BorderSide(color: Color(0xFF2F3F5C)),
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                        minimumSize:
                            const WidgetStatePropertyAll(Size(30, 36)),
                        textStyle: const WidgetStatePropertyAll(
                          TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ),
                const SizedBox(height: 10),

                // ① 엄지 스윗스팟 전폭 주력 CTA: [즉시 야간 수호 출정]
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    key: const Key('home_quick_battle_btn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: NightPalette.hanjiInk,
                      foregroundColor: NightPalette.accentGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        buildSmoothBattleRoute(
                          controller: controller,
                          stage: nextStage,
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
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ② 2열 균등 보조 버튼: [10현·100판 행군 지도] + [도착 보상 일괄 수령·파견]
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          key: const Key('home_campaign_map_btn'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: const Color(0xFFE6D4B0),
                            foregroundColor: NightPalette.hanjiInk,
                            side: const BorderSide(color: Color(0xFF2F3F5C)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            controller.setSelectedChapter(
                              nextStage.chapterNumber,
                            );
                            Navigator.of(context).push(
                              buildSmoothScreenRoute(
                                CampaignScreen(
                                  controller: controller,
                                ),
                              ),
                            );
                          },
                          icon: const NightSpriteIcon(
                            assetPath: NightArtRegistry.iconCampaign,
                            fallbackIcon: Icons.map_rounded,
                            size: 17,
                          ),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '10현·100판 행군 지도',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          key: const Key('home_batch_claim_btn'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: hasReadyAction
                                ? const Color(0xFF1E3738)
                                : const Color(0xFF233047),
                            foregroundColor: hasReadyAction
                                ? NightPalette.jadeGreen
                                : NightPalette.accentGold,
                            side: BorderSide(
                              color: hasReadyAction
                                  ? NightPalette.jadeGreen
                                  : const Color(0xFF3E506E),
                              width: hasReadyAction ? 1.5 : 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: onBatchClaimAll,
                          icon: Icon(
                            hasReadyAction
                                ? Icons.redeem_rounded
                                : Icons.done_all_rounded,
                            size: 17,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              hasReadyAction
                                  ? '도착 보상 일괄 수령·파견'
                                  : '일괄 수령·자동파견',
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),

                // ③ 탭 이동 없이 본영에서 한 손으로 끝내는 [출정 전 1초 원터치 정비 바]
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          key: const Key('home_quick_auto_loadout_btn'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: const Color(0xFF1A2740),
                            foregroundColor: NightPalette.accentGold,
                            side: BorderSide(
                              color: NightPalette.accentGold
                                  .withValues(alpha: 0.65),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            final target =
                                controller.applyRecommendedForNextStage();
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  backgroundColor: NightPalette.bgCard,
                                  content: Text(
                                    '[${target.code}] 맞춤 진법(수호석·초소·영수·동료) 원터치 편성 완료!',
                                    style: const TextStyle(
                                      color: NightPalette.accentGold,
                                    ),
                                  ),
                                ),
                              );
                          },
                          icon:
                              const Icon(Icons.auto_fix_high_rounded, size: 15),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '최적 진법 원터치 편성',
                              style: TextStyle(
                                fontSize: 12.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          key: const Key('home_quick_auto_upgrade_btn'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: const Color(0xFF16312E),
                            foregroundColor: const Color(0xFF80ED99),
                            side: const BorderSide(color: Color(0x9980ED99)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            final logs = controller.upgradeRecommendedBatch(
                              maxSteps: 6,
                            );
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  backgroundColor: NightPalette.bgCard,
                                  content: Text(
                                    logs.isNotEmpty
                                        ? '추천 일괄 강화 완료: ${logs.join(" · ")}'
                                        : '현재 보유 증표·영약·내공으로 즉시 올릴 수 있는 추천 항목이 없습니다.',
                                    style: const TextStyle(
                                      color: NightPalette.jadeGreen,
                                    ),
                                  ),
                                ),
                              );
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 16),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '추천 일괄 강화',
                              style: TextStyle(
                                fontSize: 12.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
            // 1) 코덱스 성문 요새 방어 디오라마 원화 (`lobby_stage_fortress.webp`)
            Image.asset(
              NightArtRegistry.lobbyStageFortress,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Image.asset(
                NightArtRegistry.worldMapLiveMotion,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  NightArtRegistry.worldMapMurimNight,
                  fit: BoxFit.cover,
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
                        alignment: const Alignment(-0.68, 0.06),
                        child: Transform.translate(
                          offset: Offset(0, hoverA * 0.6),
                          child: _DioramaHeroStandee(
                            hero: heroes[0],
                            level: progress.companionLevels[heroes[0]] ?? 1,
                            height: 76,
                          ),
                        ),
                      ),
                    if (heroes.length >= 2)
                      Align(
                        alignment: const Alignment(-0.18, 0.10),
                        child: Transform.translate(
                          offset: Offset(0, hoverB * 0.6),
                          child: _DioramaHeroStandee(
                            hero: heroes[1],
                            level: progress.companionLevels[heroes[1]] ?? 1,
                            height: 74,
                          ),
                        ),
                      ),
                    if (heroes.length >= 3)
                      Align(
                        alignment: const Alignment(0.32, 0.08),
                        child: Transform.translate(
                          offset: Offset(0, -hoverA * 0.5),
                          child: _DioramaHeroStandee(
                            hero: heroes[2],
                            level: progress.companionLevels[heroes[2]] ?? 1,
                            height: 72,
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

/// 본영 윤회 최종 보스전(<5%) · 무한 다회차 3배 환생 등선 제단 카드.
class _ReincarnationSanctumCard extends StatelessWidget {
  const _ReincarnationSanctumCard({required this.controller});

  final GameController controller;

  Future<void> _confirmAndReincarnate(BuildContext context) async {
    final p = controller.progress;
    final nextN = p.reincarnationCount + 1;
    final nextMult = (p.reincarnationDifficultyMultiplier * 3).round();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: NightPalette.bgPanel,
        title: Text(
          '☯️ 제$nextN환생 등선 의식 실행',
          style: const TextStyle(
            color: NightPalette.accentGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '지금까지 단련한 모든 능력치(내공 경지·십대 경맥·수호탑·5발사대·13수호석·14동료·5영수·신기연마·영기공명·재화)가 100% 그대로 유지된 채 제1현 1-1 마을부터 새롭게 시작합니다!\n\n'
          '• 전 난이도 적 전력: 기존 대비 3배 상승 (누적 ×$nextMult배)\n'
          '• 영구 증표·영약 보상: ×$nextMult배 증폭 + 윤회 초월 단련 개방\n'
          '• 등선 축하 군수품: 지원패 +3개 · 전술 비약 각 +2개 지급',
          style: const TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: const Text('잠시 보류'),
          ),
          FilledButton(
            key: const Key('home_confirm_reincarnation_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: NightPalette.accentGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(dCtx).pop(true),
            child: Text('제$nextN환생 등선!'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      controller.performReincarnation();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: NightPalette.bgCard,
            content: Text(
              '☯️ 제$nextN환생 완료! 모든 능력치를 유지한 채 1-1(난이도 ×$nextMult배)에서 새로운 수호를 시작합니다!',
              style: const TextStyle(color: NightPalette.accentGold),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = controller.progress;
    final nextN = p.reincarnationCount + 1;
    final nextMult = (p.reincarnationDifficultyMultiplier * 3).round();

    final bool readyReinc = p.canPerformReincarnation;
    final bool readyBoss = p.canChallengeReincarnationBoss;
    final bool all100Done =
        p.highestClearedGlobalStage >= CampaignCatalog.allStages.length;

    final String headline;
    final String desc;
    if (readyReinc) {
      headline =
          '☯️ 【제$nextN환생 등선 개방!】 능력치 100% 계승 · 1-1 재출발 (난이도 ×$nextMult배)';
      desc =
          '5% 미만의 【윤회 최종 보스전】을 제패했습니다! 기존 능력치를 모두 품고 3배 강해진 새 차원으로 환생하세요.';
    } else if (readyBoss) {
      headline =
          '🔥 【윤회 최종 보스전 개방】 태초 심연 마제 · 무극혼돈신 (성공률 <5% · 도전 ${p.reincarnationBossAttempts}회)';
      desc =
          '악몽 10현 돌파자 전용 10물결 종결전! 패배해도 지원패·비약이 보존됩니다. 토벌 시 제$nextN환생(×$nextMult배)이 열립니다!';
    } else if (all100Done) {
      headline =
          '⚡ [악몽] 제10현 최종 결전(10-10) 정화 시 【윤회 최종 보스전(<5%)】 & 【환생】 개방!';
      desc =
          '현재 100판을 정화했습니다. [악몽] 난이도로 10-10을 깨면 최종 보스전과 능력치 계승 제$nextN환생(×$nextMult배)에 도전할 수 있습니다!';
    } else {
      headline =
          '☯️ 제${p.reincarnationCount}환생 수호 대장정 진행 중 (전 난이도 ×${p.reincarnationDifficultyMultiplier.round()}배 · 보상 ×${p.reincarnationRewardMultiplier.round()}배)';
      desc =
          '강해진 능력치에 맞춰 전 관문이 ×${p.reincarnationDifficultyMultiplier.round()}배 격상되었습니다! 윤회 초월 단련(${p.transcendenceLevel}단)을 쌓아 악몽 10현과 차기 환생에 도전하세요.';
    }

    return Container(
      key: const Key('home_reincarnation_sanctum_card'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: readyReinc
              ? const [Color(0xFF133B35), Color(0xFF2B1E4E)]
              : (readyBoss
                  ? const [Color(0xFF3E1424), Color(0xFF1E2742)]
                  : const [Color(0xFF241B3E), Color(0xFF17273E)]),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: readyReinc
              ? NightPalette.jadeGreen
              : (readyBoss
                  ? NightPalette.crimsonMoon
                  : NightPalette.accentGold),
          width: 2.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                readyReinc
                    ? Icons.autorenew_rounded
                    : (readyBoss
                        ? Icons.whatshot_rounded
                        : Icons.auto_awesome_rounded),
                color: readyReinc
                    ? NightPalette.jadeGreen
                    : NightPalette.accentGold,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(
                        fontFamily: 'BlackHanSans',
                        fontSize: 14.5,
                        color: NightPalette.accentGold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: NightPalette.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (readyReinc || readyBoss || all100Done || p.reincarnationCount > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (p.reincarnationCount > 0 &&
                    p.tokens >= p.transcendenceTokenCost &&
                    p.elixirs >= p.transcendenceElixirCost)
                  OutlinedButton.icon(
                    key: const Key('home_quick_transcendence_btn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NightPalette.jadeGreen,
                      side: const BorderSide(color: NightPalette.jadeGreen),
                    ),
                    onPressed: () {
                      if (controller.upgradeTranscendence()) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                '🌟 윤회 초월 단련 ${p.transcendenceLevel}단 돌파! (총 화력·결계 ×${p.transcendenceMultiplier.toStringAsFixed(2)}배)',
                              ),
                            ),
                          );
                      }
                    },
                    icon: const Icon(Icons.bolt_rounded, size: 17),
                    label: Text(
                      '윤회 초월 단련 (${p.transcendenceLevel}➔${p.transcendenceLevel + 1}단)',
                    ),
                  ),
                if (readyBoss)
                  FilledButton.icon(
                    key: const Key('home_reincarnation_boss_btn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: NightPalette.crimsonMoon,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final bossStage = controller.buildReincarnationBossStage();
                      controller.setDifficulty(DefenseDifficulty.nightmare);
                      Navigator.of(context).push(
                        buildSmoothBattleRoute(
                          controller: controller,
                          stage: bossStage,
                        ),
                      );
                    },
                    icon: const Icon(Icons.whatshot_rounded, size: 18),
                    label: Text(
                      readyReinc ? '최종 보스 재도전 (<5%)' : '⚔️ 윤회 최종 보스전 출정! (<5%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (!readyBoss && all100Done)
                  FilledButton.icon(
                    key: const Key('home_nightmare_10_10_btn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: NightPalette.crimsonMoon,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      controller.setDifficulty(DefenseDifficulty.nightmare);
                      controller.setSelectedChapter(10);
                      Navigator.of(context).push(
                        buildSmoothBattleRoute(
                          controller: controller,
                          stage: CampaignCatalog.allStages.last,
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_fire_department_rounded, size: 18),
                    label: const Text(
                      '🔥 악몽 10-10 즉시 도전',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (readyReinc)
                  FilledButton.icon(
                    key: const Key('home_reincarnate_btn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: NightPalette.jadeGreen,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _confirmAndReincarnate(context),
                    icon: const Icon(Icons.autorenew_rounded, size: 18),
                    label: Text(
                      '☯️ 제$nextN환생 실행 (×$nextMult배!)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
