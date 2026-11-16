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

/// 수호 본영 메인 게임 로비 화면:
/// - 코덱스 성채 디오라마 무대(`lobby_stage_fortress.webp`) + 실시간 등불 입자 & 구출 동료·영수 전신 스탠딩
/// - 순서대로 정해진 듯 다음 관문 출정을 유도하는 황금 성문 배너(`card_gate_battle.webp`)
/// - 코덱스 전각 일러스트 6종(`card_*.webp`) 기반 이미지형 본영 시설 카드 덱.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientAnim;

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
        final nextRescue = p.nextRescueStage;

        return Scaffold(
          body: NightSceneBackdrop(
            assetPath: NightArtRegistry.bgNightLobby,
            fallbackAssetPath: NightArtRegistry.bgLobbyFallback,
            overlayOpacity: 0.72,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final isWide = viewport.maxWidth >= 820;
                  final gridColumns = viewport.maxWidth >= 900 ? 3 : 2;
                  final gridAspect = viewport.maxWidth < 360
                      ? 1.24
                      : (viewport.maxWidth >= 900 ? 1.58 : 1.44);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1) 상단 게임 타이틀 & 도감 · 설정 빠른 아이콘 바
                      Row(
                        children: [
                          const NightSpriteIcon(
                            assetPath: NightArtRegistry.appLogo,
                            fallbackAssetPath: NightArtRegistry.towerGuardian,
                            fallbackIcon: Icons.shield_moon_rounded,
                            size: 40,
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
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '경지 [${p.realm.name}] · 수호 ${p.highestClearedGlobalStage}/${CampaignCatalog.allStages.length}관문 · 동료 ${p.unlockedCompanionCount}/14 · 영수 ${p.unlockedBeastCount}/5',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.8,
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

                      // 상단 보유 재화 HUD 바
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
                            label: '보름달',
                            value: '${p.moonOmenGauge}%',
                            color: NightPalette.jadeShield,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 입문 수호 교범 미열람 시 1회 안내 배너
                      if (!p.tutorialSeen) ...[
                        MurimCard(
                          borderColor: NightPalette.jadeGreen,
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
                                '📜 길목 빈 초소 직접 배치 & 중앙 수호탑 자동·수동 비급을 30초 만에 확인하세요!',
                                style: TextStyle(
                                  fontSize: 12.2,
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
                                icon:
                                    const Icon(Icons.school_rounded, size: 16),
                                label: const Text('수호 교범 열기'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // 2) 성채 라이브 디오라마 무대 + 황금 성문 순서 출정 카드 (가로 대화면에서는 좌우 2단 배치!)
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 12,
                              child: _FortressDioramaStage(
                                ambientAnim: _ambientAnim,
                                progress: p,
                                preset: preset,
                                nextRescue: nextRescue,
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 10,
                              child: _SequentialBattleGateBanner(
                                controller: widget.controller,
                                chSpec: chSpec,
                                nextStage: nextStage,
                                preset: preset,
                                minHeight: 236,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _FortressDioramaStage(
                          ambientAnim: _ambientAnim,
                          progress: p,
                          preset: preset,
                          nextRescue: nextRescue,
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
                        _SequentialBattleGateBanner(
                          controller: widget.controller,
                          chSpec: chSpec,
                          nextStage: nextStage,
                          preset: preset,
                          minHeight: 186,
                        ),
                      ],
                      const SizedBox(height: 14),

                      // 3) 본영 전각 일러스트 카드 6종 그리드 (중첩 Scrollable 없는 고성능 행렬 배치)
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
                                '단전 운기 · 경맥 ${p.openedMeridianStep}/10단 개통',
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
                          _GameImageFacilityCard(
                            tileKey: const Key('menu_loadout_btn'),
                            sceneAsset: NightArtRegistry.cardAllyPavilion,
                            emblemAsset: NightArtRegistry.beastAsset(
                              preset.equippedBeast,
                            ),
                            fallbackIcon: Icons.groups_rounded,
                            title: '수호 진법 · 동료각',
                            tagLine:
                                '구출 동료 ${p.unlockedCompanionCount}/14 · 영수 ${p.unlockedBeastCount}/5',
                            accent: NightPalette.jadeShield,
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
                                '수호탑 ${p.centralGuardianLevel}단 · 발사대/수호석 강화',
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
                                '호송 마차 · 심야 탐색 · 출두 ${p.supportTokens}패',
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
                          _GameImageFacilityCard(
                            tileKey: const Key('menu_daily_btn'),
                            sceneAsset: NightArtRegistry.cardRescueBeacon,
                            emblemAsset: NightArtRegistry.iconAttendance,
                            fallbackIcon: Icons.event_available_rounded,
                            title: '출석 · 임무 · 비약방',
                            tagLine: '7일 출석 · 수호 임무 · 전술 비약 제조',
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
                          _GameImageFacilityCard(
                            tileKey: const Key('menu_endless_btn'),
                            sceneAsset: NightArtRegistry.cardEndlessAbyss,
                            emblemAsset: NightArtRegistry.nightEndless,
                            fallbackIcon:
                                Icons.local_fire_department_rounded,
                            title: '심야 무한 혈전장',
                            tagLine:
                                '최고 ${p.bestEndlessWave}물결 돌파 · 한계 시험장',
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
                      ),
                    ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 수호 본영 상단 라이브 성채 디오라마 무대 (`lobby_stage_fortress.webp` + 전신 동료·영수·수호탑 + 구출 배지).
class _FortressDioramaStage extends StatelessWidget {
  const _FortressDioramaStage({
    required this.ambientAnim,
    required this.progress,
    required this.preset,
    required this.nextRescue,
    required this.onOpenRescueMap,
  });

  final Animation<double> ambientAnim;
  final PlayerProgress progress;
  final LoadoutPreset preset;
  final StageSpec? nextRescue;
  final VoidCallback onOpenRescueMap;

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
      height: 236,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: NightPalette.accentGold.withValues(alpha: 0.82),
          width: 1.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88040812),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) 코덱스 심야 성채 마당 원화 배경
            Image.asset(
              NightArtRegistry.lobbyStageFortress,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                NightArtRegistry.bgNightLobby,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: NightPalette.bgDeep),
              ),
            ),

            // 2) 원근감 비네팅 그라데이션
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.45, 1.0],
                  colors: [
                    Color(0x66060A14),
                    Color(0x180B1324),
                    Color(0xCC060A14),
                  ],
                ),
              ),
            ),

            // 3) 실시간 떠오르는 등불 불티 & 비취 수호 광륜 애니메이션
            AnimatedBuilder(
              animation: ambientAnim,
              builder: (context, _) {
                final phase = ambientAnim.value * 2 * pi;
                final hoverA = sin(phase) * 3.5;
                final hoverB = cos(phase + 1.2) * 3.2;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _DioramaEmbersPainter(progress: ambientAnim.value),
                    ),

                    // 성채 중앙 기명 수호탑 + 회전 기운
                    Align(
                      alignment: const Alignment(0.0, 0.24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: phase,
                            child: Opacity(
                              opacity: 0.44,
                              child: Image.asset(
                                NightArtRegistry.fxQi,
                                width: 112,
                                height: 112,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Image.asset(
                            NightArtRegistry.towerGuardian,
                            width: 86,
                            height: 86,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.fort_rounded,
                              size: 56,
                              color: NightPalette.accentGold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 좌측 호위 동료 전신 스탠딩
                    if (heroes.isNotEmpty)
                      Align(
                        alignment: const Alignment(-0.62, 0.56),
                        child: Transform.translate(
                          offset: Offset(0, hoverA * 0.6),
                          child: _DioramaHeroStandee(
                            hero: heroes[0],
                            level: progress.companionLevels[heroes[0]] ?? 1,
                          ),
                        ),
                      ),

                    // 우측 호위 동료 전신 스탠딩 (2인 이상 구출 시)
                    if (heroes.length >= 2)
                      Align(
                        alignment: const Alignment(0.62, 0.56),
                        child: Transform.translate(
                          offset: Offset(0, hoverB * 0.6),
                          child: _DioramaHeroStandee(
                            hero: heroes[1],
                            level: progress.companionLevels[heroes[1]] ?? 1,
                          ),
                        ),
                      ),

                    // 좌측 후열 3번째 동료 (3인 편성 시)
                    if (heroes.length >= 3)
                      Align(
                        alignment: const Alignment(-0.28, 0.42),
                        child: Transform.translate(
                          offset: Offset(0, -hoverA * 0.5),
                          child: _DioramaHeroStandee(
                            hero: heroes[2],
                            level: progress.companionLevels[heroes[2]] ?? 1,
                            height: 76,
                          ),
                        ),
                      ),

                    // 우측 상공 호위 영수 스탠딩
                    Align(
                      alignment: const Alignment(0.28, 0.08),
                      child: Transform.translate(
                        offset: Offset(0, hoverA),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NightSpriteIcon(
                              assetPath: NightArtRegistry.beastAsset(
                                preset.equippedBeast,
                              ),
                              fallbackIcon: Icons.pets_rounded,
                              size: 48,
                              borderRadius: 12,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xCC08101E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: NightPalette.jadeGreen
                                      .withValues(alpha: 0.65),
                                ),
                              ),
                              child: Text(
                                preset.equippedBeast.name.split(' ').last,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: NightPalette.jadeGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // 4) 좌상단 본영 진법 문패 & 우상단 다음 동료·영수 구출 목표 배지
            Positioned(
              top: 10,
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
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xD809101E),
                      borderRadius: BorderRadius.circular(14),
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
                            '수호 본영 · ${preset.primaryStone.grade}단 ${preset.primaryStone.name}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
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
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xEE10323A), Color(0xEE194A52)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: NightPalette.jadeGreen,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          '🆘 다음 구출: ${nextRescue!.code} ${nextRescue!.rescueBadgeText}',
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

            // 5) 디오라마 하단 마을 본진 수호 현황 바
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '🏯 남단 마을 본진 수호진 (${preset.name})',
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
    this.height = 92,
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
          NightArtRegistry.heroIdleAsset(hero),
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => NightSpriteIcon(
            assetPath: NightArtRegistry.heroFaceAsset(hero),
            fallbackIcon: Icons.person_rounded,
            size: 46,
            borderRadius: 23,
            showFrame: true,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
          decoration: BoxDecoration(
            color: const Color(0xD8080F1D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: NightPalette.accentGold.withValues(alpha: 0.65),
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

/// 순서대로 정해진 듯 다음 관문 진입을 유도하는 황금 성문 주 출정 카드 (`card_gate_battle.webp`).
class _SequentialBattleGateBanner extends StatelessWidget {
  const _SequentialBattleGateBanner({
    required this.controller,
    required this.chSpec,
    required this.nextStage,
    required this.preset,
    required this.minHeight,
  });

  final GameController controller;
  final ChapterSpec chSpec;
  final StageSpec nextStage;
  final LoadoutPreset preset;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NightPalette.accentGold, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FFD166),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.2),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                NightArtRegistry.cardGateBattle,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  chSpec.bgAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: NightPalette.bgPanel),
                ),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xEB070C18),
                      Color(0xC60E182C),
                      Color(0xDC080E1C),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: NightPalette.accentGold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '▶ 이번 수호 차례 (${nextStage.globalIndex}/${CampaignCatalog.allStages.length})',
                          style: const TextStyle(
                            fontSize: 11.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC13263B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: NightPalette.jadeShield.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Text(
                          '빈 초소 ${nextStage.maxMountCount}곳 개방 · ${nextStage.waves.length}물결',
                          style: const TextStyle(
                            fontSize: 11,
                            color: NightPalette.jadeShield,
                          ),
                        ),
                      ),
                      if (nextStage.hasRescueReward)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xDD143D38),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: NightPalette.jadeGreen),
                          ),
                          child: Text(
                            '🆘 ${nextStage.rescueBadgeText}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: NightPalette.jadeGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      NightSpriteIcon(
                        assetPath: NightArtRegistry.charFace(
                          chSpec.bossPortraitPrefix,
                        ),
                        fallbackIcon: Icons.shield_rounded,
                        size: 50,
                        borderRadius: 25,
                        fit: BoxFit.cover,
                        showFrame: true,
                        frameColor: NightPalette.accentGold,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${chSpec.title} · ${chSpec.villageName}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.icon(
                        key: const Key('home_quick_battle_btn'),
                        style: FilledButton.styleFrom(
                          backgroundColor: NightPalette.accentGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
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
                          size: 20,
                          color: Colors.black,
                        ),
                        label: const Text(
                          '즉시 야간 수호 출정',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const Key('home_campaign_map_btn'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xAA0A1222),
                          side: const BorderSide(color: NightPalette.jadeShield),
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
                          color: NightPalette.jadeShield,
                        ),
                        label: const Text('1~10장 행군 지도'),
                      ),
                    ],
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

/// 코덱스 전각·시설 일러스트가 전면에 깔린 상용 게임형 본영 카드.
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
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: accent.withValues(alpha: 0.78),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66040812),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13.6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1) 전면 코덱스 시설 일러스트 원화
                Image.asset(
                  sceneAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: NightPalette.bgPanel),
                ),

                // 2) 상단 일러스트는 선명하게 살리고 하단 명패 자리만 어둡게 받쳐주는 게임 카드 그라데이션
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.36, 1.0],
                      colors: [
                        Color(0x28060A14),
                        Color(0x55080F1E),
                        Color(0xEE070C18),
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
                    frameColor: accent,
                  ),
                ),

                // 4) 우상단 실시간 알림 배지
                if (badge != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: NightPalette.crimsonMoon,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.65),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                          fontSize: 14.8,
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
                          fontSize: 11.0,
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

/// 중첩 스크롤 없이 2열/3열 전각 이미지 카드를 고정 비율로 배치하는 무지연 행렬 위젯.
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
      if (rows.isNotEmpty) {
        rows.add(SizedBox(height: spacing));
      }
      final rowChildren = <Widget>[];
      for (int c = 0; c < columns; c++) {
        if (c > 0) {
          rowChildren.add(SizedBox(width: spacing));
        }
        final idx = i + c;
        if (idx < children.length) {
          rowChildren.add(
            Expanded(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: children[idx],
              ),
            ),
          );
        } else {
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      rows.add(Row(children: rowChildren));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}
