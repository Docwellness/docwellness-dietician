import 'dart:async';
import 'dart:io';

import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:docwellnesdoc/app/modules/chat/controllers/chat_controller.dart';
import 'package:docwellnesdoc/app/modules/chat/services/service.dart';
import 'package:docwellnesdoc/app/modules/chat/views/chat_screen.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/patients/views/clint_log_data_sheet.dart';
import 'package:docwellnesdoc/app/modules/patients/views/payment_status_view.dart';
import 'package:docwellnesdoc/app/modules/patients/views/profile_options_sheet.dart';
import 'package:docwellnesdoc/app/modules/patients/views/questions_view.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/bmi_and_body_fat_container.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/bmi_card.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/calorie_intake_container.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/line_chart.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/show_diet_level_sheet.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PatientProfileView extends StatefulWidget {
  final String patientId;
  const PatientProfileView({super.key, required this.patientId});

  @override
  State<PatientProfileView> createState() => _PatientProfileViewState();
}

class _PatientProfileViewState extends State<PatientProfileView> {
  final PatientsController controller = Get.put(PatientsController());
  Timer? _autoRefreshTimer;
  static const int _refreshIntervalSeconds = 10; // Refresh every 10 seconds

  @override
  void initState() {
    controller.getPatientProfile(widget.patientId);
    controller.fetchTrackingData(widget.patientId, 'week');
    controller.fetchJourneyImages(widget.patientId);
    controller.fetchAutoJourneyMilestones(widget.patientId);
    controller.fetchDoctorNotes(widget.patientId);
    super.initState();
    debugPrint('---------------${widget.patientId}');
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (_) => _silentRefresh(),
    );
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  Future<void> _silentRefresh() async {
    // Silent refresh without showing loading indicator
    await controller.silentRefreshPatientProfile(widget.patientId);
  }

