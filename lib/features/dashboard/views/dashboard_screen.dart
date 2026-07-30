import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../../../core/models/models.dart';
import '../../../core/services/firebase_service.dart';
import '../../order/controllers/order_controller.dart';
import '../../auth/controllers/auth_controller.dart';

// ══════════════════════════════════════
// DASHBOARD SCREEN
// ══════════════════════════════════════

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _idx = 0;
  static const _tabs = [DashboardTab(), OrdersTab(), ProfileTab()];
  bool _locationRequesting = false;

  @override
  void initState() {
    super.initState();
    Get.put(OrderController());
    _requestLocationPermission();
    FirebaseService.instance.onForegroundMessage((msg) {
      final t = msg.notification?.title ?? '';
      final b = msg.notification?.body ?? '';
      if (t.isNotEmpty) {
        Get.snackbar(
          t,
          b,
          backgroundColor: AppColors.primary.withOpacity(0.95),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          borderRadius: 14,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          icon: const Icon(
            Icons.notifications_active_rounded,
            color: Colors.white,
          ),
        );
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    if (_locationRequesting) return;
    _locationRequesting = true;
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog(
          icon: Icons.location_off_rounded,
          iconColor: AppColors.primary,
          title: 'loc_off_title'.tr,
          body: 'loc_off_body'.tr,
          actionLabel: 'loc_enable_gps'.tr,
          onAction: () async {
            Get.back();
            await Geolocator.openLocationSettings();
            Future.delayed(const Duration(seconds: 1), _requestLocationPermission);
          },
        );
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied) {
        _showLocationDialog(
          icon: Icons.location_searching_rounded,
          iconColor: Colors.orange,
          title: 'loc_denied_title'.tr,
          body: 'loc_denied_body'.tr,
          actionLabel: 'loc_retry'.tr,
          onAction: () { Get.back(); _requestLocationPermission(); },
        );
        return;
      }

      if (perm == LocationPermission.deniedForever) {
        _showLocationDialog(
          icon: Icons.location_disabled_rounded,
          iconColor: Colors.red,
          title: 'loc_forever_title'.tr,
          body: 'loc_forever_body'.tr,
          actionLabel: 'loc_settings'.tr,
          onAction: () async {
            Get.back();
            await Geolocator.openAppSettings();
            Future.delayed(const Duration(seconds: 1), _requestLocationPermission);
          },
        );
      }
    } finally {
      _locationRequesting = false;
    }
  }

  void _showLocationDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    if (!mounted) return;
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62.w, height: 62.w,
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 30.sp),
                ),
                SizedBox(height: 16.h),
                Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Nunito')),
                SizedBox(height: 8.h),
                Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, color: AppColors.textMedium, fontFamily: 'Nunito', height: 1.4)),
                SizedBox(height: 22.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      elevation: 0,
                    ),
                    child: Text(actionLabel, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito')),
                  ),
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('loc_later'.tr, style: TextStyle(fontSize: 12.sp, color: AppColors.textLight, fontFamily: 'Nunito')),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _idx, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBtn(
                  Icons.dashboard_rounded,
                  Icons.dashboard_outlined,
                  'dashboard'.tr,
                  0,
                  _idx,
                      () => setState(() => _idx = 0),
                ),
                _NavBtn(
                  Icons.calendar_month_rounded,
                  Icons.calendar_month_outlined,
                  'orders'.tr,
                  1,
                  _idx,
                      () => setState(() => _idx = 1),
                ),
                _NavBtn(
                  Icons.person_rounded,
                  Icons.person_outline_rounded,
                  'profile'.tr,
                  2,
                  _idx,
                      () => setState(() => _idx = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon, outline;
  final String label;
  final int idx, cur;
  final VoidCallback onTap;

  const _NavBtn(
      this.icon,
      this.outline,
      this.label,
      this.idx,
      this.cur,
      this.onTap,
      );

  @override
  Widget build(BuildContext context) {
    final a = idx == cur;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: a ? 16.w : 12.w,
          vertical: 9.h,
        ),
        decoration: BoxDecoration(
          color: a ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              a ? icon : outline,
              color: a ? AppColors.primary : AppColors.textLight,
              size: 22.sp,
            ),
            if (a) ...[
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// HOME TAB
// ══════════════════════════════════════

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  // Helper: format date difference
  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'today'.tr;
    if (diff.inDays == 1) return 'yesterday'.tr;
    return '${diff.inDays}d ago';
  }

  // ─── Health Tips Carousel ──────────────────────────────────────────────────
  Widget _healthTips() {
    final tips = [
      {'icon': '💧', 'title': 'Drink water', 'desc': '8 glasses daily'},
      {'icon': '🏃', 'title': 'Walk 30 min', 'desc': 'Stay active'},
      {'icon': '🥗', 'title': 'Eat greens', 'desc': 'More vegetables'},
      {'icon': '😴', 'title': 'Sleep 8h', 'desc': 'Rest well'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'health_tips'.tr,
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
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            padding: EdgeInsets.symmetric(horizontal: 0),
            itemBuilder: (_, i) => Container(
              width: 140.w,
              margin: EdgeInsets.only(right: 10.w),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tips[i]['icon']!, style: TextStyle(fontSize: 24.sp)),
                  SizedBox(height: 4.h),
                  Text(
                    tips[i]['title']!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    tips[i]['desc']!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.textLight,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Medical History Card ──────────────────────────────────────────────────
  Widget _medicalHistoryCard(OrderController ctrl) {
    final completed = ctrl.orderHistory.where((o) => o.status == OrderStatus.completed).toList();
    final recent = completed.take(3).toList();
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.primary, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'recent_visits'.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontFamily: 'Nunito',
                ),
              ),
              const Spacer(),
              if (completed.length > 3)
                GestureDetector(
                  onTap: () {
                    // Navigate to full history (optional)
                  },
                  child: Text(
                    'view_all'.tr,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          if (recent.isEmpty)
            Text(
              'no_visits_yet'.tr,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textLight,
                fontFamily: 'Nunito',
              ),
            )
          else
            ...recent.map((order) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
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
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      order.services.map((s) => s.name).join(', '),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMedium,
                        fontFamily: 'Nunito',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.textLight,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  // ─── Main Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final name = GetStorage().read('user_name') as String? ?? 'Foydalanuvchi';
    final ctrl = Get.find<OrderController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -50.h,
            right: -50.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 100.h,
            left: -80.w,
            child: Container(
              width: 180.w,
              height: 180.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.02),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(name, ctrl)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 80.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: 18.h),
                    Obx(() {
                      final o = ctrl.activeOrder.value;
                      final id = ctrl.activeOrderId.value;
                      if (o == null && id.isEmpty) return const SizedBox.shrink();
                      return _ActiveBanner(order: o, orderId: id);
                    }),
                    SizedBox(height: 18.h),
                    _actionCards(ctrl),
                    SizedBox(height: 20.h),
                    _infoCard(),
                    SizedBox(height: 16.h),
                    // ─── NEW: Health Tips ──────────────────────────────
                    _healthTips(),
                    SizedBox(height: 16.h),
                    // ─── NEW: Medical History ──────────────────────────
                    _medicalHistoryCard(ctrl),
                    SizedBox(height: 16.h),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Existing widgets (unchanged) ─────────────────────────────────────────

  Widget _header(String name, OrderController ctrl) => ClipRRect(
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
    child: Container(
      padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 24.h),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'hello'.tr}, $name 👋',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 12.sp,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Andijon viloyati',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.notifications),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _actionCards(OrderController ctrl) => Column(
    children: [
      GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.order),
        child: Container(
          constraints: BoxConstraints(minHeight: 130.h),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20.w,
                bottom: -20.h,
                child: Container(
                  width: 120.w, height: 120.w,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)),
                ),
              ),
              Positioned(
                right: 16.w,
                top: 0, bottom: 0,
                child: Center(
                  child: Icon(Icons.health_and_safety_rounded, color: Colors.white.withOpacity(0.25), size: 70.sp),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.personal_injury_rounded, color: Colors.white, size: 20.sp),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'call_nurse'.tr,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'nurse_call_sub'.tr,
                        style: TextStyle(fontSize: 11.sp, color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(height: 10.h),
      GestureDetector(
        onTap: () async {
          final uri = Uri(scheme: 'tel', path: '+998886686868');
          if (await canLaunchUrl(uri)) launchUrl(uri);
        },
        child: Container(
          height: 54.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34.w, height: 34.w,
                decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: Icon(Icons.call_rounded, color: AppColors.primary, size: 17.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'phone_order_title'.tr,
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Nunito'),
                    ),
                    Text(
                      '+998 88 668 68 68',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontFamily: 'Nunito', fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textLight, size: 12.sp),
            ],
          ),
        ),
      ),
      SizedBox(height: 12.h),
      Obx(() {
        final completed = ctrl.completedOrdersCount.value;
        final cycle = completed % 6;
        final eligible = ctrl.isPromoEligible;
        final lang = Get.locale?.languageCode ?? 'uz';
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: eligible ? const Color(0xFFFFF0F0) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: eligible
                  ? const Color(0xFFEF4444).withOpacity(0.4)
                  : const Color(0xFFF59E0B).withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42.w, height: 42.w,
                decoration: BoxDecoration(
                  color: eligible
                      ? const Color(0xFFEF4444).withOpacity(0.15)
                      : const Color(0xFFF59E0B).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(eligible ? '🎉' : '🎁', style: TextStyle(fontSize: 20.sp))),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eligible
                          ? (lang == 'ru' ? '🔥 Этот заказ со скидкой 30%!' : '🔥 Ushbu buyurtmada 30% chegirma!')
                          : 'promo_title'.tr,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: eligible ? const Color(0xFFB91C1C) : const Color(0xFF92400E),
                        fontFamily: 'Nunito',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: List.generate(6, (i) => Container(
                        margin: EdgeInsets.only(right: 4.w),
                        width: 10.w, height: 10.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < cycle
                              ? const Color(0xFFF59E0B)
                              : eligible
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFD1D5DB),
                        ),
                      )),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      eligible
                          ? (lang == 'ru' ? 'Поздравляем! Скидка применена автоматически.' : 'Tabriklaymiz! Chegirma avtomatik qo\'llaniladi.')
                          : (lang == 'ru'
                          ? '$cycle/6 выполнено · осталось ${5 - cycle}'
                          : '$cycle/6 bajarildi · ${5 - cycle} ta qoldi'),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: eligible ? const Color(0xFFDC2626) : const Color(0xFFB45309),
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ],
  );

  Widget _infoCard() => Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF0FFF4), Color(0xFFE6FFFA)],
      ),
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(color: AppColors.primary.withOpacity(0.13)),
    ),
    child: Row(
      children: [
        Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.health_and_safety_rounded,
            color: AppColors.primary,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'health_motto'.tr,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontFamily: 'Nunito',
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'service_24_7'.tr,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActiveBanner extends StatelessWidget {
  final OrderModel? order;
  final String orderId;

  const _ActiveBanner({this.order, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final s = order?.status ?? OrderStatus.searching;
    final col = s == OrderStatus.enRoute
        ? const Color(0xFFF97316)
        : s == OrderStatus.arrived
        ? const Color(0xFF8B5CF6)
        : AppColors.primary;
    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.orderTracking, arguments: {'orderId': orderId}),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: col.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: col.withOpacity(0.22), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: col.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(s), color: col, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order?.statusLabel ?? 'Hamshira qidirilmoqda...',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  if (order?.nurseName != null)
                    Text(
                      order!.nurseName!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textLight,
                        fontFamily: 'Nunito',
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: col, size: 13.sp),
          ],
        ),
      ),
    );
  }

  IconData _icon(OrderStatus s) {
    switch (s) {
      case OrderStatus.enRoute:
        return Icons.directions_run_rounded;
      case OrderStatus.arrived:
        return Icons.home_rounded;
      case OrderStatus.completed:
        return Icons.task_alt_rounded;
      default:
        return Icons.search_rounded;
    }
  }
}

