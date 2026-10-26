import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Calorie intake bars - built on fl_chart's BarChart (same as BmiChart),
/// so tapping a bar shows its value in the same default tooltip bubble BMI
/// already has. The whole chart (bars + its own left-axis scale) lives in
/// one horizontally-scrolling area, same structure as BmiChart - that also
/// fixes bars sitting oddly centered/right when there are only one or two
/// of them, since fl_chart lays groups out left-anchored instead of the
/// old Row(mainAxisAlignment: spaceEvenly) stretching a handful of bars
/// across the full available width.
class CalorieIntakeContainer extends StatefulWidget {
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
  State<CalorieIntakeContainer> createState() => _CalorieIntakeContainerState();
}

class _CalorieIntakeContainerState extends State<CalorieIntakeContainer> {
  List<CalorieDataPoint> get data => widget.data;
  int get plannedCalories => widget.plannedCalories;
  int get currentIndex => widget.currentIndex;

  // fl_chart's built-in tooltip only lives while a finger is down on the bar
  // (it clears on tap-up on mobile), so a plain tap showed nothing. Keep the
  // tapped bar selected ourselves; tap it again or empty space to clear.
  int? _selectedIndex;

  final ScrollController _scroll = ScrollController();

  // fl_chart lays bars out left-anchored after the 36dp axis column: each is
  // a 10dp rod plus the 18dp groupsSpace.
  static const double _axisWidth = 36;
  static const double _barStep = 28;
  static const double _rodWidth = 10;

  @override
  void initState() {
    super.initState();
    _scheduleCenter();
  }

  @override
  void didUpdateWidget(covariant CalorieIntakeContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _selectedIndex = null;
      _scheduleCenter();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Today's bar (the backend's currentIndex, else the last bar) is scrolled
  // to the middle of the viewport; clamped when there aren't enough bars
  // either side to centre it.
  void _scheduleCenter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || data.isEmpty) return;
      final index = currentIndex >= 0 && currentIndex < data.length
          ? currentIndex
          : data.length - 1;
      final barCenter = _axisWidth + _rodWidth / 2 + index * _barStep;
      final viewport = _scroll.position.viewportDimension;
      _scroll.jumpTo(
        (barCenter - viewport / 2).clamp(0.0, _scroll.position.maxScrollExtent),
      );
    });
  }

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
    // Headroom above the tallest bar: the tap tooltip is drawn above its
    // bar, and the tallest bar used to reach the chart's top edge, so the
    // tooltip (and the top axis label) got clipped away.
    final axisMax = chartMax + scaleStep * 0.7;

    return SizedBox(
      height: 180,
      // Without an explicit width, this shrink-wraps to its (possibly
      // narrow, single-bar) content - and the ambient Column in
      // progress_view.dart around this widget uses the default
      // CrossAxisAlignment.center, so a shrunk box gets centered instead
      // of sitting flush against the left edge like the axis/bars should.
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
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: data.length * 56,
                child: BarChart(
                  BarChartData(
                    maxY: axisMax,
                    minY: 0,
                    alignment: BarChartAlignment.start,
                    groupsSpace: 18,
                    barTouchData: BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: false,
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;
                        final tapped = response?.spot?.touchedBarGroupIndex;
                        setState(() {
                          _selectedIndex = tapped == _selectedIndex
                              ? null
                              : tapped;
                        });
                      },
                      touchExtraThreshold: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xff530630),
                        fitInsideVertically: true,
                        fitInsideHorizontally: true,
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
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= data.length) {
                              return const SizedBox.shrink();
                            }
                            final isHighlighted = currentIndex >= 0
                                ? index == currentIndex
                                : index == 0;
                            final color = isHighlighted
                                ? const Color(0xffF670CA)
                                : const Color(0xff94A3B8);
                            // Daily/weekly labels are "28 Jul" - split into
                            // a day line and a month line so they don't run
                            // into each other when several bars are shown
                            // side by side. Monthly labels are a single
                            // word ("Jul") and just render on the top line.
                            final parts = data[index].label.split(' ');
                            final topLine = parts.first;
                            final bottomLine = parts.length > 1
                                ? parts.skip(1).join(' ')
                                : '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    text: topLine,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                  if (bottomLine.isNotEmpty)
                                    CustomText(
                                      text: bottomLine,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w400,
                                      color: color,
                                    ),
                                ],
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
                      final isOverPlanned =
                          point.calories > point.plannedCalories;

                      final showing = _selectedIndex == index
                          ? const [0]
                          : const <int>[];

                      if (!hasData) {
                        return BarChartGroupData(
                          x: index,
                          showingTooltipIndicators: showing,
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
                        showingTooltipIndicators: showing,
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
