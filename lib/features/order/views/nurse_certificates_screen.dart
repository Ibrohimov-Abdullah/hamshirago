import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';

class NurseCertificatesScreen extends StatefulWidget {
  const NurseCertificatesScreen({super.key});

  @override
  State<NurseCertificatesScreen> createState() => _NurseCertificatesScreenState();
}

class _NurseCertificatesScreenState extends State<NurseCertificatesScreen> {
  final String nurseId = Get.arguments as String? ?? '';
  NurseModel? _nurse;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final nurse = await FirebaseService.instance.getNurse(nurseId);
      if (mounted) setState(() { _nurse = nurse; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
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
        title: Text(
          'nurse_info_title'.tr,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 17.sp,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? _buildShimmer()
          : _error != null
          ? _buildError()
          : _nurse == null
          ? _buildEmpty()
          : _buildContent(),
    );
  }

  Widget _buildShimmer() => const Center(child: CircularProgressIndicator());

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, color: AppColors.textLight, size: 48.sp),
        SizedBox(height: 12.h),
        Text(
          'error_occurred'.tr,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15.sp,
            color: AppColors.textLight,
          ),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_off_rounded, color: AppColors.textLight, size: 48.sp),
        SizedBox(height: 12.h),
        Text(
          'info_not_found'.tr,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15.sp,
            color: AppColors.textLight,
          ),
        ),
      ],
    ),
  );

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Profile Card - REDESIGNED
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 68.w,
                  height: 68.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _nurse!.fullName.isNotEmpty ? _nurse!.fullName[0].toUpperCase() : 'N',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nurse!.fullName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Colors.white, size: 14.sp),
                            SizedBox(width: 4.w),
                            Text(
                              _nurse!.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '(${_nurse!.totalOrders} ${'order_count_suffix'.tr})',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white.withOpacity(0.7),
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Certificates Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.folder_rounded, color: AppColors.primary, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Text(
                'certificates'.tr,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontFamily: 'Nunito',
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${_nurse!.certificateItems.length}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          if (_nurse!.certificateItems.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_open_rounded, color: AppColors.textHint, size: 48.sp),
                  SizedBox(height: 12.h),
                  Text(
                    'no_certificates'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textLight,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.85,
              ),
              itemCount: _nurse!.certificateItems.length,
              itemBuilder: (_, i) {
                final item = _nurse!.certificateItems[i];
                return item.isPdf
                    ? _PdfTile(item: item)
                    : _ImageTile(item: item);
              },
            ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final CertificateItem item;
  const _ImageTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullImage(item.url),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item.url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                  color: AppColors.background,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.background,
                  child: Center(
                    child: Icon(Icons.broken_image_rounded, color: AppColors.textHint, size: 32.sp),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    ),
                  ),
                  child: Text(
                    item.name.isNotEmpty ? item.name : 'Sertifikat',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                top: 8.w,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.zoom_in_rounded,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullImage(String url) {
    Get.dialog(
      GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          color: Colors.black87,
          child: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
      barrierColor: Colors.black87,
    );
  }
}

class _PdfTile extends StatelessWidget {
  final CertificateItem item;
  const _PdfTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          await launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication);
        } catch (_) {
          try {
            await launchUrl(Uri.parse(item.url), mode: LaunchMode.inAppWebView);
          } catch (e) {
            Get.snackbar('err_title'.tr, 'err_file_open'.tr,
              backgroundColor: Colors.red.withOpacity(0.9),
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                color: const Color(0xFFDC2626),
                size: 30.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              item.name.isNotEmpty ? item.name : 'Sertifikat.pdf',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                fontFamily: 'Nunito',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 10.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}