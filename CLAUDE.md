# docwellness-dietician

Dietician Flutter app (Dart SDK ^3.9, package name `docwellnesdoc`). The patient app is the sibling repo `docwellness-user`; the API is `docwellness-backend`.

## Layout
- `lib/app/modules/` one folder per feature: auth, chat, diet_plan_wizard, exercises, home, notifications, patient_journey, patients, performance, receipes, splash.
- `lib/app/services`, `lib/app/models`, `lib/app/routes`, `lib/app/utils` (`common_widgets`, `functions`, `theme`), and `lib/core` (config, security, session).
  There is no `lib/utils` and no localization folder: screen text is plain English in the widgets, and `intl` is only used for date and number formatting.
- `GetX` (`get`) for state and navigation, `dio` for networking.
- `test/` holds widget and unit tests. Specs and change plans live in the sibling repo `docwellness-specs` (OpenSpec), not here.

## Commands
- `flutter` is `C:\flutter\bin\flutter.bat` and is not on the bash PATH by default: use PowerShell (the `dw` launcher adds it for agents).
- Analyze: `flutter analyze` (has a 114-issue baseline, see Verification). Test: `flutter test`.
- Run: `scripts/run-dev.ps1` (dev API), `scripts/run-local.ps1` (a local backend) or `scripts/run-prod.ps1` (`config/prod.json`, the PRODUCTION API
  `https://api.docwellness.fit`). Extra `flutter run` arguments pass through, for example `-d emulator-5556`.

## Verification (run before reporting any task done, and paste the output)
Run these from the repo root in PowerShell. Paste the raw result lines.
- `flutter test <the change's test files>` - healthy: `All tests passed!`.
- `flutter analyze` - baseline today (checked 2026-10-20): `114 issues found`, with a non-zero exit. A change is clean if it adds no issue to that baseline and
  none in a file it touched; report the count.
- `flutter test` - healthy: ends with `All tests passed!`, except that the stale `test/widget_test.dart` (the stock counter template) always fails, so a single
  failure there is expected; make sure it is the only one.
- `dart format --output=none --set-exit-if-changed <touched Dart files>` - healthy: exit 0 and `0 changed`. Always include `--output=none`; without it the
  command rewrites the files.
No separate build step is needed for a change. If a command cannot run, say which and why instead of reporting done.

## Production data safety
- `scripts/run-prod.ps1` runs the app against real production data. Do not use it for testing without the developer's explicit choice.
- The backend's `.env` database is not production; production runs on Coolify.
- `lib/groq_dev_credentials.dart` holds a real API key for the dev-only "magic fill" button. It is git-ignored: never read it, print it, copy it, or commit it
  (the template is `lib/groq_dev_credentials.example.dart`).
- Consultation forms, diet plans and patient records are health data: never put them in logs, Sentry or analytics events, or tests. Patient deletion is done by
  the backend (`utils/patientDataDeletion.js`); this app only calls it.

## CI
- `.github/workflows/build-release-aab.yml` only builds a release bundle, started by hand. There is no test workflow, so local `flutter analyze` and
  `flutter test` are the gate.
