import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class CalorieIntakeContainer extends StatelessWidget {
  final List<CalorieDataPoint> data;
  final int plannedCalories;
  final int currentIndex;

  const CalorieIntakeContainer({
    super.key,
    required this.data,
    required this.plannedCalories,
    this.currentIndex = -1,
  });

  @override
  Widget build(BuildContext context) {
    // Normalize: bar height based on max of (consumed, planned)
    final maxCalories = data.fold<int>(plannedCalories, (prev, point) {
      final maxVal = point.calories > point.plannedCalories
          ? point.calories
          : point.plannedCalories;
      return maxVal > prev ? maxVal : prev;
    });
    final effectiveMax = maxCalories > 0 ? maxCalories : 1;

    double barTotalHeight = 160;

    // Scale labels (4 ticks)
    final scaleStep = (effectiveMax / 4).ceil();
    final scaleLabels = List.generate(
      5,
      (i) => ((4 - i) * scaleStep).toString(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT SCALE
            SizedBox(
              height: 170,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: scaleLabels
                    .map((label) => _ScaleText(label))
                    .toList(),
              ),
            ),

            const SizedBox(width: 20),

            // BARS - spread evenly across the full available width instead
            // of being packed left inside a scroll view, which left a large
            // empty gap on the right for low bar-counts like "This week".
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(data.length, (index) {
                  final point = data[index];
                  // Determine bar color based on calorie comparison
                  // Green = on track or under, Red = over planned
                  final isOverPlanned = point.calories > point.plannedCalories;
                  final hasData = point.calories > 0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _CalorieBar(
                        consumed: point.calories,
                        planned: point.plannedCalories,
                        maxValue: effectiveMax,
                        width: 8,
                        totalHeight: barTotalHeight,
                        isOverPlanned: isOverPlanned,
                        hasData: hasData,
                      ),
                      const SizedBox(height: 8),
                      CustomText(
                        text: point.label,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color:
                            (currentIndex >= 0
                                ? index == currentIndex
                                : index == 0)
                            ? const Color(0xffF670CA)
                            : const Color(0xff94A3B8),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// SCALE TEXT
class _ScaleText extends StatelessWidget {
  final String text;
  const _ScaleText(this.text);

  @override
  Widget build(BuildContext context) {
    return CustomText(
      text: text,
      color: Color(0xffF670CA),
      fontSize: 10,
      fontWeight: FontWeight.w400,
    );
  }
}

// CALORIE BAR WIDGET
class _CalorieBar extends StatelessWidget {
  final int consumed;
  final int planned;
  final int maxValue;
  final double totalHeight;
  final double width;
  final bool isOverPlanned;
  final bool hasData;

  const _CalorieBar({
    required this.consumed,
    required this.planned,
    required this.maxValue,
    required this.totalHeight,
    required this.width,
    required this.isOverPlanned,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      // No data - show faded bar at 10% height
      final emptyHeight = totalHeight * 0.1;
      return SizedBox(
        height: totalHeight,
        child: Column(
          children: [
            Expanded(child: SizedBox()),
            Container(
              height: emptyHeight,
              width: width,
              decoration: BoxDecoration(
                color: const Color(0xffFCCEEF).withOpacity(0.5),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ],
        ),
      );
    }

    final consumedRatio = (consumed / maxValue).clamp(0.0, 1.0);

    final consumedHeight = consumedRatio * (totalHeight - 8);

    // Over-planned part (red) and on-track part (green)
    if (isOverPlanned) {
      final overAmount = consumed - planned;
      final overRatio = (overAmount / maxValue).clamp(0.0, 1.0);
      final overHeight = overRatio * (totalHeight - 8);
      final onTrackHeight = consumedHeight - overHeight;

      return SizedBox(
        height: totalHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Over part (red gradient)
            Container(
              height: overHeight,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                gradient: const LinearGradient(
                  colors: [Color(0xffFF3D3D), Color(0xffFFC3C3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // On-track part (green gradient)
            Container(
              height: onTrackHeight,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xff4FEE7C), Color(0xffCFFFCF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Under or at planned (just green + pink planned indicator)
    final remainingRatio = ((planned - consumed) / maxValue).clamp(0.0, 1.0);
    final remainingHeight = remainingRatio * (totalHeight - 8);

    return SizedBox(
      height: totalHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Remaining planned (light pink)
          Container(
            height: remainingHeight,
            width: width,
            decoration: BoxDecoration(
              color: const Color(0xffFCCEEF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
          ),
          const SizedBox(height: 4),
          // Consumed part (green gradient)
          Container(
            height: consumedHeight,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              gradient: const LinearGradient(
                colors: [Color(0xff4FEE7C), Color(0xffCFFFCF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
