import 'package:docwellnesdoc/app/models/start_date_options_model.dart';
import 'package:get/get.dart';

/// The payment review's "Diet starts on" state, held by PatientsController:
/// the server's options, the day the dietician picked, and whether the
/// options are loading or failed. Confirming is blocked until the options
/// are known, so the app never falls back to a date it computed itself.
class StartDateOptionsState {
  StartDateOptionsState({required this.fetch});

  /// Loads the options; null means the call failed.
  final Future<StartDateOptions?> Function(String patientId, String dietPlanId)
  fetch;

  final Rxn<StartDateOptions> options = Rxn<StartDateOptions>();
  final RxBool loading = false.obs;
  final RxBool error = false.obs;
  final Rxn<DateTime> picked = Rxn<DateTime>();

  /// True once the options loaded and this plan needs a start day.
  bool get required => options.value?.required ?? false;

  /// The day that will be sent: the pick, else the server's default.
  DateTime? get selectedDay => picked.value ?? options.value?.defaultDay;

  /// Confirm must wait: the options are loading, failed, or never requested.
  bool get blocksConfirm =>
      loading.value || error.value || options.value == null;

  Future<void> load(String patientId, String dietPlanId) async {
    loading.value = true;
    error.value = false;
    picked.value = null;
    options.value = null;
    try {
      final result = await fetch(patientId, dietPlanId);
      if (result == null) {
        error.value = true;
      } else {
        options.value = result;
      }
    } catch (_) {
      error.value = true;
    } finally {
      loading.value = false;
    }
  }

  /// After a refused approval: when the server rejected the start day
  /// (code START_DATE_*), reload the options so the picker shows the days it
  /// now allows. Returns whether a reload happened.
  Future<bool> refreshIfStartDateRejected(
    String patientId,
    String dietPlanId,
    dynamic response,
  ) async {
    final code = response is Map ? response['code']?.toString() : null;
    if (code == null || !code.startsWith('START_DATE_')) return false;
    await load(patientId, dietPlanId);
    return true;
  }

  void pick(DateTime day) =>
      picked.value = DateTime(day.year, day.month, day.day);
}
