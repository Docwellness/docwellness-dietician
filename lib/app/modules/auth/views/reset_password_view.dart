import 'package:docwellnesdoc/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellnesdoc/app/routes/app_pages.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/functions/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Second half of the "forgot password" flow: the code emailed by
/// ForgotPasswordView.requestPasswordReset() plus a new password, both sent
/// to the backend's /auth/reset-password in one call.
class ResetPasswordView extends GetView<AuthController> {
  final String email;
  const ResetPasswordView({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final passwordController = TextEditingController();
    final rePasswordController = TextEditingController();
    final isLoading = false.obs;

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      final error = await controller.confirmPasswordReset(
        email: email,
        code: codeController.text.trim(),
        newPassword: passwordController.text,
      );
      isLoading.value = false;
      if (error != null) {
        showAppToast(Get.overlayContext!, message: error, type: AppToastType.error);
        return;
      }
      showAppToast(
        Get.overlayContext!,
        message: 'Password reset. Please sign in with your new password.',
        type: AppToastType.success,
      );
      Get.offAllNamed(Routes.AUTH);
    }

    Future<void> resend() async {
      await controller.requestPasswordReset(email);
      showAppToast(Get.overlayContext!, message: 'A new code has been emailed to you', type: AppToastType.success);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: const Text('Reset password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              CustomText(
                text: 'Enter the code we sent to $email and choose a new password',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: const Color(0xff4D5761),
              ),
              const SizedBox(height: 32),
              CustomField(
                space: false,
                lable: 'Verification code',
                controller: codeController,
                keyboardType: TextInputType.number,
                isPoint: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the code from your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomField(
                space: false,
                hide: true,
                lable: 'New password',
                controller: passwordController,
                validator: (value) => validatePassword(value, email: email),
              ),
              const SizedBox(height: 16),
              CustomField(
                space: false,
                hide: true,
                lable: 'Re-type new password',
                controller: rePasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please re-type your new password';
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Obx(
                () => CustomButton(
                  isLoading: isLoading.value,
                  onTap: submit,
                  text: 'Reset Password',
                  isOutline: false,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: resend,
                  child: const CustomText(
                    text: "Didn't get a code? Resend",
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xff851653),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
