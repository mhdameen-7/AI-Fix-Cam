// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
// This line imports your main.dart file.
import 'package:aifixcam/main.dart';

void main() {
  testWidgets('App launches and displays home screen', (WidgetTester tester) async {
    // This line builds the widget. It MUST use the name 'MyApp'.
    await tester.pumpWidget(const MyApp());

    // We verify that the home screen is showing correctly.
    expect(find.text('Start Diagnosis'), findsOneWidget);
  });
}