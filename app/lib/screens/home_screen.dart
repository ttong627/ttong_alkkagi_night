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

/// 수호 본영 메인 대시보드 화면 (`bg_night_lobby.webp` + 코덱스 전용 아이콘 전수 적용).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    NightAudioController.instance.playBgm('bgm_lobby.ogg');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final p = widget.controller.progress;
        final nextGlobal = (p.highestClearedGlobalStage + 1)
            .clamp(1, CampaignCatalog.allStages.length);
        final nextStage = CampaignCatalog.allStages[nextGlobal - 1];
        final chSpec = CampaignCatalog.chapterOf(nextStage.chapterNumber);
        final preset = p.activePreset;
        final hasQuestReward = p.hasClaimableRewards();

        return Scaffold(
          body: NightSceneBackdrop(
            assetPath: NightArtRegistry.bgNightLobby,
            fallbackAssetPath: NightArtRegistry.bgLobbyFallback,
            overlayOpacity: 0.78,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // 상단 앱 엠블럼 & 타이틀 & 도감 · 설정 빠른 버튼
                  Row(
                    children: [
                      const NightSpriteIcon(
                        assetPath: NightArtRegistry.appLogo,
                        fallbackAssetPath: NightArtRegistry.towerGuardian,
                        fallbackIcon: Icons.shield_moon_rounded,
                        size: 38,
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
                                fontSize: 20,
                                color: NightPalette.accentGold,
                              ),
                            ),
                            Text(
                              '경지 [${p.realm.name}] · 진척 ${p.highestClearedGlobalStage}/${CampaignCatalog.allStages.length}단계 · 도감 +${(p.codexPowerBonus * 100).toStringAsFixed(1)}%',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: NightPalette.jadeGreen,
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
                              builder: (_) =>
                                  CodexScreen(controller: widget.controller),
                            ),
                          );
                        },
                        icon: const NightSpriteIcon(
                          assetPath: NightArtRegistry.iconCodex,
                          fallbackIcon: Icons.auto_stories_rounded,
                          size: 26,
                          color: NightPalette.jadeShield,
                        ),
                      ),
                      IconButton(
                        key: const Key('home_settings_btn'),
                        visualDensity: VisualDensity.compact,
                        tooltip: '환경 설정 · 백업 · 만든 이 · 제작노트',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SettingsScreen(controller: widget.controller),
                            ),
                          );
                        },
                        icon: const NightSpriteIcon(
                          assetPath: NightArtRegistry.iconSettings,
                          fallbackIcon: Icons.settings_rounded,
                          size: 26,
                          color: NightPalette.accentGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 입문 수호 교범 미열람 시 1회 안내 배너
                  if (!p.tutorialSeen) ...[
                    MurimCard(
                      borderColor: NightPalette.jadeGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '📜 처음 오셨나요? 자동 발사 진법과 증표·영약 분업을 1분 만에 확인하세요!',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: NightPalette.textPrimary,
                            ),
                          ),
                          FilledButton.tonalIcon(
                            key: const Key('home_open_tutorial_btn'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => showTutorialGuideDialog(
                              context,
                              widget.controller,
                            ),
                            icon: const Icon(Icons.school_rounded, size: 16),
                            label: const Text('수호 교범 열기'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 상단 보유 재화 바 (코덱스 전용 원화 적용)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ResourcePill(
                        iconAsset: NightArtRegistry.nightToken,
                        icon: Icons.toll_rounded,
                        label: '증표(발사대)',
                        value: '${p.tokens}',
                        color: NightPalette.accentGold,
                      ),
                      ResourcePill(
                        iconAsset: NightArtRegistry.nightElixir,
                        icon: Icons.science_rounded,
                        label: '영약(생명)',
                        value: '${p.elixirs}',
                        color: NightPalette.elixirPurple,
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
                        label: '보름달 길조',
                        value: '${p.moonOmenGauge}%',
                        color: NightPalette.jadeShield,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 다음 수호 전장 대형 카드
                  MurimCard(
                    borderColor: NightPalette.accentGold,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.charFace(
                                chSpec.bossPortraitPrefix,
                              ),
                              fallbackIcon: Icons.shield_rounded,
                              size: 56,
                              borderRadius: 28,
                              fit: BoxFit.cover,
                              showFrame: true,
                              frameColor: NightPalette.accentGold,
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
                                      fontSize: 13.5,
                                      color: NightPalette.jadeShield,
                                    ),
                                  ),
                                  Text(
                                    nextStage.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 18.5,
                                      color: NightPalette.accentGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.stoneAsset(
                                preset.primaryStone,
                              ),
                              fallbackIcon: Icons.circle,
                              size: 38,
                              color: Color(preset.primaryStone.colorHex),
                              showFrame: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.beastAsset(
                                preset.equippedBeast,
                              ),
                              fallbackIcon: Icons.pets_rounded,
                              size: 22,
                              borderRadius: 6,
                            ),
                            Text(
                              '장착 진법: [${preset.name}] · ${preset.primaryStone.grade}단 ${preset.primaryStone.name}(${preset.primaryShape.name}) · 영수 ${preset.equippedBeast.name} · 동료 ${preset.companions.map((e) => e.name).join("/")}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: NightPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              key: const Key('home_campaign_map_btn'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CampaignScreen(
                                      controller: widget.controller,
                                    ),
                                  ),
                                );
                              },
                              icon: const NightSpriteIcon(
                                assetPath: NightArtRegistry.iconCampaign,
                                fallbackIcon: Icons.map_rounded,
                                size: 18,
                                color: NightPalette.jadeShield,
                              ),
                              label: const Text('1~10장 지도 선택'),
                            ),
                            FilledButton.icon(
                              key: const Key('home_quick_battle_btn'),
                              style: FilledButton.styleFrom(
                                backgroundColor: NightPalette.accentGold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BattleScreen(
                                      controller: widget.controller,
                                      stage: nextStage,
                                    ),
                                  ),
                                );
                              },
                              icon: const NightSpriteIcon(
                                assetPath: NightArtRegistry.towerGuardian,
                                fallbackIcon: Icons.play_arrow_rounded,
                                size: 20,
                                color: Colors.black,
                              ),
                              label: const Text('즉시 야간 수호 출정'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 핵심 메뉴 2열 6타일 그리드 (좁은 화면 반응형 비율 자동 보정)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final ratio = constraints.maxWidth < 360 ? 1.18 : 1.36;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: ratio,
                        children: [
                          _MenuTile(
                            tileKey: const Key('menu_training_btn'),
                            iconAsset: NightArtRegistry.nightMeridian,
                            fallbackAsset: 'assets/images/icons/training.webp',
                            fallbackIcon: Icons.self_improvement_rounded,
                            title: '기명 심법 수련',
                            subtitle: '알까기 없음 · 실패 0%\n단전 운기 & 10단 경맥 개통',
                            accent: NightPalette.jadeGreen,
                            badge: p.canOpenNextMeridian() ? '개통 가능!' : null,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TrainingScreen(
                                  controller: widget.controller,
                                ),
                              ),
                            ),
                          ),
                          _MenuTile(
                            tileKey: const Key('menu_loadout_btn'),
                            iconAsset: NightArtRegistry.launcherAsset(
                              LauncherType.rapid,
                            ),
                            fallbackAsset: 'assets/images/icons/terrain.webp',
                            fallbackIcon: Icons.tune_rounded,
                            title: '자동 진법 편성',
                            subtitle: '거점 발사대 · 수호석\n동료/영수 발동 조건 설정',
                            accent: NightPalette.jadeShield,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LoadoutScreen(
                                  controller: widget.controller,
                                ),
                              ),
                            ),
                          ),
                          _MenuTile(
                            tileKey: const Key('menu_forge_btn'),
                            iconAsset: NightArtRegistry.towerGuardian,
                            fallbackAsset: 'assets/images/icons/depot.webp',
                            fallbackIcon:
                                Icons.precision_manufacturing_rounded,
                            title: '증표 대장간 · 영약각',
                            subtitle: '증표→발사대/수호탑 강화\n영약→영수/동료/내공 승급',
                            accent: NightPalette.accentGold,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UpgradeScreen(
                                  controller: widget.controller,
                                ),
                              ),
                            ),
                          ),
                          _MenuTile(
                            tileKey: const Key('menu_convoy_btn'),
                            iconAsset: NightArtRegistry.nightConvoyCart,
                            fallbackAsset: 'assets/images/icons/wander.webp',
                            fallbackIcon: Icons.campaign_rounded,
                            title: '물자 호송 · 지원패',
                            subtitle: '호송 마차 · 심야 탐색\n보름달 기연 & 출두 지원패',
                            accent: NightPalette.elixirPurple,
                            badge: (p.moonOmenGauge >= 100 ||
                                    (p.convoyActive &&
                                        p.convoyBattlesRemaining == 0) ||
                                    (p.exploreActive &&
                                        p.exploreBattlesRemaining == 0))
                                ? '보상 도착!'
                                : null,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ConvoyAndSerendipityScreen(
                                  controller: widget.controller,
                                ),
                              ),
                            ),
                          ),
                          _MenuTile(
                            tileKey: const Key('menu_daily_btn'),
                            iconAsset: NightArtRegistry.iconAttendance,
                            fallbackIcon: Icons.event_available_rounded,
                            title: '출석 · 임무 · 비약',
                            subtitle: '7일 순환 출석 · 주간임무\n전술 비약 제조 & 업적',
                            accent: Colors.amberAccent,
                            badge: hasQuestReward ? '수령 가능!' : null,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DailyAndQuestsScreen(
                                  controller: widget.controller,
                                ),
                              ),
                            ),
                          ),
                          _MenuTile(
                            tileKey: const Key('menu_endless_btn'),
                            iconAsset: NightArtRegistry.nightEndless,
                            fallbackAsset: 'assets/images/icons/arena.webp',
                            fallbackIcon:
                                Icons.local_fire_department_rounded,
                            title: '심야 무한 혈전',
                            subtitle: '최고 ${p.bestEndlessWave}물결 돌파\n한계 시험장 & 대량 보급',
                            accent: NightPalette.crimsonMoon,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EndlessSurvivalScreen(
                                  controller: widget.controller,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    this.tileKey,
    required this.iconAsset,
    this.fallbackAsset,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final Key? tileKey;
  final String iconAsset;
  final String? fallbackAsset;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: tileKey,
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: MurimCard(
        borderColor: accent.withValues(alpha: 0.65),
        padding: const EdgeInsets.all(11),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    NightSpriteIcon(
                      assetPath: iconAsset,
                      fallbackAssetPath: fallbackAsset,
                      fallbackIcon: fallbackIcon,
                      size: 28,
                      color: accent,
                      borderRadius: 6,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: NightPalette.textMuted,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: NightPalette.crimsonMoon,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
