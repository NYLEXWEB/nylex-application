import 'package:flutter_test/flutter_test.dart';
import 'package:nylex_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NylexApp());
    expect(find.byType(NylexApp), findsOneWidget);
  });
}
