import 'package:flutter_test/flutter_test.dart';

import 'package:doer/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DoerCustomerApp());
    expect(find.byType(DoerCustomerApp), findsOneWidget);
  });
}
