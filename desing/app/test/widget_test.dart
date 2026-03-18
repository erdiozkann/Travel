// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TravelApp());

    // Verify basic app structure exists
    expect(find.byType(TravelApp), findsOneWidget);
  });
}
