import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/routes/app_pages.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One deletable data category. `key` is sent to the backend and MUST match
/// a key in utils/patientDataDeletion.js's PATIENT_DATA_CATEGORIES - review
/// both together when adding one. `childLabels` are pure-child collections
/// that cannot outlive this category, shown indented and locked-on while
/// the parent is checked. `accountOnly` categories can only go together
/// with the whole account.
class _DeleteCategory {
  final String key;
  final String label;
  final List<String> childLabels;
  final bool accountOnly;

  const _DeleteCategory(
    this.key,
    this.label, {
    this.childLabels = const [],
    this.accountOnly = false,
  });
}

const _sections = <String, List<_DeleteCategory>>{
  'Diet & meals': [
    _DeleteCategory(
      'dietPlan',
      'Diet plans & meal schedules',
      childLabels: ['Day plans', 'Meal slots', 'Plan items', 'Supplement items'],
    ),
    _DeleteCategory('mealLog', 'Meal logs'),
    _DeleteCategory('waterLog', 'Water logs'),
    _DeleteCategory('customFoodRequest', 'Custom food requests'),
  ],
  'Exercise': [
    _DeleteCategory('exercisePlan', 'Exercise plans'),
    _DeleteCategory('exerciseLog', 'Exercise logs'),
  ],
  'Progress': [
    _DeleteCategory('progress', 'Progress entries & body photos'),
    _DeleteCategory('journeyImage', 'Before / after journey photos'),
  ],
  'Goal journey': [
    _DeleteCategory(
      'goal',
      'Goals, milestones & check-ins',
      childLabels: ['Milestones', 'Milestone tasks', 'Check-ins'],
    ),
  ],
  'Consultation': [
    _DeleteCategory('firstConsultation', 'First consultation & lab reports'),
  ],
  'Communication': [
    _DeleteCategory('chat', 'Chat messages & conversations', childLabels: ['Conversations']),
    _DeleteCategory('notification', 'Notifications'),
  ],
  'Payments': [
    _DeleteCategory('manualPaymentProof', 'Payment proofs'),
    _DeleteCategory(
      'dietPlanRequest',
      'Membership / subscription record',
      accountOnly: true,
    ),
  ],
  'Dietician records': [
    _DeleteCategory('nudge', 'Nudges sent to the patient'),
    _DeleteCategory('needAttentionLog', 'Need-attention flags'),
    _DeleteCategory('review', "Patient's review of you"),
  ],
};

const _accent = Color(0xff851653);
const _danger = Color(0xffB42318);
const _titleColor = Color(0xff1F2A37);
const _sectionColor = Color(0xff384250);
const _mutedColor = Color(0xff9DA4AE);

class DeletePatientDataSheet extends StatefulWidget {
  final String patientId;
  final ScrollController? scrollController;

  const DeletePatientDataSheet({
    super.key,
    required this.patientId,
    this.scrollController,
  });

  @override
  State<DeletePatientDataSheet> createState() => _DeletePatientDataSheetState();
}

class _DeletePatientDataSheetState extends State<DeletePatientDataSheet> {
  final PatientsController controller = Get.find<PatientsController>();

  final Set<String> _selected = {};
  bool _deleteAccount = false;
  bool _isDeleting = false;

  final TextEditingController _emailController = TextEditingController();
  bool _emailMatches = false;

  static final List<_DeleteCategory> _allCategories =
      _sections.values.expand((c) => c).toList();
  static final List<String> _dataKeys = _allCategories
      .where((c) => !c.accountOnly)
      .map((c) => c.key)
      .toList();

  String get _email =>
      controller.patientProfileModel.value?.basic?.email?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      final match = _email.isNotEmpty &&
          _emailController.text.trim().toLowerCase() == _email.toLowerCase();
      if (match != _emailMatches) setState(() => _emailMatches = match);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isChecked(_DeleteCategory c) {
    if (_deleteAccount) return true;
    return _selected.contains(c.key);
  }

  void _toggle(_DeleteCategory c) {
    if (c.accountOnly) return; // only via the account master
    setState(() {
      if (_deleteAccount) {
        // Leaving "delete everything": start from all data keys, drop this one.
        _deleteAccount = false;
        _selected
          ..clear()
          ..addAll(_dataKeys)
          ..remove(c.key);
        return;
      }
      if (_selected.contains(c.key)) {
        _selected.remove(c.key);
      } else {
        _selected.add(c.key);
      }
      // Every data category ticked ⇒ this is a full account deletion.
      if (_dataKeys.every(_selected.contains)) _deleteAccount = true;
    });
  }

