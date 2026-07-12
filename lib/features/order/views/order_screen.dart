import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_routes.dart';
import '../controllers/order_controller.dart';

// ── Simple model for Nominatim search results ─────────────────────────────────
class _Place {
  final String title;
  final String subtitle;
  final double lat;
  final double lng;

  const _Place({
    required this.title,
    required this.subtitle,
    required this.lat,
    required this.lng,
  });

  factory _Place.fromJson(Map<String, dynamic> j) {
    final full  = j['display_name'] as String? ?? '';
    final parts = full.split(',');
    final title    = parts.isNotEmpty ? parts.first.trim() : full;
    final subtitle = parts.length > 1
        ? parts.skip(1).join(',').trim()
        : '';
    return _Place(
      title:    title,
      subtitle: subtitle,
      lat: double.tryParse(j['lat'] as String? ?? '') ?? 0,
      lng: double.tryParse(j['lon'] as String? ?? '') ?? 0,
    );
  }
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  final OrderController ctrl = Get.find<OrderController>();

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<_Place> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

  // Address shown in bottom panel
  String _selectedAddress = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _selectedAddress = 'location'.tr);
    });
    _fetchMyLocation();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Location ─────────────────────────────────────────────────────────────

  Future<void> _fetchMyLocation() async {
    var pos = ctrl.clientPosition;
    if (pos == null) {
      pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) ctrl.clientPosition = pos;
    }
    if (!mounted) return;
    if (pos == null) {
      setState(() => _selectedAddress = 'location_not_found'.tr);
      return;
    }
    ctrl.setPickedLocation(pos.latitude, pos.longitude);
    setState(() => _selectedAddress = 'my_location_lbl'.tr);
    _moveCameraTo(LatLng(pos.latitude, pos.longitude));
  }

  void _moveCameraTo(LatLng pt, {double zoom = 16.0, int attempt = 0}) {
    if (_mapReady) {
      _mapController.move(pt, zoom);
    } else if (attempt < 20) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _moveCameraTo(pt, zoom: zoom, attempt: attempt + 1);
      });
    }
  }

  Future<void> _goToMyLocation() async {
    var pos = ctrl.clientPosition;
    if (pos == null) {
      pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) ctrl.clientPosition = pos;
    }
    if (!mounted || pos == null) return;
    ctrl.setPickedLocation(pos.latitude, pos.longitude);
    setState(() {
      _selectedAddress = 'my_location_lbl'.tr;
      _searchCtrl.clear();
      _showSuggestions = false;
    });
    _mapController.move(LatLng(pos.latitude, pos.longitude), 16.0);
  }

  // ── Search via Nominatim (OpenStreetMap) — free, no API key ──────────────

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(v.trim()));
  }

  Future<void> _search(String query) async {
    try {
      final lang = Get.locale?.languageCode == 'ru' ? 'ru' : 'uz,ru,en';

      final q = query.toLowerCase().contains('andij')
          ? query
          : '$query, Andijon';

      const viewbox = '71.5,41.0,73.2,40.45';

      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q':               q,
          'format':          'json',
          'countrycodes':    'uz',
          'viewbox':         viewbox,
          'bounded':         '1',
          'limit':           '10',
          'accept-language': lang,
        },
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'MeningHamshiram/1.0 (flutter app)',
      }).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final list  = jsonDecode(response.body) as List<dynamic>;
        final items = list.map((e) => _Place.fromJson(e as Map<String, dynamic>)).toList();
        setState(() {
          _suggestions     = items;
          _showSuggestions = items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('[OrderSearch] error: $e');
    }
  }

  void _pickPlace(_Place place) {
    ctrl.setPickedLocation(place.lat, place.lng);
    setState(() {
      _showSuggestions = false;
      _selectedAddress = place.title;
      _searchCtrl.text = place.title;
    });
    _searchFocus.unfocus();
    if (place.lat != 0 && place.lng != 0) {
      _moveCameraTo(LatLng(place.lat, place.lng));
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _searchFocus.unfocus(),
      child: Scaffold(
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
              child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 17.sp),
            ),
          ),
        ),
        body: Column(
          children: [
            // ── Map area ──────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // flutter_map — pure Dart, OpenStreetMap tiles, works on all iOS versions
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        ctrl.clientPosition?.latitude  ?? 40.8147,
                        ctrl.clientPosition?.longitude ?? 72.3469,
                      ),
                      initialZoom: 15.0,
                      onMapReady: () => setState(() => _mapReady = true),
                      onPositionChanged: (camera, hasGesture) {
                        if (hasGesture) {
                          ctrl.setPickedLocation(
                            camera.center.latitude,
                            camera.center.longitude,
                          );
                          if (mounted) {
                            setState(() {
                              _showSuggestions = false;
                              if (_searchCtrl.text.isEmpty) {
                                _selectedAddress = 'picked_location_lbl'.tr;
                              }
                            });
                          }
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.mening.hamshiram.meningHamshiram',
                      ),
                    ],
                  ),

                  // ── Static crosshair — pin tip at exact map center ────
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Shadow ellipse right at center (pin tip touches it)
                          Container(
                            width: 14.w,
                            height: 5.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          // Icon: padding(bottom = icon size) → tip is at center
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 52.sp),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 52.sp,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Search field + suggestions ────────────────────────
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    right: 12.w,
                    child: Column(
                      children: [
                        // Search TextField
                        Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontFamily: 'Nunito',
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'search_address_hint'.tr,
                              hintStyle: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.textHint,
                                fontFamily: 'Nunito',
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppColors.primary,
                                size: 20.sp,
                              ),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: AppColors.textLight,
                                        size: 18.sp,
                                      ),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() {
                                          _suggestions     = [];
                                          _showSuggestions = false;
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                          ),
                        ),

                        // Suggestions dropdown
                        if (_showSuggestions) ...[
                          SizedBox(height: 6.h),
                          Container(
                            constraints: BoxConstraints(maxHeight: 220.h),
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
                                  final place = _suggestions[i];
                                  return InkWell(
                                    onTap: () => _pickPlace(place),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                        vertical: 11.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            color: AppColors.primary,
                                            size: 18.sp,
                                          ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  place.title,
                                                  style: TextStyle(
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textDark,
                                                    fontFamily: 'Nunito',
                                                  ),
                                                ),
                                                if (place.subtitle.isNotEmpty)
                                                  Text(
                                                    place.subtitle,
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
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── My location button ────────────────────────────────
                  Positioned(
                    right: 14.w,
                    bottom: 16.h,
                    child: GestureDetector(
                      onTap: _goToMyLocation,
                      child: Container(
                        width: 46.w,
                        height: 46.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 22.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom panel ──────────────────────────────────────
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                            // Selected address display
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    color: AppColors.primary,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      _selectedAddress.isEmpty
                                          ? 'location'.tr
                                          : _selectedAddress,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppColors.textMedium,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColors.textLight,
                                    size: 14.sp,
                                  ),
                                ],
                              ),
                            ),
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
                                child: Row(
                                  children: [
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                              color: Colors.white.withOpacity(0.85),
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                  ],
                                ),
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
      ),
    );
  }
}
