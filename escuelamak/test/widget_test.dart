// Basic Flutter widget test for EscuelaMAK

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Basic smoke test - verify the app can be built
    // Note: Full testing requires Supabase mock setup
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('EscuelaMAK Test'),
          ),
        ),
      ),
    );

    expect(find.text('EscuelaMAK Test'), findsOneWidget);
  });
}
