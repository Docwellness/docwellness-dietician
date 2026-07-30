import 'package:docwellnesdoc/app/modules/performance/controllers/consultation_form_controller.dart';
import 'package:docwellnesdoc/app/modules/performance/models/consultation_form_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConsultationFormBuilderView extends StatelessWidget {
  ConsultationFormBuilderView({super.key});

  final ConsultationFormController controller =
      Get.put(ConsultationFormController());

  static const _accent = Color(0xff851653);
  static const _accentSoft = Color(0xffFEF6FB);
  static const _border = Color(0xffFAA7E0);
  static const _text = Color(0xff1F2A37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xffFDF2FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _text),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: const CustomText(
          text: 'Customize Consultation',
          fontWeight: FontWeight.w400,
          fontSize: 19,
          color: _text,
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _accent),
          );
        }
        return Column(
          children: [
            Expanded(
              child: controller.drafts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: controller.drafts.length,
                      itemBuilder: (context, index) =>
                          _buildFieldCard(context, index),
                    ),
            ),
            _buildBottomBar(context),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.assignment_outlined, size: 56, color: _accent),
            SizedBox(height: 12),
            CustomText(
              text: 'No custom fields yet',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: _text,
            ),
            SizedBox(height: 6),
            CustomText(
              text:
                  'Add questions you want to ask every patient during their first consultation.',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: Color(0xff6C737F),
              maxLines: 3,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(BuildContext context, int index) {
    return Obx(() {
      final draft = controller.drafts[index];
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _accentSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_upward, color: _accent),
                  onPressed: index == 0
                      ? null
                      : () => controller.reorder(index, index - 1),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_downward, color: _accent),
                  onPressed: index == controller.drafts.length - 1
                      ? null
                      : () => controller.reorder(index, index + 2),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, color: _accent),
                  onPressed: () => controller.removeField(index),
                ),
              ],
            ),

            // Question label
            TextField(
              controller: draft.labelController,
              maxLines: null,
              style: const TextStyle(fontSize: 15, color: _text),
              decoration: InputDecoration(
                hintText: 'Enter your question...',
                hintStyle: const TextStyle(color: Color(0xff9DA4AE)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _accent),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Type chip + Required toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickType(context, index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, size: 16, color: _accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              draft.type.value.displayName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _text,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 18, color: _accent),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Required',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _text),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch.adaptive(
                          activeColor: _accent,
                          value: draft.required.value,
                          onChanged: (v) => draft.required.value = v,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Who this question applies to
            Row(
              children: [
                const Text(
                  'Visible to:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _text),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _genderScopeChip(draft, 'general', 'General'),
                      _genderScopeChip(draft, 'female', 'Female only'),
                      _genderScopeChip(draft, 'male', 'Male only'),
                    ],
                  ),
                ),
              ],
            ),

            // Options editor (only for choice types)
            if (draft.type.value.hasOptions) ...[
              const SizedBox(height: 12),
              const Text(
                'Options',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _text,
                ),
              ),
              const SizedBox(height: 6),
              ...List.generate(draft.optionControllers.length, (oi) {
                final ctrl = draft.optionControllers[oi];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.circle_outlined,
                          size: 14, color: _accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          style: const TextStyle(fontSize: 14, color: _text),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Option ${oi + 1}',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: _border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: _border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: _accent),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close,
                            size: 18, color: _accent),
                        onPressed: () => controller.removeOption(index, oi),
                      ),
                    ],
                  ),
                );
              }),
              GestureDetector(
                onTap: () => controller.addOption(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border.all(color: _accent.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: _accent),
                      SizedBox(width: 4),
                      Text(
                        'Add option',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _genderScopeChip(
      ConsultationFieldDraft draft, String value, String label) {
    final selected = draft.genderScope.value == value;
    return GestureDetector(
      onTap: () => draft.genderScope.value = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.white,
          border: Border.all(color: selected ? _accent : _border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _text,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, color: _accent),
              label: const Text(
                'Add Field',
                style: TextStyle(
                    color: _accent, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _pickType(context, null),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(
              () => CustomButton(
                onTap: controller.isSaving.value
                    ? () {}
                    : () async {
                        final ok = await controller.save();
                        if (ok) Get.back();
                      },
                text: controller.isSaving.value ? 'Saving...' : 'Save',
                isOutline: false,
                fontSize: 14,
                isLoading: controller.isSaving.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// If [editIndex] is null, adds a new field; otherwise changes existing field's type.
  Future<void> _pickType(BuildContext context, int? editIndex) async {
    final selected = await showModalBottomSheet<ConsultationFieldType>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 6, bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xff79747E),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose field type',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _text),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 'file' (lab report upload) is a built-in field seeded with
              // the standard questionnaire - not offered as a type a
              // dietician can hand-author here.
              ...ConsultationFieldType.values
                  .where((t) => t != ConsultationFieldType.file)
                  .map(
                    (t) => ListTile(
                      leading: Icon(_iconForType(t), color: _accent),
                      title: Text(t.displayName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      onTap: () => Navigator.of(context).pop(t),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;
    if (editIndex == null) {
      controller.addField(selected);
    } else {
      controller.changeFieldType(editIndex, selected);
    }
  }

  IconData _iconForType(ConsultationFieldType t) {
    switch (t) {
      case ConsultationFieldType.text:
        return Icons.short_text;
      case ConsultationFieldType.textarea:
        return Icons.notes;
      case ConsultationFieldType.number:
        return Icons.tag;
      case ConsultationFieldType.date:
        return Icons.event;
      case ConsultationFieldType.yesNo:
        return Icons.toggle_on_outlined;
      case ConsultationFieldType.singleChoice:
        return Icons.radio_button_checked;
      case ConsultationFieldType.multiChoice:
        return Icons.check_box_outlined;
      case ConsultationFieldType.file:
        return Icons.attach_file;
    }
  }
}
