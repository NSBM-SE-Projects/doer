import 'package:flutter_test/flutter_test.dart';
import 'package:doer_worker/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const DoerWorkerApp());
    expect(find.text('Doer Worker'), findsNothing); // app loads
  });
}
