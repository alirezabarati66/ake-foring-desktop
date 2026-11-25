import 'dart:convert';
import 'package:http/http.dart' as http;

class DeliveryService {
  final String token;
  DeliveryService(this.token);
  Future<dynamic> request(String path, {Map<String,dynamic>? body}) async {
    final uri = Uri.parse('https://www.ake-forging.com/wp-json/ake/v1/$path');
    final headers = {'Authorization':'Bearer $token','Accept':'application/json','Content-Type':'application/json'};
    final response = await (body == null ? http.get(uri,headers:headers) : http.post(uri,headers:headers,body:jsonEncode(body))).timeout(const Duration(seconds:25));
    if(response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('خطای سرور: ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
  Future<Map<String,dynamic>> me() async => Map<String,dynamic>.from(await request('me') as Map);
  Future<List<Map<String,dynamic>>> orders() async => (await request('orders') as List).map((v)=>Map<String,dynamic>.from(v as Map)).toList();
  Future<List<Map<String,dynamic>>> missions() async => (await request('missions') as List).map((v)=>Map<String,dynamic>.from(v as Map)).toList();
  Future<Map<String,dynamic>> updateMissionStatus(int id, String status) async {
    final result = await request('missions/$id/status', body: {'status': status});
    if (result is! Map || result['saved'] != true) throw Exception('وضعیت مأموریت ذخیره نشد');
    return Map<String,dynamic>.from(result);
  }
  Future<void> saveLocation(int id,double lat,double lng) async {
    if(!lat.isFinite || !lng.isFinite || lat.abs()>90 || lng.abs()>180) throw const FormatException('مختصات نامعتبر');
    final result=await request('orders/$id/location',body:{'lat':lat,'lng':lng});
    if(result is! Map || result['saved']!=true) throw Exception('موقعیت ذخیره نشد');
  }
}
