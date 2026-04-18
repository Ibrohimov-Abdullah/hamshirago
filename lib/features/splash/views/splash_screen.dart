import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      final box = GetStorage();
      final uid = box.read('user_uid') as String?;
      if (uid != null && uid.isNotEmpty) { Get.offAllNamed(AppRoutes.main); return; }
      if (box.read('has_seen_onboarding') == true) { Get.offAllNamed(AppRoutes.login); return; }
      Get.offAllNamed(AppRoutes.language);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: Transform.scale(scale: _scale.value, child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 90.w, height: 90.w, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24.r), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 32, spreadRadius: 4)]),
                  child: Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 46.sp)),
                SizedBox(height: 20.h),
                Text('Mening Hamshiram', style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Nunito')),
                SizedBox(height: 6.h),
                Text('Tibbiy xizmatlar platformasi', style: TextStyle(fontSize: 13.sp, color: Colors.white.withOpacity(0.75), fontFamily: 'Nunito')),
              ])),
            ),
          ),
        ),
      ),
    );
  }
}
