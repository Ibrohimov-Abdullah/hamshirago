import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  static const Color primary      = Color(0xFF1EC8C8);
  static const Color primaryLight = Color(0xFFE8FAFA);
  static const Color primaryDark  = Color(0xFF0FA8A8);
  static const Color accent       = Color(0xFFFF6B6B);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color background   = Color(0xFFF7F9FC);
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color divider      = Color(0xFFEDF2F7);
  static const Color textDark     = Color(0xFF1A202C);
  static const Color textMedium   = Color(0xFF4A5568);
  static const Color textLight    = Color(0xFFA0AEC0);
  static const Color textHint     = Color(0xFFCBD5E0);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1EC8C8), Color(0xFF0FA8A8)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1EC8C8), Color(0xFF15A8B8)],
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
