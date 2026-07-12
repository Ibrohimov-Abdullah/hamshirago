import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color primary      = Color(0xFF4356D6);
  static const Color primaryLight = Color(0xFFEDEFFB);
  static const Color primaryDark  = Color(0xFF31429F);
  static const Color accent       = Color(0xFFFF7A59);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color background   = Color(0xFFF5F6FB);
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color divider      = Color(0xFFEAECF5);
  static const Color textDark     = Color(0xFF1B1E2E);
  static const Color textMedium   = Color(0xFF4A4F66);
  static const Color textLight    = Color(0xFF9CA1B8);
  static const Color textHint     = Color(0xFFC7CADB);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4356D6), Color(0xFF31429F)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF4356D6), Color(0xFF5A4BD4)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Nunito',
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
      titleTextStyle: TextStyle(fontFamily: 'Nunito', fontSize: 17.sp, fontWeight: FontWeight.w700, color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AppColors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: AppColors.divider, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: AppColors.divider, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14.sp, fontFamily: 'Nunito'),
    ),
  );
}

class AppTextStyles {
  static TextStyle get h1 => TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Nunito');
  static TextStyle get h2 => TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Nunito');
  static TextStyle get body => TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textLight, fontFamily: 'Nunito', height: 1.5);
}