// ══════════════════════════════════════
// ORDERS TAB – unchanged
// ══════════════════════════════════════
// ... (OrdersTab and _OrderList are exactly as provided, unchanged)
// I'll include them for completeness but they are untouched.
// Due to length constraints, I'll omit them here – they remain the same as in your original file.
// The same applies to ProfileTab – it remains exactly as you had.
// Only DashboardTab received the two new widgets.
// ──────────────────────────────────────────────────────────────────────────────

// Note: OrdersTab and ProfileTab are identical to your original code.
// Please copy them from your existing file – they are unchanged.

// ══════════════════════════════════════
// ORDERS TAB
// ══════════════════════════════════════

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OrderController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: 100.h,
            right: -30.w,
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 200.h,
            left: -50.w,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.02),
              ),
            ),
          ),
          Column(
            children: [
              40.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h),
                  decoration: BoxDecoration(
                    gradient: AppColors.headerGradient,
                    borderRadius: BorderRadius.all(Radius.circular(22.r)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22.sp),
                      SizedBox(width: 10.w),
                      Text(
                        'orders_title'.tr,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textLight,
                  labelStyle: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                  tabs: [
                    Tab(text: 'tab_active'.tr),
                    Tab(text: 'tab_done'.tr),
                    Tab(text: 'tab_cancelled'.tr),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  final h = ctrl.orderHistory;
                  final active = h
                      .where(
                        (o) =>
                    o.status != OrderStatus.completed &&
                        o.status != OrderStatus.cancelled,
                  )
                      .toList();
                  final completed = h
                      .where((o) => o.status == OrderStatus.completed)
                      .toList();
                  final cancelled = h
                      .where((o) => o.status == OrderStatus.cancelled)
                      .toList();
                  return TabBarView(
                    controller: _tab,
                    children: [
                      _OrderList(orders: active, empty: 'no_active_orders'.tr),
                      _OrderList(
                        orders: completed,
                        empty: 'no_done_orders'.tr,
                      ),
                      _OrderList(
                        orders: cancelled,
                        empty: 'no_cancelled_orders'.tr,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String empty;

  const _OrderList({required this.orders, required this.empty});

  String _fmt(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
                size: 28.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              empty,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textLight,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    final lang = Get.locale?.languageCode ?? 'uz';
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 30.h),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        final isSaved =
            o.status == OrderStatus.completed ||
                o.status == OrderStatus.cancelled;
        return GestureDetector(
          onTap: () {
            if (!isSaved)
              Get.toNamed(
                AppRoutes.orderTracking,
                arguments: {'orderId': o.id},
              );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          o.id.length > 12 ? '#${o.id.substring(0, 10)}' : o.id,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: AppColors.primary,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _badge(o.status, lang),
                    ],
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    o.services
                        .map((s) => lang == 'ru' ? s.nameRu : s.name)
                        .join(', '),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontFamily: 'Nunito',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.textLight,
                        size: 12.sp,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          o.address.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textLight,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Divider(color: AppColors.divider, height: 1),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jami',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textLight,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_fmt(o.totalPrice)} so\'m',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _badge(OrderStatus s, String lang) {
    Color bg, fg;
    String lbl;
    switch (s) {
      case OrderStatus.searching:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        lbl = lang == 'ru' ? 'Поиск' : 'Qidirish';
      case OrderStatus.accepted:
      case OrderStatus.enRoute:
      case OrderStatus.arrived:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        lbl = lang == 'ru' ? 'Активный' : 'Faol';
      case OrderStatus.completed:
        bg = const Color(0xFFE6FAF0);
        fg = const Color(0xFF22C55E);
        lbl = lang == 'ru' ? 'Выполнен' : 'Bajarildi';
      case OrderStatus.cancelled:
        bg = const Color(0xFFFFEEEE);
        fg = const Color(0xFFEF4444);
        lbl = lang == 'ru' ? 'Отменён' : 'Bekor';
      default:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        lbl = 'Faol';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        lbl,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: fg,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
// PROFILE TAB
// ══════════════════════════════════════

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final name = box.read('user_name') as String? ?? 'Foydalanuvchi';
    final phone = box.read('user_phone') as String? ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: 200.h,
            right: -20.w,
            child: Container(
              width: 180.w,
              height: 180.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.03),
              ),
            ),
          ),
          Positioned(
            bottom: 300.h,
            left: -60.w,
            child: Container(
              width: 140.w,
              height: 140.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.02),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                80.verticalSpace,
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 30.h),
                  child: Transform.translate(
                    offset: Offset(0, -24.h),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(18.w),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56.w,
                                height: 56.w,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppColors.textLight,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _item(
                                Icons.notifications_outlined,
                                'notifications'.tr,
                                    () => Get.toNamed(AppRoutes.notifications),
                              ),
                              Divider(height: 1, indent: 60.w, color: AppColors.divider),
                              _item(
                                Icons.feedback_outlined,
                                'complaint'.tr,
                                    () => Get.toNamed(AppRoutes.complaint),
                              ),
                              Divider(
                                height: 1,
                                indent: 60.w,
                                color: AppColors.divider,
                              ),
                              _item(
                                Icons.language_rounded,
                                'app_language'.tr,
                                    () => _langSheet(context),
                              ),
                              Divider(
                                height: 1,
                                indent: 60.w,
                                color: AppColors.divider,
                              ),
                              _item(
                                Icons.headset_mic_outlined,
                                'support'.tr,
                                    () {
                                  showModalBottomSheet(
                                    context: context,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                                    ),
                                    builder: (context) {
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.headset_mic_outlined,
                                                  color: AppColors.primary, size: 30),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'support'.tr,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Nunito',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Yordam kerakmi? Biz siz bilan bog'laning",
                                              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontFamily: 'Nunito'),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 24),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 54,
                                              child: ElevatedButton.icon(
                                                onPressed: () async {
                                                  final Uri phoneUri =
                                                  Uri(scheme: 'tel', path: '+998886686868');
                                                  if (await canLaunchUrl(phoneUri)) {
                                                    await launchUrl(phoneUri);
                                                  }
                                                },
                                                icon: const Icon(Icons.call, size: 20),
                                                label: const Text(
                                                  "+998 88 668 68 68",
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Nunito'),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  elevation: 0,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 48,
                                              child: TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.grey[700],
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                ),
                                                child: Text('cancel'.tr,
                                                    style: const TextStyle(fontSize: 15, fontFamily: 'Nunito')),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                showDivider: false,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: () => Get.dialog(
                            AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              title: Text(
                                'logout'.tr,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              content: Text(
                                'logout'.tr + '?',
                                style: const TextStyle(fontFamily: 'Nunito'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text(
                                    "Yo'q",
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    AuthController controller = Get.put(AuthController());
                                    controller.signOut();
                                  },
                                  child: const Text(
                                    'Ha',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 13.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEEEE),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.logout_rounded,
                                    color: AppColors.accent,
                                    size: 18.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'logout'.tr,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppColors.accent.withOpacity(0.5),
                                  size: 12.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        GestureDetector(
                          onTap: () => Get.dialog(
                            AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              title: Text(
                                'delete_account_title'.tr,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB91C1C),
                                ),
                              ),
                              content: Text(
                                'delete_account_warning'.tr,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  height: 1.5,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text(
                                    'cancel'.tr,
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Get.back();
                                    AuthController controller = Get.put(AuthController());
                                    controller.deleteAccount();
                                  },
                                  child: const Text(
                                    'Ha',
                                    style: TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 13.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color: const Color(0xFFB91C1C).withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    Icons.delete_forever_rounded,
                                    color: const Color(0xFFB91C1C),
                                    size: 18.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'delete_account'.tr,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB91C1C),
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: const Color(0xFFB91C1C).withOpacity(0.5),
                                  size: 12.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
      IconData icon,
      String label,
      VoidCallback onTap, {
        bool showDivider = true,
      }) => Column(
    children: [
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textHint,
                size: 14.sp,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  void _langSheet(BuildContext context) => Get.bottomSheet(
    Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.language_rounded, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'app_language'.tr,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...[('🇺🇿', "O'zbek", 'uz'), ('🇷🇺', 'Русский', 'ru')].map(
                (e) => GestureDetector(
              onTap: () {
                Get.updateLocale(Locale(e.$3));
                GetStorage().write('language', e.$3);
                Get.back();
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Get.locale?.languageCode == e.$3
                      ? AppColors.primaryLight
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: Get.locale?.languageCode == e.$3
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(e.$1, style: TextStyle(fontSize: 28.sp)),
                    SizedBox(width: 12.w),
                    Text(
                      e.$2,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Get.locale?.languageCode == e.$3
                            ? AppColors.primary
                            : AppColors.textDark,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    if (Get.locale?.languageCode == e.$3) ...[
                      const Spacer(),
                      Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20.sp),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    ),
  );
}