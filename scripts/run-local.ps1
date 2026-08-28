# Runs the dietician app against a backend running on THIS machine
# (docwellness-backend `npm run dev`, port 5000). config/local.json points
# at 10.0.2.2 (the Android emulator's host alias) - edit it for a physical
# device or the iOS simulator.
#
# Pass extra `flutter run` args through, e.g.:
#   .\scripts\run-local.ps1 -d emulator-5554

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) { $flutter = "C:\flutter\bin\flutter.bat" }

& $flutter run --dart-define-from-file=config/local.json @args
