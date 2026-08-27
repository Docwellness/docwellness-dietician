// recipe-core-ingredient-scaling-ui: IngredientEditorSheet's core/sub
// live-recompute (_coreScaleRatio, _updateQuantity/_updateUnit) and UI
// (core badge, locked-by-default sub fields with Override, controller
// sync on external recompute). See openspec/changes/
// recipe-core-ingredient-scaling-ui.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/models/wizard_week_models.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/widgets/ingredient_editor_sheet.dart';

WizardIngredientLine _line({
  required String id,
  required double qty,
  String unit = 'g',
  required String role,
  double gramsPerUnit = 1,
}) =>
    WizardIngredientLine(
      foodItemId: id,
      foodItemName: id,
      rawQuantity: qty,
      unit: unit,
      role: role,
      resolvedGramsPerUnit: gramsPerUnit,
    );

WizardPlanItemV2 _planItem(List<WizardIngredientLine> ingredients, {List<WizardComponent> components = const []}) =>
    WizardPlanItemV2(
      id: 'item1',
      recipeVersionId: 'v1',
      recipeVersion: WizardRecipeVersion(
        id: 'v1',
        parentRecipeId: 'recipe1',
        name: 'Test Recipe',
        versionNumber: 1,
        ingredients: ingredients,
        steps: const [],
        components: components,
        hasUnresolvedIngredients: false,
      ),
      locked: false,
      isLinkedComponent: false,
    );

Future<void> _pumpSheet(WidgetTester tester, WizardPlanItemV2 item) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: IngredientEditorSheet(item: item, onSave: (_) async => true),
      ),
    ),
  );
  await tester.pump();
}

Finder _quantityFieldFor(String foodItemId) =>
    find.descendant(of: find.byKey(ValueKey(foodItemId)), matching: find.byType(TextField));

Finder _lockIconFor(String foodItemId) =>
    find.descendant(of: find.byKey(ValueKey(foodItemId)), matching: find.byType(IconButton));

String _textOf(WidgetTester tester, Finder fieldFinder) => tester.widget<TextField>(fieldFinder).controller!.text;

