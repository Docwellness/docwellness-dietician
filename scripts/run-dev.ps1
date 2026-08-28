# Runs the dietician app against the DEV backend (dev-api.docwellness.fit).
#
# The API URL and SDK keys live in config/dev.json (--dart-define-from-file)
# so the backend a build talks to is bound to the config, not retyped every
# run. Pass any extra `flutter run` args straight through, e.g.:
#   .\scripts\run-dev.ps1 -d emulator-5554
#   .\scripts\run-dev.ps1 -d chrome --web-port=8766
#
# Counterparts: scripts/run-prod.ps1 (real production backend),
# scripts/run-local.ps1 (a backend running on this machine).

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) { $flutter = "C:\flutter\bin\flutter.bat" }

& $flutter run --dart-define-from-file=config/dev.json @args
