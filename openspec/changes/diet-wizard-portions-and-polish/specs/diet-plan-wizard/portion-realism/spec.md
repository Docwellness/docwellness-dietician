## Purpose

Keeps auto-computed portions of countable-serving recipes (roti, chapati, idli, egg, slice) realistic — never a fraction below one, always a clean half-step — during menu generation and auto-balance, redistributing the resulting calorie difference across the day's other recipes.

## ADDED Requirements

### Requirement: Countable serving units are identified consistently

The system SHALL classify a recipe's real-world serving unit as **countable** when its serving component unit is one of `piece`, `nos`, `roti`, `slice`, or `egg` (case-insensitive), and as **continuous** otherwise (`g`, `ml`, `tsp`, `tbsp`, `cup`, `bowl`). This classification SHALL be derived from the recipe version's serving component, not from its ingredient lines.

#### Scenario: Flatbread is countable

- **WHEN** the system evaluates a Chapati recipe whose serving component is `{ quantity: 1, unit: "piece" }`
- **THEN** it treats the recipe as countable

#### Scenario: Dal is continuous

- **WHEN** the system evaluates a Palak Dal recipe whose serving component is `{ quantity: 1, unit: "bowl" }` or is measured in grams
- **THEN** it treats the recipe as continuous and applies no floor or snapping

### Requirement: Countable portions are floored at one serving

During menu generation and during any auto-balance pass, the system SHALL NOT produce a countable recipe portion below **1** serving. A scaling factor that would take a countable recipe below 1 serving SHALL be clamped so the resulting portion is exactly 1 serving.

#### Scenario: First generated plan never starts below one piece

- **WHEN** a plan is generated and the initial auto-balance pass would scale a Chapati to 0.58 piece to hit the calorie target
- **THEN** the Chapati is set to 1 piece instead, and the Refine Portions list shows "1 piece" for it

#### Scenario: Auto Adjust does not push a countable recipe below one

- **WHEN** a dietician taps "Auto Adjust" for a day and the proportional solution would set a Jowar Bhakri to 0.7 piece
- **THEN** the Jowar Bhakri is set to 1 piece

### Requirement: Countable portions snap to half-serving steps

After the floor is applied, the system SHALL round a countable recipe's portion to the nearest **0.5** serving (1, 1.5, 2, 2.5, …). Continuous recipes SHALL NOT be snapped.

#### Scenario: Portion snaps up to a half step

- **WHEN** an auto-balance pass computes a Chapati portion of 1.72 pieces
- **THEN** the stored portion is 1.5 pieces

#### Scenario: Portion snaps to a whole step

- **WHEN** an auto-balance pass computes a Chapati portion of 2.1 pieces
- **THEN** the stored portion is 2 pieces

### Requirement: Floored calories are redistributed across the day

When flooring or snapping a countable recipe changes its calories away from that recipe's proportional share of the day target, the auto-balance pass SHALL redistribute the difference across the day's other items that are neither locked nor pinned, in proportion to their current calories, so the day total still targets the calorie goal.

#### Scenario: Other recipes absorb the floor

- **WHEN** flooring a Chapati from 0.58 to 1 piece adds ~65 kcal to a day that was on target
- **THEN** the day's other non-locked, non-pinned recipes are scaled down proportionally so the day total returns to within the plan's calorie tolerance
- **AND** the Chapati stays at 1 piece

#### Scenario: No eligible recipes to absorb the difference

- **WHEN** every other item in the day is locked or pinned and cannot absorb the floored calories
- **THEN** the countable recipe still stays at its floored portion, and the day is left flagged as outside tolerance for the dietician to resolve, rather than the floor being abandoned
