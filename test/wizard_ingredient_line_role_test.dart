// recipe-core-ingredient-scaling-ui: WizardIngredientLine.role round-trips
// through fromJson (default 'sub' when absent) and is preserved by
// copyWith, without ever being sent back via toJson (the server always
// derives/recomputes it itself - see the field's own doc comment).

import 'package:flutter_test/flutter_test.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/models/wizard_week_models.dart';

void main() {
  group('WizardIngredientLine.role', () {
    test('fromJson parses role: "core"', () {
      final line = WizardIngredientLine.fromJson({
        'foodItemId': 'abc123',
        'rawQuantity': 100,
        'unit': 'g',
        'role': 'core',
      });
      expect(line.role, 'core');
    });

    test('fromJson defaults to "sub" when role is absent (legacy/not-yet-migrated recipe)', () {
      final line = WizardIngredientLine.fromJson({
        'foodItemId': 'abc123',
        'rawQuantity': 100,
        'unit': 'g',
      });
      expect(line.role, 'sub');
    });

    test('fromJson treats any unrecognized role value as "sub"', () {
      final line = WizardIngredientLine.fromJson({
        'foodItemId': 'abc123',
        'rawQuantity': 100,
        'unit': 'g',
        'role': 'garbage',
      });
      expect(line.role, 'sub');
    });

    test('copyWith preserves role', () {
      final core = WizardIngredientLine(foodItemId: 'a', rawQuantity: 100, unit: 'g', role: 'core');
      final updated = core.copyWith(rawQuantity: 200);
      expect(updated.role, 'core');
    });

    test('toJson never includes role - the server always derives it itself', () {
      final line = WizardIngredientLine(foodItemId: 'a', rawQuantity: 100, unit: 'g', role: 'core');
      expect(line.toJson().containsKey('role'), isFalse);
    });
  });
}
