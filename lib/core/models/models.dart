import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

// ─── User ───────────────────────────────────────────────────────────────────
class UserModel {
  final String uid, name, surname, phone;
  final bool isActive;
  final String? fcmToken;
  final DateTime createdAt;
  const UserModel({required this.uid, required this.name, required this.surname, required this.phone, this.isActive = true, this.fcmToken, required this.createdAt});
  String get fullName => '$name $surname';
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(uid: doc.id, name: d['name']??'', surname: d['surname']??'', phone: d['phone']??'', isActive: d['isActive']??true, fcmToken: d['fcmToken'], createdAt: (d['createdAt'] as Timestamp?)?.toDate()??DateTime.now());
  }
  Map<String, dynamic> toMap() => {'name':name,'surname':surname,'phone':phone,'isActive':isActive,'fcmToken':fcmToken,'createdAt':Timestamp.fromDate(createdAt)};
}

// ─── Order ──────────────────────────────────────────────────────────────────
enum OrderStatus { pending, searching, accepted, enRoute, arrived, completed, cancelled }
enum PaymentMethod { cash, payme, click }

class OrderService {
  final String id, name, nameRu;
  final int price, quantity;
  const OrderService({required this.id, required this.name, required this.nameRu, required this.price, required this.quantity});
  int get total => price * quantity;
  factory OrderService.fromMap(Map<String, dynamic> m) => OrderService(id: m['id']??'', name: m['name']??'', nameRu: m['nameRu']??'', price: m['price']??0, quantity: m['quantity']??1);
  Map<String, dynamic> toMap() => {'id':id,'name':name,'nameRu':nameRu,'price':price,'quantity':quantity};
}

class OrderAddress {
  final String text, building, entrance, apartment;
  final double lat, lng;
  final String? comment;
  const OrderAddress({required this.text, required this.building, required this.entrance, required this.apartment, required this.lat, required this.lng, this.comment});
  factory OrderAddress.fromMap(Map<String, dynamic> m) => OrderAddress(text: m['text']??'', building: m['building']??'', entrance: m['entrance']??'', apartment: m['apartment']??'', lat: (m['lat']??0.0).toDouble(), lng: (m['lng']??0.0).toDouble(), comment: m['comment']);
  Map<String, dynamic> toMap() => {'text':text,'building':building,'entrance':entrance,'apartment':apartment,'lat':lat,'lng':lng,'comment':comment};
}

class OrderModel {
  final String id, clientId, clientName, clientPhone;
  final String? nurseId, nurseName;
  final List<OrderService> services;
  final int totalPrice;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final bool isPaid;
  final OrderAddress address;
  final int patientAge;
  final String patientGender;
  final bool isNow;
  final DateTime? scheduledAt;
  final List<DateTime> multiDayDates;
  final String? multiDayTime; // "HH:mm" — kept for backward compat
  final List<String> multiDayTimes; // list of "HH:mm" strings (one per time slot)
  final List<String> rejectedBy;
  final double? rating;
  final DateTime createdAt;
  final DateTime? acceptedAt, completedAt;

