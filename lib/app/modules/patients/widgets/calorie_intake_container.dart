import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Calorie intake bars - built on fl_chart's BarChart (same as BmiChart in
/// this folder), so tapping a bar shows its value in the same default
/// tooltip bubble BMI already has, instead of being untappable. The whole
/// chart (bars + its own left-axis scale) lives in one horizontally-
/// scrolling area, same structure as BmiChart - that also fixes bars
/// sitting centered instead of left-anchored when there are only one or
/// two of them (the old Row(mainAxisAlignment: spaceEvenly) stretched a
/// handful of bars across the full available width instead).
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

  static const Color _consumedColor = Color(0xff4FEE7C);
  static const Color _remainingColor = Color(0xffFCCEEF);
  static const Color _overColor = Color(0xffFF3D3D);
  static const Color _noDataColor = Color(0x80FCCEEF);

  @override
  Widget build(BuildContext context) {
    final maxCalories = data.fold<int>(plannedCalories, (prev, point) {
      final maxVal = point.calories > point.plannedCalories
          ? point.calories
          : point.plannedCalories;
      return maxVal > prev ? maxVal : prev;
    });
    final effectiveMax = maxCalories > 0 ? maxCalories : 1;
    final scaleStep = (effectiveMax / 4).ceil().clamp(1, effectiveMax);
    final chartMax = (scaleStep * 4).toDouble();

    return SizedBox(
      height: 180,
      // Without an explicit width, this shrinks to its (possibly narrow,
      // single-bar) content and gets centered by whatever ambient Column
      // wraps it in patient_profile_view.dart, instead of sitting flush
      // against the left edge like the axis/bars should.
      width: double.infinity,
      child: data.isEmpty
          ? const Center(
              child: CustomText(
                text: 'No calorie data',
                fontSize: 12,
                color: Color(0xff94A3B8),
                fontWeight: FontWeight.w400,
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: data.length * 56,
                child: BarChart(
                  BarChartData(
                    maxY: chartMax,
                    minY: 0,
                    alignment: BarChartAlignment.start,
                    groupsSpace: 18,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tooltipMargin: 6,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final point = data[groupIndex];
                          return BarTooltipItem(
                            '${point.calories} kcal',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: scaleStep.toDouble(),
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: Color(0xffFCE7F6),
                        strokeWidth: 0.6,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: scaleStep.toDouble(),
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: CustomText(
                                text: value.toInt().toString(),
                                fontSize: 10,
                                color: const Color(0xffF670CA),
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= data.length) {
                              return const SizedBox.shrink();
                            }
                            final isHighlighted = currentIndex >= 0
                                ? index == currentIndex
                                : index == 0;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: CustomText(
                                text: data[index].label,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: isHighlighted
                                    ? const Color(0xffF670CA)
                                    : const Color(0xff94A3B8),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                    ),
                    barGroups: List.generate(data.length, (index) {
                      final point = data[index];
                      final hasData = point.calories > 0;
                      final isOverPlanned = point.calories > point.plannedCalories;

                      if (!hasData) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: chartMax * 0.02,
                              width: 10,
                              borderRadius: BorderRadius.circular(20),
                              color: _noDataColor,
                            ),
                          ],
                        );
                      }

                      // Over-planned: bar height = actual consumed, with
                      // the amount over plan stacked on top of the
                      // on-plan portion. Under/at-planned: bar height =
                      // the planned target, with how much was actually
                      // consumed stacked below the remaining portion.
                      final rodTop = isOverPlanned
                          ? point.calories.toDouble()
                          : point.plannedCalories.toDouble();
                      final stackItems = isOverPlanned
                          ? [
                              BarChartRodStackItem(
                                0,
                                point.plannedCalories.toDouble(),
                                _consumedColor,
                              ),
                              BarChartRodStackItem(
                                point.plannedCalories.toDouble(),
                                point.calories.toDouble(),
                                _overColor,
                              ),
                            ]
                          : [
                              BarChartRodStackItem(
                                0,
                                point.calories.toDouble(),
                                _consumedColor,
                              ),
                              BarChartRodStackItem(
                                point.calories.toDouble(),
                                point.plannedCalories.toDouble(),
                                _remainingColor,
                              ),
                            ];

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: rodTop,
                            width: 10,
                            borderRadius: BorderRadius.circular(20),
                            rodStackItems: stackItems,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}
