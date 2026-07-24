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

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _kAuthToken = 'auth_token';
  static const String _kUserId = 'user_id';
  static const String _kUserRole = 'user_role';
  static const String _kUserName = 'user_name';

  String? _token;
  String? _userId;
  String? _userRole;
  String? _userName;

  String? get token => _token;
  String? get userId => _userId;
  String? get userRole => _userRole;
  String? get userName => _userName;

  Future<SessionService> init() async {
    _token = await _storage.read(key: _kAuthToken);
    _userId = await _storage.read(key: _kUserId);
    _userRole = await _storage.read(key: _kUserRole);
    _userName = await _storage.read(key: _kUserName);
    return this;
  }

  Future<void> setToken(String? value) => _set(_kAuthToken, value, (v) => _token = v);
  Future<void> setUserId(String? value) => _set(_kUserId, value, (v) => _userId = v);
  Future<void> setUserRole(String? value) => _set(_kUserRole, value, (v) => _userRole = v);
  Future<void> setUserName(String? value) => _set(_kUserName, value, (v) => _userName = v);

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
    await _storage.deleteAll();
  }
}
