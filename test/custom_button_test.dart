// AI_EXECUTION_PLAN.md Phase 8, P8-02 - login button state. CustomButton
// (lib/app/utils/common_widgets/custom_button.dart) is the shared button
// used on the login screen (AuthView) - this covers its loading/enabled
// visual + interaction states directly. Unlike docwellness-user's
// CustomButton, this one has no `enabled` param (only `isLoading`) and no
// Semantics/48px minimum tap target wiring, so this test only covers what
// the widget actually supports rather than asserting behavior it doesn't
// have.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';

void main() {
  testWidgets('shows the label and calls onTap when not loading', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Sign In',
            isOutline: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('shows a spinner instead of the label while loading, and onTap does not fire', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Sign In',
            isOutline: false,
            isLoading: true,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Sign In'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    expect(tapped, isFalse);
  });
}
