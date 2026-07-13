// Regression test for the nutrition circles (Protein/Fat/Carbs/Fiber) not
// being evenly spaced. They previously used a Wrap with a fixed `spacing`,
// which left-packs children and dumps all leftover width on the right.
// Switching to Row + MainAxisAlignment.spaceEvenly should give equal gaps
// (including the two outer edges) without changing circle size.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/nutrition_details_widget.dart';

void main() {
  testWidgets('nutrition circles are evenly spaced horizontally', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 375,
            child: NutritionDetailsWidget(
              nutrition: Nutrition(calories: 450, protein: 15, fats: 20, carbs: 55, fiber: 12),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    final circleFinder = find.byType(NutritionCircle);
    expect(circleFinder, findsNWidgets(4));

    final rowFinder = find.ancestor(
      of: circleFinder.first,
      matching: find.byType(Row),
    );
    final rowRect = tester.getRect(rowFinder.first);
    final circleRects = [for (int i = 0; i < 4; i++) tester.getRect(circleFinder.at(i))];

    // MainAxisAlignment.spaceEvenly guarantees 5 equal gaps: before the first
    // item, between each pair of items, and after the last item - regardless
    // of each item's own width (unlike Wrap, which left-packs and dumps all
    // slack on the right).
    final gaps = [
      circleRects.first.left - rowRect.left,
      for (int i = 0; i < circleRects.length - 1; i++)
        circleRects[i + 1].left - circleRects[i].right,
      rowRect.right - circleRects.last.right,
    ];

    for (final gap in gaps) {
      expect(gap, closeTo(gaps.first, 1.0));
    }
  });
}
