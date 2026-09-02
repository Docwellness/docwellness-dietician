import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/new_patients_container.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/patient_list_error_state.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Safely get or create the controller
    if (!Get.isRegistered<PatientsController>()) {
      Get.put(PatientsController());
    }
    controller = Get.find<PatientsController>();
    controller.fetchNewPatients();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      controller.fetchNewPatients(loadMore: true);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
                onChanged: controller.onSearchChanged,
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
            if (controller.isNewLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff851653)),
              );
            }

            if (controller.newError.value) {
              return PatientListErrorState(
                onRetry: controller.fetchNewPatients,
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
              onRefresh: () => controller.fetchNewPatients(),
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: patients.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == patients.length) {
                    return Obx(
                      () => controller.newLoadingMore.value
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  }
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
                    statusCategory: patient.statusCategory,
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
