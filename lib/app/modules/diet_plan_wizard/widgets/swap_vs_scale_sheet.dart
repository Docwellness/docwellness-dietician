import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

import '../models/wizard_week_models.dart';

const _headerColor = Color(0xff530630);
const _bodyColor = Color(0xff1F2A37);
const _mutedColor = Color(0xff6C737F);
const _primaryColor = Color(0xff851653);

/// "Lunch is 250 Cal over budget" banner + [Scale Down] [Swap Lighter]
/// actions - the original spec's Swap vs Scale flow. Shown when a Smart
/// Recipe Card is tapped for adjustment; `onScale` opens the Fraction Dial
/// inline, `onSwap` fetches and shows lighter/heavier alternatives.
class SwapVsScaleSheet extends StatelessWidget {
  final WizardPlanItem item;
  final double? deviationCalories;
  final Future<List<WizardSwapAlternative>> Function(String direction) onLoadAlternatives;
  final void Function(WizardSwapAlternative alternative) onSelectAlternative;
  final VoidCallback onScaleInstead;

  const SwapVsScaleSheet({
    super.key,
    required this.item,
    required this.deviationCalories,
    required this.onLoadAlternatives,
    required this.onSelectAlternative,
    required this.onScaleInstead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              text: item.recipeName ?? 'This item',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _headerColor,
            ),
            if (deviationCalories != null) ...[
              const SizedBox(height: 4),
              CustomText(
                text: deviationCalories! > 0
                    ? '${deviationCalories!.round()} Cal over budget'
                    : '${deviationCalories!.abs().round()} Cal under budget',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: _mutedColor,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    isOutline: true,
                    outlineButtonColor: _primaryColor,
                    textColor: _primaryColor,
                    text: 'Scale Down',
                    onTap: () {
                      Navigator.of(context).pop();
                      onScaleInstead();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    isOutline: false,
                    buttonColor: _headerColor,
                    text: 'Swap Lighter',
                    onTap: () => _showAlternatives(context, 'lighter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAlternatives(BuildContext context, String direction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => FutureBuilder<List<WizardSwapAlternative>>(
        future: onLoadAlternatives(direction),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: _primaryColor)),
            );
          }
          final alternatives = snapshot.data!;
          if (alternatives.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: CustomText(
                text: 'No lighter alternatives found in your recipe library for this slot.',
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: _mutedColor,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  text: 'Lighter alternatives',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: _headerColor,
                ),
                const SizedBox(height: 10),
                ...alternatives.map(
                  (alt) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: CustomText(text: alt.name, fontWeight: FontWeight.w500, fontSize: 14, color: _bodyColor),
                    subtitle: alt.calories != null
                        ? CustomText(
                            text: '${alt.calories!.round()} Cal',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: _mutedColor,
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right, color: _primaryColor),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onSelectAlternative(alt);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
