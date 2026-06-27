// widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app_bcp/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BcpApp(),
      ),
    );

    // Let the splash screen redirect delayed futures finish by advancing the clock.
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(BcpApp), findsOneWidget);
  });
}
