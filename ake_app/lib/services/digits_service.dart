import 'dart:convert';
import 'package:http/http.dart' as http;

class DigitsApiException implements Exception {
  final String message;
  const DigitsApiException(this.message);
  @override
  String toString() => message;
}

class DigitsService {
  static const base = 'https://www.ake-forging.com/wp-json';
  final http.Client client;
  DigitsService({http.Client? client}) : client = client ?? http.Client();

  static String normalize(String input) {
    var s = input.trim();
    const fa = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }
    s = s.replaceAll(RegExp(r'[\s-]'), '');
    if (s.startsWith('+98')) {
      s = s.substring(3);
    } else if (s.startsWith('0098')) {
      s = s.substring(4);
    } else if (s.startsWith('0')) {
      s = s.substring(1);
    }
    if (!RegExp(r'^9[0-9]{9}$').hasMatch(s)) {
      throw const DigitsApiException('شماره موبایل باید به صورت ۰۹۱۲۳۴۵۶۷۸۹ باشد.');
    }
    return s;
  }

  static String _message(Map<String, dynamic> body, int httpStatus) {
    final data = body['data'];
    if (data is Map) {
      for (final key in ['message', 'msg', 'error']) {
        if (data[key] is String && (data[key] as String).trim().isNotEmpty) return data[key] as String;
      }
    }
    for (final key in ['message', 'msg']) {
      if (body[key] is String && (body[key] as String).trim().isNotEmpty) return body[key] as String;
    }
    if (httpStatus == 403 || httpStatus == 401) {
      return 'سرور اجازه دسترسی به ورود را نداد (HTTP $httpStatus).';
    }
    return 'سرویس ورود پاسخ ناموفق داد (HTTP $httpStatus).';
  }

  Future<Map<String, dynamic>> request(String path, Map<String, String> body, {String? token}) async {
    final http.Response response;
    try {
      response = await client.post(
        Uri.parse('$base/digits/v1/$path/'),
        headers: <String, String>{
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const DigitsApiException('ارتباط با سرور پیامک برقرار نشد؛ اتصال اینترنت را بررسی کنید.');
    }
    dynamic parsed;
    try {
      parsed = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const DigitsApiException('پاسخ سرور Digits به‌صورت JSON معتبر دریافت نشد.');
    }
    if (parsed is! Map<String, dynamic>) {
      throw const DigitsApiException('ساختار پاسخ Digits معتبر نیست.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || parsed['success'] == false) {
      throw DigitsApiException(_message(parsed, response.statusCode));
    }
    return parsed;
  }

  Future<void> sendOtp(String phone, {bool register = false, bool resend = false}) async {
    final response = await request(resend ? 'resend_otp' : 'send_otp', {
      'countrycode': '+98',
      'mobileNo': normalize(phone),
      'type': register ? 'register' : 'login',
    });
    // Digits OTP endpoints use code=1; some configured gateways return success=true.
    final code = response['code']?.toString();
    if (code != '1' && response['success'] != true) {
      throw DigitsApiException(_message(response, 200));
    }
  }

  Future<String> authenticate(String phone, {String? otp, String? password, bool register = false, String name = ''}) async {
    final number = normalize(phone);
    if ((otp == null || otp.trim().isEmpty) && (password == null || password.isEmpty)) {
      throw const DigitsApiException('کد یک‌بارمصرف یا رمز عبور را وارد کنید.');
    }
    final response = await request(register ? 'create_user' : 'login_user', {
      if (register) ...{
        'digits_reg_mobile': number,
        'digits_reg_countrycode': '+98',
        'digits_reg_name': name.trim(),
        'digits_reg_firstname': name.trim(),
      } else ...{
        'user': number,
        'countrycode': '+98',
      },
      if (otp != null && otp.trim().isNotEmpty) 'otp': otp.trim(),
      if (password != null && password.isNotEmpty) 'password': password,
      'type': register ? 'register' : 'login',
    });
    final data = response['data'];
    if (response['success'] != true || data is! Map ||
        data['access_token'] is! String || (data['access_token'] as String).isEmpty) {
      throw DigitsApiException(_message(response, 200));
    }
    return data['access_token'] as String;
  }

  Future<void> logout(String token) async {
    await request('logout', {}, token: token);
  }

  void dispose() => client.close();
}
