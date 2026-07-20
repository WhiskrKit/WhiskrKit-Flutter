import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_whiskrkit_example/main.dart';

void main() {
  testWidgets('harness renders with triggers disabled until initialized', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WhiskrKitExample()));

    expect(find.text('WhiskrKit example'), findsOneWidget);
    expect(find.text('Initialize (mocked surveys)'), findsOneWidget);

    // Present buttons are disabled before initialize is tapped.
    final presentButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Present'),
    );
    expect(presentButton.onPressed, isNull);
  });
}
