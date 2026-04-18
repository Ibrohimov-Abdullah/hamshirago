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
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 17.sp),
          ),
        ),
        title: Text('Hamshira ma\'lumotlari', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16.sp)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Xatolik yuz berdi', style: TextStyle(fontFamily: 'Nunito', fontSize: 15.sp, color: AppColors.textLight)))
              : _nurse == null
                  ? Center(child: Text('Ma\'lumot topilmadi', style: TextStyle(fontFamily: 'Nunito', fontSize: 15.sp, color: AppColors.textLight)))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nurse profile card
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60.w,
                                  height: 60.w,
                                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                                  child: Icon(Icons.person_rounded, color: Colors.white, size: 30.sp),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_nurse!.fullName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Nunito')),
                                      SizedBox(height: 4.h),
                                      Row(
                                        children: [
                                          Icon(Icons.star_rounded, color: const Color(0xFFF59E0B), size: 16.sp),
                                          SizedBox(width: 4.w),
                                          Text(_nurse!.rating.toStringAsFixed(1), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textMedium, fontFamily: 'Nunito')),
                                          SizedBox(width: 8.w),
                                          Text('(${_nurse!.totalOrders} buyurtma)', style: TextStyle(fontSize: 12.sp, color: AppColors.textLight, fontFamily: 'Nunito')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24.h),

                          Text('Sertifikatlar', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: AppColors.textDark, fontFamily: 'Nunito')),
                          SizedBox(height: 12.h),

                          if (_nurse!.certificateItems.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16.r)),
                              child: Column(
                                children: [
                                  Icon(Icons.folder_open_rounded, color: AppColors.textLight, size: 40.sp),
                                  SizedBox(height: 10.h),
                                  Text('Sertifikatlar yuklanmagan', style: TextStyle(fontSize: 14.sp, color: AppColors.textLight, fontFamily: 'Nunito')),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _nurse!.certificateItems.length,
                              separatorBuilder: (_, __) => SizedBox(height: 12.h),
                              itemBuilder: (_, i) {
                                final item = _nurse!.certificateItems[i];
                                return item.isPdf
                                    ? _PdfTile(item: item)
                                    : _ImageTile(item: item);
                              },
                            ),
                          SizedBox(height: 40.h),
                        ],
                      ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Image.network(
          item.url,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  height: 200.h,
                  color: AppColors.background,
                  child: const Center(child: CircularProgressIndicator()),
                ),
          errorBuilder: (_, __, ___) => Container(
            height: 120.h,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14.r)),
            child: Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textLight, size: 32.sp)),
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
            Get.snackbar('Xato', 'Faylni ochib bo\'lmadi',
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.picture_as_pdf_rounded, color: const Color(0xFFE53E3E), size: 26.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.isNotEmpty ? item.name : 'Sertifikat.pdf',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textDark, fontFamily: 'Nunito'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  Text('Ko\'rish uchun bosing', style: TextStyle(fontSize: 11.sp, color: AppColors.primary, fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 18.sp),
          ],
        ),
      ),
    );
  }
}
