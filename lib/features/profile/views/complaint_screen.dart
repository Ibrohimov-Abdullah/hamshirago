import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/models/models.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});
  @override State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _ctrl.text.trim();
    if (msg.isEmpty) {
      Get.snackbar(
        'complaint_error_title'.tr, 'complaint_error_body'.tr,
        backgroundColor: const Color(0xFFEF4444).withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final box = GetStorage();
      final uid   = box.read('user_uid')   as String? ?? '';
      final name  = box.read('user_name')  as String? ?? '';
      final phone = box.read('user_phone') as String? ?? '';
      final complaint = ComplaintModel(
        id: '', userId: uid, userPhone: phone, userName: name,
        message: msg, createdAt: DateTime.now(),
      );
      await FirebaseService.instance.submitComplaint(complaint);
      setState(() { _sent = true; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      Get.snackbar(
        'Xato', e.toString(),
        backgroundColor: const Color(0xFFEF4444).withOpacity(0.9),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'complaint'.tr,
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16.sp),
        ),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 17.sp),
          ),
        ),
      ),
      body: _sent ? _successView() : _formView(),
    );
  }

  Widget _successView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 80.w, height: 80.w,
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 44.sp),
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          'complaint_sent'.tr,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Nunito'),
        ),
        SizedBox(height: 8.h),
        Text(
          'complaint_thanks'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.sp, color: AppColors.textLight, fontFamily: 'Nunito', height: 1.5),
        ),
        SizedBox(height: 28.h),
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 13.h),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12.r)),
            child: Text(
              'go_home'.tr,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito'),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _formView() => SingleChildScrollView(
    padding: EdgeInsets.all(20.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        // Header card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 44.w, height: 44.w,
                decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(Icons.feedback_outlined, color: AppColors.primary, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'complaint_desc'.tr,
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textMedium, fontFamily: 'Nunito', height: 1.4),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Input
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: TextField(
            controller: _ctrl,
            maxLines: 7,
            style: TextStyle(fontSize: 14.sp, fontFamily: 'Nunito', color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'complaint_hint'.tr,
              hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.textHint, fontFamily: 'Nunito'),
              contentPadding: EdgeInsets.all(16.w),
              border: InputBorder.none,
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // Send button
        GestureDetector(
          onTap: _loading ? null : _send,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52.h,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _loading ? null : AppColors.primaryGradient,
              color: _loading ? AppColors.divider : null,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: _loading ? [] : [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))],
            ),
            child: Center(
              child: _loading
                  ? SizedBox(width: 22.w, height: 22.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      'send'.tr,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito'),
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}
