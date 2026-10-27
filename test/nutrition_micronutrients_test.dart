// Micronutrient display (fill-recipe-micronutrients, tasks 7.2 and 7.3):
// null stays null through parsing, scaling and saving, a null renders as "—"
// with no %DV, and the macro rings do not count fiber on top of carbs.

import 'package:docwellnesdoc/app/models/ai_diet_plain_model.dart' as plan;
import 'package:docwellnesdoc/app/models/update_ai_diet_plain_model.dart'
    as options;
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart'
    show planNutritionFromOption;
import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/nutrition_details_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Nutrition nutrition, {
  double width = 800,
}) async {
  tester.view.physicalSize = Size(width, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: NutritionDetailsWidget(nutrition: nutrition)),
    ),
  );
}

/// The texts of the nutrition row titled [title] (title, value, %DV). The row
/// is the one holding exactly those three texts, so the "Protein" ring title
/// above the rows does not match.
List<String> _rowTexts(WidgetTester tester, String title) {
  final rows = find
      .ancestor(of: find.text(title), matching: find.byType(Row))
      .evaluate()
      .map((e) => e.widget)
      .map(
        (row) => tester
            .widgetList<Text>(
              find.descendant(
                of: find.byWidget(row),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data ?? '')
            .toList(),
      )
      .where((texts) => texts.length == 3 && texts.first == title);
  expect(rows, hasLength(1), reason: 'one nutrition row titled "$title"');
  return rows.single;
}

void main() {
  group('Nutrition model', () {
    test('fromJson keeps a missing or null micronutrient as null, not 0', () {
      final n = Nutrition.fromJson({
        'calories': 230,
        'protein': 11.7,
        'carbs': 30,
        'fats': 5,
        'fiber': 8,
        'iron': 3.1,
        'sodium': null,
      });

      expect(n.iron, 3.1);
      expect(n.sodium, isNull);
      expect(n.saturatedFat, isNull);
      expect(n.vitaminC, isNull);
    });

    test('toJson sends the five macros only, never a micronutrient', () {
      final json = Nutrition(
        calories: 230,
        protein: 11.7,
        carbs: 30,
        fats: 5,
        fiber: 8,
        saturatedFat: 1.2,
        transFat: 0,
        sugar: 4,
        cholesterol: 10,
        sodium: 340,
        calcium: 20,
        iron: 0,
        potassium: 300,
        vitaminC: 8,
      ).toJson();

      expect(json.keys, ['calories', 'protein', 'carbs', 'fats', 'fiber']);
    });

    test(
      'the plan-side Nutrition keeps micronutrients from JSON as null or value',
      () {
        final n = plan.Nutrition.fromJson({
          'calories': 230,
          'iron': 3.1,
          'sodium': null,
        });

        expect(n.iron, 3.1);
        expect(n.sodium, isNull);
        expect(n.calcium, isNull);
      },
    );

    test(
      'the draft-options NutritionModel keeps micronutrients as num or null',
      () {
        final n = options.NutritionModel.fromJson({
          'calories': 230,
          'iron': 3.1,
          'sodium': null,
        });

        expect(n.iron, 3.1);
        expect(n.sodium, isNull);
        expect(n.vitaminC, isNull);
      },
    );
  });

  group('planNutritionFromOption', () {
    test(
      'carries micronutrients through; null stays null, zero stays zero',
      () {
        final n = planNutritionFromOption(
          options.NutritionModel(
            calories: 230,
            protein: 11,
            carbs: 30,
            fats: 5,
            fiber: 8,
            saturatedFat: 1.2,
            sodium: 0,
            iron: 3.1,
          ),
        );

        expect(n.calories, 230);
        expect(n.fiber, 8);
        expect(n.saturatedFat, 1.2);
        expect(n.iron, 3.1);
        expect(n.sodium, 0);
        expect(n.calcium, isNull);
        expect(n.vitaminC, isNull);
      },
    );
  });

  group('scaleNutritionForComponentEdit', () {
    RecipeComponent part(num quantity) =>
        RecipeComponent(label: 'Idli', quantity: quantity, unit: 'g');

    test('scales non-null micronutrients with the macros and keeps nulls', () {
      final scaled = RecipePreview.scaleNutritionForComponentEdit(
        oldComponents: [part(100)],
        newComponents: [part(200)],
        baseNutrition: Nutrition(
          calories: 100,
          protein: 10,
          carbs: 20,
          fats: 4,
          fiber: 2,
          iron: 3,
          sodium: 0,
        ),
      );

      expect(scaled.calories, 200);
      expect(scaled.iron, 6);
      // A researched zero stays 0, an unresearched value stays null.
      expect(scaled.sodium, 0);
      expect(scaled.calcium, isNull);
      expect(scaled.vitaminC, isNull);
    });
  });

  group('Nutrition rows', () {
    testWidgets('a researched value shows its amount and %DV', (tester) async {
      await _pump(
        tester,
        Nutrition(
          calories: 230,
          protein: 11.7,
          carbs: 30,
          fats: 5,
          fiber: 8,
          iron: 3.6,
        ),
      );

      // 3.6 / 18mg DV, on the Iron row (not any other "20%" on screen).
      expect(_rowTexts(tester, 'Iron'), containsAll(['3.6mg', '20%']));
    });

    testWidgets('a real zero shows "0mg" and "0%", not "—"', (tester) async {
      await _pump(
        tester,
        Nutrition(
          calories: 230,
          protein: 11.7,
          carbs: 30,
          fats: 5,
          fiber: 8,
          iron: 0,
        ),
      );

      expect(_rowTexts(tester, 'Iron'), containsAll(['0mg', '0%']));
      expect(_rowTexts(tester, 'Iron'), isNot(contains('—')));
    });

    testWidgets('a trace value shows "<0.1mg" with a blank %DV', (
      tester,
    ) async {
      await _pump(
        tester,
        Nutrition(
          calories: 230,
          protein: 11.7,
          carbs: 30,
          fats: 5,
          fiber: 8,
          iron: 0.03,
        ),
      );

      expect(_rowTexts(tester, 'Iron'), ['Iron', '<0.1mg', '']);
    });

    testWidgets('every row shows its own value and %DV', (tester) async {
      await _pump(
        tester,
        Nutrition(
          calories: 230,
          fats: 7.8,
          saturatedFat: 4,
          transFat: 0.7,
          protein: 15,
          carbs: 110,
          fiber: 14,
          sugar: 9.5,
          cholesterol: 30,
          sodium: 460,
          calcium: 390,
          iron: 7.2,
          potassium: 2350,
          vitaminC: 54,
        ),
      );

      expect(_rowTexts(tester, 'Total fat'), ['Total fat', '7.8g', '10%']);
      expect(_rowTexts(tester, '   Saturated fat'), [
        '   Saturated fat',
        '4g',
        '20%',
      ]);
      expect(_rowTexts(tester, '   Trans fat'), ['   Trans fat', '0.7g', '']);
      expect(_rowTexts(tester, 'Protein'), ['Protein', '15.0g', '30%']);
      expect(_rowTexts(tester, 'Total Carbohydrates'), [
        'Total Carbohydrates',
        '110.0g',
        '40%',
      ]);
      expect(_rowTexts(tester, '   Dietary Fiber'), [
        '   Dietary Fiber',
        '14.0g',
        '50%',
      ]);
      expect(_rowTexts(tester, '   Sugar'), ['   Sugar', '9.5g', '']);
      expect(_rowTexts(tester, 'Cholesterol'), ['Cholesterol', '30mg', '10%']);
      expect(_rowTexts(tester, 'Sodium'), ['Sodium', '460mg', '20%']);
      expect(_rowTexts(tester, 'Calcium'), ['Calcium', '390mg', '30%']);
      expect(_rowTexts(tester, 'Iron'), ['Iron', '7.2mg', '40%']);
      expect(_rowTexts(tester, 'Potassium'), ['Potassium', '2350mg', '50%']);
      expect(_rowTexts(tester, 'Vitamin C'), ['Vitamin C', '54mg', '60%']);
    });

    testWidgets('a tiny macro still shows its %DV; a tiny micro does not', (
      tester,
    ) async {
      await _pump(
        tester,
        Nutrition(
          calories: 10,
          protein: 0.03,
          carbs: 0.03,
          fats: 0.03,
          fiber: 0.03,
          saturatedFat: 0.03,
          sodium: 0.03,
        ),
      );

      expect(_rowTexts(tester, 'Total fat'), ['Total fat', '0.0g', '0%']);
      expect(_rowTexts(tester, 'Protein'), ['Protein', '0.0g', '0%']);
      expect(_rowTexts(tester, 'Total Carbohydrates'), [
        'Total Carbohydrates',
        '0.0g',
        '0%',
      ]);
      expect(_rowTexts(tester, '   Dietary Fiber'), [
        '   Dietary Fiber',
        '0.0g',
        '0%',
      ]);
      expect(_rowTexts(tester, '   Saturated fat'), [
        '   Saturated fat',
        '<0.1g',
        '',
      ]);
      expect(_rowTexts(tester, 'Sodium'), ['Sodium', '<0.1mg', '']);
    });

    testWidgets('the Fiber ring says its percent is of carbs', (tester) async {
      await _pump(
        tester,
        Nutrition(calories: 230, protein: 11.7, carbs: 30, fats: 5, fiber: 8),
      );

      expect(find.text('Fiber (of carbs)'), findsOneWidget);
      expect(find.text('Fat'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
    });

    // Below ~332 the unrelated Calories row overflows, so 340 is the narrowest
    // width that isolates the ring row.
    for (final width in [375.0, 340.0]) {
      testWidgets('the Fiber title fits the ring row at width $width', (
        tester,
      ) async {
        await _pump(
          tester,
          Nutrition(calories: 230, protein: 11.7, carbs: 30, fats: 5, fiber: 8),
          width: width,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Fiber (of carbs)'), findsOneWidget);
      });
    }

    testWidgets('a null value shows "—" with no %DV and never "0mg"', (
      tester,
    ) async {
      await _pump(
        tester,
        Nutrition(calories: 230, protein: 11.7, carbs: 30, fats: 5, fiber: 8),
      );

      // Saturated fat, trans fat, sugar, cholesterol, sodium, calcium, iron,
      // potassium and vitamin C.
      expect(find.text('—'), findsNWidgets(9));
      expect(find.text('0mg'), findsNothing);
      expect(find.text('0g'), findsNothing);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('trans fat and sugar have no %DV even with a value', (
      tester,
    ) async {
      await _pump(
        tester,
        Nutrition(
          calories: 230,
          protein: 11.7,
          carbs: 30,
          fats: 5,
          fiber: 8,
          transFat: 0.2,
          sugar: 4.5,
        ),
      );

      expect(find.text('0.2g'), findsOneWidget);
      expect(find.text('4.5g'), findsOneWidget);
      // The two valued rows add no "—"; the 7 unresearched rows still do.
      expect(find.text('—'), findsNWidgets(7));
    });
  });

  group('microValueText', () {
    test('null is "—", a true zero is "0", a trace is "<0.1"', () {
      expect(microValueText(null, 'mg'), '—');
      expect(microValueText(0, 'mg'), '0mg');
      expect(microValueText(0.04, 'mg'), '<0.1mg');
      expect(microValueText(0.05, 'mg'), '0.1mg');
      expect(microValueText(3.6, 'g'), '3.6g');
      expect(microValueText(300, 'mg'), '300mg');
    });
  });

  group('dvPercentText', () {
    test('uses the FDA 2020 daily value for every nutrient', () {
      expect(dvPercentText(78, dvFat), '100%');
      expect(dvPercentText(20, dvSaturatedFat), '100%');
      expect(dvPercentText(275, dvCarbs), '100%');
      expect(dvPercentText(28, dvFiber), '100%');
      expect(dvPercentText(50, dvProtein), '100%');
      expect(dvPercentText(300, dvCholesterol), '100%');
      expect(dvPercentText(2300, dvSodium), '100%');
      expect(dvPercentText(1300, dvCalcium), '100%');
      expect(dvPercentText(18, dvIron), '100%');
      expect(dvPercentText(4700, dvPotassium), '100%');
      expect(dvPercentText(90, dvVitaminC), '100%');
    });

    test(
      'is blank for null, no DV, or a trace value; "0%" for a true zero',
      () {
        expect(dvPercentText(null, dvIron), '');
        expect(dvPercentText(4.5, null), '');
        expect(dvPercentText(0.03, dvIron), '');
        expect(dvPercentText(0, dvIron), '0%');
      },
    );
  });

  group('macroDvPercentText', () {
    test('always shows a percent, even for a value below 0.05', () {
      expect(macroDvPercentText(0.03, dvFat), '0%');
      expect(macroDvPercentText(0, dvProtein), '0%');
      expect(macroDvPercentText(78, dvFat), '100%');
    });
  });

  group('macroRingShares', () {
    test('falls back to 0.25 each when there is no energy', () {
      final r = macroRingShares(protein: 0, fats: 0, carbs: 0, fiber: 0);

      expect(r.protein, 0.25);
      expect(r.fats, 0.25);
      expect(r.carbs, 0.25);
      expect(r.fiber, 0.25);
    });

    test('fiber ring is clamped to 1 when fiber exceeds carbs', () {
      final r = macroRingShares(protein: 10, fats: 10, carbs: 5, fiber: 9);

      expect(r.fiber, 1);
    });

    test('uses energy share and does not count fiber on top of carbs', () {
      final r = macroRingShares(protein: 10, fats: 10, carbs: 30, fiber: 6);

      // Energy: 40 + 90 + 120 = 250
      expect(r.protein, closeTo(40 / 250, 1e-9));
      expect(r.fats, closeTo(90 / 250, 1e-9));
      expect(r.carbs, closeTo(120 / 250, 1e-9));
      expect(r.protein + r.fats + r.carbs, closeTo(1, 1e-9));
      // Fiber is part of the carbs, shown as its share of them.
      expect(r.fiber, closeTo(0.2, 1e-9));
    });

    test('fiber ring is empty when there are no carbs', () {
      final r = macroRingShares(protein: 10, fats: 0, carbs: 0, fiber: 3);

      expect(r.fiber, 0);
    });
  });
}
