import 'package:flutter/material.dart';

/// 심야 무협 수묵·적월·황금·청록 글래스모피즘 디자인 시스템.
class NightPalette {
  static const Color bgDeep = Color(0xFF0B0F19);
  static const Color bgPanel = Color(0xFF141B2D);
  static const Color bgCard = Color(0xFF1C253B);
  static const Color borderGold = Color(0xFFD4AF37);
  static const Color accentGold = Color(0xFFFFD166);
  static const Color jadeShield = Color(0xFF4CC9F0);
  static const Color jadeGreen = Color(0xFF72EFDD);
  static const Color crimsonMoon = Color(0xFFE63946);
  static const Color elixirPurple = Color(0xFFC77DFF);
  static const Color textPrimary = Color(0xFFF8F9FA);
  static const Color textMuted = Color(0xFFB8C4D9);

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
        backgroundColor: Color(0xEE0F1524),
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'BlackHanSans',
          fontFamilyFallback: ['DoHyeon', 'NotoKRFallback'],
          fontSize: 20,
          color: accentGold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// 수묵 금테 카드 위젯.
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
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? NightPalette.bgCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? NightPalette.borderGold.withValues(alpha: 0.42),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 상단 재화 요약 알약 배지.
class ResourcePill extends StatelessWidget {
  const ResourcePill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NightPalette.bgPanel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            '$label $value',
            style: TextStyle(
              fontSize: 13,
              color: NightPalette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
