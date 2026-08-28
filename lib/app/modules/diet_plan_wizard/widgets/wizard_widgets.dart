import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/functions/quantity_label.dart';
import 'package:flutter/material.dart';

import 'wizard_theme.dart';

/// Shared presentation widgets for the diet plan wizard (openspec change
/// diet-wizard-portions-and-polish, capability
/// diet-plan-wizard/wizard-visual-language). A recipe card looks the same on
/// the Generate review screen and the Review & Finalize screen because both
/// build it from here.

/// The real serving amount as an outline pill - "1 piece", "75 g (~5 tbsp)".
class PortionPill extends StatelessWidget {
  final String rawQuantity;
  final String unit;

  const PortionPill({super.key, required this.rawQuantity, required this.unit});

  /// Convenience for a single [WizardComponent]-style pair already formatted
  /// elsewhere.
  const PortionPill.raw(String label, {super.key})
      : rawQuantity = label,
        unit = '';

  @override
  Widget build(BuildContext context) {
    final text = unit.isEmpty ? rawQuantity : formatQuantityLabel(rawQuantity, unit);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(WizardPalette.pillRadius),
        border: Border.all(color: WizardPalette.magenta.withValues(alpha: 0.35)),
      ),
      child: CustomText(text: text, fontWeight: FontWeight.w600, fontSize: 12, color: WizardPalette.magenta),
    );
  }
}

/// A small "Edited" badge for a plan item whose portion the dietician has
/// hand-set (pinned) - tap to unpin.
class EditedBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const EditedBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: WizardPalette.tint,
        borderRadius: BorderRadius.circular(WizardPalette.pillRadius),
        border: Border.all(color: WizardPalette.magenta.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_outlined, size: 11, color: WizardPalette.magenta),
          const SizedBox(width: 3),
          const CustomText(text: 'Edited', fontWeight: FontWeight.w600, fontSize: 10, color: WizardPalette.magenta),
        ],
      ),
    );
    return onTap == null
        ? chip
        : InkWell(borderRadius: BorderRadius.circular(WizardPalette.pillRadius), onTap: onTap, child: chip);
  }
}

/// Protein / fiber / carbs / fat, 4-up, hairline icon + value + label. Kept
/// monochrome (one muted line icon each) rather than four accent colours -
/// the "rainbow macro chips" look reads as generic.
class MacroChipRow extends StatelessWidget {
  final num? protein;
  final num? fiber;
  final num? carbs;
  final num? fat;

  const MacroChipRow({super.key, this.protein, this.fiber, this.carbs, this.fat});

  static String _g(num? v) => v == null ? '—' : '${v.round()}g';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MacroChip(icon: Icons.egg_alt_outlined, value: _g(protein), label: 'Protein'),
        _MacroChip(icon: Icons.eco_outlined, value: _g(fiber), label: 'Fiber'),
        _MacroChip(icon: Icons.bakery_dining_outlined, value: _g(carbs), label: 'Carbs'),
        _MacroChip(icon: Icons.water_drop_outlined, value: _g(fat), label: 'Fat'),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MacroChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 15, color: WizardPalette.muted),
          const SizedBox(height: 2),
          CustomText(text: value, fontWeight: FontWeight.w600, fontSize: 12, color: WizardPalette.ink),
          CustomText(text: label, fontWeight: FontWeight.w400, fontSize: 10, color: WizardPalette.muted),
        ],
      ),
    );
  }
}

/// Section title + optional trailing action (e.g. a day card's "Auto Adjust").
class WizardSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const WizardSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomText(text: title, fontWeight: FontWeight.w600, fontSize: 14, color: WizardPalette.ink),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Horizontal day-group selector - a 4-segment control where the labels fit,
/// scrollable where they don't, so nothing clips at a narrow width.
class DayGroupSelector extends StatelessWidget {
  /// (canonical value, display label) pairs, in order.
  final List<MapEntry<String, String>> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const DayGroupSelector({super.key, required this.options, required this.selected, required this.onSelect});