  void _toggleAccount(bool value) {
    setState(() {
      _deleteAccount = value;
      if (value) {
        _selected
          ..clear()
          ..addAll(_dataKeys);
      }
    });
  }

  bool get _canDelete =>
      _emailMatches && (_deleteAccount || _selected.isNotEmpty);

  Future<void> _confirm() async {
    if (!_canDelete || _isDeleting) return;
    final email = _email;
    final deleteAccount = _deleteAccount;

    // Keep this sheet mounted through the whole operation: the native
    // biometric step-up (inside deletePatientData) is safe while nothing is
    // animating, an error toast then has a live Overlay to land in, and the
    // button shows a spinner instead of looking dead. The profile screen's
    // 10s auto-refresh is paused meanwhile so a background refetch can't
    // mutate the tree under the native prompt.
    setState(() => _isDeleting = true);
    controller.suspendSilentRefresh = true;
    bool ok = false;
    try {
      ok = await controller.deletePatientData(
        widget.patientId,
        email: email,
        categories: deleteAccount ? const [] : _selected.toList(),
        deleteAccount: deleteAccount,
      );
    } finally {
      controller.suspendSilentRefresh = false;
    }
    if (!mounted) return;
    setState(() => _isDeleting = false);
    if (!ok) return; // deletePatientData already surfaced the error

    Get.back(); // dismiss this sheet
    if (deleteAccount) {
      // Leave the deleted patient's now-stale profile - back to wherever the
      // dietician came from (usually the patient list).
      if (Navigator.of(Get.context!).canPop()) {
        Get.back();
      } else {
        Get.offAllNamed(Routes.PATIENTS);
      }
    }
    showAppToast(
      Get.overlayContext!,
      message: deleteAccount
          ? '"$email" has been permanently deleted.'
          : 'Selected data has been deleted.',
      type: AppToastType.success,
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
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: _titleColor),
              ),
              const CustomText(
                text: 'Delete patient data',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: _titleColor,
              ),
            ],
          ),
        ),
        const Divider(color: _mutedColor, height: 1),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              for (final entry in _sections.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: CustomText(
                    text: entry.key,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: _sectionColor,
                  ),
                ),
                for (final category in entry.value) _categoryRow(category),
              ],
              const SizedBox(height: 8),
              const Divider(color: _mutedColor, height: 1),
              _accountRow(),
              const SizedBox(height: 16),
              _confirmSection(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: CustomButton(
              onTap: _confirm,
              text: _deleteAccount
                  ? 'Delete patient & all data'
                  : 'Delete selected data',
              isOutline: false,
              buttonColor: _danger,
              fontSize: 15,
              isLoading: _isDeleting,
              isDisabled: !_canDelete,
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryRow(_DeleteCategory category) {
    final checked = _isChecked(category);
    // Only the account-only rows are ever locked. While "delete everything"
    // is on, the data rows stay tappable so unchecking one drops back to a
    // partial selection (see _toggle).
    final locked = category.accountOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: locked ? null : () => _toggle(category),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  activeColor: _accent,
                  onChanged: locked ? null : (_) => _toggle(category),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: category.label,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: _titleColor,
                      ),
                      if (category.accountOnly)
                        const CustomText(
                          text: 'Removed only with the account',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: _mutedColor,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (category.childLabels.isNotEmpty && checked)
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final child in category.childLabels)
                  Row(
                    children: [
                      const Icon(Icons.check, size: 14, color: _mutedColor),
                      const SizedBox(width: 6),
                      CustomText(
                        text: child,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: _mutedColor,
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _accountRow() {
    return InkWell(
      onTap: () => _toggleAccount(!_deleteAccount),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: _deleteAccount,
              activeColor: _danger,
              onChanged: (v) => _toggleAccount(v ?? false),
            ),
            const Expanded(
              child: CustomText(
                text: "Also delete the patient's account & login (permanent)",
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: _danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmSection() {
    final email = _email;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: _deleteAccount
              ? 'This permanently deletes "$email" and every one of their records. This cannot be undone.'
              : 'This permanently removes the selected data for "$email". This cannot be undone.',
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: const Color(0xff4D5761),
        ),
        const SizedBox(height: 12),
        CustomText(
          text: 'Type "$email" to confirm:',
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: _titleColor,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: email,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
