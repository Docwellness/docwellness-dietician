import 'package:docwellnesdoc/app/models/patient_profile_model.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

const _accent = Color(0xff851653);
const _title = Color(0xff1F2A37);
const _muted = Color(0xff6C737F);

/// Pause / resume a patient's subscription. When there's no pause the sheet
/// collects a start + resume date; when a pause is scheduled or running it
/// shows the window and lets the dietician move the resume date, resume
/// immediately, or cancel the pause entirely.
class SubscriptionPauseSheet extends StatefulWidget {
  final String patientId;
  final ScrollController? scrollController;

  const SubscriptionPauseSheet({
    super.key,
    required this.patientId,
    this.scrollController,
  });

  @override
  State<SubscriptionPauseSheet> createState() => _SubscriptionPauseSheetState();
}

class _SubscriptionPauseSheetState extends State<SubscriptionPauseSheet> {
  final PatientsController controller = Get.find<PatientsController>();

  DateTime? _startDate;
  DateTime? _resumeDate;
  bool _busy = false;

  final _fmt = DateFormat('EEE, d MMM yyyy');
  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  SubscriptionPause? get _pause => controller.subscriptionPause;
  bool get _hasPause => _pause?.hasActivePause == true;

  @override
  void initState() {
    super.initState();
    final p = _pause;
    if (p?.hasActivePause == true) {
      _startDate = p!.startDate;
      _resumeDate = p.resumeDate;
    }
  }

