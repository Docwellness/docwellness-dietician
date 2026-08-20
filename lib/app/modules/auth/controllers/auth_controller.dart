import 'dart:async';

import 'package:docwellnesdoc/app/routes/app_pages.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/core/security/device_security_service.dart';
import 'package:docwellnesdoc/core/session/session_service.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Real login for the single dietician account - replaces the previous
/// auto-login (see main.dart's now-removed _autoLoginDietician), which
/// signed in with a hardcoded email/password baked into the app at build
/// time via --dart-define/dev_credentials.dart. That was fine for an
/// internal-only APK, but baking a real password into a binary distributed
/// through the public Play Store means anyone who downloads the APK can
/// extract it - this screen exists so the credential only ever lives in
/// Tejasvini's own memory, typed in at login time.
///
/// Phase 9, P9-D1: login now goes through docwellness-backend's own
/// /auth/login proxy instead of calling
/// Supabase.instance.client.auth.signInWithPassword() directly from the
/// app - the direct-Supabase path bypassed the backend entirely, so
/// server-side lockout/rate-limiting/audit-logging never saw dietician
/// logins. Matches docwellness-user's AuthController/AuthService pattern.
class AuthController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = RxnString();

  // Phase 9, P9-D5: login lockout countdown after a 429 from the backend's
  // failed-attempt lockout (stricter dietician threshold - see
  // docwellness-backend's utils/loginLockout.js).
  RxInt loginLockSeconds = 0.obs;
  bool get isLoginLocked => loginLockSeconds.value > 0;
  Timer? _loginLockTimer;

  void _startLoginLockCountdown(int seconds) {
    _loginLockTimer?.cancel();
    loginLockSeconds.value = seconds;
    _loginLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (loginLockSeconds.value <= 1) {
        loginLockSeconds.value = 0;
        timer.cancel();
      } else {
        loginLockSeconds.value--;
      }
    });
  }

  int _parseRetryAfter(dynamic response) {
    final bodyRetryAfter = response?.data is Map ? response.data['retryAfter'] : null;
    if (bodyRetryAfter is int) return bodyRetryAfter;
    final parsed = int.tryParse(bodyRetryAfter?.toString() ?? '');
    if (parsed != null) return parsed;
    final headerRetryAfter = response?.headers?.value('retry-after');
    return int.tryParse(headerRetryAfter ?? '') ?? 300;
  }

  @override
  void onClose() {
    _loginLockTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    // Phase 9, P9-D4: defense-in-depth re-entrancy guard - the login button
    // already disables itself via isLoading in the Obx wrapper, but login()
    // itself had no guard against being invoked twice (e.g. a race between
    // a keyboard submit and a tap).
    if (isLoading.value || isLoginLocked) return;

    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Enter your email and password';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      // Phase 9, P9-D7: refuse locally on a jailbroken/rooted device rather
      // than relying solely on the backend's 403 (deviceRiskGate) - this
      // app handles patient PHI, so it doesn't get the patient app's softer
      // flag-only policy.
      if (await DeviceSecurityService.isCompromised()) {
        errorMessage.value = 'This device cannot be used to sign in.';
        return;
      }

      final riskHeaders = await DeviceSecurityService.riskHeaders();
      final response = await ApiService().request(
        endPoint: '/auth/login',
        method: 'POST',
        data: {'email': email, 'password': password},
        headers: riskHeaders,
      );

      if (response == null) {
        errorMessage.value = 'Cannot connect to server. Please try again.';
        return;
      }

      if (response.statusCode == 429) {
        _startLoginLockCountdown(_parseRetryAfter(response));
        errorMessage.value = response.data?['message'] ?? 'Too many failed login attempts.';
        return;
      }

      if (response.statusCode != 200 || response.data?['success'] != true) {
        errorMessage.value = response.data?['message'] ?? 'Login failed - please try again';
        return;
      }

      final session = response.data['data'];
      await SessionService.to.setSession(
        token: session['accessToken'],
        refreshToken: session['refreshToken'],
        expiresAt: session['expiresAt'],
      );
      token = session['accessToken'];

      final meResponse = await ApiService().request(
        endPoint: '/auth/me',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (meResponse != null &&
          meResponse.statusCode == 200 &&
          meResponse.data['success'] == true) {
        userId = meResponse.data['data']['_id'];
        // AI_EXECUTION_PLAN.md Phase 8, P8-04 - no PHI: no properties, same
        // shape as the user app's login_success.
        await Posthog().capture(eventName: 'login_success');
        Get.offAllNamed(Routes.HOME);
      } else {
        token = null;
        await SessionService.to.clear();
        errorMessage.value = 'Could not load your profile - please try again';
      }
    } catch (e) {
      errorMessage.value = 'Something went wrong - check your connection and try again';
    } finally {
      isLoading.value = false;
    }
  }

  /// Requests a password-reset code via the backend (not a direct Supabase
  /// call - see routes/dietician.js's forgot-password/reset-password, which
  /// reuse the patient app's role-agnostic Supabase-OTP-via-Resend flow).
  /// Always resolves quietly on failure, matching docwellness-user's
  /// AuthService.forgotPassword() - the backend responds with the same
  /// generic message regardless of whether the email is registered, so
  /// there's nothing meaningful to show differently either way.
  Future<void> requestPasswordReset(String email) async {
    try {
      await ApiService().request(
        endPoint: '/auth/forgot-password',
        method: 'POST',
        data: {'email': email},
      );
    } catch (_) {
      // Silent - see doc comment above.
    }
  }

  /// Verifies the code from requestPasswordReset above and sets the new
  /// password, in one backend call - no session needed client-side.
  Future<String?> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService().request(
        endPoint: '/auth/reset-password',
        method: 'POST',
        data: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return null;
      }
      return response?.data?['message'] ?? 'Invalid or expired code. Please try again.';
    } catch (e) {
      return 'Something went wrong - check your connection and try again';
    }
  }
}
