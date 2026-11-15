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
    '중앙 기명 수호탑과 길목 발사대 5곳은 손대지 않아도 100% 자동으로 알을 쏩니다.',
    '돌연변이가 떨어뜨리는 「증표」는 발사대 강화에, 「영약」은 영수·동료·내공 승급에 쓰입니다.',
    '기명 심법 수련은 알까기 없이 단전 호흡과 혈자리 점등만으로 100% 성공합니다.',
    '위기 순간 「무림수호단 출두야~~!!」 지원패를 누르면 화면 전체 변이체를 일소합니다!',
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
      NightArtRegistry.appLogo,
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
      title: '1/4 · 손 피로도 0% 완전 자동 발사 진법',
      body: '이곳에서는 손가락 아프게 직접 알을 튕기지 않아도 됩니다!\n'
          '마을 한가운데 「중앙 기명 수호탑」과 길목 5곳의 「자동 알 발사대」, '
          '그리고 「영수·동료」가 정해둔 조건에 맞춰 스스로 알을 쏘아 변이체를 물리칩니다.',
    ),
    (
      speaker: '의용대장 석두',
      portrait: 'seokdu',
      emblemAsset: NightArtRegistry.villageGranary,
      title: '2/4 · 식량 창고 · 논밭 · 가축을 지켜라',
      body: '심야 돌연변이들에게 외곽 기공 방어막과 중앙 수호탑이 모두 파괴되면 '
          '식량이 바닥나고 농작물과 가축이 병들어 마을을 떠나야 합니다.\n'
          '중갑 멧돼지엔 「중포 탄지기」, 뼈방패 야차엔 「곡사 회전기」로 상성을 맞춰보세요!',
    ),
    (
      speaker: '명궁 연비',
      portrait: 'yeonbi',
      emblemAsset: NightArtRegistry.nightToken,
      title: '3/4 · 증표와 영약의 깔끔한 역할 분담',
      body: '• 변이 처치 「증표」 → 중앙 수호탑 & 길목 발사대 강화 및 수호석 해금 전용!\n'
          '• 「영약」 → 영수·동료 강화 및 내공 8경지 돌파 전용!\n'
          '• 「기명 심법 수련」 → 알까기 없이 단전 호흡과 혈자리 터치만으로 실패 없이 100% 강해집니다.',
    ),
    (
      speaker: '기관장 정각',
      portrait: 'jeonggak',
      emblemAsset: NightArtRegistry.nightSupportSeal,
      title: '4/4 · 무림수호단 출두 & 전술 비약',
      body: '물자 호송·심야 탐색·보름달 기연으로 모은 「지원패」를 전장에서 누르면 '
          '「무림수호단 출두야~~!!」 풍악과 함께 화면의 변이체를 싹 쓸어버립니다!\n'
          '출석과 수호 임무 재료로 빚는 「전술 비약 3종」도 위기 탈출의 일등공신입니다.',
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
