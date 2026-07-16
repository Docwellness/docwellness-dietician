import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/new_patients_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewWidget extends StatefulWidget {
  const NewWidget({super.key});

  @override
  State<NewWidget> createState() => _NewWidgetState();
}

class _NewWidgetState extends State<NewWidget> {
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
    controller.fetchNewPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SEARCH BAR
        SizedBox(
          width: double.infinity,
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

        const SizedBox(height: 20),

        // LIST VIEW SHOWING PATIENTS
        Expanded(
          child: Obx(() {
            if (controller.isNewLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff851653)),
              );
            }

            final patients = controller.filteredNewPatients;

            if (patients.isEmpty) {
              return const Center(
                child: Text(
                  'No new patients found',
                  style: TextStyle(color: Color(0xff6C737F), fontSize: 16),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.fetchNewPatients,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: patients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return NewPatientsContainer(
                    patientId: patient.patientId,
                    fullName: patient.fullName ?? 'Unknown',
                    avatarUrl: patient.avatarUrl,
                    weight: patient.weight,
                    bmi: patient.bmi,
                    bmr: patient.bmr,
                    tdee: patient.tdee,
                    statusLabel: patient.statusLabel,
                    membershipPlan: patient.membershipPlan,
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
