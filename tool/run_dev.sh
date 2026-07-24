#!/usr/bin/env bash
# Cross-platform (bash) dev-run convenience script. On Windows, prefer
# running via PowerShell instead (flutter run's interactive keys/hot
# reload behave more reliably there) - see scripts/run-dev.ps1, which also
# already has real dev-backend/Supabase/Sentry/PostHog values filled in.
#
# This script defaults to localhost, matching a locally-running backend
# (see docwellness-backend's `npm run dev`). Point API_BASE_URL at
# https://dev-api.docwellness.fit instead to use the shared dev backend.
set -e

flutter pub get
flutter analyze
flutter test || true

flutter run \
  --dart-define=API_BASE_URL=http://localhost:5000 \
  --dart-define=ENV=development
