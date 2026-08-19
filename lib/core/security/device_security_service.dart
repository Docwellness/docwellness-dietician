import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:local_auth/local_auth.dart';

/// Phase 9, P9-D7 - device-integrity signal sent on login (consumed by the
/// backend's device-risk middleware). Unlike docwellness-user's soft
/// (flag-only) policy, this app blocks login locally too on a positive
/// signal - DocDesk handles patient PHI, so it doesn't rely solely on the
/// backend's own 403 (see docwellness-backend's deviceRisk.js) as the only
/// line of defense.
class DeviceSecurityService {
  static Future<Map<String, String>> riskHeaders() async {
    try {
      final jailbroken = await FlutterJailbreakDetection.jailbroken;
      return {
        'X-Jailbreak-Detected': jailbroken.toString(),
        'X-Root-Detected': jailbroken.toString(),
      };
    } catch (e) {
      // Detection failing shouldn't block login - default to "false"
      // (unknown), not a false positive.
      debugPrint('DeviceSecurityService.riskHeaders failed (non-fatal): $e');
      return {
        'X-Jailbreak-Detected': 'false',
        'X-Root-Detected': 'false',
      };
    }
  }

  /// True when the device itself (not just the header we'd send) reports
  /// jailbroken/rooted - checked before even attempting login, so the app
  /// refuses locally instead of relying only on the backend's 403.
  static Future<bool> isCompromised() async {
    try {
      return await FlutterJailbreakDetection.jailbroken;
    } catch (e) {
      debugPrint('DeviceSecurityService.isCompromised failed (non-fatal): $e');
      return false;
    }
  }

  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Biometric step-up gate for a sensitive, irreversible action (e.g.
  /// deleting a patient - see PatientsController.deletePatient). Falls back
  /// to device PIN/pattern (biometricOnly: false) rather than hard-blocking
  /// a dietician on a device with no biometrics enrolled; returns true only
  /// on an explicit successful authentication, false on cancel, failure, or
  /// an unsupported/unavailable device (fails closed, not open).
  static Future<bool> requireStepUp(String reason) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canCheck) return false;
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (e) {
      debugPrint('DeviceSecurityService.requireStepUp failed (non-fatal): $e');
      return false;
    }
  }
}
