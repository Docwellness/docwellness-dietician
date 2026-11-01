// The calorie bar tooltip names the dates the bar covers, and a payload from
// before the backend sent bucket dates still parses and renders.
import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/calorie_intake_container.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalorieDataPoint _point(Map<String, dynamic> overrides) =>
    CalorieDataPoint.fromJson({
      'label': '5 Oct',
      'calories': 1840,
      'plannedCalories': 1800,
      ...overrides,
    });

void main() {
  group('calorieTooltipLines', () {
    test(
      'a weekly bar shows kcal, its dates and the days logged when under 7',
      () {
        final lines = calorieTooltipLines(
          _point({
            'dateRange': '5 Oct - 11 Oct',
            'startDate': '2026-10-05',
            'endDate': '2026-10-11',
            'daysLogged': 3,
          }),
        );

        expect(lines, ['1840 kcal', '5 Oct - 11 Oct', '3 days logged']);
      },
    );

    test('a fully logged week shows the dates without a days-logged line', () {
      final lines = calorieTooltipLines(
        _point({'dateRange': '5 Oct - 11 Oct', 'daysLogged': 7}),
      );

      expect(lines, ['1840 kcal', '5 Oct - 11 Oct']);
    });

    test('one logged day reads "1 day logged"', () {
      final lines = calorieTooltipLines(
        _point({'dateRange': '26 Oct - 1 Nov', 'daysLogged': 1}),
      );

      expect(lines.last, '1 day logged');
    });

    test('a daily bar shows only its kcal', () {
      final lines = calorieTooltipLines(
        _point({'dateRange': '5 Oct - 5 Oct', 'daysLogged': 1}),
      );

      expect(lines, ['1840 kcal']);
    });

    test('a payload without any date fields shows only its kcal', () {
      expect(calorieTooltipLines(_point({})), ['1840 kcal']);
    });
  });

  group('CalorieDataPoint.fromJson', () {
    test('reads the bucket first and last day', () {
      final point = _point({
        'startDate': '2026-10-05',
        'endDate': '2026-10-11',
      });

      expect(point.startDate, '2026-10-05');
      expect(point.endDate, '2026-10-11');
    });

    test('an old payload leaves them null', () {
      final point = _point({'dateRange': '5 Oct - 11 Oct'});

      expect(point.startDate, isNull);
      expect(point.endDate, isNull);
    });
  });

  testWidgets('renders bars for an old payload without bucket dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalorieIntakeContainer(
            data: [
              _point({'dateRange': '5 Oct - 11 Oct', 'daysLogged': 3}),
              _point({'label': '12 Oct', 'calories': 0}),
            ],
            plannedCalories: 1800,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BarChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
