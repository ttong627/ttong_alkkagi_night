import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/night_audio.dart';
import '../state/game_controller.dart';
import '../theme/night_theme.dart';
import '../ui/night_art_registry.dart';
import 'home_screen.dart';

/// 게임 시작 오프닝 스플래시 화면 (`bg_night_splash.webp` + `app_logo.webp` + 사부/반달 원화).
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
    '본진 단독 방치로는 마을이 함락됩니다! 군수 기력(⚡)을 모아 빛나는 빈 초소(2→10곳)에 발사대를 배치하세요!',
    '⚡35 기력으로 「🎲 운빨 대박 소환」을 돌리면 상위 발사대나 2·3형 각성 포탑이 단숨에 강림하며, 같은 포탑 2기는 무료(0⚡)로 합쳐 진화합니다!',
    '물결 돌파나 보물 도깨비 처치마다 「📜 심야 돌파 비급(3택 1)」이 열려 쌍탄 분열·연쇄 뇌전·화염 폭발을 중첩할 수 있습니다!',
    '전장 한가운데 「🌀 ×2 복제 마법진」과 「🧨 심야 화약통(+16⚡)」으로 수호알 핀볼 연쇄 폭격을 터뜨리세요!',
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheCoreAssets();
    });

    _autoTimer = Timer(const Duration(milliseconds: 1250), _enterHome);
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
      NightArtRegistry.appLogo,
      NightArtRegistry.iconRogueScroll,
      NightArtRegistry.iconLuckyDice,
      'assets/images/chars/sabu_idle.webp',
      'assets/images/chars/banDal_idle.webp',
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
        transitionDuration: const Duration(milliseconds: 380),
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
            Image.asset(
              NightArtRegistry.bgNightSplash,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                NightArtRegistry.bgLobbyFallback,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: NightPalette.bgDeep),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD8070B14),
                    Color(0xB4111B30),
                    Color(0xEE070A12),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 22,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(height: 6),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const NightSpriteIcon(
                                    assetPath: NightArtRegistry.appLogo,
                                    fallbackAssetPath:
                                        NightArtRegistry.towerGuardian,
                                    fallbackIcon: Icons.shield_moon_rounded,
                                    size: 82,
                                    borderRadius: 18,
                                    showFrame: true,
                                    frameColor: NightPalette.accentGold,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: NightPalette.bgPanel
                                          .withValues(alpha: 0.88),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: NightPalette.borderGold,
                                      ),
                                    ),
                                    child: const Text(
                                      '탄지무림 외전 · 완전 자동 마을 수호전',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: NightPalette.jadeGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '수호알까기',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 44,
                                      letterSpacing: 1.5,
                                      color: NightPalette.accentGold,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xAA000000),
                                          blurRadius: 12,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Text(
                                    '탄지무림 · 심야기습',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'BlackHanSans',
                                      fontSize: 21,
                                      color: NightPalette.jadeShield,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 152,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Image.asset(
                                            'assets/images/chars/sabu_idle.webp',
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) =>
                                                const SizedBox.shrink(),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Flexible(
                                          child: Image.asset(
                                            'assets/images/chars/banDal_idle.webp',
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) =>
                                                const SizedBox.shrink(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              MurimCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '💡 수호 비급: $tip',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: NightPalette.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '화면을 가볍게 누르면 즉시 본영으로 입장합니다',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: NightPalette.accentGold,
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
      title: '1/4 · 구곡양장 아홉 굽이길 & 제한된 전술 사거리의 묘미',
      body: '돌연변이 대군은 좌우로 깊게 굽이치는 「구곡양장 대협곡길」을 따라 내려오며, 초소마다 자기 굽이만 덮는 제한된 사거리(108~162)를 가집니다!\n'
          '위·아래 두 줄기 길이 동시에 지나가는 굽이 목지점에 초소를 세우고, 기력을 모아 하단 [🔭사거리업]으로 사격망을 넓히세요!',
    ),
    (
      speaker: '의용대장 석두',
      portrait: 'seokdu',
      emblemAsset: NightArtRegistry.iconLuckyDice,
      title: '2/4 · 실시간 전군 강화 4종 & 원터치 승급·★5형 신기 합체',
      body: '• 하단 [⚔️화력업 · ⚡연사업 · 🔭사거리업 · 🛡️결계업]을 누르면 멈춤 없이 전투 도중 즉시 강화됩니다!\n'
          '• 이미 지은 초소를 톡 건드리면 창 열림 없이 0초 만에 즉시 합치기(0⚡)나 상위 형 승급(4형+4형→★5형 태초 신기!)이 이루어집니다.',
    ),
    (
      speaker: '명궁 연비',
      portrait: 'yeonbi',
      emblemAsset: NightArtRegistry.iconRogueScroll,
      title: '3/4 · ⏱6.5초 타임어택 비급 & 🌀×3 폭주진 · 🎰돌림판',
      body: '• 물결 돌파 시 상단에 뜨는 「📜 3택 1 비급」과 빈 초소 하단 띠는 실시간 제한시간 안에 재빨리 누르면 발동하고, 못 누르면 멈춤 없이 자동 통과합니다!\n'
          '• 「🌀×2 복제문」을 10번 통과시키면 8초간 「🔥×3 폭주!」로 각성하며, 이동 과녁(+60%)과 현상수배 「🎰운명의 돌림판」이 대박을 터뜨립니다.',
    ),
    (
      speaker: '기관장 정각',
      portrait: 'jeonggak',
      emblemAsset: NightArtRegistry.nightSupportSeal,
      title: '4/4 · 🕳️땅굴·🌲월담 기습 경계 & 수동 3갈래 연속 탄지!',
      body: '• 큰길뿐 아니라 숲 가장자리(🌲월담기습)와 잔디밭 한복판(🕳️땅굴기습)에서도 변이 특공대가 기습 침투합니다!\n'
          '• 「중앙탑: 수동탄지」에서 꾹 누른 채 조준하면 3갈래 파쇄 산탄이 연속 발사되며, 위기 순간 「무림수호단 출두야~~!!」로 일소하세요!',
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
                          assetPath: NightArtRegistry.charFace(cur.portrait),
                          fallbackIcon: Icons.school_rounded,
                          size: 54,
                          borderRadius: 27,
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
                          size: 36,
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
                                    : '수호 출정 준비 완료!',
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
