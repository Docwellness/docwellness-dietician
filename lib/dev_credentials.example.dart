// Template for lib/dev_credentials.dart (gitignored, never committed - see
// .gitignore). Copy this file to dev_credentials.dart and fill in the real
// values to make the dietician app auto-login silently on every launch
// without needing --dart-define flags or ever seeing a login screen (there
// isn't one - see main.dart's _autoLoginDietician).
//
// Leaving dev_credentials.dart absent/empty is also fine: main.dart falls
// back to these empty defaults, which is a no-op (matches the app's
// original committed behavior - no auto-login, just no data loads until a
// real login screen exists).

const String kDevDieticianEmail = '';
const String kDevDieticianPassword = '';
