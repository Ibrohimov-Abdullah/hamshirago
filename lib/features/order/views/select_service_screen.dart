import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../controllers/order_controller.dart';

class SelectServiceScreen extends StatelessWidget {
  const SelectServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OrderController ctrl = Get.find<OrderController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('select_service'.tr, style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16.sp)),
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 17.sp),
          ),
        ),
      ),
      body: Stack(
        children: [
          Obx(() {
            if (ctrl.servicesLoading.value) return _buildShimmer();
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 130.h),
              itemCount: ctrl.selections.length,
              itemBuilder: (_, index) {
                final sel = ctrl.selections[index];
                return _ServiceTile(
                  sel: sel,
                  onToggle: (v) => ctrl.toggleService(index, v!),
                  onInc: () => ctrl.increment(index),
                  onDec: () => ctrl.decrement(index),
                );
              },
            );
          }),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Obx(() => _BottomBar(
              servicesTotal: ctrl.servicesPrice,
              total: ctrl.totalPrice,
              enabled: ctrl.servicesPrice > 0,
              onNext: _showWarningDialog,
            )),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog() {
    Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      child: Padding(
        padding: EdgeInsets.all(22.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.w, height: 56.w,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: Center(child: Text('!', style: TextStyle(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.w900, fontFamily: 'Nunito'))),
            ),
            SizedBox(height: 14.h),
            Text(
              'warning_before_order'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Nunito', height: 1.3),
            ),
            SizedBox(height: 14.h),
            ...[
              ('💊', 'item_prescription'), ('💉', 'item_medicine'),
              ('🧴', 'item_alcohol'), ('🪡', 'item_syringe'), ('🧻', 'item_cotton'),
            ].map((item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(children: [
                Text(item.$1, style: TextStyle(fontSize: 17.sp)),
                SizedBox(width: 10.w),
                Text(item.$2.tr, style: TextStyle(fontSize: 13.sp, color: AppColors.textMedium, fontFamily: 'Nunito')),
              ]),
            )),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () { Get.back(); Get.toNamed(AppRoutes.patientInfo); },
              child: Container(
                width: double.infinity, height: 48.h,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(13.r)),
                child: Center(child: Text('understood'.tr, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito'))),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildShimmer() => ListView.builder(
    padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
    itemCount: 7,
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h), height: 68.h,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13.r)),
      ),
    ),
  );
}

// ── Service Tile ─────────────────────────────────────────────────────────────
class _ServiceTile extends StatelessWidget {
  final ServiceSelection sel;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const _ServiceTile({required this.sel, required this.onToggle, required this.onInc, required this.onDec});

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Get.locale?.languageCode ?? 'uz';

    // Obx at tile level so the whole tile reacts to selection changes
    return Obx(() {
      final hasValue = sel.hasValue;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(13.w),
        decoration: BoxDecoration(
          color: hasValue ? AppColors.primaryLight : AppColors.white,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(color: hasValue ? AppColors.primary : AppColors.divider, width: hasValue ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 3.w, height: 38.h,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2.r)),
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sel.service.localName(lang), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Nunito')),
                  SizedBox(height: 2.h),
                  Text('${_fmt(sel.service.price)} so\'m', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Nunito')),
                ],
              ),
            ),

            if (sel.service.isCountable)
              // Countable: +/- counter — fully reactive because we're inside Obx
              Row(
                children: [
                  _CountBtn(
                    icon: Icons.remove_rounded,
                    active: sel.count.value > 0,
                    onTap: onDec,
                  ),
                  SizedBox(width: 6.w),
                  SizedBox(
                    width: 28.w,
                    child: Text(
                      '${sel.count.value}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Nunito'),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  _CountBtn(icon: Icons.add_rounded, active: true, onTap: onInc),
                ],
              )
            else
              // Checkbox toggle
              GestureDetector(
                onTap: () => onToggle(!sel.isSelected.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  width: 26.w, height: 26.w,
                  decoration: BoxDecoration(
                    color: sel.isSelected.value ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(7.r),
                    border: Border.all(color: sel.isSelected.value ? AppColors.primary : AppColors.textHint, width: 2),
                  ),
                  child: sel.isSelected.value
                      ? Icon(Icons.check_rounded, color: Colors.white, size: 14.sp)
                      : null,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _CountBtn({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w, height: 32.w,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: active ? Colors.white : AppColors.textHint, size: 16.sp),
      ),
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int servicesTotal;
  final int total;
  final bool enabled;
  final VoidCallback onNext;
  const _BottomBar({
    required this.servicesTotal,
    required this.total,
    required this.enabled,
    required this.onNext,
  });

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, -3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enabled) ...[
            // Services subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('services_lbl'.tr, style: TextStyle(fontSize: 12.sp, color: AppColors.textMedium, fontFamily: 'Nunito')),
                Text('${_fmt(servicesTotal)} so\'m', style: TextStyle(fontSize: 12.sp, color: AppColors.textMedium, fontFamily: 'Nunito')),
              ],
            ),
            SizedBox(height: 5.h),
            // Transport fee row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.directions_car_rounded, color: AppColors.textLight, size: 13.sp),
                  SizedBox(width: 4.w),
                  Text('transport_fee_lbl'.tr, style: TextStyle(fontSize: 12.sp, color: AppColors.textLight, fontFamily: 'Nunito')),
                ]),
                Text('15 000 so\'m', style: TextStyle(fontSize: 12.sp, color: AppColors.textLight, fontFamily: 'Nunito')),
              ],
            ),
            // Fee range note
            Padding(
              padding: EdgeInsets.only(top: 3.h, bottom: 6.h),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'transport_fee_note'.tr,
                  style: TextStyle(fontSize: 9.5.sp, color: AppColors.textHint, fontFamily: 'Nunito'),
                ),
              ),
            ),
            Divider(height: 1, color: AppColors.divider),
            SizedBox(height: 7.h),
            // Grand total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('total_lbl'.tr, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Nunito')),
                Text('${_fmt(total)} so\'m', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Nunito')),
              ],
            ),
            SizedBox(height: 10.h),
          ],
          GestureDetector(
            onTap: enabled ? onNext : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52.h,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: enabled ? AppColors.primaryGradient : null,
                color: enabled ? null : AppColors.divider,
                borderRadius: BorderRadius.circular(13.r),
                boxShadow: enabled ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))] : [],
              ),
              child: Center(
                child: Text('next_btn'.tr, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: enabled ? Colors.white : AppColors.textHint, fontFamily: 'Nunito')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