void main() {
  group('single-core recompute', () {
    testWidgets('doubling the sole core ingredient doubles the sub ingredient', (tester) async {
      final item = _planItem([
        _line(id: 'flour', qty: 100, role: 'core'),
        _line(id: 'water', qty: 60, role: 'sub'),
      ]);
      await _pumpSheet(tester, item);

      await tester.enterText(_quantityFieldFor('flour'), '200');
      await tester.pump();

      expect(_textOf(tester, _quantityFieldFor('water')), '120');
    });

    testWidgets('a recipe with no core ingredient designated: editing an ingredient never recomputes others', (tester) async {
      final item = _planItem([
        _line(id: 'rice', qty: 100, role: 'sub'), // not-yet-migrated: nothing is 'core'
        _line(id: 'salt', qty: 5, role: 'sub'),
      ]);
      await _pumpSheet(tester, item);

      // 'sub' fields start locked, but with no core ingredient at all this
      // recipe behaves exactly as it did before this feature - both fields
      // should still be directly editable (isCore is only used to lock
      // 'sub' fields, and here there's no 'core' to distinguish against;
      // confirm salt is unaffected by editing rice regardless).
      await tester.tap(_lockIconFor('rice'));
      await tester.pump();
      await tester.enterText(_quantityFieldFor('rice'), '300');
      await tester.pump();

      expect(_textOf(tester, _quantityFieldFor('salt')), '5');
    });
  });

  group('multi-core recompute (Mixed Vegetable-style)', () {
    testWidgets('growing the core group total via just one core ingredient scales the sub by the aggregate ratio', (tester) async {
      final item = _planItem([
        _line(id: 'carrot', qty: 100, role: 'core'),
        _line(id: 'peas', qty: 100, role: 'core'),
        _line(id: 'oil', qty: 10, role: 'sub'),
      ]);
      await _pumpSheet(tester, item);

      // carrot 100 -> 250: total core 200 -> 350, ratio 1.75
      await tester.enterText(_quantityFieldFor('carrot'), '250');
      await tester.pump();

      expect(_textOf(tester, _quantityFieldFor('oil')), '17.5');
    });

    testWidgets('rebalancing within the core group without changing its total leaves the sub unchanged', (tester) async {
      final item = _planItem([
        _line(id: 'carrot', qty: 100, role: 'core'),
        _line(id: 'peas', qty: 100, role: 'core'),
        _line(id: 'oil', qty: 10, role: 'sub'),
      ]);
      await _pumpSheet(tester, item);

      // carrot +50, peas -50: total stays 200, ratio ~1 - oil untouched.
      await tester.enterText(_quantityFieldFor('carrot'), '150');
      await tester.pump();
      await tester.enterText(_quantityFieldFor('peas'), '50');
      await tester.pump();

      expect(_textOf(tester, _quantityFieldFor('oil')), '10');
    });

    testWidgets('every core row shows the Core badge, sub rows do not', (tester) async {
      final item = _planItem([
        _line(id: 'carrot', qty: 100, role: 'core'),
        _line(id: 'peas', qty: 100, role: 'core'),
        _line(id: 'oil', qty: 10, role: 'sub'),
      ]);
      await _pumpSheet(tester, item);

      expect(find.text('Core'), findsNWidgets(2));
    });
  });

  group('sub-ingredient override', () {
    testWidgets('a sub field is read-only until Override is tapped, then accepts the typed value verbatim', (tester) async {
      final item = _planItem([
        _line(id: 'flour', qty: 100, role: 'core'),
        _line(id: 'water', qty: 60, role: 'sub'),
      ]);
      await _pumpSheet(tester, item);

      final waterFieldBefore = tester.widget<TextField>(_quantityFieldFor('water'));
      expect(waterFieldBefore.readOnly, isTrue);

      await tester.tap(_lockIconFor('water'));
      await tester.pump();

      final waterFieldAfterUnlock = tester.widget<TextField>(_quantityFieldFor('water'));
      expect(waterFieldAfterUnlock.readOnly, isFalse);

      await tester.enterText(_quantityFieldFor('water'), '999');
      await tester.pump();
      expect(_textOf(tester, _quantityFieldFor('water')), '999');
    });

    testWidgets('editing an unlocked sub ingredient never affects another sub ingredient (recompute never fires from a sub edit)', (tester) async {
      final item = _planItem([
        _line(id: 'carrot', qty: 100, role: 'core'),
        _line(id: 'oil', qty: 10, role: 'sub'),
        _line(id: 'salt', qty: 5, role: 'sub'),
      ]);
      await _pumpSheet(tester, item);

      await tester.tap(_lockIconFor('oil'));
      await tester.pump();
      await tester.enterText(_quantityFieldFor('oil'), '50');
      await tester.pump();

      expect(_textOf(tester, _quantityFieldFor('salt')), '5');
    });

    testWidgets('a sub override is discarded and the field reverts to locked when a core ingredient is edited afterward', (tester) async {
      final item = _planItem([
        _line(id: 'flour', qty: 100, role: 'core'),
        _line(id: 'water', qty: 60, role: 'sub'),
      ]);
      await _pumpSheet(tester, item);

      await tester.tap(_lockIconFor('water'));
      await tester.pump();
      await tester.enterText(_quantityFieldFor('water'), '999');
      await tester.pump();

      // Now edit the core ingredient - the override should be discarded and
      // recomputed, and the field should visually revert to locked.
      await tester.enterText(_quantityFieldFor('flour'), '200');
      await tester.pump();

      expect(_textOf(tester, _quantityFieldFor('water')), '120'); // 60 * 2, not 999
      final waterFieldAfter = tester.widget<TextField>(_quantityFieldFor('water'));
      expect(waterFieldAfter.readOnly, isTrue); // reverted to locked
    });
  });

  group('"Makes (on the plate)" reverse edit', () {
    final editTrigger = find.byKey(const Key('makesOnPlateEditTrigger'));

    testWidgets('a single-component recipe shows the edit trigger', (tester) async {
      final item = _planItem(
        [_line(id: 'flour', qty: 40, role: 'core'), _line(id: 'water', qty: 24, role: 'sub')],
        components: [WizardComponent(label: 'Chapati', quantity: 1, unit: 'piece')],
      );
      await _pumpSheet(tester, item);

      expect(editTrigger, findsOneWidget);
    });

    testWidgets('a multi-component recipe does NOT show the edit trigger', (tester) async {
      final item = _planItem(
        [_line(id: 'idli-rice', qty: 100, role: 'core'), _line(id: 'sambar-dal', qty: 50, role: 'core')],
        components: [
          WizardComponent(label: 'Idli', quantity: 3, unit: 'nos'),
          WizardComponent(label: 'Sambar', quantity: 1, unit: 'bowl'),
        ],
      );
      await _pumpSheet(tester, item);

      expect(editTrigger, findsNothing);
    });

    testWidgets('doubling the quantity in the same unit doubles the core ingredient (and cascades to sub)', (tester) async {
      final item = _planItem(
        [_line(id: 'flour', qty: 40, role: 'core'), _line(id: 'water', qty: 24, role: 'sub')],
        components: [WizardComponent(label: 'Chapati', quantity: 1, unit: 'piece')],
      );
      await _pumpSheet(tester, item);

      await tester.tap(editTrigger);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('makesOnPlateQuantityField')), '2');
      await tester.tap(find.byKey(const Key('makesOnPlateApplyButton')));
      await tester.pumpAndSettle();

      expect(_textOf(tester, _quantityFieldFor('flour')), '80'); // 40 * 2
      expect(_textOf(tester, _quantityFieldFor('water')), '48'); // 24 * 2, cascaded
    });

    testWidgets('switching to grams sets the core group to that literal weight', (tester) async {
      final item = _planItem(
        [_line(id: 'flour', qty: 40, role: 'core'), _line(id: 'water', qty: 24, role: 'sub')],
        components: [WizardComponent(label: 'Chapati', quantity: 1, unit: 'piece')],
      );
      await _pumpSheet(tester, item);

      await tester.tap(editTrigger);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('makesOnPlateQuantityField')), '80');
      await tester.tap(find.byKey(const Key('makesOnPlateUnitDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('g').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('makesOnPlateApplyButton')));
      await tester.pumpAndSettle();

      // 80g target == exactly double the original 40g core group, so this
      // should land on the exact same result as the same-unit doubling
      // test above - confirms the g/ml literal-target path and the
      // ratio-based path agree when they logically should.
      expect(_textOf(tester, _quantityFieldFor('flour')), '80');
      expect(_textOf(tester, _quantityFieldFor('water')), '48');
    });

    testWidgets('re-editing back to the original quantity restores the original ingredient values', (tester) async {
      final item = _planItem(
        [_line(id: 'flour', qty: 40, role: 'core'), _line(id: 'water', qty: 24, role: 'sub')],
        components: [WizardComponent(label: 'Chapati', quantity: 1, unit: 'piece')],
      );
      await _pumpSheet(tester, item);

      await tester.tap(editTrigger);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('makesOnPlateQuantityField')), '3');
      await tester.tap(find.byKey(const Key('makesOnPlateApplyButton')));
      await tester.pumpAndSettle();
      expect(_textOf(tester, _quantityFieldFor('flour')), '120'); // 40 * 3

      await tester.tap(editTrigger);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('makesOnPlateQuantityField')), '1');
      await tester.tap(find.byKey(const Key('makesOnPlateApplyButton')));
      await tester.pumpAndSettle();

      expect(_textOf(tester, _quantityFieldFor('flour')), '40'); // back to original, not compounded
      expect(_textOf(tester, _quantityFieldFor('water')), '24');
    });
  });
}
