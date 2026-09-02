import 'package:docwellnesdoc/app/modules/auth/controllers/auth_controller.dart';
import 'package:docwellnesdoc/app/modules/auth/views/reset_password_view.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/functions/validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// First half of the "forgot password" flow - see reset_password_view.dart
/// for the second half (code + new password).
class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final isLoading = false.obs;

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      final email = emailController.text.trim();
      await controller.requestPasswordReset(email);
      isLoading.value = false;
      Get.to(() => ResetPasswordView(email: email));
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
        title: const Text('Forgot password'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              CustomText(
                text: "Enter your email and we'll send you a code to reset your password",
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: const Color(0xff4D5761),
              ),
              const SizedBox(height: 32),
              CustomField(
                space: false,
                lable: 'Email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),
              const SizedBox(height: 32),
              Obx(
                () => CustomButton(
                  isLoading: isLoading.value,
                  onTap: submit,
                  text: 'Send Reset Code',
                  isOutline: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
