import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class EskizService {
  static const String _baseUrl = 'https://notify.eskiz.uz';
  static const String _email = 'abdulloibrohimov3@gmail.com';
  static const String _password = '8yQMotABF4vXwXI2RvXK0WhGUTx7Fiv6PP2zvc5L';
  static const String _senderId = '4546'; // Your Sender ID

  final GetStorage _box = GetStorage();
  String? _cachedToken;
  int? _tokenExpiry;

  Future<String> _getToken() async {
    // Return cached token if still valid
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().millisecondsSinceEpoch < _tokenExpiry!) {
      return _cachedToken!;
    }

    final url = Uri.parse('$_baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _email, 'password': _password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Eskiz auth failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final token = data['data']['token'];

    // Token is valid for ~30 days, but we cache for 23 hours for safety
    _tokenExpiry = DateTime.now().millisecondsSinceEpoch + 23 * 60 * 60 * 1000;
    _cachedToken = token;

    // Optional: save token persistently
    _box.write('eskiz_token', token);
    _box.write('eskiz_token_expiry', _tokenExpiry);

    return token;
  }

  /// Sends real OTP (works when your Eskiz account is out of test mode)
  Future<void> sendOtp(String phoneNumber, String otp) async {
    final token = await _getToken();
    final url = Uri.parse('$_baseUrl/api/message/sms/send');

    // final message = "Sizning tasdiqlash kodingiz: $otp\nEskiz test emas!";

    final message = "MeningHamshiram ilovasiga kirish uchun tasdiqlash kodi: $otp. Hech kimga bermang.";


    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mobile_phone': phoneNumber,
        'message': message,
        'from': _senderId,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception('SMS yuborilmadi: ${error['message'] ?? response.body}');
    }
  }

  /// Generate 6-digit OTP
  String generateOtp() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10).toString()).join();
  }
}