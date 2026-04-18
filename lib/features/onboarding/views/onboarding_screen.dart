import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _items = const [
    _OItem(titleKey: 'onboard1_title', descKey: 'onboard1_desc', icon: Icons.home_outlined, color: AppColors.primary, bg: AppColors.primaryLight),
    _OItem(titleKey: 'onboard2_title', descKey: 'onboard2_desc', icon: Icons.medical_services_outlined, color: const Color(0xFF6C63FF), bg: const Color(0xFFF0EEFF)),
    _OItem(titleKey: 'onboard3_title', descKey: 'onboard3_desc', icon: Icons.local_hospital_rounded, color: const Color(0xFFFF6584), bg: const Color(0xFFFFEEF2)),
  ];

  void _finish() {
    GetStorage().write('has_seen_onboarding', true);
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _items.length - 1;
    return Scaffold(
      body: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: _items.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final item = _items[i];
            return Container(color: item.bg, child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 130.w, height: 130.w, decoration: BoxDecoration(color: item.color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(item.icon, size: 64.sp, color: item.color)),
              ]),
            ));
          },
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(
          padding: EdgeInsets.fromLTRB(26.w, 22.h, 26.w, 46.h),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0,-4))]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_items[_page].titleKey.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 21.sp, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Nunito')),
            SizedBox(height: 8.h),
            Text(_items[_page].descKey.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, color: AppColors.textLight, fontFamily: 'Nunito', height: 1.55)),
            SizedBox(height: 26.h),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              if (!isLast) GestureDetector(onTap: _finish, child: Text('skip'.tr, style: TextStyle(fontSize: 14.sp, color: AppColors.textLight, fontFamily: 'Nunito', fontWeight: FontWeight.w600)))
              else const SizedBox(),
              SmoothPageIndicator(controller: _ctrl, count: _items.length, effect: WormEffect(dotHeight: 8.h, dotWidth: 8.w, activeDotColor: _items[_page].color, dotColor: AppColors.divider)),
              GestureDetector(
                onTap: isLast ? _finish : () => _ctrl.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isLast ? 130.w : 52.w, height: 52.h,
                  decoration: BoxDecoration(color: _items[_page].color, borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: _items[_page].color.withOpacity(0.32), blurRadius: 14, offset: const Offset(0,5))]),
                  child: Center(child: isLast ? Text('get_started'.tr, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito')) : Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20.sp)),
                ),
              ),
            ]),
          ]),
        )),
      ]),
    );
  }
}

class _OItem { final String titleKey, descKey; final IconData icon; final Color color, bg;
  const _OItem({required this.titleKey, required this.descKey, required this.icon, required this.color, required this.bg}); }
