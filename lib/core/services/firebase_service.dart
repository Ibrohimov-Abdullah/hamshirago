import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/models.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;
  final _fcm  = FirebaseMessaging.instance;

  CollectionReference get _users      => _db.collection('users');
  CollectionReference get _orders     => _db.collection('orders');
  CollectionReference get _services   => _db.collection('services');
  CollectionReference get _nurses     => _db.collection('nurses');
  CollectionReference get _complaints => _db.collection('complaints');
  DocumentReference  get _settings   => _db.collection('admin_config').doc('settings');

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  // ── AUTH ──────────────────────────────────────────────────────────────────
  Future<void> sendOtp({required String phone, required Function(String) onCodeSent, required Function(String) onError, required Function(PhoneAuthCredential) onAutoVerified}) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone, timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: (e) => onError(e.message ?? 'Xatolik yuz berdi'),
      codeSent: (vid, _) => onCodeSent(vid),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential?> verifyOtp({required String verificationId, required String smsCode}) async {
    final cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
    return await _auth.signInWithCredential(cred);
  }

  Future<void> signOut() => _auth.signOut();

  // ── USERS ─────────────────────────────────────────────────────────────────
  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? UserModel.fromDoc(doc) : null;
  }
  Future<void> createUser(UserModel u) => _users.doc(u.uid).set(u.toMap());
  Future<void> updateFcmToken(String uid, String token) => _users.doc(uid).update({'fcmToken': token});
  Stream<UserModel?> userStream(String uid) => _users.doc(uid).snapshots().map((d) => d.exists ? UserModel.fromDoc(d) : null);

  // ── SERVICES ──────────────────────────────────────────────────────────────
  Future<List<ServiceModel>> getServices() async {
    final snap = await _services.where('isActive', isEqualTo: true).get();
    return snap.docs.map((d) => ServiceModel.fromDoc(d)).toList();
  }

  // ── ORDERS ────────────────────────────────────────────────────────────────
  Future<String> createOrder(OrderModel order) async {
    final ref = _orders.doc();
    final data = order.toMap();
    data['id'] = ref.id;
    await ref.set(data);
    return ref.id;
  }

  Stream<OrderModel?> orderStream(String id) => _orders.doc(id).snapshots().map((d) => d.exists ? OrderModel.fromDoc(d) : null);

  Stream<List<OrderModel>> clientOrdersStream(String clientId) => _orders
    .where('clientId', isEqualTo: clientId)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((s) => s.docs.map((d) => OrderModel.fromDoc(d)).toList());

  Future<void> cancelOrder(String id) => _orders.doc(id).update({'status': OrderStatus.cancelled.name});

  Future<void> rateOrder(String orderId, double rating) async {
    await _orders.doc(orderId).update({'rating': rating});
    final doc = await _orders.doc(orderId).get();
    final order = OrderModel.fromDoc(doc);
    if (order.nurseId != null) {
      final nurseDoc = await _nurses.doc(order.nurseId).get();
      if (nurseDoc.exists) {
        final d = nurseDoc.data() as Map<String, dynamic>;
        final total = (d['totalOrders'] as num?)?.toInt() ?? 0;
        final cur   = (d['rating'] as num?)?.toDouble() ?? 5.0;
        final updated = total > 0 ? ((cur * total) + rating) / (total + 1) : rating;
        await _nurses.doc(order.nurseId).update({'rating': double.parse(updated.toStringAsFixed(2))});
      }
    }
  }

  /// Real-time nurse GPS location — updates as nurse moves
  Stream<({double lat, double lng})?> nurseLocationStream(String nurseId) =>
      _nurses.doc(nurseId).snapshots().map((snap) {
        if (!snap.exists) return null;
        final d = snap.data() as Map<String, dynamic>;
        final loc = d['location'] as Map<String, dynamic>?;
        if (loc == null) return null;
        final lat = (loc['lat'] as num?)?.toDouble();
        final lng = (loc['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) return null;
        return (lat: lat, lng: lng);
      });

  // ── NURSES ────────────────────────────────────────────────────────────────
  Future<NurseModel?> getNurse(String id) async {
    final doc = await _nurses.doc(id).get();
    if (!doc.exists) return null;
    final nurse = NurseModel.fromDoc(doc);

    // Certificates are stored in subcollection nurses/{id}/certificates
    try {
      final snap = await _nurses.doc(id).collection('certificates').get();
      final items = snap.docs
          .map((d) {
            final url = (d.data()['fileUrl'] as String?) ?? '';
            final name = (d.data()['name'] as String?) ?? '';
            if (url.isEmpty) return null;
            return CertificateItem(url: url, name: name);
          })
          .whereType<CertificateItem>()
          .toList();
      if (items.isNotEmpty) {
        return NurseModel(
          id: nurse.id, name: nurse.name, surname: nurse.surname,
          phone: nurse.phone, rating: nurse.rating,
          totalOrders: nurse.totalOrders, isActive: nurse.isActive,
          certificates: items.map((e) => e.url).toList(),
          certificateItems: items,
        );
      }
    } catch (_) {}

    return nurse;
  }

  // ── COMPLAINTS ────────────────────────────────────────────────────────────
  Future<void> submitComplaint(ComplaintModel c) => _complaints.doc().set(c.toMap());

  // ── SETTINGS ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final doc = await _settings.get();
      if (doc.exists) return doc.data() as Map<String, dynamic>;
    } catch (_) {}
    return {'nurseCommissionPercent': 80};
  }

  // ── FCM ───────────────────────────────────────────────────────────────────
  Future<String?> getFcmToken() async {
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      return await _fcm.getToken();
    } catch (e) { log('FCM: $e'); return null; }
  }
  void onForegroundMessage(Function(dynamic) handler) => FirebaseMessaging.onMessage.listen(handler);
}
