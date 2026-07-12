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

  // ── Demo account for App Store review ────────────────────────────────────
  static const _demoPhone = '+998911234567';
  static const _demoOtp   = '554433';

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
      _err('err_title'.tr, 'err_invalid_phone'.tr);
      return;
    }

    if (isRegister &&
        (firstCtrl.text.trim().isEmpty || lastCtrl.text.trim().isEmpty)) {
      _err('err_title'.tr, 'err_enter_name'.tr);
      return;
    }

    // Format phone number
    final fmtPhone = phone.startsWith('+')
        ? phone.replaceAll(' ', '')          // strip spaces: "+998 91..." → "+998911..."
        : '+998${phone.replaceAll(RegExp(r'\D'), '')}';

    phoneNumber.value = fmtPhone;

    isLoading.value = true;

    try {
      // Demo bypass for App Store review — skip SMS, accept fixed OTP
      if (fmtPhone == _demoPhone) {
        _generatedOtp  = _demoOtp;
        _otpTimestamp  = DateTime.now().millisecondsSinceEpoch;
        isRegistering.value = isRegister;
        _startTimer();
        Get.toNamed(AppRoutes.otp);
        return;
      }

      final otp = _eskiz.generateOtp();

      await _eskiz.sendOtp(fmtPhone, otp);

      // Save for verification
      _generatedOtp = otp;
      _otpTimestamp = DateTime.now().millisecondsSinceEpoch;

      isRegistering.value = isRegister;

      _startTimer();
      Get.toNamed(AppRoutes.otp);

    } catch (e) {
      _err('err_title'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final code = otpCtrl.text.trim();
    if (code.length != 6) {
      _err('err_title'.tr, 'err_enter_6_code'.tr);
      return;
    }

    if (_generatedOtp == null || _otpTimestamp == null) {
      _err('err_title'.tr, 'err_code_expired'.tr);
      return;
    }

    // Check expiry
    if (DateTime.now().millisecondsSinceEpoch - _otpTimestamp! > _otpExpiryMs) {
      _err('err_title'.tr, 'err_code_expired'.tr);
      _clearOtp();
      return;
    }

    // Verify OTP
    if (code != _generatedOtp) {
      _err('err_title'.tr, 'err_wrong_code'.tr);
      return;
    }

    isLoading.value = true;


    try {
      await _authenticateUser();
    } catch (e) {
      _err('err_title'.tr, e.toString());
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

    // Demo account: auto-create if not exists
    if (phone == _demoPhone) {
      var user = await _fb.getUser(uid);
      if (user == null) {
        user = UserModel(uid: uid, name: 'Demo', surname: 'User', phone: phone, createdAt: DateTime.now());
        await _fb.createUser(user);
      }
      _saveSession(uid, user.name, user.phone);
    } else if (isRegistering.value) {
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
        _err('err_title'.tr, 'err_not_registered'.tr);
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

  // ── DELETE ACCOUNT (Apple Guideline 5.1.1(v) requirement) ───────────────────
  Future<void> deleteAccount() async {
    isLoading.value = true;
    try {
      final uid = _box.read('user_uid') as String?;
      if (uid != null && uid.isNotEmpty) {
        await _fb.deleteAccount(uid);
      }
      _box.erase();
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'account_deleted_title'.tr,
        'account_deleted_msg'.tr,
        backgroundColor: const Color(0xFF10B981).withOpacity(0.95),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _err('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
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