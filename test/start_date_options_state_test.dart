import 'package:docwellnesdoc/app/models/start_date_options_model.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/start_date_options_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _firstTime = StartDateOptions(
  required: true,
  defaultDate: '2026-11-19',
  minDate: '2026-11-19',
);

void main() {
  late List<String> calls;
  late StartDateOptions? Function() nextResult;
  late StartDateOptionsState state;

  setUp(() {
    calls = [];
    nextResult = () => _firstTime;
    state = StartDateOptionsState(
      fetch: (patientId, dietPlanId) async {
        calls.add('$patientId/$dietPlanId');
        return nextResult();
      },
    );
  });

  test('before the options are requested, confirming is blocked', () {
    expect(state.blocksConfirm, isTrue);
    expect(state.required, isFalse);
  });

  test('the server default is selected once the options load', () async {
    await state.load('p1', 'plan1');

    expect(calls, ['p1/plan1']);
    expect(state.blocksConfirm, isFalse);
    expect(state.required, isTrue);
    expect(state.selectedDay, DateTime(2026, 11, 19));
  });

  test('a picked day replaces the default', () async {
    await state.load('p1', 'plan1');
    state.pick(DateTime(2026, 11, 25, 15, 30));

    expect(state.selectedDay, DateTime(2026, 11, 25));
  });

  test('confirming is blocked while loading', () async {
    final pending = state.load('p1', 'plan1');

    expect(state.loading.value, isTrue);
    expect(state.blocksConfirm, isTrue);
    await pending;
    expect(state.loading.value, isFalse);
  });

  test(
    'confirming stays blocked when the options fail, and a retry clears it',
    () async {
      nextResult = () => null;
      await state.load('p1', 'plan1');

      expect(state.error.value, isTrue);
      expect(state.blocksConfirm, isTrue);
      expect(state.selectedDay, isNull);

      nextResult = () => _firstTime;
      await state.load('p1', 'plan1');

      expect(state.error.value, isFalse);
      expect(state.blocksConfirm, isFalse);
    },
  );

  test('a thrown fetch is an error, not a crash', () async {
    state = StartDateOptionsState(
      fetch: (patientId, dietPlanId) async => throw Exception('offline'),
    );
    await state.load('p1', 'plan1');

    expect(state.error.value, isTrue);
    expect(state.blocksConfirm, isTrue);
  });

  test(
    'an old-flow plan needs no start day and does not block confirming',
    () async {
      nextResult = () => StartDateOptions.notRequired;
      await state.load('p1', 'plan1');

      expect(state.required, isFalse);
      expect(state.blocksConfirm, isFalse);
    },
  );

  test(
    'a refused start day reloads the options and drops the old pick',
    () async {
      await state.load('p1', 'plan1');
      state.pick(DateTime(2026, 11, 16));

      final reloaded = await state.refreshIfStartDateRejected('p1', 'plan1', {
        'success': false,
        'code': 'START_DATE_INVALID',
        'message': 'The diet cannot start before 2026-11-19.',
      });

      expect(reloaded, isTrue);
      expect(calls, hasLength(2));
      expect(state.selectedDay, DateTime(2026, 11, 19));
    },
  );

  test('another refusal does not reload the options', () async {
    await state.load('p1', 'plan1');

    final reloaded = await state.refreshIfStartDateRejected('p1', 'plan1', {
      'success': false,
      'message': 'Payment proof must be in Submitted status before approval',
    });

    expect(reloaded, isFalse);
    expect(calls, hasLength(1));
  });
}
