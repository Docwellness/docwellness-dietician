/// Where a diet plan may start, as the backend reports it for the payment
/// review (GET .../diet-plans/:id/start-date-options). Days are `yyyy-MM-dd`
/// calendar days; the server owns "today" and the running plan's end, so the
/// app never recomputes them.
class StartDateOptions {
  /// False for a plan that already has its dates: no start-date row is shown.
  final bool required;
  final String? defaultDate;
  final String? minDate;
  final bool isRenewal;
  final String? runningCycleEndDate;

  const StartDateOptions({
    required this.required,
    this.defaultDate,
    this.minDate,
    this.isRenewal = false,
    this.runningCycleEndDate,
  });

  /// No start date to pick (an old-flow plan, or a backend without the endpoint).
  static const notRequired = StartDateOptions(required: false);

  factory StartDateOptions.fromJson(Map<String, dynamic> json) {
    return StartDateOptions(
      required: json['required'] == true,
      defaultDate: json['defaultDate']?.toString(),
      minDate: json['minDate']?.toString(),
      isRenewal: json['isRenewal'] == true,
      runningCycleEndDate: json['runningCycleEndDate']?.toString(),
    );
  }

  /// Reads the options response. A 404 means a backend without the endpoint
  /// (old flow): [notRequired]. Any other failure is null so the caller can
  /// show an error instead of guessing a date.
  static StartDateOptions? fromResponse(int? statusCode, dynamic body) {
    if (statusCode == 404) return notRequired;
    if (statusCode != 200 || body is! Map || body['success'] != true) {
      return null;
    }
    final data = body['data'];
    if (data is! Map) return null;
    return StartDateOptions.fromJson(Map<String, dynamic>.from(data));
  }

  DateTime? get defaultDay => parseStartDay(defaultDate);
  DateTime? get minDay => parseStartDay(minDate);
  DateTime? get runningCycleEndDay => parseStartDay(runningCycleEndDate);
}

/// `yyyy-MM-dd` for the API: a calendar day, never an ISO timestamp, so the
/// device time zone cannot move the start by a day.
String formatStartDay(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-$month-$date';
}

/// A `yyyy-MM-dd` day as a local-midnight [DateTime], or null when malformed.
DateTime? parseStartDay(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// The activate request body. [startDay] is sent only when the plan needs one.
Map<String, dynamic> buildActivateBody({
  String? proofId,
  double? amountReceived,
  double? amountPending,
  DateTime? startDay,
}) {
  return {
    if (proofId != null && proofId.isNotEmpty) 'proofId': proofId,
    if (amountReceived != null) 'amountReceived': amountReceived,
    if (amountPending != null) 'amountPending': amountPending,
    if (startDay != null) 'startDate': formatStartDay(startDay),
  };
}
