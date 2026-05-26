import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:purchaseorders2/main.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(
      const MyApp(isAuthenticated: false),
    );

    // Wait for frames/loading
    await tester.pumpAndSettle();

    // Verify app loaded
    expect(find.byType(MyApp), findsOneWidget);
  });
}