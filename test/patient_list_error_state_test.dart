// AI_EXECUTION_PLAN.md Phase 8, P8-02 - loading/error/empty states.
// docwellness-user's P6-01/P6-02 added generic, reusable AppLoader/
// AppErrorState/AppEmptyState widgets under lib/shared/widgets/; this app
// has no equivalent shared design-token widget library (Home/Patients/Diet
// screens each hand-roll their own inline CircularProgressIndicator/isEmpty
// checks - see home_view.dart:104,258,327,335), so there's no single
// reusable component to unit-test the way docwellness-user's
// app_state_widgets_test.dart does. PatientListErrorState (P7-04) is the
// one dedicated, reusable state widget that does exist in this codebase -
// this tests it directly as the closest honest equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/patient_list_error_state.dart';

void main() {
  testWidgets('shows the default message and a Retry button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PatientListErrorState(onRetry: () async {})),
      ),
    );

    expect(
      find.text("Couldn't load patients. Check your connection and try again."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('shows a custom message when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientListErrorState(
            onRetry: () async {},
            message: 'Something else went wrong',
          ),
        ),
      ),
    );

    expect(find.text('Something else went wrong'), findsOneWidget);
  });

  testWidgets('tapping Retry calls onRetry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientListErrorState(
            onRetry: () async {
              retried = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, isTrue);
  });
}
