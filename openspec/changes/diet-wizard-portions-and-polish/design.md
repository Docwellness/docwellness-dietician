## Context

See `proposal.md` — Why. Relevant current-state facts that shape the approach:

- **No `servingMultiplier`.** A plan item's portion *is* its `RecipeVersion`. Changing a portion means creating a new `RecipeVersion` (`services/recipeVersioningService.js::createCustomVersion`) and repointing the `PlanItem`. `RecipeVersion.components` (e.g. `[{label:"Chapati", quantity:1, unit:"piece"}]`) is the real-world serving figure the UI renders; `createCustomVersion` rescales it by the calorie ratio.
- **Auto-balance today** (`services/ingredientAutoBalanceService.js`): `autoBalanceIngredients` scales every ingredient's `rawQuantity` by `ratio = targetCalories / currentCalories`, clamped to `[1/3, 3]`. `autoBalanceDay` gives each **unlocked** item a proportional share of `dailyTarget − lockedCalories` and balances each independently. `autoBalanceWeek` loops days. The dietician-app "Auto Adjust" button calls day scope; the Refine Portions step also runs one week-scope pass on entry.
- **The "0.58 piece" bug** comes from that entry pass (or a later Auto Adjust) scaling a Chapati V1 (~154 kcal, 1 piece) down to its ~89 kcal proportional share → component `1 × 0.58`.
- **The "re-adjust after manual edit" bug**: `createCustomRecipeVersion` (the editor's Save) does not lock or otherwise mark the item, so the next `autoBalanceDay` treats it as a normal unlocked item and rescales it.
- **`PlanItem`** has `locked` (blocks auto-balance *and* swap/remove). There is no "edited but still swappable" state.
- **Wizard screens** each hand-roll their layout with local `const Color` values and inline `Container` styling; there is no shared card/pill/chip widget. The patient app's Diet Plan view (`docwellness-user`) already has the target card language: date rail, portion pill, 4-up macro row.
- An in-flight change, `diet-wizard-ux-fixes`, owns the current Generate / Refine / Targets / Recipe-Details deltas and is not yet archived.

## Goals / Non-Goals

**Goals:**

- Countable-serving recipes never auto-compute below 1 serving, and land on clean 0.5 steps, in both generation and auto-balance — with the calorie slack absorbed by other recipes, not left on the floor.
- A hand-edited portion survives every subsequent "Auto Adjust", without the dietician having to also give up swap/remove (i.e. not by reusing `locked`).
- Generate, Timeline, and Finalize share one visual system that reads as the professional counterpart to the patient Diet Plan view, in the existing brand palette.
- Finalize previews the plan per day-group as a meal timeline, with cooking prose tucked away, while keeping the ±5% activation gate byte-for-byte.

**Non-Goals:**

- No change to the days-array data model, the activation contract, `planActivationService`, or the patient app.
- No redesign of the Targets or Generate *generation* step logic (owned by `diet-wizard-ux-fixes`).
- Not attempting a perfect calorie solve after flooring — remaining deviation is left to the activation gate, matching the existing "flag, don't force" philosophy.
- No new typeface bundle; work within the app's current font and `CustomText`.

## Decisions

### D1 — Countable-unit classification lives in one backend helper

New `utils/servingUnits.js`:

```
COUNTABLE_SERVING_UNITS = ['piece', 'nos', 'roti', 'slice', 'egg']   // lower-cased compare
isCountableServing(component)        // component = RecipeVersion.components[0] | undefined → false
snapCountablePortion(qty)            // Math.max(1, Math.round(qty * 2) / 2)
```

Classification is by the recipe's **serving component unit**, never its ingredient units (a Chapati's flour is in grams; the *dish* is in pieces). Multi-component dishes (Idli + Sambar) are treated as non-countable for flooring — there is no single serving to floor, matching how `ingredient_editor_sheet.dart` already refuses "Makes on the plate" for multi-component recipes.

*Alternative considered:* a per-recipe `isCountable` flag on `Recipe`. Rejected — it's derivable, and a flag needs backfilling across the whole catalog (the same trap `menuGenerationService.js` documents for `Recipe.status`).

### D2 — Floor/snap is applied by re-deriving the scale ratio, not by post-editing the component

In `autoBalanceIngredients`, after computing the clamped `ratio`:

1. If the version is countable (`isCountableServing(version.components[0])`):
   - `projectedQty = components[0].quantity_at_V1_baseline × ratio` — but simpler and robust: compute `projectedQty` from the ratio applied to the *current* version's component quantity, i.e. `currentComponentQty × (ratio relative to current)`. Since `autoBalanceIngredients` scales from the *current* version, use `projectedQty = currentComponentQty × ratio`.
   - `snappedQty = snapCountablePortion(projectedQty)`
   - `effectiveRatio = snappedQty / currentComponentQty`
   - rebuild `updatedIngredients` with `effectiveRatio` instead of `ratio`
