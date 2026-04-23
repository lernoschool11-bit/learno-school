import 'package:flutter_test/flutter_test.dart';
import 'package:learno_app/main.dart';

void main() {
  testWidgets('App renders the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
