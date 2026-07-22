# Runs the app against the dev backend with dev-environment SDK keys.
#
# These values are safe to commit: Sentry DSNs and PostHog project API keys
# are both designed to be public/client-embeddable (they only allow sending
# events, not reading data) - same as how they end up baked into the
# compiled app binary either way. Real secrets (JWT signing keys, DB
# passwords, etc.) never belong in a Flutter --dart-define.

flutter run `
  --dart-define=ENV=development `
  --dart-define=API_BASE_URL=https://dev-api.docwellness.fit `
  --dart-define=SENTRY_DSN=https://24d8ba47f43fc752850f3fb3a1deda59@o4511762128896000.ingest.de.sentry.io/4511762171822160 `
  --dart-define=POSTHOG_API_KEY=phc_r36BW82kcdGPitJRk34vb2fNnxMamUVaHRcBPzeebVMe `
  --dart-define=POSTHOG_HOST=https://eu.i.posthog.com `
  --dart-define=SUPABASE_URL=https://ovflhhhtwrjthnyrnaoo.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_FmRYCR40VTVGDsHxK7Z9jQ_67UZ-t-o
