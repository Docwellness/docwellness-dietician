import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

const _primaryColor = Color(0xff851653);
const _mutedColor = Color(0xff9DA4AE);

const List<double> _fractionSteps = [0.5, 0.75, 1.0, 1.25, 1.5];

/// [ 0.5 | 0.75 | 1.0 | 1.25 | 1.5 ] portion selector for one plan item -
/// replaces a plain +/- stepper with the fixed set of realistic serving
/// fractions a dietician actually prescribes in practice.
class FractionDial extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const FractionDial({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // The dial only ever proposes the 5 fixed steps - an item whose current
    // multiplier came from somewhere else (a manual scale, legacy data)
    // simply shows no step highlighted rather than snapping to the nearest
    // one, so this never silently changes a value the dietician didn't tap.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _fractionSteps.map((step) {
        final isSelected = (value - step).abs() < 0.001;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onChanged(step),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : Colors.white,
                border: Border.all(color: isSelected ? _primaryColor : _mutedColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomText(
                text: step == step.roundToDouble() ? '${step.toInt()}' : '$step',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xff384250),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
