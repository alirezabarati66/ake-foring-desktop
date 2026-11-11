import 'package:flutter_test/flutter_test.dart';
import 'package:ake_app/main.dart';

void main() {
  testWidgets('AKE Forging app shows the home screen', (tester) async {
    await tester.pumpWidget(const AkeApp());
    expect(find.text('AKE FORGING'), findsOneWidget);
    expect(find.text('محصولات فروشگاه'), findsOneWidget);
  });
}
