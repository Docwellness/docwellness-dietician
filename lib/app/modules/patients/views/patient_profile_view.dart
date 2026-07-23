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
import 'package:docwellnesdoc/app/routes/app_pages.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

enum _WeekCardState { generated, eligible, locked }

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
    // Collapsible open/closed flags live on the shared PatientsController
    // singleton (not per-patient state), so leaving this expanded on one
    // patient's profile would otherwise carry over when navigating to
    // another.
    controller.showFirstConsultationiInfo.value = false;
    controller.showPaymentInfo.value = false;
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
    // Get.put() unconditionally here used to create a brand-new
    // ChatController (with its own live socket subscription) every time a
    // chat was opened, without ever disposing the previous one - each
    // leaked subscription kept firing for every future incoming message,
    // which is how the same message could end up rendered more than once.
    // Reuse the existing controller if one is already registered, same as
    // the notification-tap entry point already does.
    if (!Get.isRegistered<ChatController>()) {
      Get.put(ChatController());
    }
    final chatService = ChatService();
    final conversationId = await chatService.getOrCreateConversation(patientId);
    if (conversationId != null && conversationId.isNotEmpty) {
      Get.to(
        () => ChatScreen(conversationId: conversationId, receiverId: patientId),
      );
    } else {
      showAppToast(
        Get.overlayContext!,
        message: 'Could not open chat. Please try again.',
        type: AppToastType.error,
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
            // This screen can be reached with nothing left to pop to (e.g.
            // a cold reload landing directly on /patient-profile/:id) -
            // Get.back() would silently do nothing in that case, leaving
            // the back button appearing broken. Fall back to the patient
            // list so there's always somewhere for it to go.
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              Get.offAllNamed(Routes.PATIENTS);
            }
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
                (status?.requestStatus == 'Paid' ||
                    status?.requestStatus == 'PartiallyPaid') &&
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
          IconButton(
            onPressed: () => _showDeleteConfirmationDialog(context),
            icon: const Icon(Icons.delete_outline, color: Color(0xffB42318)),
            tooltip: 'Delete patient',
          ),
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

  /// Permanently deletes this patient (all their data + Supabase auth
  /// identity - see patientController.js's deletePatient). Irreversible, so
  /// the dietician must type the patient's exact email to enable the
  /// Delete button - a typo-proof safeguard against an accidental tap, on
  /// top of the backend's own re-check of the same email.
  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final email = controller.patientProfileModel.value?.basic?.email;
    if (email == null || email.isEmpty) return;

    final textController = TextEditingController();
    final matches = ValueNotifier<bool>(false);
    textController.addListener(() {
      matches.value = textController.text.trim().toLowerCase() == email.toLowerCase();
    });

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: CustomText(
            text: 'Delete patient?',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xff1F2A37),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text:
                    'This permanently deletes "$email" and ALL their data - diet plans, logs, chat history, payments. This cannot be undone.',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: const Color(0xff4D5761),
              ),
              const SizedBox(height: 16),
              CustomText(
                text: 'Type "$email" to confirm:',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: const Color(0xff1F2A37),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: email,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: matches,
              builder: (context, isMatch, _) {
                return TextButton(
                  onPressed: isMatch
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: isMatch ? const Color(0xffB42318) : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );

    matches.dispose();
    textController.dispose();

    if (confirmed != true || !context.mounted) return;

    final success = await controller.deletePatient(widget.patientId, email);
    if (success && context.mounted) {
      showAppToast(
        Get.overlayContext!,
        message: '"$email" has been permanently deleted.',
        type: AppToastType.success,
      );
      if (Navigator.of(context).canPop()) {
        Get.back();
      } else {
        Get.offAllNamed(Routes.PATIENTS);
      }
    }
  }

  /// Opens CreateDietPlanScreen for Week 2/3/4 with inline weight input
  Future<void> _openWeightDialogForWeek(
    BuildContext context,
    int weekNum,
    Status status,
    Basic basic, {
    List<int>? weeksToGenerate,
  }) async {
    if (!context.mounted) return;

    // Open CreateDietPlanScreen directly — weight field is built into the screen
    await Get.to(
      () => CreateDietPlanScreen(
        firstConsultationId: status.firstConsultationId ?? '',
        patientId: widget.patientId,
        requestId: status.requestId ?? '',
        name: (basic.fullName ?? '').split(' ').first,
        targetWeek: weekNum,
        dietPlanId: status.activeDietPlanId,
        weeksToGenerate: weeksToGenerate,
      ),
    );
    // Refresh so the calorie cards reflect the (re-)assigned diet immediately.
    await controller.getPatientProfile(widget.patientId);
  }

  /// Which weeks a tap on week [weekNum]'s "eligible" card should generate -
  /// Golden always regenerates weeks 3-4 together as a pair; every other
  /// tier generates one week at a time.
  List<int> _weeksToGenerateFor(int weekNum, String? tier) {
    if (tier == 'golden' && (weekNum == 3 || weekNum == 4)) return [3, 4];
    return [weekNum];
  }

  /// Matches the backend's eligibility window (see
  /// utils/membershipTiers.js::isWithinEligibilityWindow) so the UI never
  /// shows "eligible" for a tap the server will reject: the last 2 days of
  /// [priorWeek]'s date range, not weight-log-dependent.
  bool _isWithinEligibilityWindow(
    int priorWeek,
    List<WeekScheduleEntry> weekSchedule,
  ) {
    final matches = weekSchedule.where((w) => w.week == priorWeek).toList();
    final end = matches.isNotEmpty ? matches.first.endDate : null;
    if (end == null) return true; // no schedule known yet - don't block
    return DateTime.now().isAfter(end.subtract(const Duration(days: 2)));
  }

  /// generated: AI content exists, ready to pick/finalize meals.
  /// eligible: not generated yet, but the prior week is finalized AND
  /// within its last 2 days (not weight-log-dependent - product decision).
  /// locked: neither of the above yet - matches the backend's
  /// validateRegenerateRequest gating.
  _WeekCardState _weekCardState(
    int weekNum,
    String? tier,
    List<int> generatedWeeks,
    Set<int> finalizedWeeks,
    List<WeekScheduleEntry> weekSchedule,
  ) {
    if (generatedWeeks.contains(weekNum)) return _WeekCardState.generated;
    if (tier == 'golden') {
      if (weekNum == 3 || weekNum == 4) {
        return finalizedWeeks.contains(2) &&
                _isWithinEligibilityWindow(2, weekSchedule)
            ? _WeekCardState.eligible
            : _WeekCardState.locked;
      }
      return _WeekCardState.locked;
    }
    if (tier == 'platinum') {
      if (weekNum >= 2 && weekNum <= 4) {
        return finalizedWeeks.contains(weekNum - 1) &&
                _isWithinEligibilityWindow(weekNum - 1, weekSchedule)
            ? _WeekCardState.eligible
            : _WeekCardState.locked;
      }
      return _WeekCardState.locked;
    }
    // Silver generates all 4 weeks together up front - not being in
    // generatedWeeks here just means the initial generation hasn't
    // completed/synced yet, not that it's individually regenerable.
    return _WeekCardState.locked;
  }

  String _lockedExplanation(
    int weekNum,
    String? tier,
    Set<int> finalizedWeeks,
    List<WeekScheduleEntry> weekSchedule,
  ) {
    final priorWeek = tier == 'golden' ? 2 : weekNum - 1;
    final priorLabel = tier == 'golden' ? 'Week 2' : 'Week $priorWeek';
    final nextLabel = tier == 'golden' ? 'weeks 3-4' : 'Week $weekNum';
    if (!finalizedWeeks.contains(priorWeek)) {
      return 'Finalize $priorLabel first to unlock $nextLabel.';
    }
    final matches = weekSchedule.where((w) => w.week == priorWeek).toList();
    final priorEnd = matches.isNotEmpty ? matches.first.endDate : null;
    final windowOpensAt = priorEnd?.subtract(const Duration(days: 2));
    if (windowOpensAt != null) {
      return '$priorLabel is finalized - $nextLabel unlocks ${_formatShortDate(windowOpensAt)}.';
    }
    return 'This week isn\'t ready yet.';
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
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

  /// Read-only bordered field matching the patient app's CustomField look
  /// (floating label chip, same border/label colors) - used to mirror the
  /// Request Diet Plan screen's layout exactly in Basic Information.
  Widget _boxField({required String label, required String value}) {
    final hasValue = value.trim().isNotEmpty && value != '—';
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        label: hasValue
            ? Container(
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xffFEF6FB),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: CustomText(
                  text: label,
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: const Color(0xff851653),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff4D5761),
                ),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: hasValue ? const Color(0xff530630) : const Color(0xff6C737F),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: hasValue ? const Color(0xff530630) : const Color(0xff6C737F),
          ),
        ),
      ),
      child: Text(
        hasValue ? value : '',
        style: const TextStyle(
          color: Color(0xff530630),
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
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
                            text: (status?.membershipPlan ?? '').isNotEmpty
                                ? status!.membershipPlan!.toUpperCase()
                                : 'NO MEMBERSHIP',
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
                              _boxField(
                                label: 'Start Date for Diet',
                                value: healthSummary?.startDateForDiet ?? '—',
                              ),
                              const SizedBox(height: 16),
                              _boxField(
                                label: 'Full name',
                                value: basic.fullName ?? '—',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _boxField(
                                      label: 'Date of Birth',
                                      value: basic.dateOfBirth != null
                                          ? _formatDob(basic.dateOfBirth!)
                                          : '—',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _boxField(
                                      label: 'Gender',
                                      value: basic.gender ?? '—',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _boxField(
                                label: 'Primary Goal',
                                value: healthSummary?.primaryGoal ?? '—',
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _boxField(
                                      label: 'Initial',
                                      value: healthSummary?.weight != null
                                          ? '${healthSummary!.weight} Kg'
                                          : '—',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _boxField(
                                      label: 'Height',
                                      value: healthSummary?.height != null
                                          ? '${healthSummary!.height} CM'
                                          : '—',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _boxField(
                                      label: 'Target',
                                      value: healthSummary?.targetWeight ?? '—',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _boxField(
                                label: 'Illness Attention',
                                value:
                                    (healthSummary
                                            ?.healthConcerns
                                            ?.isNotEmpty ??
                                        false)
                                    ? healthSummary!.healthConcerns!.join(', ')
                                    : '—',
                              ),
                              const SizedBox(height: 16),
                              _boxField(
                                label: 'Activity Level',
                                value: healthSummary?.activityLevel ?? '—',
                              ),
                              const SizedBox(height: 16),
                              _boxField(
                                label: 'Email',
                                value: basic.email ?? '—',
                              ),
                              const SizedBox(height: 16),
                              _boxField(
                                label: 'WhatsApp Number',
                                value: basic.whatsappNumber ?? '—',
                              ),
                            ],
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                    ),

                    Divider(color: Color(0xffFAA7E0)),
                    Obx(
                      () => InkWell(
                        onTap: () => controller.showBmiCard.value =
                            !controller.showBmiCard.value,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xffFCE7F6),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.monitor_weight_outlined,
                                  color: Color(0xff851653),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomText(
                                  text: 'BMI Card',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                  color: Color(0xff530630),
                                ),
                              ),
                              AnimatedRotation(
                                turns: controller.showBmiCard.value ? 0.5 : 0,
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
                      () => Visibility(
                        visible: controller.showBmiCard.value,
                        child: Padding(
                          // Horizontal inset matches Basic Info's box-fields
                          // (EdgeInsets.fromLTRB(16, 4, 16, 16)) - this had
                          // none, so the card sat flush with the section's
                          // edge instead of aligned with everything above it.
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 15),
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

                    // Divider only shows alongside the section it separates -
                    // previously unconditional, so it left a stray line with
                    // nothing below it whenever there was no First
                    // Consultation yet (just the "Start First Consultation"
                    // button, which sits outside this card entirely).
                    //
                    // The description text and "View / Edit Consultation"
                    // button below must stay INSIDE this same conditional,
                    // not just the header - they were previously gated only
                    // by showFirstConsultationiInfo (the collapsible's
                    // open/closed flag), which lives on the shared
                    // PatientsController singleton. Once expanded for one
                    // patient with a consultation, that flag stayed true and
                    // leaked the button onto every other patient's profile,
                    // including ones with no consultation yet - showing
                    // alongside "Start First Consultation" (image: BMI Card
                    // -> orphaned "View / Edit Consultation" -> "Start First
                    // Consultation", with no "First Consultation
                    // information" header in between).
                    if (status!.firstConsultationId != null) ...[
                      Divider(color: Color(0xffFAA7E0)),
                      Obx(
                        () => InkWell(
                          onTap: () =>
                              controller.showFirstConsultationiInfo.value =
                                  !controller.showFirstConsultationiInfo.value,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFCE7F6),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_outlined,
                                    color: Color(0xff851653),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CustomText(
                                    text: 'First Consultation information',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                    color: Color(0xff530630),
                                  ),
                                ),
                                AnimatedRotation(
                                  turns:
                                      controller
                                          .showFirstConsultationiInfo
                                          .value
                                      ? 0.5
                                      : 0,
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
                        () => Visibility(
                          visible: controller.showFirstConsultationiInfo.value,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 40,
                              top: 16,
                              right: 40,
                              bottom: 20,
                            ),
                            child: CustomButton(
                              isLoading: controller.isAllQuestionLoading.value,
                              onTap: () async {
                                controller.report.value = '';
                                // Must happen before any of the reload calls
                                // below - they include a network round-trip
                                // that can outlast the draft's debounce
                                // window, and leaving the previous autosave
                                // listener attached during that window lets
                                // it save a half-reset snapshot over the
                                // real draft. See prepareConsultationDraft's
                                // doc comment.
                                controller.stopConsultationDraftAutosave();

                                // Order matters here - must NOT run
                                // concurrently. getConsultation() ends by
                                // syncing customAnswerValues against
                                // consultationTemplate, deleting any answer
                                // whose fieldId isn't in the template (so a
                                // removed field's stale answer doesn't
                                // linger). If the template hasn't been
                                // fetched yet when that runs, it's empty, so
                                // every real answer just fetched looks
                                // "unknown" and gets wiped before the
                                // template ever arrives to restore them -
                                // this is exactly what was making saved
                                // consultations appear empty. Fetch the
                                // template first so it's already populated
                                // by the time getConsultation() syncs against
                                // it.
                                await controller.fetchConsultationTemplate();
                                await controller.getConsultation(
                                  widget.patientId,
                                );
                                await controller.prepareConsultationDraft(
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
                    ],
                    // Payment Information option - only once a payment
                    // request has actually gone out (requestStatus moves
                    // off 'Unpaid'/null the moment sendPaymentRequest or the
                    // Week 1 auto-send fires). Mirrors the First
                    // Consultation information accordion immediately above
                    // it, so the two informational sections in this card
                    // read consistently.
                    if (_paymentInfoVisible(status)) ...[
                      Divider(color: Color(0xffFAA7E0)),
                      Obx(
                        () => InkWell(
                          onTap: () => controller.showPaymentInfo.value =
                              !controller.showPaymentInfo.value,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFCE7F6),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.payments_outlined,
                                    color: Color(0xff851653),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: CustomText(
                                    text: 'Payment Information',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                    color: Color(0xff530630),
                                  ),
                                ),
                                _paymentStatusChip(
                                  _resolvedPaymentState(status),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: controller.showPaymentInfo.value
                                      ? 0.5
                                      : 0,
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
                        () => Visibility(
                          visible: controller.showPaymentInfo.value,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 4,
                              right: 16,
                              bottom: 20,
                            ),
                            child: _paymentInfoBody(status),
                          ),
                        ),
                      ),
                    ],
                  ],
                ), // Column
              ), // ClipRRect
            ), // Container
          ), // Padding
          if (status.firstConsultationId != null &&
              status.activeDietPlanId == null) ...[
            if (status.patientConsented == true)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                child: CustomButton(
                  onTap: () async {
                    await Get.to(
                      () => CreateDietPlanScreen(
                        firstConsultationId: status.firstConsultationId ?? '',
                        patientId: widget.patientId,
                        requestId: status.requestId ?? "",
                        name: (basic.fullName ?? '').split(' ').first,
                      ),
                    );
                    // Refresh profile + weekly plans after the screen closes
                    // so the Create Diet Plan button flips to the calorie
                    // cards.
                    await controller.getPatientProfile(widget.patientId);
                  },
                  text: 'Create Diet Plan',
                  isOutline: false,
                  fontSize: 14,
                ),
              )
            else
              // Patient hasn't reviewed/consented yet - a silently-missing
              // button here would be confusing, so explain what's blocking
              // it rather than just omitting it.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFDF2FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xffFAA7E0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hourglass_top_rounded,
                        color: Color(0xff851653),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomText(
                          text:
                              'Waiting for the patient to review their first consultation and submit consent before a diet plan can be created.',
                          fontWeight: FontWeight.w400,
                          fontSize: 12.5,
                          color: Color(0xff851653),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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

                    final tier = status.membershipTier;
                    final profileModel = controller.patientProfileModel.value;
                    final generatedWeeks =
                        profileModel?.generatedWeekNumbers ?? [];
                    final finalizedWeeks = controller.weeklyDietPlans
                        .where((w) => (w.totalCalories ?? 0) > 0)
                        .map((w) => w.week!)
                        .toSet();
                    final weekSchedule = profileModel?.weekSchedule ?? [];
                    final displayWeekNum =
                        profileModel?.displayWeek(weekNum) ?? weekNum;
                    final thisWeekScheduleMatches = weekSchedule
                        .where((w) => w.week == weekNum)
                        .toList();
                    final thisWeekDateRange =
                        thisWeekScheduleMatches.isNotEmpty &&
                            thisWeekScheduleMatches.first.startDate != null &&
                            thisWeekScheduleMatches.first.endDate != null
                        ? '${_formatShortDate(thisWeekScheduleMatches.first.startDate!)} - ${_formatShortDate(thisWeekScheduleMatches.first.endDate!)}'
                        : null;
                    // The week the patient is actually living through right
                    // now is the latest *finalized* one - not whichever week
                    // happens to be eligible/pre-generated, which may well
                    // be a future week the dietician got a head start on.
                    final latestFinalizedWeek = finalizedWeeks.isEmpty
                        ? 0
                        : finalizedWeeks.reduce((a, b) => a > b ? a : b);
                    // ...but "finalized" only means the content is ready,
                    // not that the patient has actually started it - a
                    // dietician can (and does, for Golden/Platinum) finalize
                    // a week whose own scheduled date is still in the
                    // future. Showing that week with the bold "active right
                    // now" card would be misleading, so it only counts as
                    // the active week once its own weekSchedule date has
                    // actually arrived. Missing/incomplete schedule data
                    // (older plans predating weekSchedule) falls back to the
                    // old "finalized = active" behavior rather than losing
                    // the active-week styling entirely.
                    final latestFinalizedWeekSchedule = weekSchedule
                        .where((w) => w.week == latestFinalizedWeek)
                        .toList();
                    final latestFinalizedWeekStarted =
                        latestFinalizedWeekSchedule.isEmpty ||
                        latestFinalizedWeekSchedule.first.startDate == null ||
                        !latestFinalizedWeekSchedule.first.startDate!.isAfter(
                          DateTime.now(),
                        );
                    final effectiveCurrentWeek = latestFinalizedWeekStarted
                        ? latestFinalizedWeek
                        : 0;
                    final cardState = _weekCardState(
                      weekNum,
                      tier,
                      generatedWeeks,
                      finalizedWeeks,
                      weekSchedule,
                    );

                    // ── LOCKED CARD (not yet eligible to generate) ────
                    if (!isFinalized && cardState == _WeekCardState.locked) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => showAppToast(
                            Get.overlayContext!,
                            message: _lockedExplanation(
                              weekNum,
                              tier,
                              finalizedWeeks,
                              weekSchedule,
                            ),
                            type: AppToastType.warning,
                          ),
                          child: Container(
                            width: 120,
                            height: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xffF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xffE5E7EB),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  color: Color(0xff9DA4AE),
                                  size: 22,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Week $displayWeekNum',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff6C737F),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Locked',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xff9DA4AE),
                                  ),
                                ),
                                if (thisWeekDateRange != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    thisWeekDateRange,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Color(0xffB0B7C0),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // ── FILLED CARD ────────────────────────────────────
                    // Same centered icon-badge template every other week
                    // card (eligible/generated/locked, below) uses - a
                    // finalized week is just that same template with a food
                    // icon (it has real content, not a "+") and its actual
                    // Cal/day in primary color standing in for the generic
                    // "Generate plan"/"Pick meals" subtitle.
                    if (isFinalized) {
                      final colors = controller.getColor(
                        weekNum,
                        effectiveCurrentWeek,
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
                            decoration: BoxDecoration(
                              color: colors['bg'],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors['border']!,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xffFCE7F6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_menu,
                                    color: Color(0xff851653),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Week $displayWeekNum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors['text'],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${data!.totalCalories} Cal/day',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors['text'],
                                  ),
                                ),
                                if (thisWeekDateRange != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    thisWeekDateRange,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: colors['text'],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // ── GENERATED-NOT-FINALIZED / ELIGIBLE CARD ───────
                    // Generated: AI content already exists for this week -
                    // reuse the existing "pick meals" flow (same as today's
                    // behavior, from back when every week was always
                    // generated together up front). Eligible: nothing
                    // generated yet, but tier rules allow generating it now
                    // - opens the new generate flow scoped to this week
                    // (or, for Golden's weeks 3-4, both together).
                    final isEligible = cardState == _WeekCardState.eligible;
                    // Nothing here is finalized yet - whether it's eligible
                    // to generate now or already has a draft picked, the
                    // patient hasn't started this week, so it always reads
                    // as "future" (pink, no border) until it's finalized and
                    // takes over the "active" slot above.
                    final colors = controller.getColor(weekNum, 0);
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => _openWeightDialogForWeek(
                          context,
                          weekNum,
                          status,
                          basic,
                          weeksToGenerate: isEligible
                              ? _weeksToGenerateFor(weekNum, tier)
                              : null,
                        ),
                        child: Container(
                          width: 120,
                          height: 130,
                          decoration: BoxDecoration(
                            color: colors['bg'],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors['border']!,
                              width: 1.5,
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
                                child: Icon(
                                  isEligible
                                      ? Icons.add_rounded
                                      : Icons.restaurant_menu,
                                  color: const Color(0xff851653),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Week $displayWeekNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors['text'],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEligible ? 'Generate plan' : 'Pick meals',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors['text'],
                                ),
                              ),
                              if (thisWeekDateRange != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  thisWeekDateRange,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: colors['text'],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Send Payment Request button — shown when diet plan exists but
          // payment not yet requested, or when the patient was activated
          // with an outstanding balance still owed (PartiallyPaid).
          if ((status.requestStatus == 'Unpaid' ||
                  status.requestStatus == 'PartiallyPaid') &&
              status.activeDietPlanId != null &&
              controller.hasFinalizedWeeks)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 18),
              child: CustomButton(
                onTap: () async {
                  final requestId = status.requestId ?? '';
                  if (requestId.isEmpty) {
                    showAppToast(
                      Get.overlayContext!,
                      message: 'No request found',
                      type: AppToastType.error,
                    );
                    return;
                  }
                  await controller.sendPaymentRequest(
                    widget.patientId,
                    requestId,
                  );
                  await controller.getPatientProfile(widget.patientId);
                },
                text: status.requestStatus == 'PartiallyPaid'
                    ? 'Send Payment Request (Balance Due)'
                    : 'Send Payment Request',
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
                                  // Always false now: every renewal produces
                                  // a real new DietPlan/cycleNumber (see
                                  // createAndGenerateDietPlan), so there's no
                                  // longer a valid "just settle the bill,
                                  // don't touch the plan" case for a
                                  // membership renewal - every activation
                                  // goes through the full activateDietPlan
                                  // flow below. confirmRenewalPayment is left
                                  // in place (unreachable from here) in case
                                  // it's needed for some other balance-only
                                  // payment scenario.
                                  isRenewal: false,
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
              child: Obx(
                () => CustomButton(
                  isLoading: controller.isConsultationTemplateLoading.value,
                  onTap: () async {
                    controller.report.value = '';
                    // Must happen before clearCustomAnswers()/
                    // fetchConsultationTemplate() below - see
                    // prepareConsultationDraft's doc comment for why.
                    controller.stopConsultationDraftAutosave();
                    controller.clearCustomAnswers();

                    // Must be awaited before the sheet opens - the template
                    // starts empty, and QuestionsView shows a "not configured"
                    // placeholder while consultationTemplate is empty. Opening
                    // the sheet before the fetch resolves briefly flashed that
                    // placeholder before the real questionnaire appeared.
                    await controller.fetchConsultationTemplate();
                    await controller.prepareConsultationDraft(
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
                                    showAppToast(
                                      Get.overlayContext!,
                                      message: 'Please write a note',
                                      type: AppToastType.warning,
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
                                    showAppToast(
                                      Get.overlayContext!,
                                      message: 'Note sent to patient',
                                      type: AppToastType.success,
                                    );
                                  } else {
                                    showAppToast(
                                      Get.overlayContext!,
                                      message: 'Failed to send note',
                                      type: AppToastType.error,
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
                                    showAppToast(
                                      Get.overlayContext!,
                                      message:
                                          'Please select at least one image',
                                      type: AppToastType.warning,
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

  // Only surface Payment Information once a request has actually gone out -
  // 'Unpaid'/null means the dietician hasn't sent one yet, so there's
  // nothing to report on.
  bool _paymentInfoVisible(Status status) {
    final s = status.requestStatus;
    return s != null && s != 'Unpaid';
  }

  // Ground truth for "fully paid" vs. "partially paid" is the actual
  // received/pending amounts, not just the resting requestStatus label -
  // that label is set once at activation time and can go stale if amounts
  // are corrected afterward, while amountPending is always the current
  // truth. Only falls back to the raw requestStatus for the two in-flight
  // states (request sent / proof submitted) where "paid" isn't decided yet.
  String _resolvedPaymentState(Status status) {
    final requestStatus = status.requestStatus;
    if (requestStatus == 'PaymentRequested' ||
        requestStatus == 'PaymentSubmitted') {
      return requestStatus!;
    }
    final summary = status.paymentSummary;
    if (summary != null) {
      return (summary.amountPending ?? 0) > 0 ? 'PartiallyPaid' : 'Paid';
    }
    return requestStatus ?? 'Unpaid';
  }

  // Same semantic palette as the dashboard's patient-request badge
  // (patient_request_container.dart) - kept identical so "Fully Paid" /
  // "Partially Paid" / etc. mean the same color everywhere in the app.
  Widget _paymentStatusChip(String? status) {
    late final String label;
    late final Color bg;
    late final Color border;
    late final Color text;
    switch (status) {
      case 'Paid':
        label = 'FULLY PAID';
        bg = const Color(0xffD1FAE5);
        border = const Color(0xff10B981);
        text = const Color(0xff059669);
        break;
      case 'PartiallyPaid':
        label = 'PARTIALLY PAID';
        bg = const Color(0xffFFEDD5);
        border = const Color(0xffFB923C);
        text = const Color(0xffC2410C);
        break;
      case 'PaymentSubmitted':
        label = 'UNDER REVIEW';
        bg = const Color(0xffFEF3C7);
        border = const Color(0xffF59E0B);
        text = const Color(0xffD97706);
        break;
      case 'PaymentRequested':
      default:
        label = 'AWAITING PAYMENT';
        bg = const Color(0xffFDF2FA);
        border = const Color(0xffFCE7F6);
        text = const Color(0xffEF45B2);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1.2),
      ),
      child: CustomText(
        text: label,
        fontWeight: FontWeight.w600,
        fontSize: 10.5,
        color: text,
      ),
    );
  }

  Widget _paymentInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: Color(0xff6C737F),
        ),
        CustomText(
          text: value,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
          color: valueColor ?? Color(0xff1F2A37),
        ),
      ],
    );
  }

  // Decides Fully Paid vs. Partially Paid (and the two earlier workflow
  // states) purely from requestStatus/paymentSummary already on Status -
  // both are already resolved server-side (see backend activateDietPlan),
  // so this is just presentation, not a new decision.
  Widget _paymentInfoBody(Status status) {
    final summary = status.paymentSummary;
    final rows = <Widget>[];

    if (status.membershipPlan != null && status.membershipPlan!.isNotEmpty) {
      rows.add(_paymentInfoRow('Plan', status.membershipPlan!));
    }

    if (summary != null) {
      if ((summary.originalAmount ?? 0) > 0) {
        rows.add(
          _paymentInfoRow(
            'Subscription Amount',
            '₹${_money(summary.originalAmount)}',
          ),
        );
      }
      if (summary.couponCode != null && summary.couponCode!.isNotEmpty) {
        rows.add(
          _paymentInfoRow(
            'Coupon Applied',
            summary.couponCode!,
            valueColor: const Color(0xff851653),
            isBold: true,
          ),
        );
      }
      if ((summary.discountPercentage ?? 0) > 0) {
        rows.add(
          _paymentInfoRow(
            'Discount (${summary.discountPercentage!.toInt()}%)',
            '-₹${_money((summary.originalAmount ?? 0) * summary.discountPercentage! / 100)}',
            valueColor: const Color(0xff16A34A),
          ),
        );
      }
      rows.add(
        _paymentInfoRow(
          'Amount Received',
          '₹${_money(summary.amountReceived)}',
          valueColor: const Color(0xff059669),
        ),
      );
      if ((summary.amountPending ?? 0) > 0) {
        rows.add(
          _paymentInfoRow(
            'Amount Pending',
            '₹${_money(summary.amountPending)}',
            valueColor: const Color(0xffC2410C),
          ),
        );
        if (summary.pendingPaymentDate != null) {
          rows.add(
            _paymentInfoRow(
              'Promised By',
              DateFormat('dd MMM yyyy').format(summary.pendingPaymentDate!),
              valueColor: const Color(0xffC2410C),
              isBold: true,
            ),
          );
        }
      }
      if ((summary.totalAmount ?? 0) > 0) {
        rows.add(
          _paymentInfoRow(
            'Total Amount',
            '₹${_money(summary.totalAmount)}',
            isBold: true,
          ),
        );
      }
      if (summary.balanceClearedAt != null) {
        rows.add(
          _paymentInfoRow(
            'Balance Paid On',
            DateFormat('dd MMM yyyy').format(summary.balanceClearedAt!),
            valueColor: const Color(0xff059669),
            isBold: true,
          ),
        );
      }
    }

    String note;
    switch (_resolvedPaymentState(status)) {
      case 'PaymentRequested':
        note =
            'Payment request sent. Waiting for the patient to submit proof of payment.';
        break;
      case 'PaymentSubmitted':
        note =
            'The patient submitted a payment update - review it below to confirm or activate.';
        break;
      case 'PartiallyPaid':
        note = 'Plan activated with an outstanding balance still owed.';
        break;
      case 'Paid':
        note = 'Payment received in full.';
        break;
      default:
        note = '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffFDF2FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rows.isEmpty)
            CustomText(
              text: note,
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: Color(0xff6C737F),
              height: 1.4,
            )
          else ...[
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              rows[i],
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(color: Color(0xffFCCEEF), height: 1),
              const SizedBox(height: 10),
              CustomText(
                text: note,
                fontWeight: FontWeight.w400,
                fontSize: 12.5,
                color: Color(0xff6C737F),
                height: 1.4,
              ),
            ],
          ],
        ],
      ),
    );
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
