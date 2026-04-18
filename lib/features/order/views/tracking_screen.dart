import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/app_routes.dart';
import '../controllers/order_controller.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ORDER TRACKING SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  final ctrl = Get.find<OrderController>();
  late final String orderId;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  // ETA elapsed timer
  Timer? _etaTimer;
  int _elapsedSec = 0;

  @override
  void initState() {
    super.initState();
    orderId = (Get.arguments?['orderId'] as String?)?.trim() ?? '';

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    // Start ETA timer when nurse is en route
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSec++);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _etaTimer?.cancel();
    super.dispose();
  }

  // ── Status helpers ────────────────────────────────────────────────────────

  Color _statusColor(OrderStatus? s) {
    switch (s) {
      case OrderStatus.enRoute:   return const Color(0xFFF97316);
      case OrderStatus.arrived:   return const Color(0xFF8B5CF6);
      case OrderStatus.completed: return const Color(0xFF22C55E);
      case OrderStatus.cancelled: return const Color(0xFFEF4444);
      default:                    return AppColors.primary;
    }
  }

  IconData _statusIcon(OrderStatus? s) {
    switch (s) {
      case OrderStatus.accepted:  return Icons.check_circle_outline_rounded;
      case OrderStatus.enRoute:   return Icons.directions_run_rounded;
      case OrderStatus.arrived:   return Icons.home_rounded;
      case OrderStatus.completed: return Icons.task_alt_rounded;
      default:                    return Icons.search_rounded;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(() {
          final order = ctrl.activeOrder.value;
          return Column(
            children: [
              _buildHero(order),
              Expanded(
                child: SlideTransition(
                  position: _slideAnim,
                  child: _buildContent(order),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Hero header ───────────────────────────────────────────────────────────

  Widget _buildHero(OrderModel? order) {
    final isSearching = order == null ||
        order.status == OrderStatus.searching ||
        order.status == OrderStatus.pending;
    final color = _statusColor(order?.status);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 28.h),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: _cancelDialog,
                    child: Container(
                      width: 38.w, height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18.sp),
                    ),
                  ),
                  const Spacer(),
                  if (!isSearching)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7.w, height: 7.w,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'live'.tr,
                            style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              SizedBox(height: 18.h),

              // Animated icon
              if (isSearching)
                _SearchingRings(color: Colors.white)
              else
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 76.w, height: 76.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: Icon(_statusIcon(order!.status), color: Colors.white, size: 36.sp),
                  ),
                ),

              SizedBox(height: 14.h),

              Text(
                isSearching ? 'searching_nurse'.tr : order!.statusLabel,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Nunito',
                ),
              ),

              if (!isSearching && order!.nurseName != null && order.nurseName!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    order.nurseName!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.82),
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (isSearching) ...[
                SizedBox(height: 6.h),
                Text(
                  'searching_desc'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.75),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────────────

  Widget _buildContent(OrderModel? order) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      child: Column(
        children: [
          if (order == null) ...[
            _cancelCard(),
          ] else ...[
            // Nurse info card (when nurse is assigned)
            if (order.nurseId != null && order.nurseId!.isNotEmpty)
              _nurseCard(order),

            // ETA card (only when accepted or en route)
            if (order.status == OrderStatus.accepted || order.status == OrderStatus.enRoute)
              _etaCard(order),

            // Progress stepper
            _stepperCard(order),

            // Address
            if (order.address.text.isNotEmpty)
              _addressCard(order),

            // Certificates button
            if (order.nurseId != null && order.nurseId!.isNotEmpty)
              _certificatesButton(order),

            // Cancel
            if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled)
              _cancelButton(),
          ],
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _cancelCard() => Container(
    padding: EdgeInsets.all(18.w),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18.r),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(
      children: [
        GestureDetector(
          onTap: _cancelDialog,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 13.h),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'cancel'.tr,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.accent, fontFamily: 'Nunito'),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _nurseCard(OrderModel order) => Container(
    margin: EdgeInsets.only(bottom: 12.h),
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18.r),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Row(
      children: [
        // Avatar
        Container(
          width: 54.w, height: 54.w,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              (order.nurseName ?? '?')[0].toUpperCase(),
              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Nunito'),
            ),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.nurseName ?? 'nurse'.tr,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Nunito'),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.primary, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'verified_nurse'.tr,
                    style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Nunito'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Online indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: const Color(0xFFE6FAF0),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6.w, height: 6.w, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
              SizedBox(width: 5.w),
              Text(
                'nurse_online'.tr,
                style: TextStyle(fontSize: 10.sp, color: const Color(0xFF16A34A), fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _etaCard(OrderModel order) {
    final lang = Get.locale?.languageCode ?? 'uz';
    final isEnRoute = order.status == OrderStatus.enRoute;
    final color = isEnRoute ? const Color(0xFFF97316) : AppColors.primary;

    // Show approximate ETA range; if en-route and enough time has passed, narrow the window
    final int baseMin = isEnRoute ? math.max(3, 10 - (_elapsedSec ~/ 60)) : 15;
    final int topMin  = isEnRoute ? math.max(5, 15 - (_elapsedSec ~/ 60)) : 20;
    final String etaText = '~$baseMin–$topMin ${lang == 'ru' ? 'мин' : 'daqiqa'}';
    final String etaLabel = lang == 'ru'
        ? (isEnRoute ? 'Медсестра едет к вам' : 'Медсестра выехала')
        : (isEnRoute ? 'Hamshira yo\'lda' : 'Hamshira chiqib ketdi');

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w, height: 50.w,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(
              isEnRoute ? Icons.directions_run_rounded : Icons.access_time_rounded,
              color: color, size: 24.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etaLabel,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textLight, fontFamily: 'Nunito'),
                ),
                SizedBox(height: 3.h),
                Text(
                  etaText,
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: color, fontFamily: 'Nunito'),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.5), size: 13.sp),
        ],
      ),
    );
  }

  Widget _stepperCard(OrderModel order) {
    final steps = [
      (OrderStatus.accepted,  'step_accepted'.tr),
      (OrderStatus.enRoute,   'step_en_route'.tr),
      (OrderStatus.arrived,   'step_arrived'.tr),
      (OrderStatus.completed, 'step_completed'.tr),
    ];
    final currentIndex = steps.indexWhere((s) => s.$1 == order.status);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i    = entry.key;
          final step = entry.value;
          final done   = i < currentIndex;
          final active = i == currentIndex;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: 28.w, height: 28.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done || active ? AppColors.primary : AppColors.divider,
                          boxShadow: active
                              ? [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 8, spreadRadius: 2)]
                              : [],
                        ),
                        child: done
                            ? Icon(Icons.check_rounded, color: Colors.white, size: 15.sp)
                            : active
                                ? Icon(Icons.adjust_rounded, color: Colors.white, size: 15.sp)
                                : null,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        step.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                          color: active ? AppColors.primary : AppColors.textHint,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2.h,
                      margin: EdgeInsets.only(bottom: 22.h),
                      decoration: BoxDecoration(
                        gradient: done
                            ? LinearGradient(colors: [AppColors.primary, AppColors.primary])
                            : null,
                        color: done ? null : AppColors.divider,
                        borderRadius: BorderRadius.circular(1.r),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _addressCard(OrderModel order) => Container(
    margin: EdgeInsets.only(bottom: 12.h),
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18.r),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Row(
      children: [
        Container(
          width: 40.w, height: 40.w,
          decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'address'.tr,
                style: TextStyle(fontSize: 11.sp, color: AppColors.textLight, fontFamily: 'Nunito'),
              ),
              SizedBox(height: 2.h),
              Text(
                '${order.address.text}${order.address.building.isNotEmpty ? ', ${order.address.building}-uy' : ''}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.textDark, fontFamily: 'Nunito'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _certificatesButton(OrderModel order) => Padding(
    padding: EdgeInsets.only(bottom: 10.h),
    child: GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.nurseCertificates, arguments: order.nurseId),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_rounded, color: AppColors.primary, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'view_certificates'.tr,
              style: TextStyle(fontSize: 13.sp, color: AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Nunito'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _cancelButton() => GestureDetector(
    onTap: _cancelDialog,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Text(
        'cancel'.tr,
        style: TextStyle(
          fontSize: 13.sp,
          color: AppColors.textLight,
          fontFamily: 'Nunito',
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _cancelDialog() {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text('cancel'.tr, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
      content: Text('cancel_order_q'.tr, style: const TextStyle(fontFamily: 'Nunito')),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('no'.tr, style: const TextStyle(color: AppColors.textLight, fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () { Get.back(); ctrl.cancelOrder(orderId); },
          child: Text('yes'.tr, style: const TextStyle(color: AppColors.accent, fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}

// ── Animated searching rings ──────────────────────────────────────────────────

class _SearchingRings extends StatefulWidget {
  final Color color;
  const _SearchingRings({required this.color});

  @override
  State<_SearchingRings> createState() => _SearchingRingsState();
}

class _SearchingRingsState extends State<_SearchingRings> with TickerProviderStateMixin {
  late AnimationController _c1, _c2, _c3;

  @override
  void initState() {
    super.initState();
    _c1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _c2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward(from: 0.33)
      ..addStatusListener((s) { if (s == AnimationStatus.completed) _c2.repeat(); });
    _c3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward(from: 0.66)
      ..addStatusListener((s) { if (s == AnimationStatus.completed) _c3.repeat(); });
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80.w, height: 80.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Ring(_c3, widget.color, 40.w),
          _Ring(_c2, widget.color, 28.w),
          _Ring(_c1, widget.color, 18.w),
          Container(
            width: 36.w, height: 36.w,
            decoration: BoxDecoration(color: widget.color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(Icons.search_rounded, color: widget.color, size: 18.sp),
          ),
        ],
      ),
    );
  }
}

class _Ring extends AnimatedWidget {
  final Color color;
  final double size;
  const _Ring(AnimationController c, this.color, this.size) : super(listenable: c);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as AnimationController;
    return Opacity(
      opacity: (1.0 - anim.value).clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.4 + anim.value * 0.6,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ORDER COMPLETE SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class OrderCompleteScreen extends StatefulWidget {
  const OrderCompleteScreen({super.key});

  @override
  State<OrderCompleteScreen> createState() => _OrderCompleteScreenState();
}

class _OrderCompleteScreenState extends State<OrderCompleteScreen> {
  double _rating = 5.0;
  bool _submitted = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final OrderModel? order = Get.arguments as OrderModel?;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            children: [
              const Spacer(),

              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 88.w, height: 88.w,
                  decoration: const BoxDecoration(color: Color(0xFFE6FAF0), shape: BoxShape.circle),
                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 46.sp),
                ),
              ),

              SizedBox(height: 22.h),
              Text('done_title'.tr,
                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900, color: AppColors.textDark, fontFamily: 'Nunito')),
              SizedBox(height: 6.h),
              Text(
                order?.nurseName != null && order!.nurseName!.isNotEmpty
                    ? '${order.nurseName} ${'service_done_by'.tr}'
                    : 'service_success'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: AppColors.textLight, fontFamily: 'Nunito'),
              ),

              SizedBox(height: 32.h),

              if (!_submitted) ...[
                Text('rate_service'.tr,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Nunito')),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() => _rating = i + 1.0),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      child: Icon(
                        i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 38.sp,
                      ),
                    ),
                  )),
                ),
                SizedBox(height: 8.h),
                Builder(builder: (_) {
                  final labels = [
                    '',
                    'rating_1'.tr, 'rating_2'.tr, 'rating_3'.tr,
                    'rating_4'.tr, 'rating_5'.tr,
                  ];
                  final colors = [
                    Colors.transparent,
                    const Color(0xFFEF4444), const Color(0xFFF97316),
                    const Color(0xFFF59E0B), const Color(0xFF22C55E), const Color(0xFF0D9488),
                  ];
                  final idx = _rating.toInt().clamp(1, 5);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: colors[idx].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: colors[idx].withOpacity(0.3)),
                    ),
                    child: Text(labels[idx],
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: colors[idx], fontFamily: 'Nunito')),
                  );
                }),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: _loading ? null : () => _submit(order),
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
                          : Text('submit_rating'.tr, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Nunito')),
                    ),
                  ),
                ),
              ] else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_rounded, color: AppColors.primary, size: 32.sp),
                      SizedBox(height: 8.h),
                      Text('thank_you'.tr, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Nunito')),
                    ],
                  ),
                ),

              const Spacer(),

              GestureDetector(
                onTap: () => Get.offAllNamed(AppRoutes.main),
                child: Text('go_home'.tr,
                    style: TextStyle(fontSize: 13.sp, color: AppColors.textLight, fontFamily: 'Nunito', decoration: TextDecoration.underline)),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(OrderModel? order) async {
    setState(() => _loading = true);
    try {
      if (order != null) {
        final ctrl = Get.isRegistered<OrderController>() ? Get.find<OrderController>() : null;
        await ctrl?.rateOrder(order.id, _rating);
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() { _loading = false; _submitted = true; });
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) Get.offAllNamed(AppRoutes.main);
      });
    }
  }
}
