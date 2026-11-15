import 'package:defense_core/defense_core.dart';
import 'package:flutter/material.dart';

import '../audio/night_audio.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import 'battle_screen.dart';
import 'convoy_campaign_screens.dart';
import 'loadout_upgrade_screens.dart';
import 'training_screen.dart';

/// 수호 본영 메인 대시보드 화면.
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

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/scenes/bg_lobby.webp',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(color: NightPalette.bgDeep),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC070B14),
                      Color(0xBB101829),
                      Color(0xEE090D18),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // 상단 타이틀 & 음향 토글
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '수호알까기 · 탄지무림 심야기습',
                                style: TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 23,
                                  color: NightPalette.accentGold,
                                ),
                              ),
                              Text(
                                '현재 경지 [${p.realm.name}] · 전체 진척 ${p.highestClearedGlobalStage}/${CampaignCatalog.allStages.length}단계',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: NightPalette.jadeGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '공개 제작노트 및 검증 이력',
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: NightPalette.bgPanel,
                                title: const Text(
                                  '📜 공개 제작노트 및 검증 이력',
                                  style: TextStyle(color: NightPalette.accentGold, fontSize: 18),
                                ),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    '• 설계 원칙: 손 피로도 0% 완전 자동 발사 진법 + 실패 판정 0% 기명 심법 수련\n'
                                    '• 성장 분업: 변이 처치 「증표」(발사대·수호탑 전용) / 「영약」(영수·동료·내공 전용)\n'
                                    '• 자동 검증: 1~10장(총 111단계, 10장 보스 10연전 포함) 지원패 0회·기연 0% 순수 구성 클리어 111/111 통과\n'
                                    '• 음향·자산: 원작 정본 국악·화풍 계승 + 자체 파형 합성 전용 모션음·출두 풍악 10종\n'
                                    '• 개인정보·광고: 광고 없음 · 결제 없음 · 개인정보 수집 없음 (오프라인 실행)\n'
                                    '• 제작 환경: Flutter 3.47.6 / Dart 3.13.5 · AI 협업 제작(Antigravity)',
                                    style: TextStyle(fontSize: 13.5, height: 1.5),
                                  ),
                                ),
                                actions: [
                                  FilledButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('닫기'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.menu_book_rounded, color: NightPalette.jadeGreen),
                        ),
                        IconButton(
                          tooltip: '음향 켜기/끄기',
                          onPressed: () {
                            setState(() {
                              final audio = NightAudioController.instance;
                              audio.soundEnabled = !audio.soundEnabled;
                              audio.bgmEnabled = audio.soundEnabled;
                              if (audio.bgmEnabled) {
                                audio.playBgm('bgm_lobby.ogg');
                              } else {
                                audio.stopBgm();
                              }
                            });
                          },
                          icon: Icon(
                            NightAudioController.instance.soundEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            color: NightPalette.accentGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 보유 재화 한눈에 보기
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ResourcePill(
                          icon: Icons.toll_rounded,
                          label: '증표(발사대)',
                          value: '${p.tokens}',
                          color: NightPalette.accentGold,
                        ),
                        ResourcePill(
                          icon: Icons.science_rounded,
                          label: '영약(생명)',
                          value: '${p.elixirs}',
                          color: NightPalette.elixirPurple,
                        ),
                        ResourcePill(
                          icon: Icons.campaign_rounded,
                          label: '지원패',
                          value: '${p.supportTokens}개',
                          color: NightPalette.jadeGreen,
                        ),
                        ResourcePill(
                          icon: Icons.brightness_2_rounded,
                          label: '보름달 길조',
                          value: '${p.moonOmenGauge}%',
                          color: NightPalette.jadeShield,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 다음 수호 전장 대형 카드
                    MurimCard(
                      borderColor: NightPalette.accentGold,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'assets/images/chars/${chSpec.bossPortraitPrefix}_face.webp',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const CircleAvatar(radius: 28, child: Icon(Icons.shield)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${chSpec.title} · ${chSpec.villageName}',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: NightPalette.jadeShield,
                                      ),
                                    ),
                                    Text(
                                      nextStage.title,
                                      style: const TextStyle(
                                        fontFamily: 'BlackHanSans',
                                        fontSize: 19,
                                        color: NightPalette.accentGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '장착 진법: [${preset.name}] · ${preset.primaryStone.grade}단 ${preset.primaryStone.name}(${preset.primaryShape.name}) · 영수 ${preset.equippedBeast.name} · 동료 ${preset.companions.map((e) => e.name).join("/")}',
                            style: const TextStyle(fontSize: 13, color: NightPalette.textMuted),
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
                                      builder: (_) => CampaignScreen(controller: widget.controller),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_rounded, size: 18),
                                label: const Text('1~10장 지도 선택'),
                              ),
                              FilledButton.icon(
                                key: const Key('home_quick_battle_btn'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: NightPalette.accentGold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('즉시 야간 수호 출정'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 핵심 메뉴 2열 그리드
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.38,
                      children: [
                        _MenuTile(
                          tileKey: const Key('menu_training_btn'),
                          icon: Icons.self_improvement_rounded,
                          title: '기명 심법 수련',
                          subtitle: '알까기 없음 · 실패 0%\n단전 운기 & 10단 경맥 개통',
                          accent: NightPalette.jadeGreen,
                          badge: p.canOpenNextMeridian() ? '개통 가능!' : null,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TrainingScreen(controller: widget.controller),
                            ),
                          ),
                        ),
                        _MenuTile(
                          tileKey: const Key('menu_loadout_btn'),
                          icon: Icons.tune_rounded,
                          title: '자동 진법 편성',
                          subtitle: '거점 발사대 · 수호석\n동료/영수 발동 조건 설정',
                          accent: NightPalette.jadeShield,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LoadoutScreen(controller: widget.controller),
                            ),
                          ),
                        ),
                        _MenuTile(
                          tileKey: const Key('menu_forge_btn'),
                          icon: Icons.precision_manufacturing_rounded,
                          title: '증표 대장간 · 영약각',
                          subtitle: '증표→발사대/수호탑 강화\n영약→영수/동료/내공 승급',
                          accent: NightPalette.accentGold,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UpgradeScreen(controller: widget.controller),
                            ),
                          ),
                        ),
                        _MenuTile(
                          tileKey: const Key('menu_convoy_btn'),
                          icon: Icons.campaign_rounded,
                          title: '물자 호송 · 지원패',
                          subtitle: '호송 마차 · 심야 탐색\n보름달 기연 & 출두 지원패',
                          accent: NightPalette.elixirPurple,
                          badge: (p.moonOmenGauge >= 100 ||
                                  (p.convoyActive && p.convoyBattlesRemaining == 0) ||
                                  (p.exploreActive && p.exploreBattlesRemaining == 0))
                              ? '보상 도착!'
                              : null,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ConvoyAndSerendipityScreen(controller: widget.controller),
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
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  final Key? tileKey;
  final IconData icon;
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
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accent, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15.5, color: accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.8,
                    color: NightPalette.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
