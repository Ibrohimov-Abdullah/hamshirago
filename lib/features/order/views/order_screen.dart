import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../../../core/services/location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../controllers/order_controller.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

enum _LocationMode { myLocation, custom }

class _OrderScreenState extends State<OrderScreen> {
  YandexMapController? _mapController;
  final OrderController ctrl = Get.find<OrderController>();

  Point? _pickedPoint;
  Uint8List? _markerBytes;
  _LocationMode _locationMode = _LocationMode.myLocation;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<SuggestItem> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _buildMarkerBytes();
    _fetchAndPinMyLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Marker ───────────────────────────────────────────────────────────────

  Future<void> _buildMarkerBytes() async {
    const double w = 64, h = 84;
    const double cx = w / 2, cy = 30.0, r = 26.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(cx + 1, cy + 2), radius: r))
        ..moveTo(cx - 9, cy + r * 0.65)
        ..quadraticBezierTo(cx - 3, h - 6, cx + 1, h - 1)
        ..quadraticBezierTo(cx + 5, h - 6, cx + 11, cy + r * 0.65)
        ..close(),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 4),
    );
    canvas.drawPath(
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(cx, cy), radius: r))
        ..moveTo(cx - 9, cy + r * 0.65)
        ..quadraticBezierTo(cx - 3, h - 8, cx, h - 3)
        ..quadraticBezierTo(cx + 3, h - 8, cx + 9, cy + r * 0.65)
        ..close(),
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(const Offset(cx, cy), r * 0.52, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(cx, cy), r * 0.22, Paint()..color = AppColors.primary);

    final img = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (mounted) setState(() => _markerBytes = data!.buffer.asUint8List());
  }

  // ── Location ─────────────────────────────────────────────────────────────

  /// Fetches GPS position (whether or not the controller already has it)
  /// then drops the pin and moves the camera. Called once on initState.
  Future<void> _fetchAndPinMyLocation() async {
    // If controller already has a position, use it immediately
    var pos = ctrl.clientPosition;

    // Otherwise fetch fresh (this shows the permission dialog if needed)
    if (pos == null) {
      pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) ctrl.clientPosition = pos;
    }

    if (!mounted || pos == null) return;

    final pt = Point(latitude: pos.latitude, longitude: pos.longitude);
    ctrl.setPickedLocation(pos.latitude, pos.longitude);

    setState(() => _pickedPoint = pt);

    // Move camera — map might not be ready yet, retry until it is
    _moveCameraTo(pt);
  }

  void _moveCameraTo(Point pt, {double zoom = 16.0, int attempt = 0}) {
    if (_mapController != null) {
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: pt, zoom: zoom)),
      );
    } else if (attempt < 20) {
      // Map not ready yet — retry every 150ms (max 3 s)
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _moveCameraTo(pt, zoom: zoom, attempt: attempt + 1);
      });
    }
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locationMode = _LocationMode.myLocation;
      _showSuggestions = false;
      _searchCtrl.clear();
    });
    _searchFocus.unfocus();

    var pos = ctrl.clientPosition;
    if (pos == null) {
      ctrl.addressText.value = 'location'.tr;
      pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) ctrl.clientPosition = pos;
    }

    if (!mounted || pos == null) return;

    final pt = Point(latitude: pos.latitude, longitude: pos.longitude);
    ctrl.setPickedLocation(pos.latitude, pos.longitude);
    setState(() => _pickedPoint = pt);
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: pt, zoom: 16.0)),
    );
  }

  void _onMapTap(Point point) {
    if (_locationMode != _LocationMode.custom) return;
    setState(() {
      _pickedPoint = point;
      _showSuggestions = false;
    });
    _searchFocus.unfocus();
    ctrl.setPickedLocation(point.latitude, point.longitude);
  }

  Future<void> _goToMyLocation() async {
    var pos = ctrl.clientPosition;
    if (pos == null) {
      pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) ctrl.clientPosition = pos;
    }
    if (!mounted || pos == null) return;
    final pt = Point(latitude: pos.latitude, longitude: pos.longitude);
    // If in myLocation mode, also update the pin
    if (_locationMode == _LocationMode.myLocation) {
      ctrl.setPickedLocation(pos.latitude, pos.longitude);
      setState(() => _pickedPoint = pt);
    }
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: pt, zoom: 16.0)),
    );
  }

  // ── Search ───────────────────────────────────────────────────────────────

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
          () => _search(v.trim()),
    );
  }

  Future<void> _search(String query) async {
    try {
      final suggestResult = await YandexSuggest.getSuggestions(
        text: query,
        boundingBox: const BoundingBox(
          northEast: Point(latitude: 42.5, longitude: 70.5),
          southWest: Point(latitude: 39.5, longitude: 64.0),
        ),
        suggestOptions: const SuggestOptions(
          suggestType: SuggestType.geo,
          suggestWords: true,
          strictBounds: false,
        ),
      );

      final result = switch (suggestResult) {
        (SuggestSession _, Future<SuggestSessionResult> future) => await future,

      };

      final items = result.items?.where((s) => s.center != null).toList() ?? [];
      if (mounted) {
        setState(() {
          _suggestions = items;
          _showSuggestions = items.isNotEmpty;
        });
      }
    } catch (_) {
      // silently ignore — search just won't show results
    }
  }
  void _pickSuggestion(SuggestItem item) {
    final point = item.center!;
    setState(() {
      _pickedPoint = point;
      _showSuggestions = false;
      _searchCtrl.text = item.title;
    });
    _searchFocus.unfocus();
    ctrl.setPickedLocation(point.latitude, point.longitude);
    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: 16.0),
      ),
    );
  }

  // ── Map objects ──────────────────────────────────────────────────────────

  List<MapObject> get _mapObjects {
    if (_pickedPoint == null || _markerBytes == null) return [];
    return [
      PlacemarkMapObject(
        mapId: const MapObjectId('picked_location'),
        point: _pickedPoint!,
        opacity: 1.0,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromBytes(_markerBytes!),
            anchor: const Offset(0.5, 1.0),
            scale: 1.3,
          ),
        ),
      ),
    ];
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isCustom = _locationMode == _LocationMode.custom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'make_order'.tr,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 16.sp,
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
              size: 17.sp,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Map ──────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                YandexMap(
                  mapObjects: _mapObjects,
                  onMapCreated: (YandexMapController controller) async {
                    _mapController = controller;
                    await controller.toggleUserLayer(
                      visible: false,
                      autoZoomEnabled: false,
                    );
                    // Use already-fetched position if available, else Tashkent centre
                    final pos = ctrl.clientPosition ?? LocationService.instance.lastPosition;
                    final target = pos != null
                        ? Point(latitude: pos.latitude, longitude: pos.longitude)
                        : const Point(latitude: 41.2995, longitude: 69.2401);
                    controller.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: target, zoom: 15.0),
                      ),
                    );
                  },
                  onMapTap: _onMapTap,
                ),

                // Mode toggle
                Positioned(
                  top: 12.h,
                  left: 16.w,
                  right: 16.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      Expanded(
                        child: _ModeBtn(
                          icon: Icons.my_location_rounded,
                          label: 'my_location_btn'.tr,
                          active: !isCustom,
                          onTap: _useMyLocation,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: _ModeBtn(
                          icon: Icons.location_on_rounded,
                          label: 'other_location_btn'.tr,
                          active: isCustom,
                          onTap: () => setState(() {
                            _locationMode = _LocationMode.custom;
                            _pickedPoint = null;
                          }),
                        ),
                      ),
                    ]),
                  ),
                ),

                // Search bar (custom mode only)

                // Suggestions dropdown
                if (_showSuggestions)
                  Positioned(
                    top: 132.h,
                    left: 16.w,
                    right: 16.w,
                    child: Container(
                      constraints: BoxConstraints(maxHeight: 210.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppColors.divider,
                            indent: 16.w,
                            endIndent: 16.w,
                          ),
                          itemBuilder: (_, i) {
                            final item = _suggestions[i];
                            final subtitle = item.subtitle ?? '';
                            return InkWell(
                              onTap: () => _pickSuggestion(item),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 11.h,
                                ),
                                child: Row(children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: AppColors.primary,
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                            fontFamily: 'Nunito',
                                          ),
                                        ),
                                        if (subtitle.isNotEmpty)
                                          Text(
                                            subtitle,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: AppColors.textLight,
                                              fontFamily: 'Nunito',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // Tap-to-pick hint
                if (isCustom && _pickedPoint == null && !_showSuggestions)
                  Positioned(
                    bottom: 80.h,
                    left: 16.w,
                    right: 70.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(children: [
                        Icon(Icons.touch_app_rounded,
                            color: Colors.white, size: 18.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'map_pick_hint'.tr,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                // My location button
                Positioned(
                  right: 16.w,
                  bottom: 16.h,
                  child: GestureDetector(
                    onTap: _goToMyLocation,
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom panel ──────────────────────────────────
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Row(children: [
                              Icon(Icons.location_on_rounded,
                                  color: AppColors.primary, size: 20.sp),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  ctrl.addressText.value,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textMedium,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  color: AppColors.textLight, size: 14.sp),
                            ]),
                          )),
                          SizedBox(height: 24.h),

                          Text(
                            'service_type'.tr,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              fontFamily: 'Nunito',
                            ),
                          ),
                          SizedBox(height: 14.h),

                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.selectService),
                            child: Container(
                              padding: EdgeInsets.all(18.w),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(18.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 52.w,
                                  height: 52.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Icon(
                                    Icons.medical_services_rounded,
                                    color: Colors.white,
                                    size: 28.sp,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'call_nurse'.tr,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        'select_service'.tr,
                                        style: TextStyle(
                                          fontSize: 12.5.sp,
                                          color:
                                          Colors.white.withOpacity(0.85),
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 22.sp),
                              ]),
                            ),
                          ),
                          SizedBox(height: 30.h),
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
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : AppColors.textMedium,
              size: 16.sp,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textMedium,
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}