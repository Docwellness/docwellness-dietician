import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

import '../controllers/timeline_step_controller.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _primaryColor = Color(0xff851653);

const Map<String, String> _timingAnchorLabels = {
  'pre': 'Before',
  'with': 'With',
  'post': 'After',
};

/// Bottom sheet: search/select a supplement, pick its timing anchor
/// relative to the chosen slot, enter dosage/instructions, then "Inject" -
/// the Timeline Builder's Supplement Injection UX from the original spec.
class SupplementPickerSheet extends StatefulWidget {
  final String dayGroup;
  final String servingTime;
  final List<RecipeListItem> availableSupplements;
  final void Function(StagedSupplement supplement) onInject;

  const SupplementPickerSheet({
    super.key,
    required this.dayGroup,
    required this.servingTime,
    required this.availableSupplements,
    required this.onInject,
  });

  @override
  State<SupplementPickerSheet> createState() => _SupplementPickerSheetState();
}

class _SupplementPickerSheetState extends State<SupplementPickerSheet> {
  RecipeListItem? _selected;
  String _timingAnchor = 'with';
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: 'Add Supplement · ${widget.dayGroup} ${widget.servingTime}',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _headerColor,
            ),
            const SizedBox(height: 12),
            if (widget.availableSupplements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CustomText(
                  text: 'No supplements found in your recipe library yet.',
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: Color(0xff6C737F),
                ),
              )
            else
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.availableSupplements.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final s = widget.availableSupplements[index];
                    final isSelected = _selected?.id == s.id;
                    return ChoiceChip(
                      label: Text(s.name),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selected = s),
                      selectedColor: const Color(0xffFEF6FB),
                      labelStyle: TextStyle(
                        color: isSelected ? _primaryColor : _bodyColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      side: BorderSide(color: isSelected ? _primaryColor : const Color(0xffFAA7E0)),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            const CustomText(text: 'Timing', fontWeight: FontWeight.w500, fontSize: 14, color: _headerColor),
            const SizedBox(height: 8),
            Row(
              children: _timingAnchorLabels.entries.map((entry) {
                final isSelected = _timingAnchor == entry.key;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${entry.value} ${widget.servingTime}'),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _timingAnchor = entry.key),
                      selectedColor: const Color(0xffFEF6FB),
                      labelStyle: TextStyle(
                        color: isSelected ? _primaryColor : _bodyColor,
                        fontSize: 12,
                      ),
                      side: BorderSide(color: isSelected ? _primaryColor : const Color(0xffFAA7E0)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              decoration: _inputDecoration('Dosage (e.g. 1 tablet)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _instructionsController,
              decoration: _inputDecoration('Instructions (optional)'),
            ),
            const SizedBox(height: 20),
            CustomButton(
              isOutline: false,
              buttonColor: _headerColor,
              text: 'Inject',
              onTap: () {
                if (_selected == null) return;
                widget.onInject(
                  StagedSupplement(
                    dayGroup: widget.dayGroup,
                    servingTime: widget.servingTime,
                    supplementId: _selected!.id,
                    supplementName: _selected!.name,
                    dosage: _dosageController.text.trim().isEmpty ? null : _dosageController.text.trim(),
                    instructions: _instructionsController.text.trim().isEmpty
                        ? null
                        : _instructionsController.text.trim(),
                    timingAnchor: _timingAnchor,
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xffFEF6FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffFAA7E0)),
      ),
    );
  }
}
