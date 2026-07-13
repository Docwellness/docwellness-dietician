import 'package:docwellnesdoc/app/modules/performance/models/consultation_form_field.dart';
import 'package:docwellnesdoc/app/modules/performance/services/consultation_form_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Holds editable state for one field row in the builder UI.
class ConsultationFieldDraft {
  String fieldId;
  Rx<ConsultationFieldType> type;
  TextEditingController labelController;
  RxList<TextEditingController> optionControllers;
  RxBool required;
  // Section grouping and conditional-follow-up dependencies aren't editable
  // via this builder UI, but must round-trip unchanged so seeded fields
  // don't get silently wiped the first time a dietician saves any edit here
  // - upsertMyTemplate fully replaces the fields array. genderScope IS
  // editable here (General / Female only / Male only selector).
  final String section;
  RxString genderScope;
  final String? dependsOnFieldId;
  final List<String> dependsOnValues;

  ConsultationFieldDraft({
    required this.fieldId,
    required ConsultationFieldType initialType,
    required String initialLabel,
    required List<String> initialOptions,
    required bool initialRequired,
    this.section = '',
    String initialGenderScope = 'general',
    this.dependsOnFieldId,
    this.dependsOnValues = const [],
  })  : type = initialType.obs,
        labelController = TextEditingController(text: initialLabel),
        optionControllers = (initialOptions.isEmpty
                ? <TextEditingController>[]
                : initialOptions
                    .map((o) => TextEditingController(text: o))
                    .toList())
            .obs,
        required = initialRequired.obs,
        genderScope = initialGenderScope.obs;

  factory ConsultationFieldDraft.fromField(ConsultationFormField f) {
    return ConsultationFieldDraft(
      fieldId: f.fieldId,
      initialType: f.type,
      initialLabel: f.label,
      initialOptions: f.options,
      initialRequired: f.required,
      section: f.section,
      initialGenderScope: f.genderScope,
      dependsOnFieldId: f.dependsOnFieldId,
      dependsOnValues: f.dependsOnValues,
    );
  }

  ConsultationFormField toField(int order) {
    final opts = optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return ConsultationFormField(
      fieldId: fieldId,
      type: type.value,
      label: labelController.text.trim(),
      options: type.value.hasOptions ? opts : const [],
      required: required.value,
      order: order,
      section: section,
      genderScope: genderScope.value,
      dependsOnFieldId: dependsOnFieldId,
      dependsOnValues: dependsOnValues,
    );
  }

  void dispose() {
    labelController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
  }
}

class ConsultationFormController extends GetxController {
  final ConsultationFormService _service = ConsultationFormService();

  RxList<ConsultationFieldDraft> drafts = <ConsultationFieldDraft>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTemplate();
  }

  Future<void> fetchTemplate() async {
    isLoading.value = true;
    try {
      final fields = await _service.getMyTemplate();
      _disposeAll();
      drafts.value =
          fields.map((f) => ConsultationFieldDraft.fromField(f)).toList();
    } finally {
      isLoading.value = false;
    }
  }

  void addField(ConsultationFieldType type) {
    drafts.add(
      ConsultationFieldDraft(
        fieldId: 'local-${DateTime.now().microsecondsSinceEpoch}',
        initialType: type,
        initialLabel: '',
        initialOptions: type.hasOptions ? <String>[''] : <String>[],
        initialRequired: false,
      ),
    );
  }

  void removeField(int index) {
    if (index < 0 || index >= drafts.length) return;
    drafts[index].dispose();
    drafts.removeAt(index);
  }

  void changeFieldType(int index, ConsultationFieldType newType) {
    if (index < 0 || index >= drafts.length) return;
    final d = drafts[index];
    final wasOptions = d.type.value.hasOptions;
    final nowOptions = newType.hasOptions;
    d.type.value = newType;
    if (nowOptions && !wasOptions) {
      d.optionControllers.add(TextEditingController());
    }
    if (!nowOptions && wasOptions) {
      for (final c in d.optionControllers) {
        c.dispose();
      }
      d.optionControllers.clear();
    }
  }

  void addOption(int fieldIndex) {
    if (fieldIndex < 0 || fieldIndex >= drafts.length) return;
    drafts[fieldIndex].optionControllers.add(TextEditingController());
  }

  void removeOption(int fieldIndex, int optionIndex) {
    if (fieldIndex < 0 || fieldIndex >= drafts.length) return;
    final opts = drafts[fieldIndex].optionControllers;
    if (optionIndex < 0 || optionIndex >= opts.length) return;
    opts[optionIndex].dispose();
    opts.removeAt(optionIndex);
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= drafts.length) return;
    if (newIndex > drafts.length) newIndex = drafts.length;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = drafts.removeAt(oldIndex);
    drafts.insert(newIndex, item);
  }

  /// Validate & save. Returns true on success.
  Future<bool> save() async {
    // Validate
    for (int i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      if (d.labelController.text.trim().isEmpty) {
        Get.snackbar(
          'Missing label',
          'Field #${i + 1} needs a question label.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
      if (d.type.value.hasOptions) {
        final opts = d.optionControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (opts.isEmpty) {
          Get.snackbar(
            'Missing options',
            'Field "${d.labelController.text.trim()}" needs at least one option.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      }
    }

    isSaving.value = true;
    try {
      final fields = <ConsultationFormField>[];
      for (int i = 0; i < drafts.length; i++) {
        fields.add(drafts[i].toField(i));
      }
      final ok = await _service.upsertTemplate(fields);
      if (ok) {
        Get.snackbar(
          'Saved',
          'Consultation form updated.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Could not save consultation form.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return ok;
    } finally {
      isSaving.value = false;
    }
  }

  void _disposeAll() {
    for (final d in drafts) {
      d.dispose();
    }
  }

  @override
  void onClose() {
    _disposeAll();
    super.onClose();
  }
}
