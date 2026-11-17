import 'package:flutter/material.dart';

/// 심야 무협 수묵·청람 석판·황금·비취 정통 디자인 시스템 (디자인 하네스 명도·색수·덩어리 규격 준수).
class NightPalette {
  static const Color bgDeep = Color(0xFF25324B);
  static const Color bgPanel = Color(0xFF2F3F5C);
  static const Color bgCard = Color(0xFF394B6D);
  static const Color borderGold = Color(0xFFD9B65C);
  static const Color accentGold = Color(0xFFF4CC6A);
  static const Color jadeShield = Color(0xFF6EC8E8);
  static const Color jadeGreen = Color(0xFF7CE2D4);
  static const Color crimsonMoon = Color(0xFFE0525E);
  static const Color elixirPurple = Color(0xFFB38AE6);
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
        backgroundColor: Color(0xF227354F),
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
    );
  }
}

/// 수묵 청람 석판 카드 위젯 (과한 형광 테두리 대신 은은한 머리카락 선과 면 단계로 묶음 형성).
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
        color: backgroundColor ?? NightPalette.bgCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (borderColor ?? NightPalette.borderGold).withValues(alpha: 0.24),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
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
        color: NightPalette.bgCard.withValues(alpha: 0.90),
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
