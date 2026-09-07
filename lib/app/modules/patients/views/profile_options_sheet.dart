import 'package:docwellnesdoc/app/modules/patients/views/delete_patient_data_sheet.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The "Patient Settings" bottom sheet, opened from the ⋮ menu on the
/// Patient profile screen.
class ProfileOptionsSheet extends StatefulWidget {
  final String patientId;
  const ProfileOptionsSheet({super.key, required this.patientId});

  @override
  State<ProfileOptionsSheet> createState() => _SelectDietSheetState();
}

class _SelectDietSheetState extends State<ProfileOptionsSheet> {
  void _openDeleteDataSheet() {
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
  }

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
              ),
              const CustomText(
                text: 'Patient Settings',
                fontWeight: FontWeight.w400,
                fontSize: 18,
                color: Color(0xff1F2A37),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        const Divider(color: Color(0xff9DA4AE)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: _openDeleteDataSheet,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
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
        const Spacer(),
      ],
    );
  }
}
