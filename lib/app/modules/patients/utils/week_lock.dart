/// Shown when a dietician taps a week that is locked because the plan has no
/// start date yet (it is chosen when the payment is approved). Matches the
/// backend's `week_locked_until_activation` message.
const String kWeekLockedUntilActivationMessage =
    'Weeks after Week 1 open once the payment is approved and the start date is set.';

/// Whether the plan the dietician is looking at is the one waiting for its
/// start date. The profile's pending flag follows the newest cycle, so during
/// a renewal ([hasPendingCycle]) it describes the renewal, not the running
/// plan, whose dates stay visible and editable.
bool runningPlanStartPending({
  required bool startDatePending,
  required bool hasPendingCycle,
}) => startDatePending && !hasPendingCycle;

/// Body of the "Move the diet start date?" confirmation. While a renewal waits
/// for its payment ([renewalPending]) the edit moves the running plan, so the
/// text says the renewal's own start is still chosen at payment approval.
String startDateEditConfirmText({
  required bool renewalPending,
  required String day,
}) {
  if (renewalPending) {
    return 'The running diet plan\'s week schedule and the exercise plan (if generated) will shift to start on $day. The new plan\'s start is chosen when you approve its payment.';
  }
  return 'The diet plan\'s week schedule and the exercise plan (if generated) will shift to start on $day.';
}

/// Only Week 1 can be built before the plan starts: later weeks wait on the
/// "last 2 days of the prior week" rule, which needs dated weeks.
bool weekLockedUntilActivation({
  required bool startDatePending,
  required int week,
}) => startDatePending && week > 1;
