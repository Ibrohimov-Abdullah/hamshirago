import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mening_hamshiram/features/home/views/main_screen.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/app_routes.dart';

class ServiceSelection {
  final ServiceModel service;
  final RxBool isSelected = false.obs;
  final RxInt count = 0.obs;
  ServiceSelection(this.service);
  bool get hasValue => service.isCountable ? count.value > 0 : isSelected.value;
  int get quantity  => service.isCountable ? count.value : (isSelected.value ? 1 : 0);
  int get subtotal  => quantity * service.price;
}

class OrderController extends GetxController {
  final _fb  = FirebaseService.instance;
  final _loc = LocationService.instance;
  final _box = GetStorage();

  final RxList<ServiceSelection> selections = <ServiceSelection>[].obs;
  final RxBool servicesLoading = true.obs;
  final RxBool placing         = false.obs;
  final RxInt patientAge       = 25.obs;
  final RxString patientGender = ''.obs;
  final RxBool isNow           = true.obs;
  DateTime? scheduledAt;
  // Multi-day scheduling
  final RxList<DateTime> multiDayDates = <DateTime>[].obs;
  TimeOfDay? multiDayTime; // kept for backward compat
  final RxList<String> multiDayTimes = <String>[].obs; // list of "HH:mm" strings
  int timesPerDay = 1;
  final buildingCtrl  = TextEditingController();
  final entranceCtrl  = TextEditingController();
  final apartmentCtrl = TextEditingController();
  final commentCtrl   = TextEditingController();
  final Rx<PaymentMethod> paymentMethod = PaymentMethod.cash.obs;
  Position? clientPosition;
  double? pickedLat, pickedLng;
  final RxString addressText = 'Manzil aniqlanmoqda...'.obs;
  final Rx<OrderModel?> activeOrder = Rx(null);
  final RxString activeOrderId = ''.obs;
  final RxList<OrderModel> orderHistory = <OrderModel>[].obs;
  final RxInt completedOrdersCount = 0.obs;

  // 30% discount on every 6th order
  bool get isPromoEligible =>
      completedOrdersCount.value > 0 && completedOrdersCount.value % 6 == 5;
  int get discountedPrice =>
      isPromoEligible ? (totalPrice * 0.7).round() : totalPrice;

  // Alias used by PaymentScreen
  List<ServiceSelection> get selected => selectedServices;

  @override
  void onInit() {
    super.onInit();
    _loadServices();
    _loadLocation();
    _listenOrders();
    final saved = _box.read('active_order_id') as String?;
    if (saved != null && saved.isNotEmpty) { activeOrderId.value = saved; _listenActiveOrder(saved); }
  }

  Future<void> _loadServices() async {
    servicesLoading.value = true;
    try {
      final list = await _fb.getServices();
      selections.value = list.map((s) => ServiceSelection(s)).toList();
    } catch (_) {}
    servicesLoading.value = false;
  }

  Future<void> _loadLocation() async {
    try {
      clientPosition = await _loc.getCurrentPosition();
      if (clientPosition != null) {
        // Use actual coordinates for display
        final lat = clientPosition!.latitude;
        final lng = clientPosition!.longitude;
        // Simple region detection based on Uzbekistan coordinates
        if (lat >= 41.0 && lat <= 41.6 && lng >= 68.8 && lng <= 69.8) {
          addressText.value = 'Toshkent shahri';
        } else if (lat >= 39.5 && lat <= 40.2 && lng >= 66.7 && lng <= 67.5) {
          addressText.value = 'Samarqand shahri';
        } else if (lat >= 39.7 && lat <= 40.2 && lng >= 64.2 && lng <= 65.0) {
          addressText.value = 'Buxoro shahri';
        } else if (lat >= 40.3 && lat <= 41.0 && lng >= 71.5 && lng <= 72.5) {
          addressText.value = 'Farg\'ona shahri';
        } else if (lat >= 40.0 && lat <= 41.0 && lng >= 65.0 && lng <= 66.0) {
          addressText.value = 'Navoiy shahri';
        } else {
          addressText.value = 'Joylashuv aniqlandi';
        }
      } else {
        addressText.value = 'Joylashuv topilmadi';
      }
    } catch (e) {
      addressText.value = 'Joylashuv xatosi';
    }
  }

