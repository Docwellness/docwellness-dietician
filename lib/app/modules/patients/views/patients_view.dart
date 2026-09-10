import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/new_widget.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/ongoing_widget.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/past_widget.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientsView extends StatelessWidget {
  const PatientsView({super.key});

  PatientsController get _controller {
    if (!Get.isRegistered<PatientsController>()) {
      Get.put(PatientsController());
    }
    return Get.find<PatientsController>();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Client list",
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xff1F2A37),
          ),
        ),
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ------------------- CUSTOM SEGMENTED TAB BAR -------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 41,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Color(0xff530630), width: 1),
              ),
              child: Obx(
                () => Row(
                  children: [
                    _buildTab(controller, 0, "Ongoing"),
                    _verticalDivider(),
                    _buildTab(controller, 1, "New"),
                    _verticalDivider(),
                    _buildTab(controller, 2, "Past"),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: Obx(
              () => IndexedStack(
                index: controller.selectedTab.value,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: OngoingWidget(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: NewWidget(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: PastWidget(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TAB ITEM ----------------
  Widget _buildTab(PatientsController controller, int index, String title) {
    final bool isSelected = controller.selectedTab.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = index,
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? Color(0xffFDF2FA) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(index == 0 ? 22 : 0),
              bottomLeft: Radius.circular(index == 0 ? 22 : 0),
              topRight: Radius.circular(index == 2 ? 22 : 0),
              bottomRight: Radius.circular(index == 2 ? 22 : 0),
            ),
          ),
          alignment: Alignment.center,
          child: CustomText(
            text: title,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isSelected ? Color(0xff530630) : Color(0xff384250),
          ),
        ),
      ),
    );
  }

  // ---------------- DIVIDER ----------------
  Widget _verticalDivider() {
    return Container(
      width: 1.3,
      height: double.infinity,
      color: Color(0xff530630),
    );
  }
}
