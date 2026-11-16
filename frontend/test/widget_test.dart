import 'package:flutter_test/flutter_test.dart';
import 'package:medgo/main.dart';

void main() {
  testWidgets('MEDGO smoke test - app initializes properly', (WidgetTester tester) async {
    await tester.pumpWidget(const MedgoApp());
    expect(find.byType(MedgoApp), findsOneWidget);
  });
}
