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
}
