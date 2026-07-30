import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../controllers/auth_controller.dart';

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'phone_number'.tr,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textMedium,
          fontFamily: 'Nunito',
        ),
      ),
      SizedBox(height: 7.h),
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s\-]')),
        ],
        style: TextStyle(
          fontSize: 15.sp,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: '+998 90 123 45 67',
          prefixIcon: Container(
            margin: EdgeInsets.all(8.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 18.sp),
          ),
        ),
      ),
    ],
  );
}

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textMedium,
          fontFamily: 'Nunito',
        ),
      ),
      SizedBox(height: 7.h),
      TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: 14.sp,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20.sp),
        ),
      ),
    ],
  );
}

class _PrimaryBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;

  const _PrimaryBtn({
    required this.text,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isLoading ? null : AppColors.primaryGradient,
        color: isLoading ? AppColors.divider : null,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: isLoading
            ? []
            : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
          width: 24.w,
          height: 24.w,
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        )
            : Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Nunito',
            letterSpacing: 0.5,
          ),
        ),
      ),
    ),
  );
}

Widget _header({required String title, required String subtitle}) => Container(
  width: double.infinity,
  padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 30.h),
  decoration: BoxDecoration(
    gradient: AppColors.headerGradient,
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            'HamshiraGo',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
      SizedBox(height: 18.h),
      Text(
        title,
        style: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontFamily: 'Nunito',
          height: 1.2,
        ),
      ),
      SizedBox(height: 6.h),
      Text(
        subtitle,
        style: TextStyle(
          fontSize: 13.sp,
          color: Colors.white.withOpacity(0.75),
          fontFamily: 'Nunito',
        ),
      ),
    ],
  ),
);

// ─── Login ────────────────────────────────────────────────────────────────────
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AuthController());
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(
              title: 'welcome'.tr,
              subtitle: 'login_subtitle'.tr,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 0),
              child: Column(
                children: [
                  _PhoneField(controller: ctrl.phoneCtrl),
                  SizedBox(height: 26.h),
                  Obx(
                        () => _PrimaryBtn(
                      text: 'get_sms'.tr,
                      isLoading: ctrl.isLoading.value,
                      onTap: () => ctrl.sendOtp(isRegister: false),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.register),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13.sp,
                          ),
                          children: [
                            TextSpan(
                              text: '${'no_account'.tr} ',
                              style: TextStyle(color: AppColors.textLight),
                            ),
                            TextSpan(
                              text: 'go_register'.tr,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Register ─────────────────────────────────────────────────────────────────
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 17.sp,
            ),
          ),
        ),
        title: Text(
          'register'.tr,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 26.h),
        child: Column(
          children: [
            _LabeledField(
              controller: ctrl.firstCtrl,
              label: 'first_name'.tr,
              hint: 'first_name_hint'.tr,
              icon: Icons.assignment_ind_rounded,
            ),
            SizedBox(height: 14.h),
            _LabeledField(
              controller: ctrl.lastCtrl,
              label: 'last_name'.tr,
              hint: 'last_name_hint'.tr,
              icon: Icons.assignment_ind_rounded,
            ),
            SizedBox(height: 14.h),
            _PhoneField(controller: ctrl.phoneCtrl),
            SizedBox(height: 28.h),
            Obx(
                  () => _PrimaryBtn(
                text: 'get_sms'.tr,
                isLoading: ctrl.isLoading.value,
                onTap: () => ctrl.sendOtp(isRegister: true),
              ),
            ),
            SizedBox(height: 16.h),
            Center(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 13.sp),
                    children: [
                      TextSpan(
                        text: '${'have_account'.tr} ',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                      TextSpan(
                        text: 'login'.tr,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OTP ──────────────────────────────────────────────────────────────────────
class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();
    final pin = PinTheme(
      width: 58.w,
      height: 58.h,
      textStyle: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        fontFamily: 'Nunito',
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.textDark,
              size: 17.sp,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            Container(
              width: 76.w,
              height: 76.w,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 22,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Icon(Icons.verified_rounded, color: Colors.white, size: 34.sp),
            ),
            SizedBox(height: 22.h),
            Text('otp_title'.tr, style: AppTextStyles.h2),
            SizedBox(height: 8.h),
            Obx(
                  () => Text(
                "${'code_sent'.tr}: ${ctrl.phoneNumber.value}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textLight,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
            SizedBox(height: 36.h),
            Pinput(
              controller: ctrl.otpCtrl,
              length: 6,
              defaultPinTheme: pin,
              focusedPinTheme: pin.copyWith(
                decoration: pin.decoration!.copyWith(
                  border: Border.all(color: AppColors.primary, width: 2),
                  color: AppColors.primaryLight,
                ),
              ),
              submittedPinTheme: pin.copyWith(
                decoration: pin.decoration!.copyWith(
                  border: Border.all(color: AppColors.primary, width: 2),
                  color: AppColors.primaryLight,
                ),
              ),
              onCompleted: (_) => ctrl.verifyOtp(),
            ),
            SizedBox(height: 24.h),
            Obx(
                  () => ctrl.resendSeconds.value > 0
                  ? Text(
                '${'resend'.tr}: ${ctrl.resendSeconds.value} s',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textLight,
                  fontFamily: 'Nunito',
                ),
              )
                  : GestureDetector(
                onTap: () =>
                    ctrl.sendOtp(isRegister: ctrl.isRegistering.value),
                child: Text(
                  'resend'.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
            const Spacer(),
            Obx(
                  () => _PrimaryBtn(
                text: 'verify'.tr,
                isLoading: ctrl.isLoading.value,
                onTap: ctrl.verifyOtp,
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}