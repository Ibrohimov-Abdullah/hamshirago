import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _lang = 'uz';

  void _continue() {
    GetStorage().write('language', _lang);
    Get.updateLocale(Locale(_lang));
    Get.offAllNamed(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 60.h),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 44.w, height: 44.w, decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(13.r)), child: Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 22.sp)),
                SizedBox(width: 10.w),
                Text('Mening Hamshiram', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Nunito')),
              ]),
              SizedBox(height: 48.h),
              Text('Tilni tanlang / Выберите язык', style: TextStyle(fontSize: 15.sp, color: AppColors.textLight, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
              SizedBox(height: 24.h),
              _tile('uz', "O'zbek", "O'zbekcha", '🇺🇿'),
              SizedBox(height: 12.h),
              _tile('ru', 'Русский', 'Русский язык', '🇷🇺'),
              const Spacer(),
              GestureDetector(
                onTap: _continue,
                child: Container(height: 54.h, width: double.infinity,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0,6))]),
                  child: Center(child: Text('Davom etish / Продолжить', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito')))),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(String code, String name, String native, String flag) {
    final sel = _lang == code;
    return GestureDetector(
      onTap: () => setState(() => _lang = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: sel ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: sel ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Row(children: [
          Text(flag, style: TextStyle(fontSize: 30.sp)),
          SizedBox(width: 14.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: sel ? AppColors.primary : AppColors.textDark, fontFamily: 'Nunito')),
            Text(native, style: TextStyle(fontSize: 11.sp, color: AppColors.textLight, fontFamily: 'Nunito')),
          ])),
          if (sel) Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20.sp),
        ]),
      ),
    );
  }
}
