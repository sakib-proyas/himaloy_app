import 'package:flutter_test/flutter_test.dart';
import 'package:himaloy_inventory_mobile/main.dart';

void main() {
  testWidgets('App initializes smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HimaloyInventoryApp());
  });
}