2. Create the version with the (possibly) adjusted ingredients. `createCustomVersion` then rescales the component off the calorie ratio as it does today, which — because ingredients moved by `effectiveRatio` — lands the component at `snappedQty` (± rounding).
3. Annotate `newVersion._flooredTo = snappedQty` (in-memory, like the existing `_wasScaleClamped`) so the caller knows this item could not freely hit its target.

*Alternative considered:* snap `components[0].quantity` directly in `createCustomVersion` and leave ingredients at the un-snapped ratio. Rejected — it desyncs the component ("1 piece") from the ingredient amounts and the calorie figure ("as if 0.72 piece"), which is exactly the kind of quiet inaccuracy `recipeVersioningService.js` is built to prevent.

### D3 — `autoBalanceDay` solves countable items first, then fills continuous items with the remainder

Replace the single independent-share loop with:

1. Partition unlocked **and unpinned** items into `countable` and `continuous` (skip locked/pinned entirely, as today).
2. For each `countable` item: target = its current proportional share; `autoBalanceIngredients` applies D2; record `achievedCalories`.
3. `remaining = dailyTarget − lockedCalories − pinnedCalories − Σ countable.achievedCalories`.
4. Distribute `remaining` across `continuous` items in proportion to their current calories; `autoBalanceIngredients` each (these won't floor).
5. If `continuous` is empty (or `remaining ≤ 0`), leave the countable results as-is; the day may be outside tolerance — surfaced by the existing `warnings` / activation check, not forced.

Bounded, single pass, deterministic. `autoBalanceWeek` is unchanged (loops `autoBalanceDay`).

*Alternative considered:* iterative re-solve to convergence. Rejected for now — adds non-determinism and latency to a call that runs on every Refine Portions entry; the partition approach is exact whenever there's at least one continuous item, which is the overwhelmingly common case (drinks, dals, sabzis, salads).

### D4 — `pinned` is a new `PlanItem` boolean, distinct from `locked`

- `models/PlanItem.js`: `pinned: { type: Boolean, default: false }`.
- `controllers/dietician/planItemController.js`:
  - `createCustomRecipeVersion` and `updateItemRecipeVersion` set `planItem.pinned = true` before `save()`. This covers both the ingredient editor's Save **and** "Makes (on the plate)" (which saves through the same `create-custom-version` endpoint).
  - `autoBalance` (scope `day`/`week`) → the service filters `!locked && !pinned`.
  - New `PATCH /patients/:patientId/diet-plans/:dietPlanId/plan-items/:planItemId` accepting `{ pinned: boolean }` for unpin (and re-pin). Ownership via the existing `loadOwnedPlanItem`.
- `getWeekPlanItems` maps `pinned` into each item.
- `services/ingredientAutoBalanceService.js`: `autoBalanceDay` filter becomes `!item.locked && !item.pinned && calories > 0`; pinned calories are added to the fixed baseline alongside locked.

*Why not reuse `locked`:* `locked` also blocks swap and remove (`removePlanItem` returns 409, the swap icon is hidden). The dietician who fine-tunes a portion still wants to swap the recipe or drop it — the ask is specifically "don't re-scale what I set", nothing more.

*Why auto-pin rather than a manual pin toggle in the editor:* the editor's whole purpose is deliberate portioning; every Save there is a deliberate choice. An extra "pin this" checkbox would be noise, and forgetting it reintroduces the bug. Unpin stays one tap away on the card.

### D5 — Frontend-design pass: "clinical counterpart" direction

Ran the `frontend-design` brief-first process. Subject: a portioning-and-review workbench for Indian dieticians, used many times a day, right before a plan goes live to a patient. The patient app's Diet Plan view is soft, friendly, spacious. This tool is its **professional counterpart**: same identity, but tighter, more information-dense, with a structural spine.

**Signature element:** a **meal-timeline rail** — a vertical hairline with a filled node per serving-time — down the left of the Finalize (and reused on Timeline & Supplements). It's the one memorable device, it encodes real information (the fixed 7-slot day order), and it visually rhymes with the patient app's own timeline so a dietician recognises "this is what the patient will see".

**Tokens** (Flutter `const` values in a shared `wizard_theme.dart`):

| role | value | note |
|---|---|---|
| `plum` (headers) | `#530630` | unchanged brand |
| `magenta` (primary/actions) | `#851653` | unchanged brand |
| `ink` (body) | `#1F2A37` | unchanged |
| `muted` | `#6C737F` | unchanged |
| `surface` (card) | `#FBF7F9` | warmer than today's `#FAFAFA`, ties to the pink tints |
| `tint` (selected / summary) | `#FDF2FA` | unchanged |
| `line` (hairline rails, dividers) | `#EBD9E4` | new — the rail + card borders |
| `ok` / `warn` | `#12B76A` / `#DC2626` | unchanged (calorie checks) |
| macro icons | monochrome `muted` line icons | protein/fiber/carbs/fat — **not** four colors (avoids the "AI rainbow chip" default) |

**Type scale** (weights on the existing family via `CustomText`): screen title 20/w600 `plum`; section/day-group 14/w600 `ink`; recipe name 13/w600 `ink`; meta (portion, cal, V-number) 11/w400 `muted`; macro value 12/w600 `ink` + 10/w400 `muted` label.

**Shared widgets** (`lib/app/modules/diet_plan_wizard/widgets/`):

- `WizardRecipeCard` — name + right-aligned calorie, portion pill, optional macro row, optional trailing actions (swap / remove / expand), optional "Edited" pin badge.
- `PortionPill` — rounded outline pill, `formatQuantityLabel` text (reuses the existing util).
- `MacroChipRow` — 4-up protein/fiber/carbs/fat, hairline icon + value + label.
- `DayGroupSelector` — horizontal scrollable chip row (4 groups; full 4-segment control where they fit, scroll where they don't).
- `MealTimeline` — the rail + nodes, takes a list of `(servingTime, children)`.
- `WizardSectionHeader` — title + optional trailing action (e.g. "Auto Adjust").

Generate review and Timeline restyle = swapping their hand-rolled containers for these; **no logic touched** (enforced by the `wizard-visual-language` spec's "presentation-only" requirement).

**Restraint:** one signature (the rail). Cooking steps collapse behind an expand with a short size animation; nothing else animates. Selectors keep visible selection + tap feedback. Everything responsive to a narrow phone width — `DayGroupSelector` scrolls rather than clips.

### D6 — This change layers on `diet-wizard-ux-fixes`

`diet-wizard-ux-fixes` should be archived first (its specs land under `openspec/specs/diet-plan-wizard/{generate-step,refine-portions-step,targets-step}` and `recipe-library/recipe-details`). This change adds new sibling capabilities and does not modify those files' *requirements*; it does edit the same source files, so implementation must rebase on that change's final state. If it is abandoned, its already-applied code (auto-balance-on-entry, paired buttons, per-ingredient calories) is still present in the tree and this change still applies cleanly.

## Risks / Trade-offs

- **[Flooring a countable item on a day with no continuous items to absorb it leaves the day off-target]** → Accepted and specified: the day is flagged, not forced; the activation gate already blocks activation until the dietician resolves it. This is strictly better than today (implausible "0.58 piece").
- **[Snapping to 0.5 steps coarsens the calorie solve for plans that are mostly rotis/idlis]** → In practice such plans still have drinks/dals/sabzis as continuous ballast. Documented; revisit only if a real plan can't be brought within ±5%.
- **[`effectiveRatio` after snapping can exceed the existing `[1/3, 3]` clamp]** → Clamp `effectiveRatio` to the same bounds; a snapped target outside them is under/over-shot exactly as an un-snapped one is today.
- **[Auto-pinning surprises a dietician who edited one ingredient and still wanted Auto Adjust to tune it]** → The "Edited" badge is visible on the card and unpin is one tap; the alternative (silent, no affordance) was rejected in the questions. Copy on the badge/confirm should make the effect obvious.
- **[Existing tests assume `autoBalanceDay` rescales every unlocked item]** → `tests/ingredientAutoBalanceService.test.js` and `tests/dietPlanCleverEndpoints.test.js` need updating for the partition + pinned-skip behavior; new cases for floor/redistribute.
- **[Two apps drift: the wizard's shared widgets vs. the patient app's card widgets are separate codebases]** → Accepted; they're different repos. Keep the tokens documented here as the reconciliation point; match visually, don't share code.
- **[Restyle regressions]** → The `wizard-visual-language` spec pins "presentation-only"; the apply phase must include a behavior walkthrough of Generate and Timeline (add/remove/swap/regenerate, supplement staging/flush).

## Migration Plan

1. Backend: add `PlanItem.pinned` (additive, defaults false — no backfill needed; existing plans simply have nothing pinned).
2. Ship `utils/servingUnits.js` + auto-balance changes + pin plumbing + tests behind the normal deploy (dev-api → prod via Coolify, per the prod-infra split).
3. Flutter: land `pinned` parsing + unpin call first (safe with old backend — field just absent → `false`), then the visual work.
4. Rollback: revert the Flutter build; backend `pinned` can stay (inert if the app never sets/reads it). The auto-balance partition change is the only behavioral backend risk — it is covered by tests and is a pure improvement over the current fractional-piece output.

## Open Questions

- Exact macro-icon glyphs for the `MacroChipRow` (reuse the patient app's four line icons vs. Material `Icons` equivalents) — cosmetic, resolvable during implementation without touching specs or tasks.
- Whether "Auto Adjust" should show a one-line "3 recipes rebalanced, Chapati kept" summary toast — nice-to-have, can be added later without spec impact.
