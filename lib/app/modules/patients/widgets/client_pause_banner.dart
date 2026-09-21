import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shown in place of a client's logged-data/diet content for a date that
/// falls inside one of their subscription pause windows (see
/// PatientsController.clientLogSelectedDatePauseWindow) - the day's numbers
/// would otherwise read as zero/broken, and the dietician set this pause
/// deliberately, so it should look intentional rather than empty.
class ClientPauseBanner extends StatelessWidget {
  final DateTime startDate;
  final DateTime resumeDate;

  const ClientPauseBanner({
    super.key,
    required this.startDate,
    required this.resumeDate,
  });

  /// True once [resumeDate] itself is on/before today - this window has
  /// already fully resumed (the dietician browsed back onto a date inside a
  /// pause that's since ended), so the copy switches to past tense instead
  /// of describing it as still running/upcoming.
  bool get _isExpired {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final resume = DateTime(resumeDate.year, resumeDate.month, resumeDate.day);
    return !resume.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final expired = _isExpired;
    final startLabel = DateFormat('d MMM yyyy').format(startDate);
    final resumeLabel = DateFormat('d MMM yyyy').format(resumeDate);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          const Icon(
            Icons.pause_circle_outline,
            size: 72,
            color: Color(0xff851653),
          ),
          const SizedBox(height: 20),
          CustomText(
            text: expired ? "Client's plan was paused" : "Client's plan is paused",
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xff851653),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xffFEF6FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffFCE7F6)),
            ),
            child: CustomText(
              text: expired
                  ? '$startLabel – $resumeLabel  ·  resumed $resumeLabel'
                  : '$startLabel – $resumeLabel  ·  resumes $resumeLabel',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xff851653),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          CustomText(
            text: expired
                ? 'No logging happened on this day - the plan was paused. It picked up right where it left off once resumed.'
                : 'Logging is disabled for this day. The plan will pick up right where it left off once it resumes.',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xff4D5761),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
