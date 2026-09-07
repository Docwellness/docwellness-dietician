import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/views/delete_patient_data_sheet.dart';
import 'package:docwellnesdoc/app/modules/patients/views/subscription_pause_sheet.dart';
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
  final PatientsController _controller = Get.find<PatientsController>();

  void _openSheet(Widget Function(ScrollController) builder, {double size = 0.9}) {
    Get.back(); // close this "Patient Settings" sheet
    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: size,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => builder(scrollController),
      ),
    );
  }

  void _openDeleteDataSheet() => _openSheet(
        (sc) => DeletePatientDataSheet(
          patientId: widget.patientId,
          scrollController: sc,
        ),
      );

  void _openPauseSheet() => _openSheet(
        (sc) => SubscriptionPauseSheet(
          patientId: widget.patientId,
          scrollController: sc,
        ),
        size: 0.75,
      );

  Widget _row({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xff384250),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              CustomText(
                text: label,
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: color,
              ),
            ],
          ),
        ),
      ),
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
        Obx(() {
          // rebuild when the profile (and its pause state) refreshes
          _controller.patientProfileModel.value;
          final paused = _controller.subscriptionPause?.hasActivePause == true;
          return _row(
            icon: paused
                ? Icons.play_circle_outline
                : Icons.pause_circle_outline,
            label: paused ? 'Manage subscription pause' : 'Pause subscription',
            onTap: _openPauseSheet,
            color: const Color(0xff851653),
          );
        }),
        const SizedBox(height: 4),
        _row(
          icon: Icons.delete_sweep_outlined,
          label: 'Delete specific data…',
          onTap: _openDeleteDataSheet,
          color: const Color(0xffB42318),
        ),
        const Spacer(),
      ],
    );
  }
}