  Future<DateTime?> _pickDate({
    required DateTime initial,
    required DateTime first,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(_today.year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _accent),
        ),
        child: child!,
      ),
    );
  }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Get.back();
      showAppToast(
        Get.overlayContext ?? context,
        message: 'Subscription pause updated',
        type: AppToastType.success,
      );
    } else {
      // Sheet is still on screen -> its own context has a live Overlay
      // (Get.overlayContext is unreliable mid-navigation).
      showAppToast(context, message: error, type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Rebuild when the profile refetches after an action.
      controller.patientProfileModel.value;
      return SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, color: _title),
                ),
                CustomText(
                  text: _hasPause ? 'Manage pause' : 'Pause subscription',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: _title,
                ),
              ],
            ),
            const Divider(color: Color(0xff9DA4AE)),
            const SizedBox(height: 12),
            CustomText(
              text: _hasPause
                  ? 'While paused, the patient can’t log meals, water or exercise and their Diet & Exercise tab is locked. When it resumes, every plan day shifts forward by the pause length — nothing is skipped. The subscription end date moves out too.'
                  : 'Pause the plan for a date range — the patient can’t log anything and their tab locks until it resumes. Plan content and the subscription end date shift forward by the pause length so nothing is lost.',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: const Color(0xff4D5761),
            ),
            const SizedBox(height: 20),
            if (_hasPause) ..._manageBody() else ..._scheduleBody(),
          ],
        ),
      );
    });
  }

  // ---- No pause yet: pick start + resume ----
  List<Widget> _scheduleBody() {
    final canSubmit = _startDate != null &&
        _resumeDate != null &&
        _resumeDate!.isAfter(_startDate!) &&
        !_busy;
    return [
      _dateRow(
        label: 'Pause starts',
        value: _startDate,
        onTap: () async {
          final d = await _pickDate(
            initial: _startDate ?? _today,
            first: _today,
          );
          if (d != null) {
            setState(() {
              _startDate = d;
              if (_resumeDate != null && !_resumeDate!.isAfter(d)) {
                _resumeDate = null;
              }
            });
          }
        },
      ),
      const SizedBox(height: 12),
      _dateRow(
        label: 'Resumes on',
        value: _resumeDate,
        enabled: _startDate != null,
        onTap: () async {
          final base = _startDate!.add(const Duration(days: 1));
          final d = await _pickDate(
            initial: _resumeDate ?? base,
            first: base,
          );
          if (d != null) setState(() => _resumeDate = d);
        },
      ),
      if (_startDate != null && _resumeDate != null) ...[
        const SizedBox(height: 12),
        _lengthNote(_startDate!, _resumeDate!),
      ],
      const SizedBox(height: 24),
      CustomButton(
        onTap: () => _run(() => controller.submitSubscriptionPause(
              widget.patientId,
              op: 'pause',
              startDate: _startDate,
              resumeDate: _resumeDate,
            )),
        text: 'Pause subscription',
        isOutline: false,
        buttonColor: _accent,
        fontSize: 15,
        isLoading: _busy,
        isDisabled: !canSubmit,
      ),
    ];
  }

  // ---- Pause scheduled / running: change / resume now / cancel ----
  List<Widget> _manageBody() {
    final p = _pause!;
    final running = p.isPausedNow;
    final canSave = _resumeDate != null &&
        _startDate != null &&
        _resumeDate!.isAfter(_startDate!) &&
        _resumeDate!.isAfter(_today) &&
        _resumeDate != p.resumeDate &&
        !_busy;
    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffFAA7E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: running ? 'Paused now' : 'Pause scheduled',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _accent,
            ),
            const SizedBox(height: 4),
            CustomText(
              text:
                  '${_fmt.format(p.startDate!)}  →  ${_fmt.format(p.resumeDate!)}',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: _title,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _dateRow(
        label: 'Change resume date',
        value: _resumeDate,
        onTap: () async {
          final first = _today.add(const Duration(days: 1));
          final d = await _pickDate(initial: _resumeDate ?? first, first: first);
          if (d != null) setState(() => _resumeDate = d);
        },
      ),
      const SizedBox(height: 16),
      CustomButton(
        onTap: () => _run(() => controller.submitSubscriptionPause(
              widget.patientId,
              op: 'update',
              startDate: running ? null : _startDate,
              resumeDate: _resumeDate,
            )),
        text: 'Save new resume date',
        isOutline: false,
        buttonColor: _accent,
        fontSize: 15,
        isDisabled: !canSave,
      ),
      const SizedBox(height: 10),
      CustomButton(
        onTap: () => _run(() => controller.submitSubscriptionPause(
              widget.patientId,
              op: 'update',
              startDate: running ? null : _startDate,
              resumeDate: _today.add(const Duration(days: 1)),
            )),
        text: 'Resume tomorrow',
        isOutline: true,
        outlineButtonColor: _accent,
        textColor: _accent,
        fontSize: 15,
        isDisabled: _busy,
      ),
      const SizedBox(height: 10),
      CustomButton(
        onTap: () => _run(() => controller.submitSubscriptionPause(
              widget.patientId,
              op: 'cancel',
            )),
        text: 'Cancel pause',
        isOutline: true,
        outlineButtonColor: const Color(0xffB42318),
        textColor: const Color(0xffB42318),
        fontSize: 15,
        isDisabled: _busy,
      ),
    ];
  }

  Widget _dateRow({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xffFAA7E0) : const Color(0xffE5E7EB),
          ),
        ),
        child: Row(
          children: [
            CustomText(
              text: label,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: enabled ? _title : _muted,
            ),
            const Spacer(),
            CustomText(
              text: value != null ? _fmt.format(value) : 'Select',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: value != null ? _accent : _muted,
            ),
            const SizedBox(width: 6),
            Icon(Icons.calendar_today_outlined,
                size: 18, color: enabled ? _accent : _muted),
          ],
        ),
      ),
    );
  }

  Widget _lengthNote(DateTime start, DateTime resume) {
    final days = resume.difference(start).inDays;
    return CustomText(
      text:
          'Plan paused for $days day${days == 1 ? '' : 's'}. Everything after ${_fmt.format(start)} shifts $days day${days == 1 ? '' : 's'} forward.',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      color: _muted,
    );
  }
}
