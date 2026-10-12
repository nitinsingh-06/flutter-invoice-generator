import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:invoice_generator/app.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BillGeneratorApp(),
      ),
    );

    // Splash screen should appear immediately on first frame.
    expect(find.byType(BillGeneratorApp), findsOneWidget);
  });
}