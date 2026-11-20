import 'dart:async';

import 'package:docwellnesdoc/app/models/start_date_options_model.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/start_date_options_state.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/start_date_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _firstTime = StartDateOptions(
  required: true,
  defaultDate: '2026-11-19',
  minDate: '2026-11-19',
);

const _renewal = StartDateOptions(
  required: true,
  defaultDate: '2026-11-19',
  minDate: '2026-11-26',
  isRenewal: true,
  runningCycleEndDate: '2026-11-25',
);

Future<DateTime?> _noPick(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async => null;

Future<StartDateOptionsState> _pumpRow(
  WidgetTester tester, {
  required Future<StartDateOptions?> Function() fetch,
  StartDatePicker pickDate = _noPick,
}) async {
  final state = StartDateOptionsState(
    fetch: (patientId, dietPlanId) => fetch(),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StartDateRow(
          state: state,
          patientId: 'p1',
          dietPlanId: 'plan1',
          pickDate: pickDate,
        ),
      ),
    ),
  );
  return state;
}

void main() {
  testWidgets('shows the server default as Today for a first-time plan', (
    tester,
  ) async {
    await _pumpRow(tester, fetch: () async => _firstTime);
    await tester.pumpAndSettle();

    expect(find.text('Diet starts on'), findsOneWidget);
    expect(find.text('Today, 19 Nov 2026'), findsOneWidget);
    expect(
      find.text(
        'Plan weeks run from this day. The patient is not told the date.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Earliest'), findsNothing);
  });

  testWidgets('shows a spinner while the options load', (tester) async {
    final pending = Completer<StartDateOptions?>();
    await _pumpRow(tester, fetch: () => pending.future);
    await tester.pump();

    expect(find.text('Loading start date…'), findsOneWidget);
    expect(find.text('Diet starts on'), findsNothing);

    pending.complete(_firstTime);
    await tester.pumpAndSettle();

    expect(find.text('Loading start date…'), findsNothing);
    expect(find.text('Diet starts on'), findsOneWidget);
  });

  testWidgets('shows an error with Retry, and Retry loads the options again', (
    tester,
  ) async {
    var attempts = 0;
    final state = await _pumpRow(
      tester,
      fetch: () async => ++attempts == 1 ? null : _firstTime,
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load start date.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(state.blocksConfirm, isTrue);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Could not load start date.'), findsNothing);
    expect(find.text('Today, 19 Nov 2026'), findsOneWidget);
    expect(state.blocksConfirm, isFalse);
  });

  testWidgets(
    'a renewal shows the earliest day and when the current plan ends',
    (tester) async {
      await _pumpRow(tester, fetch: () async => _renewal);
      await tester.pumpAndSettle();

      expect(
        find.text('Earliest: 26 Nov (current plan ends 25 Nov)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the picker gets the server minimum as its first day and the pick is shown',
    (tester) async {
      DateTime? receivedFirst;
      DateTime? receivedInitial;
      final state = await _pumpRow(
        tester,
        fetch: () async => _renewal,
        pickDate:
            (
              context, {
              required initialDate,
              required firstDate,
              required lastDate,
            }) async {
              receivedInitial = initialDate;
              receivedFirst = firstDate;
              return DateTime(2026, 11, 28);
            },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Diet starts on'));
      await tester.pumpAndSettle();

      expect(receivedFirst, DateTime(2026, 11, 26));
      expect(receivedInitial, DateTime(2026, 11, 26));
      expect(state.selectedDay, DateTime(2026, 11, 28));
      expect(find.text('Sat, 28 Nov 2026'), findsOneWidget);
    },
  );

  testWidgets('a plan that already has its dates shows no row', (tester) async {
    await _pumpRow(tester, fetch: () async => StartDateOptions.notRequired);
    await tester.pumpAndSettle();

    expect(find.text('Diet starts on'), findsNothing);
    expect(find.text('Could not load start date.'), findsNothing);
  });
}
