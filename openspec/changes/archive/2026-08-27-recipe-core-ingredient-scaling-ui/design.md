## Context

See proposal.md - Why/What Changes. The Ingredient Editor (`lib/app/modules/diet_plan_wizard/widgets/ingredient_editor_sheet.dart`) already has the exact mechanism this needs, just scoped to the whole ingredient list instead of the core group:

- `_originalIngredients` (immutable snapshot from when the sheet opened) vs `_ingredients` (mutable, edited in-session).
- `_portionScaleRatio` (getter): sums `rawQuantity * resolvedGramsPerUnit` across `_originalIngredients` and across `_ingredients`, returns `current / original` (falling back to `1` when the original total isn't resolvable).
- `_scaledComponents` (getter): applies `_portionScaleRatio` to `widget.item.recipeVersion.components` for the live "Makes (on the plate)" preview.
- `_updateQuantity(index, value)` / `_updateUnit(index, unit)`: the only two places `_ingredients` changes, both via `setState`.
- `_IngredientRow`/`_IngredientRowState`: one `TextEditingController` per row, initialized once from `widget.ingredient.rawQuantity` in `late final`. Today this is fine because nothing external ever changes a row's value after it's built — `onChanged` is the only writer. This change introduces the first case where a row's value needs to change from *outside* that row (a sub ingredient's field updates because a *different* row, the core one, was edited) - `_IngredientRowState` needs to start reacting to `didUpdateWidget` to keep its `TextEditingController` in sync, or a scaled-up sub ingredient's field will keep showing its old value until the row happens to rebuild for an unrelated reason.

