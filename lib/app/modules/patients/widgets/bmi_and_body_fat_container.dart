import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:docwellnesdoc/app/modules/patients/widgets/date_range_selector_button.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BmiChart extends StatefulWidget {
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

  @override
  State<BmiChart> createState() => _BmiChartState();
}

class _BmiChartState extends State<BmiChart> {
  // Matches values.length * 65 sizing of the bar-chart content below - each
  // bar (plus its spacing) occupies one 65px-wide slot.
  static const double _barSlotWidth = 65;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnCurrent());
  }

  @override
  void didUpdateWidget(covariant BmiChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-center whenever the highlighted bar or the data set itself changes
    // (e.g. async data finishing load after first mount, or the date range
    // picker loading a new range) - not on every rebuild, so it doesn't
    // fight a manual scroll the patient is mid-way through.
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.bmiData.length != widget.bmiData.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnCurrent());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerOnCurrent() {
    if (!_scrollController.hasClients) return;
    final total = widget.bmiData.length;
    if (total == 0) return;
    final targetIndex = widget.currentIndex >= 0
        ? widget.currentIndex
        : total - 1;
    final viewport = _scrollController.position.viewportDimension;
    final target =
        (targetIndex * _barSlotWidth) - viewport / 2 + _barSlotWidth / 2;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  String get _bmiCategory {
    final currentBmi = widget.currentBmi;
    if (currentBmi <= 0) return '--';
    if (currentBmi < 18.5) return 'Underweight';
    if (currentBmi < 25) return 'Health range';
    if (currentBmi < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.bmiData.map((e) => e.bmi).toList();
    final labels = widget.bmiData.map((e) => e.label).toList();

    final nonZeroValues = values.where((v) => v > 0).toList();
    final hasData = nonZeroValues.isNotEmpty;

    final maxBmi = !hasData
        ? 30.0
        : nonZeroValues.reduce((a, b) => a > b ? a : b);

    final chartMax = (maxBmi * 1.2).ceilToDouble();
    const chartMin = 0.0;
    final yRange = chartMax - chartMin;
    final yInterval = _niceInterval(yRange / 4);

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xffFDF2FA),
        borderRadius: BorderRadius.circular(10),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: "BMI",
                    fontSize: 12,
                    color: Color(0xff4D5761),
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      CustomText(
                        text: widget.currentBmi > 0
                            ? widget.currentBmi.toStringAsFixed(1)
                            : '--',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff111927),
                      ),
                      SizedBox(width: 10),
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
                  selectedStart: widget.rangeStart,
                  selectedEnd: widget.rangeEnd,
                  firstDate: widget.firstSelectableDate,
                  lastDate: widget.lastSelectableDate,
                  onRangeSelected: widget.onRangeSelected,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed, non-scrolling y-axis - a twin BarChart with no bars
                // of its own, sharing the exact same maxY/minY/gridData/
                // interval/reservedSize as the scrollable chart below so fl_
                // chart lays out its internal plot area identically in both
                // (same height, same axis width) and the two line up
                // pixel-for-pixel. Without this, the axis lived inside the
                // same horizontally-scrolling SizedBox as the bars, so
                // scrolling - now automatic, to center today's bar - dragged
                // the labels off-screen along with it instead of leaving
                // them pinned while only the bars scroll underneath.
                SizedBox(
                  width: 42,
                  child: BarChart(
                    BarChartData(
                      maxY: chartMax,
                      minY: chartMin,
                      groupsSpace: 22,
                      barGroups: const [],
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
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: yInterval,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
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
                        bottomTitles: AxisTitles(),
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
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
                                titlesData: FlTitlesData(
                                  // Drawn by the fixed axis column to the
                                  // left instead - showing it here too would
                                  // duplicate the labels and scroll them
                                  // with the bars.
                                  leftTitles: AxisTitles(),
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
                                barGroups: List.generate(values.length, (
                                  index,
                                ) {
                                  final hasBarData = values[index] > 0;
                                  final isHighlighted =
                                      hasBarData &&
                                      (widget.currentIndex >= 0
                                          ? index == widget.currentIndex
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
          ),
        ],
      ),
    );
  }

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
