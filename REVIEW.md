# Review policy: docwellness-dietician

Read by the `dw-reviewer` agent and by human reviewers. It is advisory: findings never approve or block a change on their own.

## Passes (every review runs all three)
1. **Bugs** - logic errors, broken edge cases, `setState` or controller use after dispose, async gaps that use a stale `BuildContext`, state not reset on account
   switch, lists that do not handle the empty or failed-load case, wrong date or timezone handling.
2. **Security** - tokens, keys or patient data in logs, analytics events or error reports; the production API URL or `config/prod.json` referenced from code or
   scripts that tests might run; anything that reads or exposes `lib/groq_dev_credentials.dart`; weakened session handling in `lib/core/session`.
3. **Compliance** - does the diff match the change's specs, design and tasks (`docwellness-specs/openspec/changes/<change>/`), including every screen and state
   in the design's UI section? Flag anything built that nobody asked for and anything asked for that was not built.

## Important (always raise)
- Any change touching authentication, patient health data (consultation forms, diet plans, logs, journeys), subscriptions or memberships, or deletion.
- A new or changed API call whose request or response shape the backend does not provide (check against `docwellness-backend`).
- A screen or widget change with no handling of the empty, loading, error and offline states.
- A call that sends patient data anywhere other than the backend.
- Test code that would pass without the production change, or that is dead, duplicated or over-mocked. Remember `test/widget_test.dart` is the stale template and
  always fails; do not count it as a regression.
- A change that raises `flutter analyze` above its 114-issue baseline, or adds an issue in a touched file.
- GetX controllers, bindings or routes added without being wired the way neighbouring modules are.

## Nit (raise at most 5 per review, only if nothing Important is left out)
- Naming, widget structure or comment density that departs from the surrounding module; small duplication. This app has no color or spacing token file
  (`lib/app/utils/theme` has only the date-picker theme and shadows), so hard-coded colors are common: raise one only when a neighbouring screen clearly uses
  a shared value, and never ask for a new design system inside another change.

## Skip
- `build/`, `.dart_tool/`, `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/` generated files, `pubspec.lock`, the `*.log` files in the repo root, and
  formatting that `flutter analyze` or `dart format` already enforces.
