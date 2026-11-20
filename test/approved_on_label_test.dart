import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:docwellnesdoc/app/modules/patients/utils/approved_on_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Built from a local time so the expected text cannot depend on the
  // machine's timezone.
  final approvedAt = DateTime(2026, 11, 20, 16, 22);
  final iso = approvedAt.toUtc().toIso8601String();

  group('approvedOnLabel', () {
    test('the Week 1 card says the day and time the payment was approved', () {
      expect(approvedOnLabel(iso), 'Approved 20 Nov, 4:22 PM');
    });

    test('the Basic Information caption says the day only', () {
      expect(approvedOnLabel(iso, withTime: false), 'Approved on 20 Nov 2026');
    });

    test('shows nothing when there is no activation time', () {
      expect(approvedOnLabel(null), isNull);
      expect(approvedOnLabel(''), isNull);
      expect(approvedOnLabel('   '), isNull);
    });

    test('shows nothing for an unreadable value instead of throwing', () {
      expect(approvedOnLabel('not a date'), isNull);
    });
  });

  group('HealthSummary.activationDate', () {
    test('is read when the backend sends it', () {
      final summary = HealthSummary.fromJson({'activationDate': iso});

      expect(summary.activationDate, iso);
    });

    test('is null for a plan that is not activated (backend sends null)', () {
      final summary = HealthSummary.fromJson({'activationDate': null});

      expect(summary.activationDate, isNull);
    });

    test('is null from an older backend that does not send it', () {
      final summary = HealthSummary.fromJson({
        'startDateForDiet': '20-11-2026',
      });

      expect(summary.activationDate, isNull);
    });
  });
}
