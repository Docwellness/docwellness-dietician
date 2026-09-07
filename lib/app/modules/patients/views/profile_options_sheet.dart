import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/views/delete_patient_data_sheet.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileOptionsSheet extends StatefulWidget {
  final String patientId;
  const ProfileOptionsSheet({super.key, required this.patientId});

  @override
  State<ProfileOptionsSheet> createState() => _SelectDietSheetState();
}

class _SelectDietSheetState extends State<ProfileOptionsSheet> {
  final PatientsController controller = Get.find<PatientsController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            height: 4,
            width: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: const Color(0xff79747E),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Top row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Get.back();
                },
                icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
              ),

              CustomText(
                text: 'Patient Settings',
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Color(0xff1F2A37),
              ),
              Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.more_vert_sharp, color: Colors.black),
              ),
            ],
          ),
        ),

        const SizedBox(height: 5),
        const Divider(color: Color(0xff9DA4AE)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Deactivate profile',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Color(0xff384250),
              ),

              GestureDetector(
                onTap: () {
                  controller.togglePatientActive(widget.patientId);
                },
                child: Obx(() {
                  final isSelected = controller.isProfileDeactivated.value;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 31,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xff851653)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xff851653)
                            : const Color(0xffCCCCCC),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isSelected
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xffCCCCCC),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              CustomText(
                text: 'Program Ends on',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Color(0xff384250),
              ),

              Spacer(),
              CustomText(
                text: '21/08/2025',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Color(0xff384250),
              ),
              SizedBox(width: 8),
              Image.asset(
                'assets/icons/Calendar.png',
                height: 24,
                width: 24,
                fit: BoxFit.cover,
                color: Color(0xff851653),
                colorBlendMode: BlendMode.srcIn,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0xff9DA4AE)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () {
              Get.back(); // close this "Patient Settings" sheet
              showModalBottomSheet(
                context: Get.context!,
                backgroundColor: Colors.white,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (_, scrollController) {
                      return DeletePatientDataSheet(
                        patientId: widget.patientId,
                        scrollController: scrollController,
                      );
                    },
                  );
                },
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_outlined, color: Color(0xffB42318)),
                  SizedBox(width: 12),
                  CustomText(
                    text: 'Delete specific data…',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Color(0xffB42318),
                  ),
                ],
              ),
            ),
          ),
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomButton(
            onTap: () {},
            text: 'Update Selections for Breakfast',
            isOutline: false,
            fontSize: 14,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: CustomButton(
            onTap: () {},
            text: 'Find more Breakfast',
            isOutline: true,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
