/// Centralized compile-time environment configuration - every
/// --dart-define value this app reads lives here instead of scattered
/// String.fromEnvironment calls across main.dart and elsewhere. Fields are
/// static const (not instance/runtime state) because dart-define
/// substitution only happens at compile time - there is nothing to "load".
class EnvService {
  EnvService._();

  /// Backend host (no path suffix - callers append their own /api/... path,
  /// see apiBaseUrl in main.dart). Override at build time with:
  ///   flutter run --dart-define=API_BASE_URL=https://dev-api.docwellness.fit
  static const String apiHost = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  // Publishable (anon) key - safe to commit, same as docwellness-user's
  // scripts/run-dev.ps1 (it only allows the actions RLS policies permit,
  // not reading arbitrary data - never the *service role* key). Defaulted
  // here (rather than left empty like the optional Sentry/PostHog values
  // below) because auto-login below can't function at all without
  // Supabase actually being initialized.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ovflhhhtwrjthnyrnaoo.supabase.co',
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_FmRYCR40VTVGDsHxK7Z9jQ_67UZ-t-o',
  );

  // Sentry/PostHog are only enabled once a real DSN/API key is supplied via
  // --dart-define at build time; empty defaults keep both no-ops so local
  // runs without those defines behave exactly as before.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  static const String appEnv = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
  static const String posthogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );
  static const String posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );
}
