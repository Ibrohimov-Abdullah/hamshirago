import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../controllers/order_controller.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  // Helper method to format number with spaces (e.g., 1 234 567)
  String _formatPrice(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final OrderController ctrl = Get.find<OrderController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'payment'.tr,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 17.sp,
          ),
        ),
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
              size: 18.sp,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 130.h),
            child: Column(
              children: [
                // Order Details Card
                _buildSectionCard(
                  title: 'order_details'.tr,
                  icon: Icons.receipt_long_rounded,
                  child: Column(
                    children: [
                      ...ctrl.selected.map((item) {
                        final lang = Get.locale?.languageCode ?? 'uz';
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            children: [
                              Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 9.w),
                              Expanded(
                                child: Text(
                                  '${item.service.localName(lang)}${item.service.isCountable ? " × ${item.count.value}" : ""}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.textMedium,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                              Text(
                                '${_formatPrice(item.subtotal)} so\'m',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(color: AppColors.divider),
                      Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ctrl.isPromoEligible) ...[
                              // Promo badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                                ),
                                child: Text(
                                  '🎉 30% chegirma qo\'llanildi!',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFDC2626),
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'total'.tr,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (ctrl.isPromoEligible)
                                      Text(
                                        '${_formatPrice(ctrl.totalPrice)} so\'m',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textHint,
                                          fontFamily: 'Nunito',
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    Text(
                                      '${_formatPrice(ctrl.discountedPrice)} so\'m',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w900,
                                        color: ctrl.isPromoEligible
                                            ? const Color(0xFFDC2626)
                                            : AppColors.primary,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                // Payment Method Card
                _buildSectionCard(
                  title: 'payment_method_title'.tr,
                  icon: Icons.payments_outlined,
                  child: Column(
                    children: [

                      _buildPaymentTile(PaymentMethod.cash, 'cash'.tr, '💵',
                          const Color(0xFFF59E0B), ctrl,
                          isLast: true),
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                // Warning Banner
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: const Color(0xFFEDC200).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'payment_soon'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMedium,
                            fontFamily: 'Nunito',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Fixed Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(
                  () => Container(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 34.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 14,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: ctrl.placing.value ? null : ctrl.placeOrder,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: ctrl.placing.value
                          ? null
                          : AppColors.primaryGradient,
                      color: ctrl.placing.value ? AppColors.divider : null,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: ctrl.placing.value
                          ? []
                          : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ctrl.placing.value
                          ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'confirm_order'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          SizedBox(width: 6.w),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Section Card
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 10.h),
            child: Row(
              children: [
                Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 14.sp),
                ),
                SizedBox(width: 9.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: child,
          ),
        ],
      ),
    );
  }

  // Reusable Payment Method Tile
  Widget _buildPaymentTile(
      PaymentMethod method,
      String label,
      String emoji,
      Color color,
      OrderController ctrl, {
        bool isLast = false,
      }) {
    return Obx(
          () => Column(
        children: [
          GestureDetector(
            onTap: () => ctrl.paymentMethod.value = method,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 4.w),
              decoration: BoxDecoration(
                color: ctrl.paymentMethod.value == method
                    ? color.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    child: Center(
                      child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: ctrl.paymentMethod.value == method
                            ? color
                            : AppColors.textDark,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22.w,
                    height: 22.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ctrl.paymentMethod.value == method
                          ? color
                          : Colors.transparent,
                      border: Border.all(
                        color: ctrl.paymentMethod.value == method
                            ? color
                            : AppColors.textHint,
                        width: 2,
                      ),
                    ),
                    child: ctrl.paymentMethod.value == method
                        ? Icon(
                      size: 12.sp,
                      Icons.check_rounded,
                      color: Colors.white,
                    )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (!isLast)
            Divider(height: 8.h, color: AppColors.divider, thickness: 1),
        ],
      ),
    );
  }
}