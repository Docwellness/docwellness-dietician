## Why

The backend change `recipe-core-ingredient-scaling` (docwellness-backend, proposal stage) adds a `role: 'core' | 'sub'` designation to recipe ingredients and server-side proportional recompute of sub-ingredient quantities when the core ingredient group's total weight changes. None of that is visible or usable in the Ingredient Editor (`IngredientEditorSheet`, the Step 3/Refine-Portions sheet shown when a dietician edits Chapati/Kala Chana Curry/etc.'s quantities) without app-side changes: today every ingredient row looks and behaves identically, and editing one never visibly affects any other row until after Save. The editor already has the exact live-recompute machinery this needs — `_portionScaleRatio`/`_scaledComponents` already recompute a weight ratio and live-preview "Makes (on the plate)" locally as ingredients are typed — this proposal extends that same pattern to sub-ingredient quantities, keyed off the new `role` field.

## What Changes

- `WizardIngredientLine` gains a `role` field (`'core' | 'sub'`, parsed from the `role` the backend change adds to `RecipeVersion.ingredients[]` — already flows through `GET .../weeks/:week/plan-items` automatically today, since that endpoint spreads the raw ingredient subdocument).
- `_IngredientRow` visually distinguishes core ingredients (e.g. a small "Core" tag) from sub ingredients, so a dietician can tell at a glance which field is the one that drives the rest.
- When a **core** ingredient's quantity or unit is edited, the sheet live-recomputes every **sub** ingredient's `rawQuantity` in the same session, mirroring the existing `_portionScaleRatio` pattern but scoped to the core-ingredient group's total weight instead of every ingredient — the sub ingredient rows' text fields update to reflect the new values immediately, without waiting for Save.
- When a **sub** ingredient is edited directly (core group unchanged), no recompute happens — that edit is a deliberate override, exactly matching the backend's contract for that case.
- Sub-ingredient rows' quantity fields become read-only-by-default with an explicit "Override" affordance to edit them directly — surfacing, in the UI, the same two-step limitation the backend design accepts (a dietician can't change core and hand-tune a sub ingredient in one Save) rather than letting the dietician type into a field whose value will be silently discarded server-side if they also change a core ingredient in the same visit.
- On Save, the sheet still submits the full `_ingredients` list exactly as it does today (`widget.onSave(_ingredients)`) — no request-shape change on this side either; the client-side recompute is a preview, the backend remains authoritative.

## Capabilities

### New Capabilities
- `diet-plan-wizard/core-ingredient-scaling`: the Ingredient Editor's core/sub visual distinction, live sub-ingredient recompute, and the sub-ingredient override affordance.

### Modified Capabilities
(none — no existing capability under `openspec/specs/` covers this screen yet; note `diet-wizard-ux-fixes`, a separate in-flight change touching this same file, proposed `diet-plan-wizard/refine-portions-step` as a capability but its own artifacts were never committed/archived even though its code already shipped — see design.md's Context for how this change avoids colliding with it)

## Impact

- `lib/app/modules/diet_plan_wizard/models/wizard_week_models.dart`: `WizardIngredientLine` gains `role`.
- `lib/app/modules/diet_plan_wizard/widgets/ingredient_editor_sheet.dart`: `_IngredientRow` (core/sub badge, read-only-vs-override sub field), `_IngredientEditorSheetState` (new sub-ingredient recompute logic alongside the existing `_portionScaleRatio`, `_updateQuantity`/`_updateUnit`).
- Depends on the backend change `recipe-core-ingredient-scaling` shipping first (specifically: `role` present on `RecipeVersion.ingredients[]`) — this change adds no new backend calls and needs no new endpoint, since `GET .../weeks/:week/plan-items` already forwards unknown ingredient-subdocument fields verbatim.
- No change to the Save request shape or `PlanItemFinalizeStepController.editIngredients`/`create-custom-version` call.