  const OrderModel({required this.id, required this.clientId, required this.clientName, required this.clientPhone, this.nurseId, this.nurseName, required this.services, required this.totalPrice, required this.status, required this.paymentMethod, this.isPaid = false, required this.address, required this.patientAge, this.patientGender = '', this.isNow = true, this.scheduledAt, this.multiDayDates = const [], this.multiDayTime, this.multiDayTimes = const [], this.rejectedBy = const [], this.rating, required this.createdAt, this.acceptedAt, this.completedAt});

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:   return 'status_pending'.tr;
      case OrderStatus.searching: return 'status_searching'.tr;
      case OrderStatus.accepted:  return 'status_accepted'.tr;
      case OrderStatus.enRoute:   return 'status_en_route'.tr;
      case OrderStatus.arrived:   return 'status_arrived'.tr;
      case OrderStatus.completed: return 'status_completed'.tr;
      case OrderStatus.cancelled: return 'status_cancelled'.tr;
    }
  }

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id, clientId: d['clientId']??'', clientName: d['clientName']??'', clientPhone: d['clientPhone']??'',
      nurseId: d['nurseId'], nurseName: d['nurseName'],
      services: (d['services'] as List? ?? []).map((s) => OrderService.fromMap(s as Map<String, dynamic>)).toList(),
      totalPrice: d['totalPrice']??0,
      status: OrderStatus.values.firstWhere((s) => s.name == (d['status']??'pending'), orElse: () => OrderStatus.pending),
      paymentMethod: PaymentMethod.values.firstWhere((p) => p.name == (d['paymentMethod']??'cash'), orElse: () => PaymentMethod.cash),
      isPaid: d['isPaid']??false,
      address: OrderAddress.fromMap(d['address'] as Map<String, dynamic>? ?? {}),
      patientAge: d['patientAge']??25, patientGender: d['patientGender']??'',
      isNow: d['isNow']??true, scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate(),
      multiDayDates: ((d['multiDayDates'] as List?) ?? []).map((e) => (e as Timestamp).toDate()).toList(),
      multiDayTime: d['multiDayTime'] as String?,
      multiDayTimes: List<String>.from(d['multiDayTimes'] ?? [d['multiDayTime'] ?? ''].where((s) => (s as String).isNotEmpty).toList()),
      rejectedBy: List<String>.from(d['rejectedBy']??[]), rating: (d['rating'] as num?)?.toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate()??DateTime.now(),
      acceptedAt: (d['acceptedAt'] as Timestamp?)?.toDate(), completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'clientId':clientId,'clientName':clientName,'clientPhone':clientPhone,'nurseId':nurseId,'nurseName':nurseName,
    'services':services.map((s)=>s.toMap()).toList(),'totalPrice':totalPrice,'status':status.name,'paymentMethod':paymentMethod.name,
    'isPaid':isPaid,'address':address.toMap(),'patientAge':patientAge,'patientGender':patientGender,'isNow':isNow,
    'scheduledAt':scheduledAt!=null?Timestamp.fromDate(scheduledAt!):null,
    'multiDayDates':multiDayDates.map((d)=>Timestamp.fromDate(d)).toList(),
    'multiDayTime':multiDayTime,
    'multiDayTimes':multiDayTimes,
    'rejectedBy':rejectedBy,'rating':rating,
    'createdAt':Timestamp.fromDate(createdAt),'acceptedAt':acceptedAt!=null?Timestamp.fromDate(acceptedAt!):null,'completedAt':completedAt!=null?Timestamp.fromDate(completedAt!):null,
  };
}

// ─── Certificate ────────────────────────────────────────────────────────────
class CertificateItem {
  final String url;
  final String name;
  CertificateItem({required this.url, required this.name});
  bool get isPdf => name.toLowerCase().endsWith('.pdf');
}

// ─── Nurse ──────────────────────────────────────────────────────────────────
class NurseModel {
  final String id, name, surname, phone;
  final double rating;
  final int totalOrders;
  final List<String> certificates;
  final List<CertificateItem> certificateItems;
  final bool isActive;

  const NurseModel({required this.id, required this.name, required this.surname, required this.phone, this.rating = 5.0, this.totalOrders = 0, this.certificates = const [], this.certificateItems = const [], this.isActive = true});

  String get fullName => '$name $surname';

  factory NurseModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NurseModel(
      id: doc.id,
      name: d['name'] ?? '',
      surname: d['surname'] ?? '',
      phone: d['phone'] ?? '',
      rating: (d['rating'] as num?)?.toDouble() ?? 5.0,
      totalOrders: (d['totalOrders'] as num?)?.toInt() ?? 0,
      certificates: List<String>.from(d['certificates'] ?? []),
      isActive: d['isActive'] ?? true,
    );
  }
}

// ─── Complaint ──────────────────────────────────────────────────────────────
class ComplaintModel {
  final String id, userId, userPhone, userName, message;
  final DateTime createdAt;
  const ComplaintModel({required this.id, required this.userId, required this.userPhone, required this.userName, required this.message, required this.createdAt});
  Map<String, dynamic> toMap() => {'userId':userId,'userPhone':userPhone,'userName':userName,'message':message,'createdAt':Timestamp.fromDate(createdAt),'isRead':false};
  factory ComplaintModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ComplaintModel(id: doc.id, userId: d['userId']??'', userPhone: d['userPhone']??'', userName: d['userName']??'', message: d['message']??'', createdAt: (d['createdAt'] as Timestamp?)?.toDate()??DateTime.now());
  }
}

// ─── Service ────────────────────────────────────────────────────────────────
class ServiceModel {
  final String id, name, nameRu;
  final int price;
  final bool isCountable, isActive;
  const ServiceModel({required this.id, required this.name, required this.nameRu, required this.price, required this.isCountable, this.isActive = true});
  String localName(String lang) => lang == 'ru' ? nameRu : name;
  factory ServiceModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ServiceModel(id: doc.id, name: d['name']??'', nameRu: d['nameRu']??d['name']??'', price: d['price']??0, isCountable: d['isCountable']??false, isActive: d['isActive']??true);
  }
}
