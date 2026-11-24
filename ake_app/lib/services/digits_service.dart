import 'dart:convert';
import 'package:http/http.dart' as http;

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
    if (s.startsWith('+98')) s = s.substring(3);
    else if (s.startsWith('0098')) s = s.substring(4);
    else if (s.startsWith('0')) s = s.substring(1);
    if (!RegExp(r'^9[0-9]{9}$').hasMatch(s)) {
      throw const FormatException('شماره موبایل معتبر نیست');
    }
    return s;
  }

  Future<Map<String, dynamic>> request(String path, Map<String,String> body, {String? token}) async {
    final r = await client.post(Uri.parse('$base/digits/v1/$path/'),
      headers: {'Accept':'application/json', if(token != null) 'Authorization':'Bearer $token'},
      body: body).timeout(const Duration(seconds: 25));
    final value = jsonDecode(utf8.decode(r.bodyBytes));
    if (value is! Map<String,dynamic>) throw const FormatException('پاسخ نامعتبر سرور');
    if (r.statusCode >= 400 || value['success'] == false) {
      final data = value['data'];
      throw Exception(data is Map ? (data['message'] ?? data['msg'] ?? 'خطای احراز هویت') : 'خطای احراز هویت');
    }
    return value;
  }

  Future<void> sendOtp(String phone, {bool register = false, bool resend = false}) async {
    final r = await request(resend ? 'resend_otp' : 'send_otp', {
      'countrycode': '+98', 'mobileNo': normalize(phone), 'type': register ? 'register' : 'login',
    });
    if (r['code'].toString() != '1') throw Exception(r['message'] ?? 'ارسال کد تایید نشد');
  }

  Future<String> authenticate(String phone, String otp, {bool register = false, String name = ''}) async {
    final number = normalize(phone);
    final r = await request(register ? 'create_user' : 'login_user', {
      if(register) ...{'digits_reg_mobile':number,'digits_reg_countrycode':'+98','digits_reg_name':name.trim()}
      else ...{'user':number,'countrycode':'+98'},
      'otp':otp.trim(),
    });
    final data = r['data'];
    if(r['success'] != true || data is! Map || data['access_token'] is! String || (data['access_token'] as String).isEmpty) {
      throw const FormatException('توکن ورود دریافت نشد');
    }
    return data['access_token'] as String;
  }

  Future<void> logout(String token) async {
    await request('logout', {}, token: token);
  }
  void dispose() => client.close();
}