  Widget _segment(MapEntry<String, String> entry, {required bool expanded}) {
    final isSelected = entry.key == selected;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? WizardPalette.magenta : Colors.transparent,
        borderRadius: BorderRadius.circular(WizardPalette.pillRadius),
      ),
      child: CustomText(
        text: entry.value,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: isSelected ? Colors.white : WizardPalette.magenta,
        textAlign: TextAlign.center,
      ),
    );
    final tappable = InkWell(
      onTap: () => onSelect(entry.key),
      borderRadius: BorderRadius.circular(WizardPalette.pillRadius),
      child: child,
    );
    return expanded ? Expanded(child: tappable) : tappable;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Rough fit check: ~92px per segment covers the longest label
        // ("Wed & Sun") plus padding.
        final fits = constraints.maxWidth >= options.length * 92;
        final container = BoxDecoration(color: WizardPalette.tint, borderRadius: BorderRadius.circular(WizardPalette.pillRadius));
        if (fits) {
          return Container(
            padding: const EdgeInsets.all(3),
            decoration: container,
            child: Row(children: options.map((e) => _segment(e, expanded: true)).toList()),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: container,
            child: Row(
              children: [
                for (final e in options) ...[_segment(e, expanded: false), const SizedBox(width: 4)],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The wizard's signature structural device: a hairline rail down the left
/// with a filled node per serving-time, echoing the patient app's own diet
/// timeline. Each entry is (serving-time label, its content).
class MealTimeline extends StatelessWidget {
  final List<({String servingTime, Widget child})> slots;

  const MealTimeline({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < slots.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(color: WizardPalette.magenta, shape: BoxShape.circle),
                      ),
                      if (i != slots.length - 1)
                        Expanded(child: Container(width: 1.5, color: WizardPalette.line)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == slots.length - 1 ? 0 : 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: slots[i].servingTime,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: WizardPalette.magenta,
                        ),
                        const SizedBox(height: 6),
                        slots[i].child,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The one recipe card used everywhere in the wizard. Name + right-aligned
/// calories on top; a portion pill and optional "Edited" badge; an optional
/// macro row; optional trailing actions (swap/remove) and an optional
/// expandable body (ingredients / cooking steps).
class WizardRecipeCard extends StatefulWidget {
  final String title;
  final String? portionLabel;
  final int? calories;
  final String? versionLabel;
  final MacroChipRow? macros;
  final bool pinned;
  final VoidCallback? onUnpin;
  final List<Widget> actions;
  final Widget? expandedBody;
  final VoidCallback? onTap;

  const WizardRecipeCard({
    super.key,
    required this.title,
    this.portionLabel,
    this.calories,
    this.versionLabel,
    this.macros,
    this.pinned = false,
    this.onUnpin,
    this.actions = const [],
    this.expandedBody,
    this.onTap,
  });

  @override
  State<WizardRecipeCard> createState() => _WizardRecipeCardState();
}

class _WizardRecipeCardState extends State<WizardRecipeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (widget.calories != null) '${widget.calories} Cal',
      if (widget.versionLabel != null) widget.versionLabel!,
    ].join(' · ');

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(WizardPalette.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WizardPalette.surface,
          borderRadius: BorderRadius.circular(WizardPalette.cardRadius),
          border: Border.all(color: WizardPalette.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomText(text: widget.title, fontWeight: FontWeight.w600, fontSize: 13, color: WizardPalette.ink),
                ),
                ...widget.actions,
              ],
            ),
            if (widget.portionLabel != null || meta.isNotEmpty || widget.pinned) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.portionLabel != null) PortionPill.raw(widget.portionLabel!),
                  if (widget.pinned) EditedBadge(onTap: widget.onUnpin),
                  if (meta.isNotEmpty)
                    CustomText(text: meta, fontWeight: FontWeight.w400, fontSize: 11, color: WizardPalette.muted),
                ],
              ),
            ],
            if (widget.macros != null) ...[
              const SizedBox(height: 10),
              widget.macros!,
            ],
            if (widget.expandedBody != null) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CustomText(
                        text: _expanded ? 'Hide details' : 'Recipe & steps',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: WizardPalette.magenta,
                      ),
                      Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 16, color: WizardPalette.magenta),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: widget.expandedBody!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
