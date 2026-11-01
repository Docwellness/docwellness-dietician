import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthSummary.fromJson', () {
    test('a decimal weight and height parse', () {
      final health = HealthSummary.fromJson({'weight': 63.3, 'height': 165.5});

      expect(health.weight, 63.3);
      expect(health.height, 165.5);
    });

    test('a whole weight and height still parse', () {
      final health = HealthSummary.fromJson({'weight': 75, 'height': 170});

      expect(health.weight, 75);
      expect(health.height, 170);
    });

    test('weightIndex accepts a double and stays an int', () {
      final health = HealthSummary.fromJson({'weightIndex': 2.0});

      expect(health.weightIndex, 2);
    });

    test('missing values stay null', () {
      final health = HealthSummary.fromJson({});

      expect(health.weight, isNull);
      expect(health.height, isNull);
      expect(health.weightIndex, isNull);
    });
  });
}
