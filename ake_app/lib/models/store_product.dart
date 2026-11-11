class StoreProduct {
  final int id; final String name, sku, permalink, imageUrl, price, regularPrice, currencyCode, currencySymbol; final int currencyMinorUnit; final bool inStock; final List<String> categories;
  const StoreProduct({required this.id, required this.name, required this.sku, required this.permalink, required this.imageUrl, required this.price, required this.regularPrice, required this.currencyCode, required this.currencySymbol, required this.currencyMinorUnit, required this.inStock, required this.categories});
  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final prices = (json['prices'] as Map<String, dynamic>?) ?? const {};
    final images = (json['images'] as List<dynamic>?) ?? const [];
    final cats = (json['categories'] as List<dynamic>?) ?? const [];
    final image = images.isNotEmpty && images.first is Map<String, dynamic> ? images.first as Map<String, dynamic> : const <String, dynamic>{};
    return StoreProduct(id: (json['id'] as num?)?.toInt() ?? 0, name: (json['name'] ?? '').toString(), sku: (json['sku'] ?? '').toString(), permalink: (json['permalink'] ?? '').toString(), imageUrl: (image['src'] ?? '').toString(), price: (prices['price'] ?? '').toString(), regularPrice: (prices['regular_price'] ?? '').toString(), currencyCode: (prices['currency_code'] ?? '').toString(), currencySymbol: (prices['currency_symbol'] ?? '').toString(), currencyMinorUnit: (prices['currency_minor_unit'] as num?)?.toInt() ?? 0, inStock: json['is_in_stock'] == true, categories: cats.whereType<Map<String, dynamic>>().map((c) => (c['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList());
  }
  String get displayPrice {
    if (price.isEmpty) return '';
    final raw = int.tryParse(price); if (raw == null) return price;
    final divisor = _pow10(currencyMinorUnit); final whole = raw ~/ divisor; final formatted = _groupDigits(whole.toString());
    final label = (currencyCode == 'IRR' || currencyCode == 'IRT') ? 'تومان' : (currencySymbol.isNotEmpty ? currencySymbol : currencyCode);
    if (currencyMinorUnit <= 0 || raw % divisor == 0) return '$formatted $label';
    return '$formatted,${(raw % divisor).toString().padLeft(currencyMinorUnit, '0')} $label';
  }
  static int _pow10(int exp) { var n = 1; for (var i = 0; i < exp.clamp(0, 6); i++) { n *= 10; } return n; }
  static String _groupDigits(String digits) { final b = StringBuffer(); for (var i = 0; i < digits.length; i++) { if (i > 0 && (digits.length - i) % 3 == 0) b.write(','); b.write(digits[i]); } return b.toString(); }
}
class StoreCategory {
  final int id; final String name, slug, imageUrl;
  const StoreCategory({required this.id, required this.name, required this.slug, required this.imageUrl});
  factory StoreCategory.fromJson(Map<String, dynamic> json) { final image = json['image'] as Map<String, dynamic>?; return StoreCategory(id: (json['id'] as num?)?.toInt() ?? 0, name: (json['name'] ?? '').toString(), slug: (json['slug'] ?? '').toString(), imageUrl: (image?['src'] ?? '').toString()); }
}
