import 'package:get/get.dart';
import '../../features/notification/views/notification_screen.dart';
import '../../features/splash/views/splash_screen.dart';
import '../../features/onboarding/views/language_screen.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/auth/views/auth_screens.dart';
import '../../features/home/views/main_screen.dart';
import '../../features/order/views/order_screen.dart';
import '../../features/order/views/select_service_screen.dart';
import '../../features/order/views/patient_info_screen.dart';
import '../../features/order/views/payment_screen.dart';
import '../../features/order/views/tracking_screen.dart';
import '../../features/order/views/nurse_certificates_screen.dart';
import '../../features/profile/views/complaint_screen.dart';

class AppRoutes {
  static const splash        = '/splash';
  static const language      = '/language';
  static const onboarding    = '/onboarding';
  static const login         = '/login';
  static const register      = '/register';
  static const otp           = '/otp';
  static const main          = '/main';
  static const order         = '/order';
  static const selectService = '/select-service';
  static const patientInfo   = '/patient-info';
  static const payment       = '/payment';
  static const orderTracking = '/order-tracking';
  static const orderComplete = '/order-complete';
  static const notifications = '/notifications';
  static const nurseCertificates = '/nurse-certificates';
  static const complaint         = '/complaint';

  static final pages = [
    GetPage(name: splash,        page: () => const SplashScreen()),
    GetPage(name: language,      page: () => const LanguageScreen()),
    GetPage(name: onboarding,    page: () => const OnboardingScreen()),
    GetPage(name: login,         page: () => const LoginScreen()),
    GetPage(name: register,      page: () => const RegisterScreen()),
    GetPage(name: otp,           page: () => const OtpScreen()),
    GetPage(name: main,          page: () => const MainScreen()),
    GetPage(name: order,         page: () => const OrderScreen()),
    GetPage(name: selectService, page: () => const SelectServiceScreen()),
    GetPage(name: patientInfo,   page: () => const PatientInfoScreen()),
    GetPage(name: payment,       page: () => const PaymentScreen()),
    GetPage(name: orderTracking, page: () => const OrderTrackingScreen()),
    GetPage(name: orderComplete, page: () => const OrderCompleteScreen()),
    GetPage(name: notifications, page: () => const NotificationScreen()),
    GetPage(name: nurseCertificates, page: () => const NurseCertificatesScreen()),
    GetPage(name: complaint,         page: () => const ComplaintScreen()),
  ];
}
