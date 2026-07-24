import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/performance/models/consultation_form_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/app_toast.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuestionsView extends StatelessWidget {
  final String gendar;
  final String patientId;
  final ScrollController scrollController;
  final bool isDisable;
  final bool isEditMode;
  QuestionsView({
    super.key,
    required this.scrollController,
    required this.gendar,
    required this.patientId,
    required this.isDisable,
    this.isEditMode = false,
  });
  final PatientsController controller = Get.find<PatientsController>();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          // Header (drag handle + back button + title) is fixed above the
          // scrollable body rather than living inside the ListView, so it
          // stays visible while the form content scrolls underneath it.
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(height: 16),
              Center(
                child: Container(
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Color(0xff79747E),
                  ),
                ),
              ),
              SizedBox(height: 15),

              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                  ),
                  CustomText(
                    text: isEditMode ? 'Edit Consultation' : 'First Consultation',
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    color: Color(0xff1F2A37),
                  ),
                  // Dev-only "magic fill" button: auto-generates mock answers
                  // via Groq for fast manual testing. Never built into a
                  // release binary regardless of what's tapped.
                  if (!kReleaseMode && !isDisable) ...[
                    Spacer(),
                    Obx(
                      () => IconButton(
                        tooltip: 'Dev only: fill with AI mock data',
                        onPressed: controller.isMockFillLoading.value
                            ? null
                            : () async {
                                try {
                                  await controller.fillConsultationWithMockData(
                                    gendar,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    showAppToast(
                                      context,
                                      message: 'Mock fill failed: $e',
                                      type: AppToastType.error,
                                    );
                                  }
                                }
                              },
                        icon: controller.isMockFillLoading.value
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xff851653),
                                ),
                              )
                            : Icon(
                                Icons.auto_fix_high,
                                color: Color(0xff851653),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
              Divider(color: Color(0xff9DA4AE)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
              // ── Consultation form - driven by the dietician's own template
              // (Performance > Customize Consultation), pre-populated by
              // default with the DocWellness standard questionnaire the
              // first time a dietician opens this screen. Reactive on
              // customAnswerValues too, so conditional follow-up fields
              // (dependsOnFieldId) appear/disappear live as answers change.
              Obx(() {
                // ignore: unused_local_variable
                final _ = controller.customAnswerValues.length;
                if (controller.consultationTemplate.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 40,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: Color(0xff851653),
                        ),
                        SizedBox(height: 12),
                        CustomText(
                          text: 'No consultation questions configured yet',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xff1F2A37),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6),
                        CustomText(
                          text:
                              'Set up questions from Performance > Customize Consultation before starting a consultation.',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Color(0xff6C737F),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final visible = controller.consultationTemplate
                    .where((f) => controller.isFieldVisible(f, gendar))
                    .toList();

                final children = <Widget>[];
                String? lastSection;
                for (final f in visible) {
                  if (f.section.isNotEmpty && f.section != lastSection) {
                    children.add(_buildSectionHeader(f));
                    lastSection = f.section;
                  } else if (f.section.isEmpty) {
                    lastSection = null;
                  }
                  children.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCustomFieldCard(f),
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.only(
                    top: 16,
                    left: horizontalPadding,
                    right: horizontalPadding,
                  ),
                  child: Column(children: children),
                );
              }),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 35,
                ),
                child: Obx(
                  () => CustomButton(
                    isLoading: controller.isConsultationSending.value,
                    onTap: isDisable == true
                        ? () {}
                        : () async {
                            await controller.sendConsultation(
                              patientId,
                              gendar == 'Male' ? false : true,
                            );
                          },
                    text: isEditMode
                        ? 'Update Consultation'
                        : 'Save Consultation',
                    isOutline: false,
                    fontSize: 14,
                  ),
                ),
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ConsultationFormField field) {
    final suffix = field.genderScope == 'female'
        ? ' (Female clients only)'
        : field.genderScope == 'male'
        ? ' (Male clients only)'
        : '';
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${field.section}$suffix',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xff851653),
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Color(0xffFAA7E0), height: 1),
        ],
      ),
    );
  }

  // ── Dynamic field renderer for the dietician's custom consultation form ──
  Widget _buildCustomFieldCard(ConsultationFormField field) {
    const accent = Color(0xff851653);
    const bg = Color(0xffFEF6FB);
    const border = Color(0xffFAA7E0);
    const labelColor = Color(0xff1F2A37);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
              if (field.required)
                const Text(
                  ' *',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          if (_isConsentField(field.fieldId)) ...[
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.lock_outline, size: 13, color: Color(0xff9DA4AE)),
                SizedBox(width: 4),
                Text(
                  'Completed by the patient - not editable here',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xff9DA4AE),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _buildCustomFieldInput(field),
        ],
      ),
    );
  }

  // Consent & Confidentiality is filled in by the patient, not the
  // dietician - locked here regardless of isDisable, and resaving the form
  // clears any prior consent server-side (see firstConsultationController.js)
  // since the patient must re-review whatever changed.
  bool _isConsentField(String fieldId) =>
      fieldId == 'consent_acknowledgement' || fieldId == 'consent_signature_name';

  bool _fieldDisabled(ConsultationFormField field) =>
      isDisable || _isConsentField(field.fieldId);

  Widget _buildCustomFieldInput(ConsultationFormField field) {
    switch (field.type) {
      case ConsultationFieldType.text:
        return _customTextInput(field, maxLines: 1);
      case ConsultationFieldType.textarea:
        return _customTextInput(field, maxLines: 4);
      case ConsultationFieldType.number:
        return _customTextInput(
          field,
          maxLines: 1,
          keyboardType: TextInputType.number,
        );
      case ConsultationFieldType.date:
        return _customDateInput(field);
      case ConsultationFieldType.yesNo:
        return _customSingleChoice(field, const ['Yes', 'No']);
      case ConsultationFieldType.singleChoice:
        return _customSingleChoice(field, field.options);
      case ConsultationFieldType.multiChoice:
        return _customMultiChoice(field, field.options);
      case ConsultationFieldType.file:
        return _customFileInput(field);
    }
  }

  Widget _customFileInput(ConsultationFormField field) {
    return Obx(() {
      final picked = controller.pickedReport.value;
      final existing = controller.report.value;
      final label = picked != null
          ? picked.name
          : (existing.isNotEmpty ? 'Existing file on record' : 'No file selected');
      return Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xff1F2A37)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isDisable ? null : () => controller.pickReport(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff851653),
              side: const BorderSide(color: Color(0xff851653)),
            ),
            child: Text(picked != null || existing.isNotEmpty ? 'Replace' : 'Upload'),
          ),
        ],
      );
    });
  }

  Widget _customTextInput(
    ConsultationFormField field, {
    required int maxLines,
    TextInputType? keyboardType,
  }) {
    final ctrl = controller.customTextControllerFor(field.fieldId);
    final disabled = _fieldDisabled(field);
    return TextField(
      controller: ctrl,
      enabled: !disabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: disabled ? null : (v) => controller.setCustomAnswer(field.fieldId, v),
      decoration: InputDecoration(
        hintText: 'Type your answer...',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        hintStyle: const TextStyle(color: Color(0xff9DA4AE), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffFAA7E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffFAA7E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xff851653)),
        ),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xff1F2A37)),
    );
  }

  Widget _customDateInput(ConsultationFormField field) {
    final ctrl = controller.customTextControllerFor(field.fieldId);
    return Builder(
      builder: (context) => TextField(
        controller: ctrl,
        readOnly: true,
        enabled: !isDisable,
        onTap: isDisable
            ? null
            : () async {
                final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  final text =
                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  ctrl.text = text;
                  controller.setCustomAnswer(field.fieldId, text);
                }
              },
        decoration: InputDecoration(
          hintText: 'Pick a date',
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.event, color: Color(0xff851653)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          hintStyle: const TextStyle(color: Color(0xff9DA4AE), fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffFAA7E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffFAA7E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xff851653)),
          ),
        ),
        style: const TextStyle(fontSize: 13, color: Color(0xff1F2A37)),
      ),
    );
  }

  /// Single choice → renders as RADIO buttons.
  Widget _customSingleChoice(
    ConsultationFormField field,
    List<String> options,
  ) {
    final disabled = _fieldDisabled(field);
    return Obx(() {
      final selected = (controller.customAnswerValues[field.fieldId] ?? '')
          .toString();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map((opt) {
          return InkWell(
            onTap: disabled
                ? null
                : () => controller.setCustomAnswer(field.fieldId, opt),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Radio<String>(
                    value: opt,
                    groupValue: selected,
                    activeColor: const Color(0xff851653),
                    onChanged: disabled
                        ? null
                        : (v) => controller.setCustomAnswer(
                            field.fieldId,
                            v ?? '',
                          ),
                  ),
                  Expanded(
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff1F2A37),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  /// Multiple choice → renders as CHECK BOXES.
  Widget _customMultiChoice(ConsultationFormField field, List<String> options) {
    final disabled = _fieldDisabled(field);
    return Obx(() {
      final raw = controller.customAnswerValues[field.fieldId];
      final selected = raw is List
          ? List<String>.from(raw.map((e) => e.toString()))
          : <String>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map((opt) {
          final isChecked = selected.contains(opt);
          return InkWell(
            onTap: disabled
                ? null
                : () => controller.toggleMultiChoiceAnswer(field.fieldId, opt),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: const Color(0xff851653),
                    onChanged: disabled
                        ? null
                        : (_) => controller.toggleMultiChoiceAnswer(
                            field.fieldId,
                            opt,
                          ),
                  ),
                  Expanded(
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff1F2A37),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

// model
class DietOption {
  String name;
  RxBool isSelected;

  DietOption({required this.name, required bool selected})
    : isSelected = RxBool(selected);
}

class CustomDoctorQuestion {
  final TextEditingController questionController;
  final TextEditingController answerController;

  CustomDoctorQuestion({String question = '', String answer = ''})
    : questionController = TextEditingController(text: question),
      answerController = TextEditingController(text: answer);

  void dispose() {
    questionController.dispose();
    answerController.dispose();
  }
}
