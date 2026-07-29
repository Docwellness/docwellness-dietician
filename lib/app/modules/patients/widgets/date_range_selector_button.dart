import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pill button that opens a bounded date-range picker - replaces the old
/// "This month/This year" period dropdown (TimePeriodDropdown) on the
/// patient profile's Weight, BMI, and Calorie charts, mirroring
/// docwellness-user's Progress screen. Each chart owns its own range
/// independently (see PatientsController's per-chart Range fields),
/// bounded to [firstDate, lastDate] - firstDate is the patient's diet
/// plan's real start date (no data exists before it), lastDate is today.
class DateRangeSelectorButton extends StatelessWidget {
  final DateTime selectedStart;
  final DateTime selectedEnd;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTimeRange> onRangeSelected;

  const DateRangeSelectorButton({
    super.key,
    required this.selectedStart,
    required this.selectedEnd,
    required this.firstDate,
    required this.lastDate,
    required this.onRangeSelected,
  });

  String get _label {
    final fmt = DateFormat('d MMM');
    final startText = fmt.format(selectedStart);
    final endText = fmt.format(selectedEnd);
    if (startText == endText) return startText;
    return '$startText - $endText';
  }

  Future<void> _pickRange(BuildContext context) async {
    // firstDate/lastDate can collapse to the same day (e.g. a plan that
    // started today) - showDateRangePicker requires firstDate < lastDate,
    // so widen lastDate by a day in that edge case rather than crashing.
    final effectiveLastDate = !lastDate.isAfter(firstDate)
        ? firstDate.add(const Duration(days: 1))
        : lastDate;
    final initialStart = selectedStart.isBefore(firstDate)
        ? firstDate
        : selectedStart;
    final initialEnd = selectedEnd.isAfter(effectiveLastDate)
        ? effectiveLastDate
        : selectedEnd;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: effectiveLastDate,
      initialDateRange: !initialStart.isAfter(initialEnd)
          ? DateTimeRange(start: initialStart, end: initialEnd)
          : DateTimeRange(start: firstDate, end: effectiveLastDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xff9F1561),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onRangeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickRange(context),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          border: Border.all(color: const Color(0xffE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: Color(0xff111927),
            ),
            const SizedBox(width: 6),
            CustomText(
              text: _label,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xff111927),
            ),
          ],
        ),
      ),
    );
  }
}
