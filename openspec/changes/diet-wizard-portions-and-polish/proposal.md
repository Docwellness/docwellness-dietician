## Why

Dieticians building a plan through the "Create Diet Plan" wizard hit two portioning problems and three screens that look unfinished (surfaced via screenshots):

1. Auto-balance can scale a countable staple (Chapati, Bhakri, roti) down to implausible fractions like "0.58 piece" in the first generated plan — a real diet sheet never prescribes half a roti as a starting point.
2. After a dietician manually sets a recipe's portion (e.g. Chapati → 1 piece), tapping "Auto Adjust" for that day silently re-scales that same recipe again (1 → 0.96 piece), discarding the deliberate choice instead of solving the day's calorie gap with the other recipes.
3. The Generate review, Timeline & Supplements, and Review & Finalize screens are plain lists with ad-hoc spacing; the Finalize screen in particular dumps every day-group's recipes and full cooking-step prose in one scroll, unlike the polished patient-facing Diet Plan view the same plan is eventually shown in.

## What Changes

### Portioning

- **Serving-size realism in generation and auto-balance**: when a recipe's real-world serving is a countable unit (`piece`/`nos`/`roti`/`slice`/`egg` and equivalents), its auto-computed portion is floored at **1** and snapped to the nearest **0.5** step (1, 1.5, 2, …). The calorie difference this floor introduces is redistributed across the day's other non-pinned, non-locked items so the day still lands on target. Gram/ml/tbsp/bowl recipes are unaffected.
- **Manual portion edits are pinned**: saving an ingredient edit or a "Makes (on the plate)" edit for a plan item marks that item **pinned**. "Auto Adjust" (day and week) skips pinned items exactly as it already skips `locked` items, and rebalances only the rest of the day toward the target. Pinning is a new state, distinct from `locked` (which also blocks swap/remove).
- **Pin visibility**: a pinned plan item shows a small "Edited" indicator on its Refine Portions card, tappable to unpin (which returns it to Auto Adjust's pool). Locked items are unchanged.

### Visual polish (Flutter only, no behavior change)

- **Shared wizard visual language**: one card/badge/typography system applied across the Generate review, Timeline & Supplements, and Finalize screens — consistent recipe cards, portion pills, macro chips, and section rhythm, aligned with the patient app's Diet Plan view and the existing `#851653 / #530630` brand palette. Built following the `frontend-design` skill's brief-first process (documented in `design.md`).
- **Generate review screen**: restyled recipe cards and slot/day-group selectors; no change to add/remove/swap/regenerate behavior.
- **Timeline & Supplements screen**: restyled day-group sections and per-slot supplement rows; no change to supplement staging/flush behavior.

### Finalize / Review screen redesign

- **Day-group selector + meal timeline**: the Review & Finalize screen gains a horizontal day-group selector (Mon & Fri / Tue & Sat / Wed & Sun / Thu) at the top; below it, only the selected day-group's meals render, as a vertical meal timeline of recipe cards showing portion pill, calories, and per-recipe macro icons (protein / fiber / carbs / fat), matching the patient Diet Plan view's card language.
- Full cooking-step prose moves behind a per-recipe expand rather than always-on.
- The per-day ±5% calorie-tolerance checks and the "Confirm & Activate" gate are retained and unchanged.

## Capabilities

### New Capabilities

- `diet-plan-wizard/portion-realism`: serving-size floors and 0.5-step snapping for countable-unit recipes during menu generation and auto-balance, with calorie redistribution to other items.
- `diet-plan-wizard/refine-portions-pinning`: manual portion edits pin a plan item so "Auto Adjust" excludes it and rebalances the remaining items; pin indicator and unpin affordance on the Refine Portions card.
- `diet-plan-wizard/finalize-step`: Review & Finalize screen with a day-group selector, patient-style meal-timeline recipe cards, collapsible cooking steps, and the retained activation-tolerance gate.
- `diet-plan-wizard/wizard-visual-language`: a shared visual system (cards, portion pills, macro chips, typography scale, spacing) applied to the Generate review and Timeline & Supplements screens.

### Modified Capabilities

(none — the affected wizard steps have no requirements under `openspec/specs/` yet; the in-flight `diet-wizard-ux-fixes` change owns the current `generate-step` / `refine-portions-step` deltas and should be archived before or alongside this one.)

## Impact

**docwellness-backend** (Node/Express/Mongo):
- `services/menuGenerationService.js` — apply serving-size floor/snap when creating the initial PlanItems.
- `services/ingredientAutoBalanceService.js` — respect a new `pinned` flag; apply countable-unit floor/snap per item; redistribute the floored deficit across remaining unlocked/unpinned items.
- `models/PlanItem.js` — add `pinned: Boolean` (default false).
- `controllers/dietician/planItemController.js` — `createCustomRecipeVersion` and `updateItemRecipeVersion` set `pinned: true`; `auto-balance` (day/week) excludes pinned items; new endpoint or flag to toggle `pinned`.
- `utils/` — a small shared helper for "is this a countable serving unit" + snap math (mirrors `utils/recipeJsonSchema.js`'s `COMPONENT_UNITS`).
- `services/recipeVersioningService.js` — component-quantity snapping when the resulting serving is countable.
- Tests: `tests/ingredientAutoBalanceService.test.js`, `tests/dietPlanCleverEndpoints.test.js`, plus new coverage for the floor/redistribute path.

**docwellness-dietician** (Flutter/GetX):
- `lib/app/modules/diet_plan_wizard/models/wizard_week_models.dart` — parse `pinned` on `WizardPlanItemV2`.
- `lib/app/modules/diet_plan_wizard/services/diet_plan_wizard_service.dart` — pin/unpin call.
- `lib/app/modules/diet_plan_wizard/controllers/refine_portions_step_controller.dart` — unpin action; keep the one-shot balance respecting pins.
- `lib/app/modules/diet_plan_wizard/views/refine_portions_step_view.dart` — "Edited" indicator + unpin.
- `lib/app/modules/diet_plan_wizard/views/generate_review_view.dart` — visual restyle.
- `lib/app/modules/diet_plan_wizard/views/timeline_step_view.dart` — visual restyle.
- `lib/app/modules/diet_plan_wizard/views/plan_item_finalize_step_view.dart` + `controllers/plan_item_finalize_step_controller.dart` — day-group selector, meal-timeline cards, collapsible steps.
- New shared widgets under `lib/app/modules/diet_plan_wizard/widgets/` (recipe card, portion pill, macro chip row) and/or `lib/app/utils/common_widgets/`.
- `~/.claude/skills/frontend-design/` — the `frontend-design` skill is installed for this and future UI work (personal skill; not vendored into the repo).

No change to the patient app, the diet-plan activation contract, or the plan-item / days-array data-model split.
