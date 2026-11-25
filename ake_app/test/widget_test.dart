import 'package:flutter_test/flutter_test.dart';
import 'package:ake_app/models/store_product.dart';
import 'package:ake_app/services/digits_service.dart';

void main() {
  group('Iran mobile validation', () {
    test('normalizes mobile numbers with country codes and Persian digits', () {
      expect(DigitsService.normalize('09123456789'), '9123456789');
      expect(DigitsService.normalize('+989123456789'), '9123456789');
      expect(DigitsService.normalize('۰۹۱۲۳۴۵۶۷۸۹'), '9123456789');
    });
    test('rejects malformed mobile numbers', () {
      expect(() => DigitsService.normalize('123'), throwsA(isA<DigitsApiException>()));
    });
  });

  test('parses HTML description and specification attributes from WooCommerce Store API', () {
    final product = StoreProduct.fromJson({
      'id': 1902, 'name': 'قرقری 405', 'sku': 'AKE-405',
      'permalink': 'https://example.com/test',
      'images': [{'src': 'https://example.com/product.jpg'}],
      'prices': {
        'price': '1800000', 'regular_price': '2000000',
        'currency_code': 'IRT', 'currency_symbol': 'تومان',
        'currency_minor_unit': 0,
      },
      'is_in_stock': true,
      'categories': [{'name': 'قطعات'}],
      'short_description': '<p>معرفی محصول</p>',
      'description': '<table><tr><td>وزن</td><td>۲ کیلو</td></tr></table>',
      'attributes': [{'name': 'جنس', 'terms': [{'name': 'فولاد'}]}],
    });
    expect(product.description, contains('<table>'));
    expect(product.shortDescription, contains('معرفی'));
    expect(product.attributes.first.values, ['فولاد']);
    expect(product.displayPrice, '1,800,000 تومان');
  });
}
