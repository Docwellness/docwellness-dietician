// The calorie chart is one bar per day: its tooltip names the kcal and the
// day, it opens scrolled to the latest day, and payloads from before the
// backend sent bucket dates or calorieCurrentIndex still parse and render.
import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/calorie_intake_container.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
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

Map<String, dynamic> _trackingJson(Map<String, dynamic> overrides) => {
  'dateRange': {'start': '21 Sep', 'end': '1 Nov'},
  'currentIndex': 5,
  ...overrides,
};

List<CalorieDataPoint> _days(int count) => List.generate(
  count,
  (i) => _point({
    'label': '${i + 1} Oct',
    'dateRange': '${i + 1} Oct - ${i + 1} Oct',
    'calories': 1500,
    'daysLogged': 1,
  }),
);

Future<void> _pump(
  WidgetTester tester,
  List<CalorieDataPoint> data, {
  double width = 360,
  int currentIndex = -1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: CalorieIntakeContainer(
              data: data,
              plannedCalories: 1800,
              currentIndex: currentIndex,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('calorieTooltipLines', () {
    test('a day within its target shows kcal, the day and the target', () {
      final lines = calorieTooltipLines(
        _point({
          'dateRange': '5 Oct - 5 Oct',
          'calories': 1650,
          'daysLogged': 1,
        }),
      );

      expect(lines, ['1650 kcal', '5 Oct', 'Target 1800 kcal']);
    });

    test('a day over its target adds the exact kcal over', () {
      final lines = calorieTooltipLines(
        _point({
          'dateRange': '5 Oct - 5 Oct',
          'calories': 1650,
          'plannedCalories': 1500,
          'daysLogged': 1,
        }),
      );

      expect(lines, [
        '1650 kcal',
        '5 Oct',
        'Target 1500 kcal',
        '150 kcal over',
      ]);
    });

    test('a day with no target shows no target lines', () {
      final lines = calorieTooltipLines(
        _point({
          'dateRange': '5 Oct - 5 Oct',
          'calories': 1650,
          'plannedCalories': 0,
          'daysLogged': 1,
        }),
      );

      expect(lines, ['1650 kcal', '5 Oct']);
    });

    test('an unlogged day shows "Not logged", the day and its target', () {
      final lines = calorieTooltipLines(
        _point({'dateRange': '6 Oct - 6 Oct', 'calories': 0, 'daysLogged': 0}),
      );

      expect(lines, ['Not logged', '6 Oct', 'Target 1800 kcal']);
    });

    test('a payload without dateRange or target shows only its kcal', () {
      final lines = calorieTooltipLines(_point({'plannedCalories': 0}));

      expect(lines, ['1840 kcal']);
    });

    test('never adds a days-logged line', () {
      final lines = calorieTooltipLines(
        _point({
          'dateRange': '5 Oct - 11 Oct',
          'plannedCalories': 0,
          'daysLogged': 3,
        }),
      );

      expect(lines, ['1840 kcal', '5 Oct - 11 Oct']);
    });
  });

  group('CalorieDataPoint.fromJson plannedCalories', () {
    test('reads a day target and a no-target 0', () {
      final withTarget = _point({'plannedCalories': 1850});
      final withoutTarget = _point({'plannedCalories': 0});

      expect(withTarget.plannedCalories, 1850);
      expect(withTarget.hasTarget, isTrue);
      expect(withoutTarget.plannedCalories, 0);
      expect(withoutTarget.hasTarget, isFalse);
    });

    test('a fractional target does not throw', () {
      final point = _point({'plannedCalories': 1850.0});

      expect(point.plannedCalories, 1850);
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

  group('TrackingData.fromJson calorieCurrentIndex', () {
    test('reads the index of today in the daily items', () {
      final data = TrackingData.fromJson(
        _trackingJson({'calorieCurrentIndex': 41}),
      );

      expect(data.calorieCurrentIndex, 41);
    });

    test('is null when the backend does not send it', () {
      final data = TrackingData.fromJson(_trackingJson({}));

      expect(data.calorieCurrentIndex, isNull);
      expect(data.currentIndex, 5);
    });
  });

  group('CalorieIntakeContainer', () {
    testWidgets('opens scrolled to the latest day with 28dp per bar', (
      tester,
    ) async {
      await _pump(tester, _days(42));

      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      final position = scroll.controller!.position;
      expect(position.maxScrollExtent, greaterThan(0));
      expect(position.pixels, position.maxScrollExtent);

      final content = tester.getSize(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(BarChart),
        ),
      );
      expect(content.width, closeTo(42 * 28, 16));

      scroll.controller!.jumpTo(0);
      await tester.pump();
      expect(position.pixels, 0);
    });

    testWidgets('a single day does not scroll', (tester) async {
      await _pump(tester, _days(1));

      final scroll = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroll.controller!.position.maxScrollExtent, 0);
    });

    testWidgets('judges each day against its own target', (tester) async {
      await _pump(tester, [
        _point({'calories': 1650, 'plannedCalories': 1800, 'daysLogged': 1}),
        _point({'calories': 1650, 'plannedCalories': 1500, 'daysLogged': 1}),
        _point({'calories': 1650, 'plannedCalories': 0, 'daysLogged': 1}),
      ]);

      final bars = tester.widget<BarChart>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(BarChart),
        ),
      );
      final groups = bars.data.barGroups;
      List<Color?> colors(int i) =>
          groups[i].barRods.single.rodStackItems.map((s) => s.color).toList();

      const consumed = Color(0xff4FEE7C);
      const remaining = Color(0xffFCCEEF);
      const over = Color(0xffFF3D3D);
      expect(colors(0), [consumed, remaining]);
      expect(colors(1), [consumed, over]);
      expect(colors(2), [consumed]);
      expect(groups[2].barRods.single.toY, 1650);
    });

    testWidgets('renders an old payload without bucket dates', (tester) async {
      await _pump(tester, [
        _point({'dateRange': '5 Oct - 11 Oct', 'daysLogged': 3}),
        _point({'label': '12 Oct', 'calories': 0}),
      ]);

      expect(find.byType(BarChart), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping an unlogged day selects it and names the day', (
      tester,
    ) async {
      await _pump(tester, [
        _point({'dateRange': '5 Oct - 5 Oct', 'daysLogged': 1}),
        _point({
          'label': '6 Oct',
          'dateRange': '6 Oct - 6 Oct',
          'calories': 0,
          'daysLogged': 0,
        }),
      ]);
      final chart = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(BarChart),
      );

      // The second bar's column, well above its small stub.
      await tester.tapAt(tester.getTopLeft(chart) + const Offset(33, 90));
      await tester.pump();

      final data = tester.widget<BarChart>(chart).data;
      expect(data.barGroups[0].showingTooltipIndicators, isEmpty);
      expect(data.barGroups[1].showingTooltipIndicators, [0]);
      final group = data.barGroups[1];
      final item = data.barTouchData.touchTooltipData.getTooltipItem(
        group,
        1,
        group.barRods.single,
        0,
      )!;
      expect(item.text, 'Not logged');
      expect(
        [for (final c in item.children!) c.text],
        ['\n6 Oct', '\nTarget 1800 kcal'],
      );
    });

    testWidgets('highlights only the current day label, none without one', (
      tester,
    ) async {
      List<Color> monthLabelColors() => tester
          .widgetList<CustomText>(
            find.byWidgetPredicate((w) => w is CustomText && w.text == 'Oct'),
          )
          .map((label) => label.color)
          .toList();
      const highlighted = Color(0xffF670CA);
      const muted = Color(0xff94A3B8);

      await _pump(tester, _days(3), currentIndex: 1);
      expect(monthLabelColors(), [muted, highlighted, muted]);

      await _pump(tester, _days(3));
      expect(monthLabelColors(), [muted, muted, muted]);
    });
  });
}
