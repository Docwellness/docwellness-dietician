import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/date_range_selector_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BmiChart extends StatelessWidget {
  final List<BmiDataPoint> bmiData;
  final double currentBmi;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final DateTime firstSelectableDate;
  final DateTime lastSelectableDate;
  final ValueChanged<DateTimeRange> onRangeSelected;
  final int currentIndex;

  const BmiChart({
    super.key,
    required this.bmiData,
    required this.currentBmi,
    required this.rangeStart,
    required this.rangeEnd,
    required this.firstSelectableDate,
    required this.lastSelectableDate,
    required this.onRangeSelected,
    this.currentIndex = -1,
  });

  String get _bmiCategory {
    if (currentBmi < 18.5) return 'Underweight';
    if (currentBmi < 25) return 'Health range';
    if (currentBmi < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) {
    final values = bmiData.map((e) => e.bmi).toList();
    final labels = bmiData.map((e) => e.label).toList();

    // Filter out zero values for Y-axis calculations
    final nonZeroValues = values.where((v) => v > 0).toList();
    final hasData = nonZeroValues.isNotEmpty;

    // Calculate dynamic Y-axis range
    final maxBmi = !hasData
        ? 30.0
        : nonZeroValues.reduce((a, b) => a > b ? a : b);

    // Smart Y-axis: show 4-5 labels with nice round intervals
    final chartMax = (maxBmi * 1.2).ceilToDouble();
    final chartMin = 0.0;
    final yRange = chartMax - chartMin;
    final yInterval = _niceInterval(yRange / 4);

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xffFDF2FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// TITLE
                  CustomText(
                    text: "BMI",
                    fontSize: 12,
                    color: Color(0xff4D5761),
                    fontWeight: FontWeight.w600,
                  ),

                  SizedBox(height: 6),

                  /// BMI VALUE + CATEGORY
                  Row(
                    children: [
                      CustomText(
                        text: currentBmi.toStringAsFixed(1),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff111927),
                      ),
                      SizedBox(width: 10),

                      /// CATEGORY CONTAINER
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffFCE7F6),
                          border: Border.all(
                            color: Color(0xffFCE7F6),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: CustomText(
                          text: _bmiCategory,
                          fontSize: 10,
                          color: Color(0xffDE2493),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DateRangeSelectorButton(
                  selectedStart: rangeStart,
                  selectedEnd: rangeEnd,
                  firstDate: firstSelectableDate,
                  lastDate: lastSelectableDate,
                  onRangeSelected: onRangeSelected,
                ),
              ),
            ],
          ),

          SizedBox(height: 18),

          /// CHART WITH SCROLLING
          SizedBox(
            height: 170,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: values.isEmpty ? 200 : values.length * 65,
                child: values.isEmpty
                    ? Center(
                        child: CustomText(
                          text: 'No BMI data',
                          fontSize: 12,
                          color: Color(0xff94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          maxY: chartMax,
                          minY: chartMin,
                          groupsSpace: 22,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              tooltipMargin: 6,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      rod.toY.toStringAsFixed(1),
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
                            horizontalInterval: yInterval,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Color(0xffFCE7F6),
                              strokeWidth: 0.6,
                              dashArray: [4, 4],
                            ),
                          ),
                          borderData: FlBorderData(show: false),

                          /// TITLES
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: yInterval,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
                                  // Skip min/max boundary labels to avoid overlap
                                  if (value == meta.min || value == meta.max) {
                                    return const SizedBox.shrink();
                                  }
                                  final label = value == value.roundToDouble()
                                      ? value.toInt().toString()
                                      : value.toStringAsFixed(1);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: CustomText(
                                      text: label,
                                      fontSize: 10,
                                      color: Color(0xffF670CA),
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
                                  return Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: CustomText(
                                      text: index < labels.length
                                          ? labels[index]
                                          : "",
                                      fontSize: 10.5,
                                      color: Color(0xffF670CA),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(),
                            rightTitles: AxisTitles(),
                          ),

                          /// BARS
                          barGroups: List.generate(values.length, (index) {
                            final hasBarData = values[index] > 0;
                            // Highlight the current day/week/month
                            final isHighlighted =
                                hasBarData &&
                                (currentIndex >= 0
                                    ? index == currentIndex
                                    : index == values.length - 1);

                            return BarChartGroupData(
                              x: index,
                              barsSpace: 12,
                              barRods: [
                                BarChartRodData(
                                  width: 38,
                                  toY: hasBarData ? values[index] : 0,
                                  color: !hasBarData
                                      ? Color(0xffFCCEEF).withOpacity(0.3)
                                      : isHighlighted
                                      ? Color(0xff530630)
                                      : Color(0xffFCCEEF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pick a nice round interval for Y-axis
  static double _niceInterval(double raw) {
    if (raw <= 1) return 1;
    if (raw <= 2) return 2;
    if (raw <= 5) return 5;
    if (raw <= 10) return 10;
    if (raw <= 15) return 15;
    if (raw <= 20) return 20;
    if (raw <= 25) return 25;
    if (raw <= 50) return 50;
    return (raw / 10).ceilToDouble() * 10;
  }
}
