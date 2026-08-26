## Purpose

Defines the Ingredient Editor's core/sub ingredient behavior: visually distinguishing which ingredients are `core` (the portion-meaningful ones, e.g. a Chapati's flour or a Mixed Vegetable's whole vegetable group) from `sub` (ingredients only meaningful relative to the core group, e.g. water/salt/ghee/oil), and live-recomputing sub-ingredient quantities as core ingredients are edited, mirroring what the backend does authoritatively at Save.

## ADDED Requirements

### Requirement: Core ingredients are visually distinguished from sub ingredients
The Ingredient Editor SHALL visually mark every ingredient whose `role` is `core` as distinct from `sub` ingredients, so a dietician can identify at a glance which ingredient(s) drive the recipe's proportions.

#### Scenario: Single-core recipe
- **WHEN** a dietician opens the Ingredient Editor for a recipe with one `core` ingredient (e.g. Chapati's Whole Wheat Flour)
- **THEN** that ingredient's row is visually marked as core and every other row is not

#### Scenario: Multi-core recipe
- **WHEN** a dietician opens the Ingredient Editor for a recipe with several `core` ingredients (e.g. Mixed Vegetable's Carrot, Beans, Peas, and Cauliflower)
- **THEN** every one of those rows is visually marked as core, and only the remaining (e.g. Oil, Salt) rows are not

### Requirement: Editing a core ingredient live-recomputes sub ingredients in the same session
When a dietician edits a `core` ingredient's quantity or unit, the Ingredient Editor SHALL recompute every `sub` ingredient's quantity in the same proportion as the core ingredient group's total weight change, and update the displayed value for each affected sub-ingredient row immediately, without a network round-trip.

#### Scenario: Increasing a single core ingredient scales sub ingredients live
- **WHEN** a dietician increases a single-core recipe's core ingredient quantity
- **THEN** every sub ingredient's displayed quantity updates immediately to the proportionally scaled value, before Save is tapped

#### Scenario: Increasing a multi-core group's total scales sub ingredients live
- **WHEN** a dietician increases the total quantity across a multi-core recipe's core ingredient group (in one or several of those rows)
- **THEN** every sub ingredient's displayed quantity updates immediately to reflect the resulting proportional change in the core group's total weight

#### Scenario: Rebalancing within a multi-core group without changing its total does not recompute sub ingredients
- **WHEN** a dietician adjusts individual core ingredients within a multi-core group such that the group's total weight is unchanged (e.g. more peas, fewer carrots, same total)
- **THEN** sub ingredients' displayed quantities do not change as a result

### Requirement: Sub ingredients require an explicit override to edit directly
The Ingredient Editor SHALL present sub-ingredient quantity fields as read-only by default, with an explicit "Override" action to make one editable, rather than allowing silent, unqualified direct edits that a later core-ingredient edit in the same session would discard.

#### Scenario: Sub ingredient field starts read-only
- **WHEN** a dietician opens the Ingredient Editor
- **THEN** every `sub` ingredient's quantity field is not directly editable until its override action is used, while every `core` ingredient's field is directly editable as normal

#### Scenario: Overriding a sub ingredient
- **WHEN** a dietician uses a sub ingredient's override action and edits its quantity, without editing any core ingredient afterward in the same session
- **THEN** that submitted value is used on Save exactly as entered, matching the backend's contract for an unchanged core group

### Requirement: Save submits the full ingredient list unchanged in shape
Enabling core/sub-aware live recompute SHALL NOT change the shape of the data submitted on Save — the full ingredient list (including `rawQuantity`/`unit` for every ingredient, `role` included) is submitted exactly as it is today, with the backend remaining the authoritative source of the actually-persisted quantities.

#### Scenario: Save payload shape is unchanged
- **WHEN** a dietician taps Save after editing ingredients in a recipe with core/sub ingredients designated
- **THEN** the submitted request contains the same fields for every ingredient as it did before this capability existed, with no new top-level request field added
