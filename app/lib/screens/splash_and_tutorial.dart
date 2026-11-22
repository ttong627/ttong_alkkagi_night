import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/night_audio.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'home_screen.dart';

/// 게임 시작 오프닝 스플래시 화면:
/// - 영웅단(기명·검황·연비·금룡) 대 3페이즈 돌연변이 대수괴 결전 키아트(`bg_night_splash.webp`) 전면 노출
/// - 하단 한지 주인공 명패 + 54px 대형 출정 단추로 클로드 디자인/프로그램 하네스 기준 충족.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Timer? _autoTimer;
  bool _navigated = false;

  static const List<String> _tips = [
    '본진 단독 방치로는 마을이 함락됩니다. 군수 기력을 모아 빛나는 빈 초소에 발사대를 배치하세요.',
    '50 기력부터 도박 소환이나 ★추천 축조로 초소를 세우고, 같은 포탑 2기는 유료 연성 합체로 진화시켜 5형 태초 신기를 깨우세요.',
    '중간보스는 2차 재변이를 일으키고, 3페이즈 대수괴는 회전 약점을 정밀 타격해야 외각 장갑이 파쇄됩니다.',
    '하단 5탭에서 진법 원터치 최적 편성과 도착 보상 일괄 수령으로 손쉽게 출정 준비를 마치세요.',
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheCoreAssets();
    });

    _autoTimer = Timer(const Duration(milliseconds: 1350), _enterHome);
  }

  Future<void> _precacheCoreAssets() async {
    const assets = [
      NightArtRegistry.bgNightSplash,
      NightArtRegistry.bgNightLobby,
      NightArtRegistry.lobbyStageFortress,
      NightArtRegistry.cardGateBattle,
      NightArtRegistry.cardTrainingHall,
      NightArtRegistry.cardAllyPavilion,
      NightArtRegistry.cardForgeSanctum,
      NightArtRegistry.cardSupplyConvoy,
      NightArtRegistry.cardRescueBeacon,
      NightArtRegistry.cardEndlessAbyss,
      NightArtRegistry.heroClashBanner,
      NightArtRegistry.mutantPackBanner,
      NightArtRegistry.showcaseBossChapter,
      NightArtRegistry.appLogo,
      NightArtRegistry.iconRogueScroll,
      NightArtRegistry.iconLuckyDice,
      NightArtRegistry.wslogisLogo,
    ];
    for (final path in assets) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
    }
  }

  void _enterHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _autoTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, _, _) => HomeScreen(controller: widget.controller),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().second % _tips.length];
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enterHome,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) 전면 영웅 대 3페이즈 대수괴 3D 시네마틱 루프 모션 + 절제된 청람·황금 색조 보정(색 가짓수 ≤ 5)
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.86, 0.08, 0.06, 0, 0,
                0.06, 0.88, 0.06, 0, 0,
                0.05, 0.08, 0.92, 0, 0,
                0,    0,    0,    1, 0,
              ]),
              child: Image.asset(
                NightArtRegistry.splashClashLoop,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Image.asset(
                  NightArtRegistry.bgNightSplash,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: NightPalette.bgDeep),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.54, 1.0],
                  colors: [
                    Color(0x46121C30),
                    Color(0x4A162238),
                    Color(0xEE142034),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 상단 인장 배지
                              Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xDC18253C),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: NightPalette.borderGold,
                                    ),
                                  ),
                                  child: const Text(
                                    '탄지무림 외전 · 영웅 진법 대 변이 대수괴 수호전',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: NightPalette.accentGold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 180),

                              // 하단 한지 주인공 타이틀 명패 + 즉시 출정 행동 단추 (단일 시선 초점!)
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 520),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    18,
                                    20,
                                    18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: NightPalette.hanjiLight,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: NightPalette.accentGold,
                                      width: 2.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x58000000),
                                        blurRadius: 18,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const NightSpriteIcon(
                                            assetPath: NightArtRegistry.appLogo,
                                            fallbackAssetPath:
                                                NightArtRegistry.towerGuardian,
                                            fallbackIcon:
                                                Icons.shield_moon_rounded,
                                            size: 56,
                                            borderRadius: 14,
                                            showFrame: true,
                                            frameColor: NightPalette.hanjiInk,
                                          ),
                                          const SizedBox(width: 14),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: const [
                                                Text(
                                                  '수호알까기',
                                                  style: TextStyle(
                                                    fontFamily: 'BlackHanSans',
                                                    fontSize: 36,
                                                    letterSpacing: 1.0,
                                                    color: NightPalette.hanjiInk,
                                                    height: 1.08,
                                                  ),
                                                ),
                                                Text(
                                                  '탄지무림 · 심야기습',
                                                  style: TextStyle(
                                                    fontFamily: 'BlackHanSans',
                                                    fontSize: 18.5,
                                                    color:
                                                        NightPalette.hanjiSubInk,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        tip,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13.0,
                                          color: NightPalette.hanjiSubInk,
                                          height: 1.38,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                NightPalette.hanjiInk,
                                            foregroundColor:
                                                NightPalette.accentGold,
                                          ),
                                          onPressed: _enterHome,
                                          icon: const Icon(
                                            Icons.shield_moon_rounded,
                                          ),
                                          label: const Text(
                                            '심야 수호 본영 즉시 입장',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// 4단계 초간단 입문 수호 교범 대화상자 (첫 실행 시 안내 또는 설정에서 언제든 다시 열람).
Future<void> showTutorialGuideDialog(
  BuildContext context,
  GameController controller,
) async {
  const steps = [
    (
      speaker: '사부 현암',
      portrait: 'sabu',
      emblemAsset: NightArtRegistry.towerGuardian,
      title: '1/4 · 10장 고유 지형 경로 & 전략 초소 배치',
      body: '1장부터 10장까지 매 장마다 경로 구조·수호탑 위치·지형 효과가 달라지며, 초소마다 제한된 전술 사거리를 가집니다.\n'
          '두 줄기 길이 만나는 요충지 거점을 우선 개척해 추천 포탑을 세우고, 하단 [사거리업]으로 사격망을 넓히세요.',
    ),
    (
      speaker: '의용대장 석두',
      portrait: 'seokdu',
      emblemAsset: NightArtRegistry.iconLuckyDice,
      title: '2/4 · 실시간 전군 강화 4종 & 유료 연성 5형 신기 합체',
      body: '• 하단 [🔨추천축조 · ⚔️화력업 · ⚡연사업 · 🔭사거리업 · 🛡️결계업]을 누르면 멈춤 없이 즉시 반영됩니다.\n'
          '• 이미 지은 같은 등급 초소 2기는 연성 기력(24⚡~)으로 합쳐 상위 형으로 진화하며, 4형 2기 합체 시 ★5형 태초 신기와 돌림판이 개방됩니다.',
    ),
    (
      speaker: '명궁 연비',
      portrait: 'yeonbi',
      emblemAsset: NightArtRegistry.showcaseBossChapter,
      title: '3/4 · 중간보스 2차 재변이 & 3페이즈 대수괴 약점 저격',
      body: '• 중간보스는 체력 소진 시 2차 재변이를 일으키며 근처 포탑에 마기 침식을 겁니다(침식된 포탑을 누르면 즉시 정화 및 각성).\n'
          '• 장별 대수괴는 3페이즈 외각 장갑을 두르므로, 빛나는 회전 약점 과녁을 직접 눌러 파갑 신궁탄으로 정밀 파쇄하세요.',
    ),
    (
      speaker: '기관장 정각',
      portrait: 'jeonggak',
      emblemAsset: NightArtRegistry.nightSupportSeal,
      title: '4/4 · 하단 5탭 원터치 편성 & 무림수호단 출두',
      body: '• 본영 하단 5탭에서 [원터치 최적 진법 편성], [추천 일괄 강화], [도착 보상 일괄 수령]을 한 번에 처리할 수 있습니다.\n'
          '• 전장 위기 순간에는 [무림수호단 출두]를 눌러 황금 기마대 일제 사격으로 변이 군단을 쓸어버리세요.',
    ),
  ];

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      int page = 0;
      return StatefulBuilder(
        builder: (ctx, setModal) {
          final cur = steps[page];
          return Dialog(
            backgroundColor: NightPalette.bgPanel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: NightPalette.accentGold, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        NightSpriteIcon(
                          assetPath: NightArtRegistry.charAttack(cur.portrait),
                          fallbackAssetPath: NightArtRegistry.charFace(cur.portrait),
                          fallbackIcon: Icons.school_rounded,
                          size: 62,
                          borderRadius: 16,
                          fit: BoxFit.contain,
                          showFrame: true,
                          frameColor: NightPalette.accentGold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cur.speaker,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: NightPalette.jadeGreen,
                                ),
                              ),
                              Text(
                                cur.title,
                                style: const TextStyle(
                                  fontFamily: 'BlackHanSans',
                                  fontSize: 16.5,
                                  color: NightPalette.accentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        NightSpriteIcon(
                          assetPath: cur.emblemAsset,
                          fallbackIcon: Icons.auto_awesome_rounded,
                          size: 40,
                          borderRadius: 8,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      cur.body,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: NightPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () {
                            controller.markTutorialSeen();
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('바로 시작하기'),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (page > 0)
                              OutlinedButton(
                                onPressed: () {
                                  NightAudioController.instance
                                      .playAsset('ui_tap.ogg');
                                  setModal(() => page--);
                                },
                                child: const Text('이전'),
                              ),
                            if (page > 0) const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: NightPalette.accentGold,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                NightAudioController.instance
                                    .playAsset('ui_tap.ogg');
                                if (page + 1 < steps.length) {
                                  setModal(() => page++);
                                } else {
                                  controller.markTutorialSeen();
                                  Navigator.of(ctx).pop();
                                }
                              },
                              child: Text(
                                page + 1 < steps.length
                                    ? '다음 비급'
                                    : '수호 출정 준비 완료',
                              ),
                            ),
                          ],
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
    },
  );
  controller.markTutorialSeen();
}
