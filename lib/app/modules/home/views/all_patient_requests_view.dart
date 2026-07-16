import 'package:docwellnesdoc/app/modules/home/controllers/home_controller.dart';
import 'package:docwellnesdoc/app/modules/home/widgets/patient_request_container.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AllPatientRequestsView extends GetView<HomeController> {
  const AllPatientRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'All Patient Requests',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            color: const Color(0xff1F2A37),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (controller.allRequestedPatientList.isEmpty) {
            return const Center(
              child: CustomText(
                text: 'No patient requests found',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xff6C737F),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.allRequestedPatientList.length,
            itemBuilder: (context, index) {
              final data = controller.allRequestedPatientList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PatientRequestContainer(
                  goal: data.primaryGoal ?? "",
                  title: data.patientName ?? "",
                  onTap: () {
                    Get.toNamed('/patient-profile/${data.patientId ?? ''}');
                  },
                  status: data.status ?? 'Unpaid',
                  avatarUrl: data.avatarUrl,
                  membershipPlan: data.membershipPlan,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
