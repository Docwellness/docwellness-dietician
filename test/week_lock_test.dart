import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:docwellnesdoc/app/modules/patients/utils/week_lock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weekLockedUntilActivation', () {
    test('a plan waiting for its start date only opens Week 1', () {
      expect(
        weekLockedUntilActivation(startDatePending: true, week: 1),
        isFalse,
      );
      for (final week in [2, 3, 4]) {
        expect(
          weekLockedUntilActivation(startDatePending: true, week: week),
          isTrue,
          reason: 'week $week',
        );
      }
    });

    test('a plan that has its dates is never locked by it', () {
      for (final week in [1, 2, 3, 4]) {
        expect(
          weekLockedUntilActivation(startDatePending: false, week: week),
          isFalse,
          reason: 'week $week',
        );
      }
    });

    test('the toast message matches the backend', () {
      expect(
        kWeekLockedUntilActivationMessage,
        'Weeks after Week 1 open once the payment is approved and the start date is set.',
      );
    });
  });

  group('runningPlanStartPending', () {
    test('is true for a pending plan with no renewal behind it', () {
      expect(
        runningPlanStartPending(startDatePending: true, hasPendingCycle: false),
        isTrue,
      );
    });

    test('is false during a renewal, so the running plan keeps its date', () {
      expect(
        runningPlanStartPending(startDatePending: true, hasPendingCycle: true),
        isFalse,
      );
    });

    test('is false when nothing is pending', () {
      expect(
        runningPlanStartPending(
          startDatePending: false,
          hasPendingCycle: false,
        ),
        isFalse,
      );
    });
  });

  group('startDateEditConfirmText', () {
    test('tells the dietician a renewal day is not being set', () {
      expect(
        startDateEditConfirmText(renewalPending: true, day: '01 Feb 2030'),
        'The running diet plan\'s week schedule and the exercise plan (if generated) will shift to start on 01 Feb 2030. The new plan\'s start is chosen when you approve its payment.',
      );
    });

    test('keeps the current text when no renewal is pending', () {
      expect(
        startDateEditConfirmText(renewalPending: false, day: '01 Feb 2030'),
        'The diet plan\'s week schedule and the exercise plan (if generated) will shift to start on 01 Feb 2030.',
      );
    });
  });

  group('PendingCycle.fromJson startDatePending', () {
    test('reads true', () {
      expect(
        PendingCycle.fromJson({'startDatePending': true}).startDatePending,
        isTrue,
      );
    });

    test('reads false', () {
      expect(
        PendingCycle.fromJson({'startDatePending': false}).startDatePending,
        isFalse,
      );
    });

    test('is false when the backend does not send it', () {
      expect(PendingCycle.fromJson({}).startDatePending, isFalse);
    });
  });
}
