import 'package:flutter/material.dart';

class AppColors {
  static const cream = Color(0xFFFFFDF8);
  static const paper = Color(0xFFFFFFFF);
  static const sand = Color(0xFFFFF4EA);
  static const ink = Color(0xFF101A3A);
  static const navy = Color(0xFF101A3A);
  static const navy2 = Color(0xFF1B2A58);
  static const navyDeep = Color(0xFF070C20);
  static const orange = Color(0xFFEF5B25);
  static const ember = Color(0xFFF26832);
  static const amber = Color(0xFFFFB37A);
  static const gold = Color(0xFFC6922F);
  static const goldLight = Color(0xFFF7E3BB);
  static const muted = Color(0xFF5F6880);
  static const green = Color(0xFF2F7A45);
  static const line = Color(0x1F101A3A);
  static const glassLine = Color(0x33FFFFFF);
}

class AppGradients {
  static const dock = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.navy, AppColors.navy2, Color(0xFF233568)],
  );
  static const orange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.ember, Color(0xFFE9501C)],
  );
  static const navy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.navy, AppColors.navy2],
  );
  static const cream = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.cream, Color(0xFFFFFAF3)],
  );
}

BoxDecoration cardDecoration({
  Color color = AppColors.paper,
  double radius = 18,
  Color border = AppColors.line,
  List<BoxShadow>? shadow,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border, width: 1),
    boxShadow: shadow ??
        const [
          BoxShadow(
            color: Color(0x19101A3A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
  );
}

BoxDecoration premiumCard({
  Color color = AppColors.paper,
  double radius = 20,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.line),
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A101A3A),
        blurRadius: 30,
        offset: Offset(0, 14),
      ),
    ],
  );
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.navy,
      secondary: AppColors.orange,
      surface: AppColors.cream,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    canvasColor: AppColors.cream,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFAFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.4),
      ),
      labelStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
    ),
  );
}

TextStyle displayStyle({double size = 24, Color color = AppColors.ink, FontWeight weight = FontWeight.w800}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: -size * 0.035,
    height: 1.06,
    color: color,
  );
}

TextStyle sectionStyle({double size = 22}) {
  return TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: -size * 0.04,
    height: 1.08,
    color: AppColors.ink,
  );
}

TextStyle eyebrowStyle({Color color = AppColors.orange}) {
  return TextStyle(
    fontSize: 8.5,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    color: color,
  );
}
