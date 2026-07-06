import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('AuthView',style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Color(0xff1F2A37),
          ),),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'AuthView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
