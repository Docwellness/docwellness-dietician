import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/icons/logo.png', width: 180),
                  const SizedBox(height: 32),
                  CustomText(
                    text: 'Dietician Login',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: const Color(0xff1F2A37),
                  ),
                  const SizedBox(height: 24),
                  CustomField(
                    lable: 'Email',
                    controller: controller.emailController,
                    hintText: 'you@docwellness.fit',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => CustomField(
                      lable: 'Password',
                      controller: controller.passwordController,
                      hintText: 'Enter your password',
                      hide: controller.obscurePassword.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.obscurePassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xff6C737F),
                        ),
                        onPressed: () => controller.obscurePassword.value =
                            !controller.obscurePassword.value,
                      ),
                    ),
                  ),
                  Obx(() {
                    final error = controller.errorMessage.value;
                    if (error == null) return const SizedBox(height: 24);
                    return Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      child: CustomText(
                        text: error,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    );
                  }),
                  Obx(
                    () => CustomButton(
                      text: 'Log In',
                      isOutline: false,
                      isLoading: controller.isLoading.value,
                      onTap: controller.login,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