  void _listenOrders() {
    final uid = _box.read('user_uid') as String?;
    if (uid == null) return;
    _fb.clientOrdersStream(uid).listen((l) {
      orderHistory.value = l;
      completedOrdersCount.value =
          l.where((o) => o.status == OrderStatus.completed).length;
    });
  }

  void _listenActiveOrder(String id) {
    _fb.orderStream(id).listen((order) {
      activeOrder.value = order;
      if (order == null) return;
      if (order.status == OrderStatus.completed) {
        _box.remove('active_order_id');
        Get.toNamed(AppRoutes.orderComplete, arguments: order);
      } else if (order.status == OrderStatus.cancelled) {
        _box.remove('active_order_id');
        activeOrderId.value = '';
        activeOrder.value   = null;
      }
    });
  }

  int get totalPrice => selections.fold(0, (s, x) => s + x.subtotal);
  List<ServiceSelection> get selectedServices => selections.where((s) => s.hasValue).toList();

  void setPickedLocation(double lat, double lng) {
    pickedLat = lat;
    pickedLng = lng;
    addressText.value = 'Tanlangan manzil (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  void toggleService(int i, bool val) => selections[i].isSelected.value = val;
  void increment(int i) => selections[i].count.value++;
  void decrement(int i) { if (selections[i].count.value > 0) selections[i].count.value--; }

  Future<void> placeOrder() async {
    final uid   = _box.read('user_uid')   as String? ?? '';
    final name  = _box.read('user_name')  as String? ?? '';
    final phone = _box.read('user_phone') as String? ?? '';
    if (selectedServices.isEmpty) return;
    if (buildingCtrl.text.trim().isEmpty) {
      Get.snackbar('Xato', 'Uy raqamini kiriting',
        backgroundColor: const Color(0xFFEF4444).withOpacity(0.9),
        colorText: const Color(0xFFFFFFFF), snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16));
      return;
    }
    placing.value = true;
    try {
      final address = OrderAddress(
        text: addressText.value,
        lat: pickedLat ?? clientPosition?.latitude ?? 41.2995,
        lng: pickedLng ?? clientPosition?.longitude ?? 69.2401,
        building: buildingCtrl.text.trim(), entrance: entranceCtrl.text.trim(),
        apartment: apartmentCtrl.text.trim(),
        comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
      );
      final svcs = selectedServices.map((s) => OrderService(
        id: s.service.id, name: s.service.name, nameRu: s.service.nameRu,
        price: s.service.price, quantity: s.quantity,
      )).toList();
      final mdTimes = multiDayTimes.toList();
      final promoApplied = isPromoEligible;
      final finalPrice = promoApplied ? discountedPrice : totalPrice;
      final order = OrderModel(
        id: '', clientId: uid, clientName: name, clientPhone: phone,
        services: svcs, totalPrice: finalPrice, status: OrderStatus.pending,
        paymentMethod: paymentMethod.value, address: address,
        patientAge: patientAge.value, patientGender: patientGender.value,
        isNow: isNow.value, scheduledAt: scheduledAt,
        multiDayDates: multiDayDates.toList(),
        multiDayTimes: mdTimes,
        multiDayTime: mdTimes.isNotEmpty ? mdTimes.first : null,
        createdAt: DateTime.now(),
      );
      final orderId = await _fb.createOrder(order);
      _box.write('active_order_id', orderId);
      activeOrderId.value = orderId;
      _listenActiveOrder(orderId);
      for (final s in selections) { s.isSelected.value = false; s.count.value = 0; }
      buildingCtrl.clear(); entranceCtrl.clear(); apartmentCtrl.clear(); commentCtrl.clear();
      multiDayDates.clear(); multiDayTime = null; multiDayTimes.clear(); timesPerDay = 1; scheduledAt = null; isNow.value = true;
      Get.offAllNamed(AppRoutes.orderTracking, arguments: {'orderId': orderId});
    } finally { placing.value = false; }
  }

  Future<void> cancelOrder(String id) async {
    await _fb.cancelOrder(id);
    _box.remove('active_order_id');
    activeOrderId.value = '';
    activeOrder.value   = null;
    Get.offAll(const MainScreen());
  }

  Future<void> rateOrder(String id, double rating) => _fb.rateOrder(id, rating);


}
