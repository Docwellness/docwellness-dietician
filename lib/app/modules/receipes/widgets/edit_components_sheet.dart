import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lets a dietician review/correct the AI-generated `components` for a
/// recipe - e.g. fixing "Masala Omelette: 100 g" to "Masala Omelette: 2
/// egg", or splitting "Idli with Sambar and Chutney" into its 3 real parts
/// (Idli: 3 nos, Sambar: 1 bowl, Chutney: 2 tbsp) instead of one forced
/// gram total. This is the only place in the app a component's label/
/// quantity/unit can be corrected after generation - see
/// PatientsController's diet-plan stepper, which reads whatever is saved
/// here.
class EditComponentsSheet extends StatefulWidget {
  final ScrollController scrollController;
  final List<RecipeComponent> initialComponents;
  final void Function(List<RecipeComponent> components) onSaved;

  const EditComponentsSheet({
    super.key,
    required this.scrollController,
    required this.initialComponents,
    required this.onSaved,
  });

  @override
  State<EditComponentsSheet> createState() => _EditComponentsSheetState();
}

/// Matches the backend's COMPONENT_UNITS (utils/recipeJsonSchema.js) -
/// keep in sync if that enum ever changes.
const List<String> _componentUnits = [
  'g',
  'ml',
  'cup',
  'tbsp',
  'tsp',
  'piece',
  'nos',
  'bowl',
  'egg',
  'slice',
];

class _ComponentDraft {
  final TextEditingController labelController;
  final TextEditingController quantityController;
  String unit;

  _ComponentDraft({required String label, required num quantity, required this.unit})
    : labelController = TextEditingController(text: label),
      quantityController = TextEditingController(
        text: quantity == quantity.roundToDouble()
            ? quantity.toStringAsFixed(0)
            : quantity.toString(),
      );

  void dispose() {
    labelController.dispose();
    quantityController.dispose();
  }
}

class _EditComponentsSheetState extends State<EditComponentsSheet> {
  late List<_ComponentDraft> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = widget.initialComponents.isNotEmpty
        ? widget.initialComponents
              .map(
                (c) => _ComponentDraft(
                  label: c.label,
                  quantity: c.quantity,
                  unit: _componentUnits.contains(c.unit) ? c.unit : 'g',
                ),
              )
              .toList()
        : [_ComponentDraft(label: '', quantity: 1, unit: 'g')];
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addComponent() {
    setState(
      () => _drafts.add(_ComponentDraft(label: '', quantity: 1, unit: 'g')),
    );
  }

  void _removeComponent(int index) {
    // Every recipe needs at least one component - a compound dish reduced
    // to zero parts has nothing left for the diet-plan stepper to adjust.
    if (_drafts.length <= 1) return;
    setState(() {
      _drafts[index].dispose();
      _drafts.removeAt(index);
    });
  }

  Future<void> _pickUnit(int index) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xff79747E),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 12),
              const CustomText(
                text: 'Choose a unit',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xff1F2A37),
              ),
              const SizedBox(height: 8),
              for (final u in _componentUnits)
                ListTile(
                  title: CustomText(
                    text: u,
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                    color: const Color(0xff384250),
                  ),
                  trailing: _drafts[index].unit == u
                      ? const Icon(Icons.check, color: Color(0xff851653))
                      : null,
                  onTap: () => Navigator.pop(ctx, u),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) setState(() => _drafts[index].unit = selected);
  }

  void _save() {
    final components = _drafts
        .map(
          (d) => RecipeComponent(
            label: d.labelController.text.trim().isEmpty
                ? 'Serving'
                : d.labelController.text.trim(),
            quantity: num.tryParse(d.quantityController.text.trim()) ?? 1,
            unit: d.unit,
          ),
        )
        .toList();
    widget.onSaved(components);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag handle
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10, top: 10),
            decoration: BoxDecoration(
              color: const Color(0xff79747E),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
              ),
              const SizedBox(width: 8),
              const CustomText(
                text: 'Edit Portions',
                fontWeight: FontWeight.w400,
                fontSize: 19,
                color: Color(0xff1F2A37),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: CustomText(
            text:
                'Break this dish into the real parts a patient would recognize '
                'and count - e.g. Idli (nos), Sambar (bowl), Chutney (tbsp) - '
                'instead of one gram total. A simple dish just needs one part.',
            fontWeight: FontWeight.w400,
            fontSize: 12.5,
            color: Color(0xff6C737F),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xff9DA4AE)),

        // Scrollable list of component rows
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _drafts.length,
            itemBuilder: (context, index) {
              final draft = _drafts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffFEF6FB),
                  border: Border.all(color: const Color(0xffFDF2FA)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            text: 'Part ${index + 1}',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: const Color(0xff851653),
                          ),
                        ),
                        if (_drafts.length > 1)
                          GestureDetector(
                            onTap: () => _removeComponent(index),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Color(0xff98A2B3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CustomField(
                      controller: draft.labelController,
                      lable: 'Name (e.g. Idli, Sambar, Chutney)',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomField(
                            controller: draft.quantityController,
                            lable: 'Quantity',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickUnit(index),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                labelStyle: const TextStyle(
                                  color: Color(0xff6C737F),
                                  fontSize: 13,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xffD0D5DD),
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CustomText(
                                    text: draft.unit,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: const Color(0xff384250),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xff6C737F),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: _addComponent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_circle_outline, color: Color(0xff851653)),
                SizedBox(width: 6),
                CustomText(
                  text: 'Add another part',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xff851653),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: CustomButton(onTap: _save, text: 'Save Portions', isOutline: false),
        ),
      ],
    );
  }
}
