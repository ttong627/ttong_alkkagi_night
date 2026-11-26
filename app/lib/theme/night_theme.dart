import 'package:flutter/material.dart' hide Text;
import '../i18n/tr_text.dart';

/// 심야 무협 수묵·청람 석판·한지·황금·적염 정통 디자인 시스템
/// - 클로드 디자인 하네스(`design.py` · 게슈탈트 · AI티 0건) 및 프로그램 제작 하네스(52px 대형 조작계) 동시 준수.
class NightPalette {
  static const Color bgDeep = Color(0xFF1E2B43);
  static const Color bgPanel = Color(0xFF273754);
  static const Color bgCard = Color(0xFF324668);
  static const Color hanjiLight = Color(0xFFF4E7CA);
  static const Color hanjiInk = Color(0xFF1A263C);
  static const Color hanjiSubInk = Color(0xFF354869);
  static const Color borderGold = Color(0xFFD9B65C);
  static const Color accentGold = Color(0xFFF4CC6A);
  static const Color jadeShield = Color(0xFF6EC8E8);
  static const Color jadeGreen = Color(0xFF7CE2D4);
  static const Color crimsonMoon = Color(0xFFE05248);
  // 보라색 네온 AI티를 원천 차단하기 위해 영약 강조색을 맑은 청옥·호박 빛으로 통일
  static const Color elixirPurple = Color(0xFF7AD7F0);
  static const Color textPrimary = Color(0xFFF6F8FC);
  static const Color textMuted = Color(0xFFC8D4E6);

  static ThemeData buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      fontFamily: 'DoHyeon',
      fontFamilyFallback: const ['NotoKRFallback'],
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: jadeGreen,
        surface: bgPanel,
        error: crimsonMoon,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xF522304A),
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'BlackHanSans',
          fontFamilyFallback: ['DoHyeon', 'NotoKRFallback'],
          fontSize: 20,
          color: accentGold,
          letterSpacing: 0.4,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DoHyeon',
            fontFamilyFallback: ['NotoKRFallback'],
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: borderGold.withValues(alpha: 0.55)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        backgroundColor: const Color(0xFA1A263C),
        indicatorColor: accentGold.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'DoHyeon',
            fontFamilyFallback: const ['NotoKRFallback'],
            fontSize: 12.0,
            fontWeight: sel ? FontWeight.bold : FontWeight.w500,
            color: sel ? accentGold : textMuted,
          );
        }),
      ),
    );
  }
}

/// 수묵 청람 석판 카드 위젯 (형광 테두리 없이 면 단계와 머리카락 선으로 게슈탈트 묶음 형성).
class MurimCard extends StatelessWidget {
  const MurimCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? NightPalette.bgCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (borderColor ?? NightPalette.borderGold).withValues(alpha: 0.28),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// 전 화면 공통 『영웅 대 돌연변이 실전 격돌 쇼케이스 배너』
/// - 상단에 영웅과 돌연변이가 맞붙는 고해상도 실전 일러스트 + 좌우 전신 캐릭터·보스 대립 연출
/// - 하단에 조선 한지 명패(단일 시선 주인공 1.4 이상 확보)와 원터치 주 행동 단추를 결합.
class HeroVsMutantShowcaseBanner extends StatelessWidget {
  const HeroVsMutantShowcaseBanner({
    super.key,
    required this.sceneAsset,
    required this.badgeText,
    required this.title,
    required this.subtitle,
    this.leftHeroAsset,
    this.leftHeroLabel,
    this.rightMutantAsset,
    this.rightMutantLabel,
    this.actionRow,
    this.artHeight = 164,
  });

  final String sceneAsset;
  final String badgeText;
  final String title;
  final String subtitle;
  final String? leftHeroAsset;
  final String? leftHeroLabel;
  final String? rightMutantAsset;
  final String? rightMutantLabel;
  final Widget? actionRow;
  final double artHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NightPalette.hanjiLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NightPalette.accentGold, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단: 생생한 영웅 대 돌연변이 실전 전투 원화 무대 (암막 최소화!)
            SizedBox(
              height: artHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    sceneAsset,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.15),
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: NightPalette.bgPanel),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.58, 1.0],
                        colors: [
                          Color(0x36141F33),
                          Color(0x18141F33),
                          Color(0xCC18253C),
                        ],
                      ),
                    ),
                  ),
                  if (leftHeroAsset != null)
                    Align(
                      alignment: const Alignment(-0.86, 0.92),
                      child: _StandeeBadgeFigure(
                        assetPath: leftHeroAsset!,
                        label: leftHeroLabel,
                        height: artHeight * 0.80,
                        isHero: true,
                      ),
                    ),
                  if (rightMutantAsset != null)
                    Align(
                      alignment: const Alignment(0.86, 0.92),
                      child: _StandeeBadgeFigure(
                        assetPath: rightMutantAsset!,
                        label: rightMutantLabel,
                        height: artHeight * 0.80,
                        isHero: false,
                      ),
                    ),
                  Positioned(
                    left: 12,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE618253C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: NightPalette.accentGold.withValues(alpha: 0.75),
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: NightPalette.accentGold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 하단: 고대비 한지 주인공 명패 + 원터치 주 행동 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'BlackHanSans',
                      fontSize: 22.0,
                      color: NightPalette.hanjiInk,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: NightPalette.hanjiSubInk,
                      fontWeight: FontWeight.w600,
                      height: 1.32,
                    ),
                  ),
                  if (actionRow != null) ...[
                    const SizedBox(height: 12),
                    actionRow!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandeeBadgeFigure extends StatelessWidget {
  const _StandeeBadgeFigure({
    required this.assetPath,
    required this.height,
    required this.isHero,
    this.label,
  });

  final String assetPath;
  final double height;
  final bool isHero;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Image.asset(
            assetPath,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        if (label != null && label!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xE8162238),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isHero ? NightPalette.accentGold : NightPalette.crimsonMoon,
              ),
            ),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isHero ? NightPalette.accentGold : const Color(0xFFFFB4A2),
              ),
            ),
          ),
      ],
    );
  }
}

/// 상단 재화 요약 알약 배지 (단일 청람 면 + 미세 테두리로 시선 분산 억제).
class ResourcePill extends StatelessWidget {
  const ResourcePill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.iconAsset,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NightPalette.bgCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null && iconAsset!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                iconAsset!,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(icon, size: 15, color: color),
              ),
            )
          else
            Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label $value',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: NightPalette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
