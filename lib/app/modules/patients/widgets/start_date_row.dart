import 'package:docwellnesdoc/app/models/start_date_options_model.dart';
import 'package:docwellnesdoc/app/modules/diet_plan_wizard/widgets/wizard_theme.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/start_date_options_state.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Opens the date picker; [firstDate] is the server's earliest allowed day.
typedef StartDatePicker =
    Future<DateTime?> Function(
      BuildContext context, {
      required DateTime initialDate,
      required DateTime firstDate,
      required DateTime lastDate,
    });

Future<DateTime?> _showStartDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: 'Diet start date',
  );
}

/// The "Diet starts on" row of the payment review. The dietician picks the
/// day the plan begins when approving the payment; the server supplies the
/// default and the earliest allowed day. Not shown for a plan that already
/// has its dates. While the options load or failed the row says so and the
/// confirm button stays disabled (see StartDateOptionsState.blocksConfirm).
class StartDateRow extends StatefulWidget {
  final StartDateOptionsState state;
  final String patientId;
  final String dietPlanId;
  final StartDatePicker pickDate;

  const StartDateRow({
    super.key,
    required this.state,
    required this.patientId,
    required this.dietPlanId,
    this.pickDate = _showStartDatePicker,
  });

  @override
  State<StartDateRow> createState() => _StartDateRowState();
}

class _StartDateRowState extends State<StartDateRow> {
  @override
  void initState() {
    super.initState();
    // After the first frame: loading flips observables the sheet listens to.
    Future.microtask(_load);
  }

  Future<void> _load() =>
      widget.state.load(widget.patientId, widget.dietPlanId);

  Future<void> _pick(StartDateOptions options, DateTime selected) async {
    final first = options.minDay ?? selected;
    final picked = await widget.pickDate(
      context,
      initialDate: selected.isBefore(first) ? first : selected,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
    );
    if (picked != null) widget.state.pick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Obx(() {
      if (state.loading.value) {
        return _card(
          child: const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: WizardPalette.magenta,
                ),
              ),
              SizedBox(width: 10),
              CustomText(
                text: 'Loading start date…',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: WizardPalette.muted,
              ),
            ],
          ),
        );
      }
      if (state.error.value) {
        return _card(
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 20,
                color: WizardPalette.warn,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: CustomText(
                  text: 'Could not load start date.',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: WizardPalette.warn,
                ),
              ),
              TextButton(
                onPressed: _load,
                child: const CustomText(
                  text: 'Retry',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: WizardPalette.magenta,
                ),
              ),
            ],
          ),
        );
      }

      final options = state.options.value;
      final selected = state.selectedDay;
      if (options == null || !options.required || selected == null) {
        return const SizedBox.shrink();
      }

      final isDefault = selected == options.defaultDay;
      final dateText = isDefault
          ? 'Today, ${DateFormat('dd MMM yyyy').format(selected)}'
          : DateFormat('EEE, dd MMM yyyy').format(selected);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'Diet start date, $dateText, tap to change',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => _pick(options, selected),
              borderRadius: BorderRadius.circular(WizardPalette.cardRadius),
              child: _card(
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 20,
                      color: WizardPalette.plum,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomText(
                            text: 'Diet starts on',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: WizardPalette.muted,
                          ),
                          const SizedBox(height: 2),
                          CustomText(
                            text: dateText,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: WizardPalette.plum,
                          ),
                        ],
                      ),
                    ),
                    const CustomText(
                      text: 'Change',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: WizardPalette.magenta,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const CustomText(
            text:
                'Plan weeks run from this day. The patient is not told the date.',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: WizardPalette.muted,
          ),
          if (options.isRenewal && options.minDay != null)
            CustomText(
              text: _renewalHelper(options),
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: WizardPalette.muted,
            ),
        ],
      );
    });
  }

  String _renewalHelper(StartDateOptions options) {
    final earliest = DateFormat('dd MMM').format(options.minDay!);
    final end = options.runningCycleEndDay;
    return end == null
        ? 'Earliest: $earliest'
        : 'Earliest: $earliest (current plan ends ${DateFormat('dd MMM').format(end)})';
  }

  Widget _card({required Widget child}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WizardPalette.surface,
        borderRadius: BorderRadius.circular(WizardPalette.cardRadius),
        border: Border.all(color: WizardPalette.line),
      ),
      child: child,
    );
  }
}
