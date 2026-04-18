import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mening_hamshiram/features/auth/controllers/auth_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_routes.dart';
import 'core/constants/app_strings.dart';

@pragma('vm:entry-point')
Future<void> _bgFcm(RemoteMessage message) async =>
    await Firebase.initializeApp();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_bgFcm);
  await GetStorage.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Get.put(AuthController());
  runApp(const MeningHamshiramApp());
}

class MeningHamshiramApp extends StatelessWidget {
  const MeningHamshiramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, __) => GetMaterialApp(
        title: 'Mening Hamshiram',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: Locale(GetStorage().read('language') ?? 'uz'),
        fallbackLocale: const Locale('uz'),
        initialRoute: _initialRoute(),
        getPages: AppRoutes.pages,
      ),
    );
  }

  String _initialRoute() {
    final box = GetStorage();
    final uid = box.read('user_uid') as String?;
    if (uid != null && uid.isNotEmpty) return AppRoutes.main;
    if (box.read('has_seen_onboarding') == true) return AppRoutes.login;
    return AppRoutes.splash;
  }
}
