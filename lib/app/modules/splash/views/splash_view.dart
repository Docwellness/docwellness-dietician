import 'package:docwellnesdoc/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Plain launch screen: brand background, logo - nothing else. The stacked
/// logo (assets/icons/logo.png) already bakes in the "Docwellness" wordmark
/// and tagline, so no separate text widget is needed here. Shown for a
/// fixed short delay then replaces itself with the real initial route
/// (Get.offNamed, not Get.to, so it's never left on the back-stack).
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Get.offNamed(Routes.HOME);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFEF6FB),
      body: Center(
        child: Image.asset('assets/icons/logo.png', width: 260),
      ),
    );
  }
}
