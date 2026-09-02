import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/past_patient_widget.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/patient_list_error_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PastWidget extends StatefulWidget {
  const PastWidget({super.key});

  @override
  State<PastWidget> createState() => _PastWidgetState();
}

class _PastWidgetState extends State<PastWidget> {
  late final PatientsController controller;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Safely get or create the controller
    if (!Get.isRegistered<PatientsController>()) {
      Get.put(PatientsController());
    }
    controller = Get.find<PatientsController>();
    controller.fetchPastPatients();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SEARCH BAR + SORT
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (value) => controller.searchQuery.value = value,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xffFCFCFD),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/icons/vector(2).png',
                      height: 15,
                      width: 15,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  hintText: 'Search',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xffF670CA),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => Semantics(
                button: true,
                label: controller.sortByAttentionFirst.value
                    ? 'Sorted by name - tap for default order'
                    : 'Default order - tap to sort by name',
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: IconButton(
                    onPressed: controller.toggleAttentionSort,
                    tooltip: controller.sortByAttentionFirst.value
                        ? 'Sorted: name (A-Z)'
                        : 'Sorted: default order',
                    icon: Icon(
                      controller.sortByAttentionFirst.value
                          ? Icons.sort_by_alpha_rounded
                          : Icons.sort_rounded,
                      color: const Color(0xff851653),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // LIST VIEW SHOWING PATIENTS
        Expanded(
          child: Obx(() {
            if (controller.isPastLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff851653)),
              );
            }

            if (controller.pastError.value) {
              return PatientListErrorState(
                onRetry: controller.fetchPastPatients,
              );
            }

            final patients = controller.filteredPastPatients;

            if (patients.isEmpty) {
              return const Center(
                child: Text(
                  'No past patients found',
                  style: TextStyle(color: Color(0xff6C737F), fontSize: 16),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchPastPatients,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: patients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return PastPatientWidget(
                    patientId: patient.patientId,
                    fullName: patient.fullName ?? 'Unknown',
                    avatarUrl: patient.avatarUrl,
                    finalWeight: patient.finalWeight,
                    totalKgLost: patient.totalKgLost,
                    bmiBefore: patient.bmiBefore,
                    bmiAfter: patient.bmiAfter,
                    completedOn: patient.completedOn,
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}
