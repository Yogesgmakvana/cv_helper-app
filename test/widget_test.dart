import 'package:flutter_test/flutter_test.dart';

import 'package:cv_helper/main.dart';

void main() {
  testWidgets('CV Helper App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CVHelperApp());

    // Verify that our app displays greeting and quick action.
    expect(find.text('Hello James '), findsOneWidget);
    expect(find.text('Quick Action'), findsOneWidget);
  });
}
