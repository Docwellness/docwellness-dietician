import 'package:intl/intl.dart';

/// When the payment was approved and the plan went live, from the backend's
/// ISO `activationDate`. Shown beside the start day so the dietician can see
/// both and spot a wrongly picked start. Returns null when there is no usable
/// time (plan not activated yet, or an older backend that does not send it),
/// so the caller shows nothing.
///
/// [withTime] true:  "Approved 20 Nov, 4:22 PM" (the Week 1 card).
/// [withTime] false: "Approved on 20 Nov 2026" (the Basic Information caption).
String? approvedOnLabel(String? iso, {bool withTime = true}) {
  if (iso == null || iso.trim().isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) {
    return null;
  }
  final local = parsed.toLocal();
  if (withTime) {
    return 'Approved ${DateFormat('d MMM').format(local)}, '
        '${DateFormat('h:mm a').format(local)}';
  }
  return 'Approved on ${DateFormat('d MMM yyyy').format(local)}';
}
