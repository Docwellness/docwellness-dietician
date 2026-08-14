import 'package:docwellnesdoc/app/routes/app_pages.dart';
import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Real login for the single dietician account - replaces the previous
/// auto-login (see main.dart's now-removed _autoLoginDietician), which
/// signed in with a hardcoded email/password baked into the app at build
/// time via --dart-define/dev_credentials.dart. That was fine for an
/// internal-only APK, but baking a real password into a binary distributed
/// through the public Play Store means anyone who downloads the APK can
/// extract it - this screen exists so the credential only ever lives in
/// Tejasvini's own memory, typed in at login time.
class AuthController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = RxnString();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'Enter your email and password';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final authRes = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = authRes.session;
      if (session == null) {
        errorMessage.value = 'Login failed - please try again';
        return;
      }
      token = session.accessToken;

      final response = await ApiService().request(
        endPoint: '/auth/me',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        userId = response.data['data']['_id'];
        // AI_EXECUTION_PLAN.md Phase 8, P8-04 - no PHI: no properties, same
        // shape as the user app's login_success.
        await Posthog().capture(eventName: 'login_success');
        Get.offAllNamed(Routes.HOME);
      } else {
        token = null;
        errorMessage.value = 'Could not load your profile - please try again';
      }
    } on AuthException catch (e) {
      errorMessage.value = e.message;
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
