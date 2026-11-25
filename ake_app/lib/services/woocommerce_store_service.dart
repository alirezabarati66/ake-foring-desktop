import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/store_product.dart';
class WooCommerceStoreService {
  static const String _baseUrl = 'https://ake-forging.com/wp-json/wc/store/v1';
  final http.Client _client;
  WooCommerceStoreService({http.Client? client}) : _client = client ?? http.Client();
  Future<List<StoreProduct>> fetchProductsPage({int page = 1, int perPage = 20}) async {
    final response = await _get('/products?per_page=$perPage&page=$page');
    return _decodeList(response).map(StoreProduct.fromJson).toList();
  }
  Future<List<StoreProduct>> fetchProducts() async {
    final firstResponse = await _get('/products?per_page=100&page=1');
    final first = _decodeList(firstResponse);
    final totalPages = int.tryParse(firstResponse.headers['x-wp-totalpages'] ?? '1') ?? 1;
    final products = <StoreProduct>[...first.map(StoreProduct.fromJson)];
    for (var page = 2; page <= totalPages && page <= 50; page++) {
      final response = await _get('/products?per_page=100&page=$page');
      products.addAll(_decodeList(response).map(StoreProduct.fromJson));
    }
    return products;
  }
  Future<List<StoreProduct>> fetchVariations(int parentId) async {
    if (parentId <= 0) return const [];
    final response = await _get('/products?type=variation&parent=$parentId&per_page=100');
    return _decodeList(response).map((json) {
      final normalized = Map<String, dynamic>.from(json);
      normalized['type'] = 'variation';
      normalized['parent'] ??= parentId;
      return StoreProduct.fromJson(normalized);
    }).where((variation) => variation.id > 0 && variation.inStock).toList();
  }
  Future<List<StoreCategory>> fetchCategories() async {
    final response = await _get('/products/categories?per_page=100');
    return _decodeList(response).map(StoreCategory.fromJson).where((c) => c.id > 0 && c.name.isNotEmpty).toList();
  }
  Future<http.Response> _get(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'), headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) throw WooCommerceException('دریافت اطلاعات از فروشگاه با خطا مواجه شد (کد ${response.statusCode}).');
    return response;
  }
  List<Map<String, dynamic>> _decodeList(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) throw const WooCommerceException('پاسخ فروشگاه در قالب مورد انتظار نیست.');
    return decoded.whereType<Map<String, dynamic>>().toList();
  }
  void dispose() => _client.close();
}
class WooCommerceException implements Exception {
  final String message; const WooCommerceException(this.message);
  @override String toString() => message;
}
