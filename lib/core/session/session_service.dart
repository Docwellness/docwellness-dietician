import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

/// Single source of truth for the current auth session, backed by secure
/// storage (Keychain on iOS, an encrypted Keystore-backed store on
/// Android) instead of a bare in-memory global that's lost on every app
/// restart, or plain SharedPreferences (not encrypted at rest).
///
/// Register once at bootstrap via:
///   await Get.putAsync(() => SessionService().init(), permanent: true);
/// as the very FIRST line, before anything else touches auth state -
/// init() hydrates the in-memory fields from secure storage synchronously
/// relative to the rest of bootstrap, so every getter below reflects the
/// last-persisted session immediately. Getters are synchronous (not
/// Future-returning) on purpose: dozens of existing call sites read
/// `token`/`userId` inline (e.g. inside a header map literal such as
/// `{'Authorization': 'Bearer $token'}`), and an async API here would
/// ripple out to every one of them for no behavioral benefit - see
/// main.dart's token/userId getter-setter bridge, which is what those call
/// sites actually go through.
class SessionService extends GetxService {
  static SessionService get to => Get.find<SessionService>();

  // Phase 9, P9-D6: explicit options instead of the package defaults -
  // encryptedSharedPreferences forces the modern EncryptedSharedPreferences
  // backing on Android (older API defaults can vary by OS version/vendor),
  // and first_unlock_this_device keeps the Keychain entry off backups/other
  // devices while still being readable by background refresh before the
  // user re-enters their passcode after a reboot.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _kAuthToken = 'auth_token';
  static const String _kUserId = 'user_id';
  static const String _kUserRole = 'user_role';
  static const String _kUserName = 'user_name';
  // Phase 9, P9-D2: backend-issued (see /auth/login, /auth/refresh) now
  // that login goes through docwellness-backend's proxy instead of the
  // Supabase SDK managing its own session/refresh internally - these two
  // replace what the SDK used to handle. tokenExpiresAt is a Supabase
  // epoch-seconds `expires_at` value, stored as a string like everything
  // else here. Same shape as docwellness-user's SessionService.
  static const String _kRefreshToken = 'refresh_token';
  static const String _kTokenExpiresAt = 'token_expires_at';

  String? _token;
  String? _userId;
  String? _userRole;
  String? _userName;
  String? _refreshToken;
  String? _tokenExpiresAt;

  String? get token => _token;
  String? get userId => _userId;
  String? get userRole => _userRole;
  String? get userName => _userName;
  String? get refreshToken => _refreshToken;
  String? get tokenExpiresAt => _tokenExpiresAt;

  Future<SessionService> init() async {
    _token = await _storage.read(key: _kAuthToken);
    _userId = await _storage.read(key: _kUserId);
    _userRole = await _storage.read(key: _kUserRole);
    _userName = await _storage.read(key: _kUserName);
    _refreshToken = await _storage.read(key: _kRefreshToken);
    _tokenExpiresAt = await _storage.read(key: _kTokenExpiresAt);
    return this;
  }

  Future<void> setToken(String? value) => _set(_kAuthToken, value, (v) => _token = v);
  Future<void> setUserId(String? value) => _set(_kUserId, value, (v) => _userId = v);
  Future<void> setUserRole(String? value) => _set(_kUserRole, value, (v) => _userRole = v);
  Future<void> setUserName(String? value) => _set(_kUserName, value, (v) => _userName = v);
  Future<void> setRefreshToken(String? value) => _set(_kRefreshToken, value, (v) => _refreshToken = v);
  Future<void> setTokenExpiresAt(String? value) => _set(_kTokenExpiresAt, value, (v) => _tokenExpiresAt = v);

  /// Persists a full session (access + refresh token + expiry) in one go -
  /// login/refresh call sites set all three together, never just one, so
  /// this avoids three separate awaited round-trips to secure storage for
  /// what's really one atomic update.
  Future<void> setSession({
    required String token,
    required String refreshToken,
    required int expiresAt,
  }) async {
    await setToken(token);
    await setRefreshToken(refreshToken);
    await setTokenExpiresAt(expiresAt.toString());
  }

  Future<void> _set(String key, String? value, void Function(String?) assign) async {
    assign(value);
    if (value == null || value.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  /// Full logout - clears both the in-memory state and everything
  /// persisted in secure storage.
  Future<void> clear() async {
    _token = null;
    _userId = null;
    _userRole = null;
    _userName = null;
    _refreshToken = null;
    _tokenExpiresAt = null;
    await _storage.deleteAll();
  }
}
