import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppColors {
  // 🌿 Healing & Medical Friendly Theme
  static const Color primary      = Color(0xFF0E9C7E);      // Healing Teal Green
  static const Color primaryLight = Color(0xFFE6F4F1);      // Soft Mint
  static const Color primaryDark  = Color(0xFF0A7A62);      // Deep Forest
  static const Color accent       = Color(0xFFF27A6B);      // Warm Coral (trust + care)
  static const Color secondary    = Color(0xFF4ECDC4);      // Fresh Aqua
  static const Color success      = Color(0xFF2ECC71);      // Health Green
  static const Color warning      = Color(0xFFF39C12);      // Warm Amber
  static const Color white        = Color(0xFFFFFFFF);
  static const Color background   = Color(0xFFF7FBF9);      // Very soft mint-white
  static const Color cardBg       = Color(0xFFFFFFFF);
  static const Color divider      = Color(0xFFE8F0ED);
  static const Color textDark     = Color(0xFF1A2E2A);      // Deep forest
  static const Color textMedium   = Color(0xFF4A6B63);      // Muted green-gray
  static const Color textLight    = Color(0xFF8AA89E);      // Soft sage
  static const Color textHint     = Color(0xFFB8CEC6);      // Light sage

  // 🌟 New Medical Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0E9C7E), Color(0xFF0A7A62)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0E9C7E), Color(0xFF4ECDC4)],  // Teal to Aqua
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF27A6B), Color(0xFFE8655A)],  // Coral warmth
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🌿 Calming gradient for cards/backgrounds
  static const LinearGradient calmGradient = LinearGradient(
    colors: [Color(0xFFE6F4F1), Color(0xFFF7FBF9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Nunito',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      background: AppColors.background,
      surface: AppColors.cardBg,
      error: const Color(0xFFE74C3C),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: AppColors.divider, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: AppColors.divider, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: TextStyle(
        color: AppColors.textHint,
        fontSize: 14.sp,
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: AppColors.textMedium,
        fontSize: 14.sp,
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        textStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
  );
}

class AppTextStyles {
  // 🌟 Headings with healing vibe
  static TextStyle get h1 => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    fontFamily: 'Nunito',
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get h2 => TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    fontFamily: 'Nunito',
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle get h3 => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    fontFamily: 'Nunito',
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get body => TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
    fontFamily: 'Nunito',
    height: 1.6,
    letterSpacing: 0.2,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
    fontFamily: 'Nunito',
    height: 1.5,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
    fontFamily: 'Nunito',
    letterSpacing: 0.3,
  );

  static TextStyle get accentText => TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
    fontFamily: 'Nunito',
    letterSpacing: 0.3,
  );

  static TextStyle get buttonText => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    fontFamily: 'Nunito',
    letterSpacing: 0.5,
  );

  static TextStyle get medicalLabel => TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    fontFamily: 'Nunito',
    letterSpacing: 0.5,
  );

  static TextStyle get successText => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.success,
    fontFamily: 'Nunito',
  );
}