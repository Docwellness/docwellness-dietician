import 'package:flutter/material.dart';

/// Display label + tier-appropriate colors for a membership plan badge -
/// shared by every place the dietician app shows a patient's plan (patient
/// request cards, patient list cards, patient profile). Previously every
/// one of these rendered the raw backend string ("Golden Membership" etc.)
/// in the same generic gray pill regardless of tier - this gives each tier
/// its own recognizable color and drops the redundant "Membership" suffix.
class MembershipBadgeStyle {
  final String label;
  final Color background;
  final Color border;
  final Color text;

  const MembershipBadgeStyle({
    required this.label,
    required this.background,
    required this.border,
    required this.text,
  });
}

MembershipBadgeStyle membershipBadgeStyle(String? rawPlan) {
  final plan = (rawPlan ?? '').toLowerCase();

  if (plan.contains('platinum')) {
    // Cool steel-blue - reads as a tier above gold rather than a near-
    // identical gray to Silver (true platinum/silver hex values are almost
    // indistinguishable at badge size).
    return const MembershipBadgeStyle(
      label: 'Platinum',
      background: Color(0xffEFF6FF),
      border: Color(0xff60A5FA),
      text: Color(0xff1E40AF),
    );
  }
  if (plan.contains('gold')) {
    return const MembershipBadgeStyle(
      label: 'Golden',
      background: Color(0xffFEF3C7),
      border: Color(0xffD97706),
      text: Color(0xff92400E),
    );
  }
  if (plan.contains('silver')) {
    return const MembershipBadgeStyle(
      label: 'Silver',
      background: Color(0xffF3F4F6),
      border: Color(0xff9CA3AF),
      text: Color(0xff4B5563),
    );
  }

  // Unrecognized plan name (or null/empty, though callers already guard
  // that) - keep the previous generic-gray look rather than guessing.
  return MembershipBadgeStyle(
    label: rawPlan ?? '',
    background: const Color(0xffF3F4F6),
    border: const Color(0xffD1D5DB),
    text: const Color(0xff4D5761),
  );
}
