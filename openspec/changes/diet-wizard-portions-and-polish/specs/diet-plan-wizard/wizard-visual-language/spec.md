## Purpose

Gives the diet plan wizard's screens one deliberate visual system — shared recipe cards, portion pills, macro chips, type scale, and spacing — so the wizard reads as a finished product consistent with the patient-facing Diet Plan view, rather than a set of ad-hoc lists.

## ADDED Requirements

### Requirement: Shared wizard component set

The wizard SHALL use a single shared set of presentation components for recurring elements — recipe card, portion pill, macro chip row, section header, and day-group / slot selector — reused across the Generate review, Timeline & Supplements, and Review & Finalize screens rather than each screen defining its own. The components SHALL follow the documented design tokens (palette, type scale, spacing, radius) in this change's `design.md`.

#### Scenario: A recipe card looks the same across screens

- **WHEN** a dietician sees a recipe on the Generate review screen and the same recipe on the Review & Finalize screen
- **THEN** both use the same card style, portion pill, and macro chip treatment

#### Scenario: Brand palette is preserved

- **WHEN** any restyled wizard screen is rendered
- **THEN** its primary and header colors remain the existing `#851653` / `#530630` brand values

### Requirement: Restyle is presentation-only

Applying the shared visual language to the Generate review and Timeline & Supplements screens SHALL NOT change their behavior: recipe add / remove / swap / regenerate, day-group and slot selection, supplement staging and flush, and step navigation SHALL all work exactly as before.

#### Scenario: Generate review behavior unchanged

- **WHEN** a dietician adds, removes, swaps, or regenerates a recipe on the restyled Generate review screen
- **THEN** the outcome is identical to the pre-restyle behavior

#### Scenario: Timeline behavior unchanged

- **WHEN** a dietician stages and removes a supplement on the restyled Timeline & Supplements screen and continues
- **THEN** the supplements flush to the backend exactly as before

### Requirement: Quality floor

Every restyled screen SHALL remain usable at a standard mobile width with no horizontal overflow, SHALL keep all interactive targets reachable without clipping, and SHALL preserve visible focus / tap feedback on interactive elements.

#### Scenario: No clipping at mobile width

- **WHEN** a restyled wizard screen is shown on a standard phone width
- **THEN** no content is cut off at the screen edge and every selector option is reachable