`WizardIngredientLine` (`lib/app/modules/diet_plan_wizard/models/wizard_week_models.dart`) has no `role` field yet - the backend change (`recipe-core-ingredient-scaling`, docwellness-backend) adds `role` to `RecipeVersion.ingredients[]`, and confirmed (read `controllers/dietician/planItemController.js`'s `getWeekPlanItems`) that endpoint already spreads `...ing` (the raw ingredient subdocument) before adding its own joined fields (`foodItemName`, `nutritionPer100g`, `resolvedGramsPerUnit`) - so `role` reaches this client automatically once the backend schema change ships, with no endpoint change needed on either side for that alone.

## Goals / Non-Goals

**Goals:**
- Extend the existing `_portionScaleRatio` pattern (not replace it) with a second, core-group-scoped ratio that drives sub-ingredient recompute, keeping the existing whole-list ratio exactly as it is today for the components preview (per the backend spec, `components` still scales off the overall calorie/weight change, not specifically the core group).
- Make it visually unambiguous which ingredient(s) are core, and make it structurally hard to lose a sub-ingredient override to a later core edit in the same session (the read-only-until-overridden field, not just documentation).
- Zero change to what gets submitted on Save - this is a preview layer in front of an unchanged request.

**Non-Goals:**
- No change to `PlanItemFinalizeStepController.editIngredients`, the wizard service's `create-custom-version` call, or any other network call - purely local state/UI.
- No handling for a recipe with zero `role: core` ingredients beyond graceful degradation (see Decisions) - matches the backend's "inert, not an error" behavior for legacy recipes exactly.
- Not attempting to reconcile with `diet-wizard-ux-fixes`'s own pending (uncommitted, but already fully implemented in code) `diet-plan-wizard/refine-portions-step` capability declaration - this change deliberately uses its own capability path (`diet-plan-wizard/core-ingredient-scaling`) to avoid a two-pending-changes-claim-the-same-path conflict; reconciling/archiving that stale change is a separate, pre-existing housekeeping task, not part of this change.

## Decisions

**A second ratio getter, `_coreScaleRatio`, computed the same way as `_portionScaleRatio` but summed only over `role == 'core'` ingredients.**
Mirrors the existing pattern exactly (`resolvedGramsPerUnit`-based summation, `original`/`current` from the same two lists, falls back to `1` when unresolvable) rather than introducing a different calculation style - a reviewer who already understands `_portionScaleRatio` reads `_coreScaleRatio` for free. When no ingredient has `role == 'core'` (a not-yet-migrated recipe, per the backend's legacy fallback), the core total on both sides is `0`, and the ratio getter returns `1` (its existing divide-by-zero guard) - sub-ingredient recompute becomes a no-op automatically, with no separate "does this recipe support this feature" branch needed anywhere else in the widget.

**Recompute fires from within `_updateQuantity`/`_updateUnit`, only for ingredients with `role == 'core'`.**
When the edited ingredient (`_ingredients[index]`) has `role == 'core'`, after applying its own `copyWith`, the same `setState` block recomputes every `role == 'sub'` ingredient's `rawQuantity` as `originalSubQuantity * newCoreRatio` (looked up from `_originalIngredients` by `foodItemId`, same lookup style already used elsewhere in this file) and replaces those entries in `_ingredients`. Editing a `sub` ingredient never triggers this - it only ever updates its own entry, identical to today.

**Sub-ingredient fields: read-only text + an explicit "Override" tap-to-unlock action, not a permanently-disabled field or a silent-allow.**
Three options considered:
1. *Leave every field freely editable, as today* - rejected: a dietician who hand-tunes salt and then, in the same visit, nudges the core flour amount would see their salt edit silently discarded at Save (per the backend's documented trade-off) with zero on-screen indication anything happened - a genuinely confusing, hard-to-notice bug-shaped UX.
2. *Permanently lock sub-ingredient fields (core-only editing, full stop)* - rejected: removes the legitimate, backend-supported "reduce salt for a hypertensive patient" case entirely from the UI even though the server still supports it.
3. *Read-only by default, one explicit tap to unlock a specific sub ingredient's field for this session* (chosen) - makes the two states (recomputed-from-core vs. deliberately-overridden) visually distinct as they're happening, not just discoverable after a confusing Save; a dietician who unlocks a sub ingredient and then edits a core ingredient afterward in the same visit can still be warned in-place (e.g. the unlocked field visually reverts to locked/recomputed) rather than silently losing the edit with no feedback at all.

**`_IngredientRowState` syncs its `TextEditingController` on `didUpdateWidget` when the value changed externally.**
Compares `widget.ingredient.rawQuantity`/`unit` against `oldWidget`'s in `didUpdateWidget`; if either changed and the field doesn't currently have focus (a dietician actively typing in a different field shouldn't have some unrelated row's cursor/selection disturbed - only an unfocused row's controller is safe to overwrite wholesale), updates `_controller.text` to the new formatted value. This is the one genuinely new piece of state-management plumbing this change needs; everything else composes existing patterns.

## Risks / Trade-offs

- [The "Override" interaction adds a tap most dieticiens won't need most of the time (only relevant when they specifically want a non-proportional sub-ingredient value).] → Mitigation: only sub ingredients are gated this way; core ingredients (the common edit) stay a single plain tap-and-type, unchanged from today.
- [`didUpdateWidget`-based controller sync is a known source of subtle Flutter bugs (cursor jumping, focus loss) if done carelessly.] → Mitigation: only sync when the row is unfocused, and only when the value actually differs from what the controller already shows (avoid clobbering an in-progress edit or resetting cursor position on unrelated rebuilds).
- [A recipe with ingredients spanning units where `resolvedGramsPerUnit` resolves for some but not all core ingredients could show a partial, slightly-off live preview if the getter isn't careful, and this per-ingredient-skip convention is looser than the backend's own all-or-nothing "any unresolvable core ingredient means no recompute at all" rule.] → Mitigation: `_coreScaleRatio` reuses `_portionScaleRatio`'s existing per-ingredient-skip convention (an ingredient with no resolvable weight contributes to neither side, not treated as 0) rather than inventing a stricter all-or-nothing client-side check - acceptable because this is only ever a same-session preview; the backend remains authoritative at Save and applies its own stricter rule there, so the two never disagreeing matters far less than the preview staying visually consistent with the recipe's other existing live figures (`_portionScaleRatio`/`_scaledComponents`), which already use the looser convention today.
