## 1. Model

- [ ] 1.1 Add `final String role;` (default `'sub'` when parsing, matching the backend's own schema default) to `WizardIngredientLine` in `lib/app/modules/diet_plan_wizard/models/wizard_week_models.dart`, parsed in `fromJson` from `json['role']`, and included in `copyWith`; verify with a unit test round-tripping a JSON payload with `role: 'core'` and one with the field absent (defaults to `'sub'`)

## 2. Core-group live recompute

- [ ] 2.1 Add `_coreScaleRatio` getter to `_IngredientEditorSheetState` (`ingredient_editor_sheet.dart`), mirroring `_portionScaleRatio`'s summation but filtered to `role == 'core'` on both `_originalIngredients` and `_ingredients`; verify with a widget test asserting it returns `1` when no ingredient has `role == 'core'`
- [ ] 2.2 In `_updateQuantity`/`_updateUnit`, when the edited ingredient's `role == 'core'`, after updating that entry recompute every `role == 'sub'` entry's `rawQuantity` as `originalSubQuantity * _coreScaleRatio` (looked up from `_originalIngredients` by `foodItemId`) and replace those entries in `_ingredients` within the same `setState`; verify with widget tests for: doubling a single core ingredient doubles every sub ingredient; growing a multi-core group's total scales sub ingredients by that total's ratio regardless of which core ingredient(s) changed; rebalancing within a multi-core group without changing its total leaves sub ingredients unchanged
- [ ] 2.3 Confirm editing a `sub` ingredient never triggers the recompute in 2.2 (only its own entry changes) - verify with a widget test

## 3. Ingredient Editor UI

- [ ] 3.1 In `_IngredientRow`, add a small "Core" tag/badge next to the ingredient name when `ingredient.role == 'core'`; verify visually (single-core recipe shows exactly one tag, multi-core recipe shows one per core ingredient)
- [ ] 3.2 Make a `sub`-role row's quantity `TextField` read-only by default (`readOnly: true` / disabled styling) with a small "Override" tap target that unlocks it for editing for the rest of this sheet's session; verify manually that a fresh sheet open shows sub fields locked and tapping Override unlocks the tapped one
- [ ] 3.3 When a core ingredient is edited after a sub ingredient was unlocked via Override in the same session, visually revert that sub ingredient's field back to locked/recomputed (consistent with 2.2's recompute overwriting its value) rather than leaving it looking editable while actually being about to be discarded; verify manually
- [ ] 3.4 In `_IngredientRowState`, add a `didUpdateWidget` override that updates `_controller.text` to the new formatted `rawQuantity` when `widget.ingredient.rawQuantity` or `.unit` differs from `oldWidget`'s AND the field is not currently focused; verify manually that a sub ingredient's displayed number visibly updates when a core ingredient is edited, without disturbing focus/cursor on whichever field the dietician is actively typing in

## 4. Verification pass

- [ ] 4.1 Run `flutter analyze` and confirm no new warnings/errors across all touched files
- [ ] 4.2 Manual `flutter run` walkthrough: open a single-core recipe (e.g. Chapati, once the backend change and a re-save have given it a designated core ingredient) and confirm editing the core field live-updates sub fields; open a multi-core recipe (e.g. Mixed Vegetable) and confirm the same for the whole core group; confirm a recipe with no core ingredient designated (not yet migrated) behaves exactly as it does today, with no tags and no recompute
