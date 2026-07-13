// Verifies the dietary-habit mutual-exclusion logic and the client-side
// ingredient-conflict pre-check added to ReceipesController, without needing
// to drive the actual running app.

import 'package:flutter_test/flutter_test.dart';
import 'package:docwellnesdoc/app/modules/receipes/controllers/receipes_controller.dart';

int _indexOf(ReceipesController c, String name) =>
    c.dietOptions.indexWhere((e) => e.name == name);

void main() {
  group('toggleDietOption mutual exclusion', () {
    test('selecting Non-Vegetarian turns off Jain, Vegetarian, Eggetarian', () {
      final c = ReceipesController();
      c.toggleDietOption(_indexOf(c, 'Jain'));
      c.toggleDietOption(_indexOf(c, 'Vegetarian'));
      expect(c.selectedOptions.toSet(), {'Jain', 'Vegetarian'});

      c.toggleDietOption(_indexOf(c, 'Non-Vegetarian'));

      expect(c.selectedOptions.toSet(), {'Non-Vegetarian'});
    });

    test('Vegan and Eggetarian can never both be selected', () {
      final c = ReceipesController();
      c.toggleDietOption(_indexOf(c, 'Vegan'));
      c.toggleDietOption(_indexOf(c, 'Eggetarian'));

      expect(c.selectedOptions, ['Eggetarian']);
    });

    test('Jain can combine with Vegetarian', () {
      final c = ReceipesController();
      c.toggleDietOption(_indexOf(c, 'Vegetarian'));
      c.toggleDietOption(_indexOf(c, 'Jain'));

      expect(c.selectedOptions.toSet(), {'Vegetarian', 'Jain'});
    });

    test('selecting Eggetarian while Jain is active turns Jain off', () {
      final c = ReceipesController();
      c.toggleDietOption(_indexOf(c, 'Jain'));
      c.toggleDietOption(_indexOf(c, 'Eggetarian'));

      expect(c.selectedOptions, ['Eggetarian']);
    });

    test('reproduces the reported screenshot bug: is now impossible', () {
      // Screenshot showed Jain, Vegetarian, Non-Vegetarian, Eggetarian all ON
      // simultaneously. Tapping each in turn must never allow more than one
      // base category (+ optionally Jain) active at once.
      final c = ReceipesController();
      for (final name in ['Jain', 'Vegetarian', 'Non-Vegetarian', 'Eggetarian']) {
        c.toggleDietOption(_indexOf(c, name));
      }
      expect(c.selectedOptions.length, lessThanOrEqualTo(1));
    });
  });

  group('validateInputs ingredient conflict pre-check', () {
    test('Jain + Garlic in custom ingredients is rejected', () {
      final c = ReceipesController();
      c.recipeNameController.text = 'Chickpeas Salad';
      c.selectedServingTime.value = 'Evening Snack';
      c.selectedServingCount.value = '1';
      c.toggleDietOption(_indexOf(c, 'Jain'));
      c.customPreferencesController.text = 'lemon - 1.5 tbs mustard - salt - garlic';

      final error = c.validateInputs();

      expect(error, isNotNull);
      expect(error, contains('garlic'));
    });

    test('Jain without excluded ingredients passes', () {
      final c = ReceipesController();
      c.recipeNameController.text = 'Chickpeas Salad';
      c.selectedServingTime.value = 'Evening Snack';
      c.selectedServingCount.value = '1';
      c.toggleDietOption(_indexOf(c, 'Jain'));
      c.customPreferencesController.text = 'lemon, mustard, salt';

      expect(c.validateInputs(), isNull);
    });

    test('Oil-free + "extra virgin olive oil" in custom ingredients is rejected', () {
      final c = ReceipesController();
      c.recipeNameController.text = 'Chickpeas Salad';
      c.selectedServingTime.value = 'Evening Snack';
      c.selectedServingCount.value = '1';
      c.freeFromOptions.firstWhere((e) => e.key == 'oil').isChecked = true;
      c.customPreferencesController.text = 'extra virgin olive oil';

      final error = c.validateInputs();

      expect(error, isNotNull);
      expect(error, contains('Oil-free'));
    });

    test('"eggplant" does not false-positive against Vegetarian\'s egg exclusion', () {
      final c = ReceipesController();
      c.recipeNameController.text = 'Veg Curry';
      c.selectedServingTime.value = 'Lunch';
      c.selectedServingCount.value = '2';
      c.toggleDietOption(_indexOf(c, 'Vegetarian'));
      c.customPreferencesController.text = 'add eggplant';

      expect(c.validateInputs(), isNull);
    });
  });
}
