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
    final full = j['display_name'] as String? ?? '';
    final parts = full.split(',');
    final title = parts.isNotEmpty ? parts.first.trim() : full;
    final subtitle = parts.length > 1
        ? parts.skip(1).join(',').trim()
        : '';
    return _Place(
      title: title,
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

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<_Place> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

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
          'q': q,
          'format': 'json',
          'countrycodes': 'uz',
          'viewbox': viewbox,
          'bounded': '1',
          'limit': '10',
          'accept-language': lang,
        },
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'MeningHamshiram/1.0 (flutter app)',
      }).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final items = list.map((e) => _Place.fromJson(e as Map<String, dynamic>)).toList();
        setState(() {
          _suggestions = items;
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _searchFocus.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: Text(
            'make_order'.tr,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 17.sp,
              letterSpacing: 0.3,
            ),
          ),
          centerTitle: true,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              margin: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 17.sp),
            ),
          ),
        ),
        body: Column(
          children: [
            // Map Area
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        ctrl.clientPosition?.latitude ?? 40.8147,
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

                  Positioned.fill(
                    child: IgnorePointer(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 16.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 56.sp),
                              child: Icon(
                                Icons.place_rounded,
                                size: 56.sp,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Field
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    right: 12.w,
                    child: Column(
                      children: [
                        Container(
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: 'Nunito',
                              color: AppColors.textDark,
                            ),
                            decoration: InputDecoration(
                              hintText: 'search_address_hint'.tr,
                              hintStyle: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textHint,
                                fontFamily: 'Nunito',
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: AppColors.primary,
                                size: 22.sp,
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
                                    _suggestions = [];
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

                        if (_showSuggestions) ...[
                          SizedBox(height: 6.h),
                          Container(
                            constraints: BoxConstraints(maxHeight: 200.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
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
                                        vertical: 10.h,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(6.w),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.location_on_rounded,
                                              color: AppColors.primary,
                                              size: 14.sp,
                                            ),
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
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: AppColors.textHint,
                                            size: 12.sp,
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

                  // My Location Button
                  Positioned(
                    right: 14.w,
                    bottom: 16.h,
                    child: GestureDetector(
                      onTap: _goToMyLocation,
                      child: Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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

            // Bottom Panel - REDESIGNED
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 12.h),
                      width: 48.w,
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
                            // Location Display - REDESIGNED
                            Container(
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primaryLight, AppColors.primaryLight.withOpacity(0.5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 16.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'selected_location'.tr,
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            color: AppColors.textLight,
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _selectedAddress.isEmpty
                                              ? 'location'.tr
                                              : _selectedAddress,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark,
                                            fontFamily: 'Nunito',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 20.sp,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24.h),

                            // Service Selection - REDESIGNED
                            Text(
                              'service_type'.tr,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            SizedBox(height: 12.h),

                            GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.selectService),
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18.r),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56.w,
                                      height: 56.w,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(14.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.2),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
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
                                              color: AppColors.textDark,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                          Text(
                                            'tap_to_select'.tr,
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: AppColors.textLight,
                                              fontFamily: 'Nunito',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(6.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: AppColors.primary,
                                        size: 16.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 20.h),
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