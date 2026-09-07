// Selection logic for DeletePatientDataSheet: parent/child rows, the
// "check every category => this is a full account delete" master toggle,
// and the type-the-email gate on the delete button. The actual delete call
// + navigation is covered by the backend suite (patientDataDeletion.test.js)
// and manual verification.
import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/views/delete_patient_data_sheet.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _email = 'patient@example.test';

Future<void> _pumpSheet(WidgetTester tester) async {
  // Tall surface so the sheet's ListView builds every row (the account
  // master + confirm field sit well below a phone viewport).
  tester.view.physicalSize = const Size(1200, 5000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Get.testMode = true;
  final controller = PatientsController();
  controller.patientProfileModel.value = PatientProfileModel.fromJson({
    'basic': {'email': _email},
  });
  Get.put<PatientsController>(controller);

  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: DeletePatientDataSheet(patientId: 'p1')),
    ),
  );
  await tester.pumpAndSettle();
}

CustomButton _button(WidgetTester tester) =>
    tester.widget<CustomButton>(find.byType(CustomButton));

void main() {
  tearDown(Get.reset);

  testWidgets('renders section headers and category labels', (tester) async {
    await _pumpSheet(tester);
    expect(find.text('Diet & meals'), findsOneWidget);
    expect(find.text('Meal logs'), findsOneWidget);
    expect(find.text("Also delete the patient's account & login (permanent)"),
        findsOneWidget);
  });

  testWidgets('checking a parent reveals its locked child rows', (tester) async {
    await _pumpSheet(tester);
    expect(find.text('Day plans'), findsNothing);

    await tester.tap(find.text('Diet plans & meal schedules'));
    await tester.pump();

    expect(find.text('Day plans'), findsOneWidget);
    expect(find.text('Plan items'), findsOneWidget);
  });

  testWidgets('delete button is gated on typing the exact email',
      (tester) async {
    await _pumpSheet(tester);

    await tester.tap(find.text('Meal logs'));
    await tester.pump();
    expect(_button(tester).isDisabled, isTrue, reason: 'no email yet');

    await tester.enterText(find.byType(TextField), _email);
    await tester.pump();
    expect(_button(tester).isDisabled, isFalse);
    expect(find.text('Delete selected data'), findsOneWidget);
  });

  testWidgets('checking every data category turns on the account master',
      (tester) async {
    await _pumpSheet(tester);

    // Tap every category checkbox (the account-only one is disabled - a
    // no-op - and the last checkbox is the account master itself).
    final boxes = find.byType(Checkbox);
    final count = tester.widgetList(boxes).length;
    for (var i = 0; i < count - 1; i++) {
      await tester.tap(boxes.at(i), warnIfMissed: false);
      await tester.pump();
    }

    final accountBox = tester.widget<Checkbox>(boxes.at(count - 1));
    expect(accountBox.value, isTrue);
    expect(find.text('Delete patient & all data'), findsOneWidget);

    // Unchecking one category drops back out of full-account mode.
    await tester.tap(find.text('Meal logs'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox).last).value, isFalse);
    expect(find.text('Delete selected data'), findsOneWidget);
  });

  testWidgets('the account master checkbox checks all categories on',
      (tester) async {
    await _pumpSheet(tester);

    await tester
        .tap(find.text("Also delete the patient's account & login (permanent)"));
    await tester.pump();

    // Every rendered checkbox is now on.
    for (final box in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
      expect(box.value, isTrue);
    }
    expect(find.text('Delete patient & all data'), findsOneWidget);
  });
}
