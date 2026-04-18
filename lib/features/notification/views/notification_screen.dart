import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('notifications'.tr, style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16.sp)),
        leading: GestureDetector(onTap: () => Get.back(),
          child: Container(margin: EdgeInsets.all(10.w), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 17.sp))),
      ),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.notifications_outlined, color: AppColors.textHint, size: 54.sp),
        SizedBox(height: 14.h),
        Text('no_notifications'.tr, style: TextStyle(fontSize: 15.sp, color: AppColors.textLight, fontFamily: 'Nunito')),
        SizedBox(height: 6.h),
        Text('notifications_desc'.tr, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textHint, fontFamily: 'Nunito')),
      ])),
    );
  }
}
