import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/eskiz_service.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/app_routes.dart';

class AuthController extends GetxController {
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }
  final _fb = FirebaseService.instance;
  final _eskiz = EskizService();
  final _box = GetStorage();

  // Controllers
  final phoneCtrl = TextEditingController(text: '+998 ');
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final otpCtrl = TextEditingController();

  // Reactive
  final RxBool isLoading = false.obs;
  final RxBool isRegistering = false.obs;
  final RxString phoneNumber = ''.obs;
  final RxInt resendSeconds = 0.obs;

  // OTP storage
  String? _generatedOtp;
  int? _otpTimestamp;
  static const int _otpExpiryMs = 5 * 60 * 1000; // 5 minutes

  void _startTimer() {
    resendSeconds.value = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (resendSeconds.value > 0) resendSeconds.value--;
      return resendSeconds.value > 0;
    });
  }

  Future<void> sendOtp({required bool isRegister}) async {
    final phone = phoneCtrl.text.trim();
    if (phone.length < 10) {
      _err('Xato', 'To\'g\'ri telefon raqamini kiriting');
      return;
    }

    if (isRegister &&
        (firstCtrl.text.trim().isEmpty || lastCtrl.text.trim().isEmpty)) {
      _err('Xato', 'Ism va familiyani kiriting');
      return;
    }

    // Format phone number
    final fmtPhone = phone.startsWith('+')
        ? phone
        : '+998${phone.replaceAll(RegExp(r'\D'), '')}';

    phoneNumber.value = fmtPhone;

    isLoading.value = true;

    try {
      final otp = _eskiz.generateOtp();

      await _eskiz.sendOtp(fmtPhone, otp);

      // Save for verification
      _generatedOtp = otp;
      _otpTimestamp = DateTime.now().millisecondsSinceEpoch;

      isRegistering.value = isRegister;

      _startTimer();
      Get.toNamed(AppRoutes.otp);

    } catch (e) {
      _err('Xato', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final code = otpCtrl.text.trim();
    if (code.length != 6) {
      _err('Xato', '6 raqamli kodni kiriting');
      return;
    }

    if (_generatedOtp == null || _otpTimestamp == null) {
      _err('Xato', 'Kod muddati tugagan. Qayta yuboring');
      return;
    }

    // Check expiry
    if (DateTime.now().millisecondsSinceEpoch - _otpTimestamp! > _otpExpiryMs) {
      _err('Xato', 'Kod muddati tugagan. Qayta yuboring');
      _clearOtp();
      return;
    }

    // Verify OTP
    if (code != _generatedOtp) {
      _err('Xato', "Noto'g'ri kod");
      return;
    }

    isLoading.value = true;

    try {
      await _authenticateUser();
    } catch (e) {
      _err('Xato', e.toString());
    } finally {
      isLoading.value = false;
      _clearOtp();
    }
  }

  void _clearOtp() {
    _generatedOtp = null;
    _otpTimestamp = null;
    otpCtrl.clear();
  }

  Future<void> _authenticateUser() async {
    final phone = phoneNumber.value;
    final uid = phone; // Using phone as UID

    if (isRegistering.value) {
      final user = UserModel(
        uid: uid,
        name: firstCtrl.text.trim(),
        surname: lastCtrl.text.trim(),
        phone: phone,
        createdAt: DateTime.now(),
      );
      await _fb.createUser(user);
      _saveSession(uid, user.name, user.phone);
    } else {
      final user = await _fb.getUser(uid);
      if (user == null) {
        _err('Xato', "Bu raqam ro'yxatdan o'tmagan");
        Get.offAllNamed(AppRoutes.register);
        return;
      }
      _saveSession(uid, user.name, user.phone);
    }

    // Update FCM token if available
    final token = await _fb.getFcmToken();
    if (token != null) await _fb.updateFcmToken(uid, token);

    Get.offAllNamed(AppRoutes.main);
  }

  void _saveSession(String uid, String name, String phone) {
    _box.write('user_uid', uid);
    _box.write('user_name', name);
    _box.write('user_phone', phone);
  }

  Future<void> signOut() async {
    await _fb.signOut();
    _box.erase();
    Get.offAllNamed(AppRoutes.login);
  }

  void _err(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFFEF4444).withOpacity(0.95),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }
}