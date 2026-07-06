import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

/// Reusable time period selector dropdown
class TimePeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onChanged;

  const TimePeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  String get _displayText {
    switch (selectedPeriod) {
      case 'week':
        return 'This week';
      case 'month':
        return 'This month';
      case 'year':
        return 'This year';
      default:
        return 'This week';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          border: Border.all(color: Color(0xffE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/petient_calendar.png',
              height: 15.4,
              width: 14,
              color: Color(0xff111927),
              fit: BoxFit.contain,
              colorBlendMode: BlendMode.srcIn,
            ),
            SizedBox(width: 5),
            CustomText(
              text: _displayText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xff111927),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xff111927)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'week', child: Text('This week')),
        PopupMenuItem(value: 'month', child: Text('This month')),
        PopupMenuItem(value: 'year', child: Text('This year')),
      ],
    );
  }
}
