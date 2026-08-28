## Purpose

Protects a dietician's deliberate portion choices: once a recipe's ingredients or serving size are edited by hand, "Auto Adjust" leaves that recipe alone and solves the day's calorie gap with the other recipes instead.

## ADDED Requirements

### Requirement: Manual portion edits pin the plan item

The system SHALL mark a plan item as **pinned** when a dietician saves either an ingredient-quantity edit or a "Makes (on the plate)" edit for that item. Pinning SHALL persist with the plan item until explicitly removed. Pinned SHALL be a distinct state from locked: a pinned item MAY still be swapped or removed, whereas a locked item may not.

#### Scenario: Saving an ingredient edit pins the item

- **WHEN** a dietician opens the ingredient editor for a Chapati, changes it to 1 piece, and taps Save
- **THEN** that Chapati plan item is pinned

#### Scenario: Saving a "Makes on the plate" edit pins the item

- **WHEN** a dietician edits "Makes (on the plate)" for a recipe and applies it, then saves
- **THEN** that plan item is pinned

#### Scenario: Auto-balance does not pin

- **WHEN** the step's one-shot automatic balance runs, or a dietician taps "Auto Adjust"
- **THEN** no plan item is pinned as a result

### Requirement: Auto Adjust excludes pinned items

"Auto Adjust" (day scope and week scope) SHALL exclude pinned plan items from rescaling, exactly as it already excludes locked items, and SHALL rebalance only the remaining items toward the calorie target. A pinned item's calories SHALL count toward the day total as a fixed amount that the other items are balanced around.

#### Scenario: Manually set portion is preserved through Auto Adjust

- **WHEN** a dietician has set a Chapati to 1 piece (pinning it) and then taps "Auto Adjust" for that day
- **THEN** the Chapati remains at 1 piece
- **AND** the day's other non-locked, non-pinned recipes are rescaled to bring the day total to the calorie target

#### Scenario: Every item pinned or locked

- **WHEN** a dietician taps "Auto Adjust" for a day in which every item is pinned or locked
- **THEN** no portions change, and the day's calorie total is reported as-is

### Requirement: Pinned state is visible and reversible on the Refine Portions card

The Refine Portions list SHALL show an "Edited" indicator on each pinned plan item's card. Tapping that indicator SHALL unpin the item, returning it to the pool that "Auto Adjust" rescales. Unpinning SHALL NOT itself change any portion.

#### Scenario: Pinned card shows the indicator

- **WHEN** a dietician views the Refine Portions list after manually editing a Chapati
- **THEN** the Chapati card shows an "Edited" indicator

#### Scenario: Unpinning returns the item to Auto Adjust

- **WHEN** a dietician taps the "Edited" indicator on the Chapati card and confirms
- **THEN** the indicator is removed, the Chapati's current portion is unchanged, and a subsequent "Auto Adjust" is free to rescale it

### Requirement: The one-shot entry balance respects pins

When the Refine Portions step re-runs its automatic whole-week balance on re-entry (for example after the dietician changed recipes on the Generate step), that automatic pass SHALL also exclude pinned items.

#### Scenario: Re-entering Refine Portions keeps a pinned portion

- **WHEN** a dietician pins a Chapati, returns to the Generate step, adds a recipe, and comes back to Refine Portions (triggering the automatic re-balance)
- **THEN** the Chapati is still at its pinned portion after the re-balance