  Future<void> _openChatWithPatient(String patientId) async {
    Get.put(ChatController());
    final chatService = ChatService();
    final conversationId = await chatService.getOrCreateConversation(patientId);
    if (conversationId != null && conversationId.isNotEmpty) {
      Get.to(() => ChatScreen(conversationId: conversationId));
    } else {
      Get.snackbar(
        'Error',
        'Could not open chat. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: 'Patient profile',
          fontWeight: FontWeight.w400,
          fontSize: 21,
          color: Color(0xff1F2A37),
        ),
        actions: [
          Obx(() {
            final status = controller.patientProfileModel.value?.status;
            final isOngoing =
                status?.requestStatus == 'Paid' &&
                status?.activeDietPlanId != null;
            if (!isOngoing) return const SizedBox.shrink();
            return IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return DraggableScrollableSheet(
                      initialChildSize: 0.6,
                      minChildSize: 0.6,
                      maxChildSize: 0.6,
                      expand: false,
                      builder: (context, scrollController) {
                        return ProfileOptionsSheet(patientId: widget.patientId);
                      },
                    );
                  },
                );
              },
              icon: Icon(Icons.more_vert_sharp, color: Colors.black),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isProfileLoading.value == true) {
          return Center(
            child: CircularProgressIndicator(color: Color(0xff851653)),
          );
        }

        if (controller.patientProfileModel.value == null) {
          return Center(child: Text("No profile data found"));
        }

        return _buildProfileContent();
      }),
    );
  }

  /// Opens CreateDietPlanScreen for Week 2/3/4 with inline weight input
  Future<void> _openWeightDialogForWeek(
    BuildContext context,
    int weekNum,
    Status status,
    Basic basic,
  ) async {
    if (!context.mounted) return;

    // Open CreateDietPlanScreen directly — weight field is built into the screen
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 1,
          maxChildSize: 1,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx2, sc) {
            return CreateDietPlanScreen(
              scrollController: sc,
              firstConsultationId: status.firstConsultationId ?? '',
              patientId: widget.patientId,
              requestId: status.requestId ?? '',
              name: (basic.fullName ?? '').split(' ').first,
              targetWeek: weekNum,
            );
          },
        );
      },
    );
    // Refresh so the calorie cards reflect the (re-)assigned diet immediately.
    await controller.getPatientProfile(widget.patientId);
  }

  /// Formats an ISO date string (e.g. "1995-08-14") to "14 Aug 1995"
  String _formatDob(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  /// A single info row: [icon container] | [label + value]
  Widget _basicInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffFAA7E0).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffEF45B2).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff9DA4AE),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1F2A37),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final basic = controller.patientProfileModel.value?.basic;
    final healthSummary = controller.patientProfileModel.value?.healthSummary;
    final status = controller.patientProfileModel.value?.status;

    debugPrint('--------------idd-${status?.activeDietPlanId}');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deactivated banner
          if (status?.isActive == false)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: const Color(0xffFEE2E2),
              child: Row(
                children: [
                  const Icon(Icons.block, color: Color(0xffDC2626), size: 18),
                  const SizedBox(width: 8),
                  const CustomText(
                    text: 'This patient is deactivated',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xffDC2626),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            color: Color(0xffFEF6FB),
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Stack(
                    children: [
                      Container(
                        height: 70,
                        width: 70,

                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3.2),
                          borderRadius: BorderRadius.circular(90),
                          color: Color(0xffF3F4F6),
                        ),
                        child: Center(
                          child:
                              (basic?.profileImage != null &&
                                  basic!.profileImage!.isNotEmpty)
                              ? CircleAvatar(
                                  radius: 28.3,
                                  backgroundImage: NetworkImage(
                                    basic.profileImage!,
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 28.3,
                                  backgroundColor: Color(0xff851653),
                                  child: Text(
                                    (basic?.fullName ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: basic!.fullName!,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                      color: Color(0xff111927),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _openChatWithPatient(widget.patientId),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 6.5),
                        width: 147,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Color(0xffE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/chat_icon.png',
                              width: 16,
                              height: 16,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(width: 8),
                            CustomText(
                              text: 'Chat with patient',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xff111927),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xffFDF2FA),
                        border: Border.all(color: Color(0xffEF45B2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/star.png',
                            width: 11.91,
                            height: 12,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(width: 4),
                          CustomText(
                            text: 'FIRST USER',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Color(0xffEF45B2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xffFAA7E0).withOpacity(0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffEF45B2).withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // ── Basic Information header ──────────────────────────
                    Obx(
                      () => InkWell(
                        onTap: () => controller.showBasicInfo.value =
                            !controller.showBasicInfo.value,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Section icon
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xffFCE7F6),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.badge_outlined,
                                  color: Color(0xff851653),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Title + subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Basic Information',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff530630),
                                      ),
                                    ),
                                    Text(
                                      'Patient identity & contact',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xff9DA4AE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Animated chevron
                              AnimatedRotation(
                                turns: controller.showBasicInfo.value ? 0.5 : 0,
                                duration: const Duration(milliseconds: 280),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xff530630),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Obx(
                      () => AnimatedCrossFade(
                        duration: const Duration(milliseconds: 280),
                        crossFadeState: controller.showBasicInfo.value
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Column(
                            children: [
                              _basicInfoRow(
                                icon: Icons.person_outline_rounded,
                                label: 'Full Name',
                                value: basic.fullName ?? '—',
                                iconColor: Color(0xff851653),
                                iconBg: Color(0xffFCE7F6),
                              ),
                              const SizedBox(height: 10),
                              _basicInfoRow(
                                icon: Icons.alternate_email_rounded,
                                label: 'Username',
                                value: basic.username ?? '—',
                                iconColor: Color(0xff7C3AED),
                                iconBg: Color(0xffEDE9FE),
                              ),
                              const SizedBox(height: 10),
                              _basicInfoRow(
                                icon: Icons.mail_outline_rounded,
                                label: 'Email',
                                value: basic.email ?? '—',
                                iconColor: Color(0xff0369A1),
                                iconBg: Color(0xffE0F2FE),
                              ),
                              const SizedBox(height: 10),
                              _basicInfoRow(
                                icon: Icons.phone_android_rounded,
                                label: 'WhatsApp Number',
                                value: basic.whatsappNumber ?? '—',
                                iconColor: Color(0xff047857),
                                iconBg: Color(0xffD1FAE5),
                              ),
                              const SizedBox(height: 10),
                              _basicInfoRow(
                                icon: Icons.wc_rounded,
                                label: 'Gender',
                                value: basic.gender ?? '—',
                                iconColor: Color(0xffC2410C),
                                iconBg: Color(0xffFFEDD5),
                              ),
                              const SizedBox(height: 10),
                              _basicInfoRow(
                                icon: Icons.cake_outlined,
                                label: 'Date of Birth',
                                value: basic.dateOfBirth != null
                                    ? _formatDob(basic.dateOfBirth!)
                                    : '—',
                                iconColor: Color(0xff9D174D),
                                iconBg: Color(0xffFCE7F6),
                              ),
                            ],
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                    ),

                    Divider(color: Color(0xffFAA7E0)),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 7,
                        top: 0,
                        bottom: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: 'BMI Card',
                            fontWeight: FontWeight.w500,
                            fontSize: 17,
                            color: Color(0xff530630),
                          ),
                          Obx(
                            () => IconButton(
                              onPressed: () {
                                controller.showBmiCard.value =
                                    !controller.showBmiCard.value;
                              },
                              icon: Icon(
                                controller.showBmiCard.value
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                              ),
                              color: Color(0xff530630),
                              iconSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.showBmiCard.value,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: BmiContainer(
                            index: healthSummary?.weightIndex ?? 0,
                            value: healthSummary?.bmi ?? 0.0,
                            targetedWeight:
                                healthSummary?.targetWeight ?? 'N/A',
                            activityLevelText: healthSummary?.activityLevel,
                            healthConcerentList:
                                healthSummary?.healthConcerns ?? [],
                            activityLevel: null,
                          ),
                        ),
                      ),
                    ),

                    Divider(color: Color(0xffFAA7E0)),
                    if (status!.firstConsultationId != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 7,
                          top: 0,
                          bottom: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              text: 'First Consultation information',
                              fontWeight: FontWeight.w500,
                              fontSize: 17,
                              color: Color(0xff530630),
                            ),
                            Obx(
                              () => IconButton(
                                onPressed: () {
                                  controller.showFirstConsultationiInfo.value =
                                      !controller
                                          .showFirstConsultationiInfo
                                          .value;
                                },
                                icon: Icon(
                                  controller.showFirstConsultationiInfo.value
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                ),
                                color: Color(0xff530630),
                                iconSize: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Obx(
                      () => Visibility(
                        visible: controller.showFirstConsultationiInfo.value,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 50, left: 35),
                          child: CustomText(
                            text:
                                'Supporting line text lorem ipsum dolor sit amet, consectetur. Supporting line text lorem ipsum dolor sit amet, consectetur.Supporting line text lorem ipsum dolor sit amet, consectetur.',
                            fontWeight: FontWeight.w400,
                            fontSize: 13.5,
                            color: Color(0xff4D5761),
                          ),
                        ),
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: controller.showFirstConsultationiInfo.value,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 40,
                            top: 24,
                            right: 40,
                          ),
                          child: CustomButton(
                            isLoading: controller.isAllQuestionLoading.value,
                            onTap: () async {
                              controller.report.value = '';

                              await controller.getConsultation(
                                widget.patientId,
                              );
                              if (!mounted) return;
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                useSafeArea: true,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    initialChildSize: 1,
                                    maxChildSize: 1,
                                    minChildSize: 0.5,
                                    expand: false,
                                    builder: (context, scrollController) {
                                      return QuestionsView(
                                        scrollController: scrollController,
                                        gendar: basic.gender!,
                                        patientId: widget.patientId,
                                        isDisable: false,
                                        isEditMode: true,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            text: 'View / Edit Consultation',
                            isOutline: false,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (status.firstConsultationId != null)
                      Divider(color: Color(0xffFAA7E0)),
                  ],
                ), // Column
              ), // ClipRRect
            ), // Container
          ), // Padding
          if (status.firstConsultationId != null &&
              status.activeDietPlanId == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: CustomButton(
                onTap: () async {
                  await showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    useSafeArea: true,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return DraggableScrollableSheet(
                        initialChildSize: 1,
                        maxChildSize: 1,
                        minChildSize: 0.5,
                        expand: false,
                        builder: (context, scrollController) {
                          return CreateDietPlanScreen(
                            scrollController: scrollController,
                            firstConsultationId:
                                status.firstConsultationId ?? '',
                            patientId: widget.patientId,
                            requestId: status.requestId ?? "",
                            name: (basic.fullName ?? '').split(' ').first,
                          );
                        },
                      );
                    },
                  );
                  // Refresh profile + weekly plans after the sheet closes so
                  // the Create Diet Plan button flips to the calorie cards.
                  await controller.getPatientProfile(widget.patientId);
                },
                text: 'Create Diet Plan',
                isOutline: false,
                fontSize: 14,
              ),
            ),
          // ── Weekly Diet Plan section ──────────────────────────────
          if (status.firstConsultationId != null &&
              status.activeDietPlanId != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: CustomText(
                text: 'Weekly Diet Plans',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xff530630),
              ),
            ),
          if (status.firstConsultationId != null &&
              status.activeDietPlanId != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 16, bottom: 8),
              child: SizedBox(
                height: 130,
                child: ListView.builder(
                  itemCount: 4, // always show all 4 week slots
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final weekNum = index + 1; // 1‑based

                    // Look up backend data for this week (null-safe without collection pkg)
                    final matches = controller.weeklyDietPlans
                        .where((w) => w.week == weekNum)
                        .toList();
                    final data = matches.isNotEmpty ? matches.first : null;
                    final isFinalized = (data?.totalCalories ?? 0) > 0;

                    // ── FILLED CARD ────────────────────────────────────
                    if (isFinalized) {
                      final colors = controller.getColor(
                        weekNum,
                        controller.getCurrentWeek(),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openWeightDialogForWeek(
                            context,
                            weekNum,
                            status,
                            basic,
                          ),
                          child: Container(
                            width: 120,
                            height: 130,
                            padding: const EdgeInsets.only(top: 16, left: 14),
                            decoration: BoxDecoration(
                              color: colors['bg'],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors['border']!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: data!.totalCalories.toString(),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: const Color(0xff1F2A37),
                                ),
                                const CustomText(
                                  text: 'Cal / day',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xff6C737F),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFDF2FA),
                                    border: Border.all(
                                      color: const Color(0xffFCE7F6),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CustomText(
                                    text: 'Week $weekNum ✓',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: const Color(0xffEF45B2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // ── EMPTY PLACEHOLDER CARD (Week 2/3/4) ───────────
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => _openWeightDialogForWeek(
                          context,
                          weekNum,
                          status,
                          basic,
                        ),
                        child: Container(
                          width: 120,
                          height: 130,
                          decoration: BoxDecoration(
                            color: const Color(0xffFAFAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xffFAA7E0),
                              width: 1.5,
                              // dashed look via custom paint is complex; border color conveys the idea
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xffFCE7F6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Color(0xff851653),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Week $weekNum',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff851653),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Add plan',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xff9DA4AE),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Send Payment Request button — shown when diet plan exists but payment not yet requested
          if (status.requestStatus == 'Unpaid' &&
              status.activeDietPlanId != null &&
              controller.hasFinalizedWeeks)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 18),
              child: CustomButton(
                onTap: () async {
                  final requestId = status.requestId ?? '';
                  if (requestId.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'No request found',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  await controller.sendPaymentRequest(
                    widget.patientId,
                    requestId,
                  );
                  await controller.getPatientProfile(widget.patientId);
                },
                text: 'Send Payment Request',
                isOutline: false,
                fontSize: 14,
              ),
            ),

          if (status.requestStatus == 'PaymentSubmitted' ||
              status.requestStatus == 'PaymentRequested')
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 18),
              child: GestureDetector(
                onTap: status.requestStatus != 'PaymentSubmitted'
                    ? () {}
                    : () async {
                        controller.isProofLoading.value = true;
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          useSafeArea: true,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) {
                            return DraggableScrollableSheet(
                              initialChildSize: 1,
                              maxChildSize: 1,
                              minChildSize: 0.5,
                              expand: false,
                              builder: (context, scrollController) {
                                return PaymentStatusSheet(
                                  scrollController: scrollController,
                                  patientId: widget.patientId,
                                  dietPlanId: status.activeDietPlanId ?? '',
                                );
                              },
                            );
                          },
                        );
                        await controller.getPaymentProof(widget.patientId);
                      },
                child: Container(
                  padding: EdgeInsets.only(
                    top: 10,
                    bottom: 10,
                    left: 5,
                    right: 19.5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Color(0xffFEF6FB),
                    border: Border.all(color: Color(0xffFDF2FA)),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/Clip path group.png',
                        height: 60,
                        width: 60,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: status.requestStatus == 'PaymentSubmitted'
                                  ? 'Payment Update Received'
                                  : 'Payment Request Sent',
                              fontWeight: FontWeight.w400,
                              fontSize: 18,
                              color: Color(0xff384250),
                            ),
                            CustomText(
                              text: status.requestStatus == 'PaymentSubmitted'
                                  ? 'Review Payment update from Client and confirm'
                                  : 'Contact client to send payment screenshot via app',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xff6C737F),
                              height: 1.3,
                            ),
                            if (status.paymentSummary != null)
                              CustomText(
                                text:
                                    'Received: Rs ${_money(status.paymentSummary?.amountReceived)} | Pending: Rs ${_money(status.paymentSummary?.amountPending)}',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color:
                                    (status.paymentSummary?.amountPending ??
                                            0) >
                                        0
                                    ? Color(0xff851653)
                                    : Color(0xff027A48),
                                height: 1.4,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      if (status.requestStatus == 'PaymentSubmitted')
                        Image.asset(
                          'assets/icons/home_right_arrow.png',
                          width: 40,
                          height: 20,
                          fit: BoxFit.fitHeight,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (status.subscriptionExpiresAt != null)
            _buildSubscriptionBanner(status),
          if (status.firstConsultationId == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: CustomButton(
                onTap: () {
                  controller.report.value = '';
                  controller.clearCustomAnswers();
                  controller.fetchConsultationTemplate();

                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    useSafeArea: true,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return DraggableScrollableSheet(
                        initialChildSize: 1,
                        maxChildSize: 1,
                        minChildSize: 0.5,
                        expand: false,
                        builder: (context, scrollController) {
                          return QuestionsView(
                            isDisable: false,
                            scrollController: scrollController,
                            gendar: basic.gender!,
                            patientId: widget.patientId,
                          );
                        },
                      );
                    },
                  );
                },
                text: 'Start First Consultation',
                isOutline: true,
                fontSize: 14,
              ),
            ),
          if (status.firstConsultationId != null &&
              status.activeDietPlanId != null &&
              controller.hasFinalizedWeeks)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              child: Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xffFDF2FA),
                ),

                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 13,
                    top: 12,
                    bottom: 12,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomText(
                              text: 'Calorie intake',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff4D5761),
                            ),
                          ),
                          Obx(
                            () => TimePeriodDropdown(
                              selectedPeriod:
                                  controller.trackingTimePeriod.value,
                              onChanged: (period) =>
                                  controller.changeTrackingPeriod(
                                    widget.patientId,
                                    period,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      Obx(() {
                        final td = controller.trackingData.value;
                        if (td == null) return SizedBox.shrink();
                        return CalorieIntakeContainer(
                          data: td.calorieData,
                          plannedCalories: td.plannedDailyCalories,
                          currentIndex: td.currentIndex,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          if (status.firstConsultationId != null &&
              status.activeDietPlanId != null &&
              controller.hasFinalizedWeeks)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: CustomButton(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    useSafeArea: true,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return DraggableScrollableSheet(
                        initialChildSize: 1,
                        maxChildSize: 1,
                        minChildSize: 0.5,
                        expand: false,
                        builder: (context, scrollController) {
                          return ClintLogDataSheet(patientId: widget.patientId);
                        },
                      );
                    },
                  );
                },
                text: 'Show Logged Data',
                fontSize: 14,
                isOutline: false,
              ),
            ),
          if (status.firstConsultationId != null &&
              status.activeDietPlanId != null &&
              controller.hasFinalizedWeeks)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      text: 'Weight trend over time (in KG)',

                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff9F1561),
                    ),
                  ),

                  Obx(
                    () => TimePeriodDropdown(
                      selectedPeriod: controller.trackingTimePeriod.value,
                      onChanged: (period) => controller.changeTrackingPeriod(
                        widget.patientId,
                        period,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (status.firstConsultationId != null &&
              status.activeDietPlanId != null &&
              controller.hasFinalizedWeeks)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10),

              child: Obx(() {
                final td = controller.trackingData.value;
                if (td == null || td.weightTrend.isEmpty) {
                  return SizedBox.shrink();
                }
                return TargetWeightChart(weightData: td.weightTrend);
              }),
            ),

          if (status.firstConsultationId != null &&
              status.activeDietPlanId != null &&
              controller.hasFinalizedWeeks)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16),

              child: Obx(() {
                final td = controller.trackingData.value;
                if (td == null || td.bmiTrend.isEmpty) {
                  return SizedBox.shrink();
                }
                return BmiChart(
                  bmiData: td.bmiTrend,
                  currentBmi: td.currentBmi,
                  selectedPeriod: controller.trackingTimePeriod.value,
                  onPeriodChanged: (period) =>
                      controller.changeTrackingPeriod(widget.patientId, period),
                  currentIndex: td.currentIndex,
                );
              }),
            ),
          if (status.firstConsultationId != null &&
              status.activeDietPlanId != null &&
              controller.hasFinalizedWeeks)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 32),
              child: CustomText(
                text: 'Clients Journey',
                fontWeight: FontWeight.w400,
                fontSize: 20,
                color: Color(0xff530630),
              ),
            ),

          if (status.firstConsultationId != null &&
              status.activeDietPlanId != null &&
              controller.hasFinalizedWeeks)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                color: Color(0xffFEF6FB),
                padding: EdgeInsets.only(top: 24, left: 24, bottom: 10),
                width: double.infinity,
                child: Obx(() {
                  if (controller.isJourneyLoading.value ||
                      !controller.isAutoMilestonesLoaded.value) {
                    return const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  // Use auto-generated milestone cards, fallback to manual
                  final cards = controller.autoJourneyCards.isNotEmpty
                      ? controller.autoJourneyCards
                      : controller.journeyImages;
                  return SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Add New Image button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _showAddJourneyImageSheet(context),
                              child: Container(
                                height: 200,
                                width: 144,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/icons/Clip path group.png',
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            CustomText(
                              text: 'Add New Image',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Color(0xff530630),
                            ),
                          ],
                        ),
                        SizedBox(width: 18),
                        // Journey cards (auto-generated + manual)
                        if (cards.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: cards.length,
                            itemBuilder: (context, index) {
                              final image = cards[index];
                              final hasAfter = image.afterImageUrl.isNotEmpty;
                              return Padding(
                                padding: const EdgeInsets.only(right: 17),
                                child: SizedBox(
                                  width: hasAfter ? 290 : 180,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Before / single image
                                          Expanded(
                                            child: Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image:
                                                    image
                                                        .beforeImageUrl
                                                        .isNotEmpty
                                                    ? DecorationImage(
                                                        image: NetworkImage(
                                                          image.beforeImageUrl,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                              child:
                                                  image.beforeImageUrl.isEmpty
                                                  ? const Center(
                                                      child: Text(
                                                        'Before',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xff49454F,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          // Only show after box when there is an after image
                                          if (image
                                              .afterImageUrl
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      image.afterImageUrl,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: CustomText(
                                              text: image.dayLabel,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              color: Color(0xff530630),
                                            ),
                                          ),
                                          // Only show edit for manual (non-auto) images
                                          if (image.uploadedByRole != 'auto')
                                            InkWell(
                                              onTap: () =>
                                                  _showEditJourneyImageSheet(
                                                    context,
                                                    image,
                                                  ),
                                              child: Image.asset(
                                                'assets/icons/edit_procress.png',
                                                height: 16,
                                                width: 16,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(top: 45, left: 32),
            child: CustomText(
              text: 'Notes & Suggestions',
              fontWeight: FontWeight.w400,
              fontSize: 20,
              color: Color(0xff530630),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 9, left: 16),
            child: SizedBox(
              width: double.infinity,
              height: 118,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showAddNotePopup(context);
                    },
                    child: Container(
                      height: 118,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xff9F1561)),
                        color: Color(0xffFCFCFD),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            child: CustomText(
                              text: 'Add more Notes',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Color(0xff1F2A37),
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 24,
                            width: 23,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xffFCE7F6)),
                              color: Color(0xffFCE7F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                color: Color(0xffEF45B2),
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Obx(() {
                    if (controller.doctorNotes.isEmpty) {
                      return SizedBox.shrink();
                    }
                    return ListView.builder(
                      itemCount: controller.doctorNotes.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final note = controller.doctorNotes[index];
                        final noteDate = note['noteDate'] != null
                            ? DateTime.tryParse(note['noteDate'].toString())
                            : null;
                        final formattedDate = noteDate != null
                            ? '${noteDate.day.toString().padLeft(2, '0')}/${noteDate.month.toString().padLeft(2, '0')}/${noteDate.year}'
                            : '';
                        final noteContent = note['noteContent'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Container(
                            padding: EdgeInsets.only(
                              left: 16,
                              top: 26,
                              right: 14,
                            ),
                            height: 118,
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xff9F1561)),
                              color: Color(0xffFCFCFD),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xffFDF2FA),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Color(0xffFCE7F6),
                                    ),
                                  ),
                                  child: CustomText(
                                    text: formattedDate,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: Color(0xffEF45B2),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Expanded(
                                  child: CustomText(
                                    text: noteContent,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    color: Color(0xff1F2A37),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  // ===== Add Doctor Note Popup =====

  void _showAddNotePopup(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final formattedDate =
                '${selectedDate.month.toString().padLeft(2, '0')}/'
                '${selectedDate.day.toString().padLeft(2, '0')}/'
                '${selectedDate.year}';

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xff79747E),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: 'Add Note',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Color(0xff1F2A37),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setSheetState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Color(0xffFCE7F6),
                              border: Border.all(color: Color(0xffEF45B2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Color(0xff851653),
                                ),
                                SizedBox(width: 6),
                                CustomText(
                                  text: formattedDate,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Color(0xff851653),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: noteController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write your note for the patient...',
                        hintStyle: TextStyle(
                          color: Color(0xff9CA3AF),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Color(0xffF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xff9F1561)),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: controller.isSendingNote.value
                              ? null
                              : () async {
                                  if (noteController.text.trim().isEmpty) {
                                    Get.snackbar(
                                      'Error',
                                      'Please write a note',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red.withValues(
                                        alpha: 0.9,
                                      ),
                                      colorText: Colors.white,
                                      margin: const EdgeInsets.all(12),
                                    );
                                    return;
                                  }
                                  final success = await controller
                                      .sendDoctorNote(
                                        patientId: widget.patientId,
                                        noteContent: noteController.text.trim(),
                                        noteDate: selectedDate,
                                      );
                                  if (success) {
                                    Navigator.of(ctx).pop();
                                    Get.snackbar(
                                      'Success',
                                      'Note sent to patient',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.green.withValues(
                                        alpha: 0.9,
                                      ),
                                      colorText: Colors.white,
                                      margin: const EdgeInsets.all(12),
                                      duration: const Duration(seconds: 2),
                                    );
                                  } else {
                                    Get.snackbar(
                                      'Error',
                                      'Failed to send note',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red.withValues(
                                        alpha: 0.9,
                                      ),
                                      colorText: Colors.white,
                                      margin: const EdgeInsets.all(12),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff9F1561),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: controller.isSendingNote.value
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : CustomText(
                                  text: 'Submit Notes',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===== Journey Image Bottom Sheets =====

  void _showAddJourneyImageSheet(BuildContext context) {
    final descController = TextEditingController();
    final dayLabelController = TextEditingController(text: 'Day 1');
    XFile? selectedBeforeImage;
    XFile? selectedAfterImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xff79747E),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomText(
                      text: 'Add Journey Image',
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: const Color(0xff530630),
                    ),
                    const SizedBox(height: 16),

                    // Before & After image pickers
                    Row(
                      children: [
                        // Before image
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (img != null) {
                                setSheetState(() => selectedBeforeImage = img);
                              }
                            },
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: const Color(0xffFEF6FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xffFDF2FA),
                                ),
                              ),
                              child: selectedBeforeImage == null
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 36,
                                            color: Color(0xff530630),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Before',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xff530630),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(selectedBeforeImage!.path),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 160,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // After image
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (img != null) {
                                setSheetState(() => selectedAfterImage = img);
                              }
                            },
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: const Color(0xffFEF6FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xffFDF2FA),
                                ),
                              ),
                              child: selectedAfterImage == null
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo,
                                            size: 36,
                                            color: Color(0xff530630),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'After',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xff530630),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(selectedAfterImage!.path),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 160,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Day label
                    TextField(
                      controller: dayLabelController,
                      decoration: const InputDecoration(
                        labelText: 'Day Label',
                        hintText: 'e.g. Day 1, Day 30',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Add a description...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    Obx(() {
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff530630),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: controller.isJourneyUploading.value
                              ? null
                              : () async {
                                  if (selectedBeforeImage == null &&
                                      selectedAfterImage == null) {
                                    Get.snackbar(
                                      'Error',
                                      'Please select at least one image',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }
                                  final success = await controller
                                      .uploadJourneyImage(
                                        widget.patientId,
                                        beforeImagePath:
                                            selectedBeforeImage?.path,
                                        afterImagePath:
                                            selectedAfterImage?.path,
                                        description: descController.text,
                                        dayLabel:
                                            dayLabelController.text.isEmpty
                                            ? 'Day 1'
                                            : dayLabelController.text,
                                      );
                                  if (success) {
                                    Navigator.pop(ctx);
                                  }
                                },
                          child: controller.isJourneyUploading.value
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Upload',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditJourneyImageSheet(BuildContext context, dynamic journeyImage) {
    final descController = TextEditingController(
      text: journeyImage.description,
    );
    final dayLabelController = TextEditingController(
      text: journeyImage.dayLabel,
    );
    XFile? newBeforeImage;
    XFile? newAfterImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xff79747E),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: 'Edit Journey Image',
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          color: const Color(0xff530630),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Delete'),
                                content: const Text(
                                  'Delete this journey image?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await controller.deleteJourneyImage(
                                widget.patientId,
                                journeyImage.id,
                              );
                              Navigator.pop(ctx);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Before & After images
                    Row(
                      children: [
                        // Before image
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (img != null) {
                                setSheetState(() => newBeforeImage = img);
                              }
                            },
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: const Color(0xffFEF6FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xffFDF2FA),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: newBeforeImage != null
                                    ? Image.file(
                                        File(newBeforeImage!.path),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 160,
                                      )
                                    : journeyImage.beforeImageUrl.isNotEmpty
                                    ? Image.network(
                                        journeyImage.beforeImageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 160,
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: 28,
                                              color: Color(0xff530630),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Before',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xff530630),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // After image
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (img != null) {
                                setSheetState(() => newAfterImage = img);
                              }
                            },
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: const Color(0xffFEF6FB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xffFDF2FA),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: newAfterImage != null
                                    ? Image.file(
                                        File(newAfterImage!.path),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 160,
                                      )
                                    : journeyImage.afterImageUrl.isNotEmpty
                                    ? Image.network(
                                        journeyImage.afterImageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 160,
                                      )
                                    : const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: 28,
                                              color: Color(0xff530630),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'After',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xff530630),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: CustomText(
                        text: 'Tap image to replace',
                        fontSize: 12,
                        color: const Color(0xff49454F),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Day label
                    TextField(
                      controller: dayLabelController,
                      decoration: const InputDecoration(
                        labelText: 'Day Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff530630),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () async {
                          final success = await controller.updateJourneyImage(
                            widget.patientId,
                            journeyImage.id,
                            beforeImagePath: newBeforeImage?.path,
                            afterImagePath: newAfterImage?.path,
                            description: descController.text,
                            dayLabel: dayLabelController.text,
                          );
                          if (success) {
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _money(double? value) {
    final v = value ?? 0;
    if (v % 1 == 0) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  Widget _buildSubscriptionBanner(Status status) {
    final expiryStr = status.subscriptionExpiresAt;
    if (expiryStr == null) return SizedBox.shrink();

    final expiresAt = DateTime.tryParse(expiryStr);
    if (expiresAt == null) return SizedBox.shrink();

    final now = DateTime.now();
    final isExpired = now.isAfter(expiresAt);
    final daysLeft = isExpired ? 0 : expiresAt.difference(now).inDays;
    final expiryDate = DateFormat('dd MMM yyyy').format(expiresAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpired ? const Color(0xffFEF2F2) : const Color(0xffF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpired
                ? const Color(0xffFECACA)
                : const Color(0xffBBF7D0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpired ? Icons.error_outline : Icons.check_circle_outline,
              color: isExpired
                  ? const Color(0xffDC2626)
                  : const Color(0xff16A34A),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: isExpired
                        ? 'Subscription Expired'
                        : 'Subscription Active',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isExpired
                        ? const Color(0xffDC2626)
                        : const Color(0xff16A34A),
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    text: isExpired
                        ? 'Expired on $expiryDate'
                        : '$daysLeft days remaining \u2022 Expires $expiryDate',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: isExpired
                        ? const Color(0xff991B1B)
                        : const Color(0xff166534),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
