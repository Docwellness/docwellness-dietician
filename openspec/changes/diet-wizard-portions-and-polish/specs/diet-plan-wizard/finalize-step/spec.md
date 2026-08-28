## Purpose

Defines the diet plan wizard's Step 5 "Review & Finalize" screen: a day-group-selectable meal timeline that previews the plan in the same visual language the patient sees, while keeping the calorie-tolerance gate that guards activation.

## ADDED Requirements

### Requirement: Day-group selector

The Review & Finalize screen SHALL present a horizontal selector of the plan's day-groups (for example Mon & Fri / Tue & Sat / Wed & Sun / Thu) at the top of the screen. Selecting a day-group SHALL show only that day-group's meals below. One day-group SHALL be selected by default when the screen opens.

#### Scenario: Switching day-groups

- **WHEN** a dietician opens Review & Finalize and taps "Tue & Sat"
- **THEN** the meal timeline below updates to show only the Tue & Sat meals

#### Scenario: Default selection

- **WHEN** the screen first opens
- **THEN** the first day-group is selected and its meals are shown

### Requirement: Meal timeline of recipe cards

For the selected day-group, the screen SHALL render its meals in serving-time order as a vertical timeline. Each recipe SHALL be shown as a card displaying the recipe name, its serving portion as a pill (for example "1 piece" or "75 g (~5 tbsp)"), its calories, and per-recipe macro figures for protein, fiber, carbs, and fat. Supplements attached to a slot SHALL be shown within that slot.

#### Scenario: Recipe card contents

- **WHEN** a dietician views the Lunch slot for the selected day-group
- **THEN** each Lunch recipe card shows its name, a portion pill, a calorie figure, and protein / fiber / carbs / fat values

#### Scenario: Supplement shown in its slot

- **WHEN** a supplement is attached to the Breakfast slot
- **THEN** it appears in the Breakfast section of the timeline with its dosage and timing

### Requirement: Collapsible cooking steps

Full cooking-step prose SHALL be hidden by default on each recipe card and revealed only when the dietician expands that card. Ingredient lists MAY be shown inline or behind the same expand.

#### Scenario: Steps hidden by default

- **WHEN** a dietician views the meal timeline
- **THEN** no recipe's cooking steps are shown until they expand that recipe

#### Scenario: Expanding a recipe

- **WHEN** a dietician taps a recipe card to expand it
- **THEN** that recipe's cooking steps become visible

### Requirement: Activation-tolerance gate is retained

The screen SHALL continue to show a per-day-group calorie check against the plan's calorie target, SHALL continue to require every generated day-group to be within ±5% of the target before "Confirm & Activate" is enabled, and "Confirm & Activate" SHALL continue to finalize and activate the plan through the existing endpoint.

#### Scenario: Day-group outside tolerance blocks activation

- **WHEN** one day-group is 12% above the calorie target
- **THEN** the screen shows that day-group as outside tolerance and "Confirm & Activate" is disabled

#### Scenario: All day-groups within tolerance

- **WHEN** every day-group is within ±5% of the target
- **THEN** "Confirm & Activate" is enabled and activates the plan when tapped
