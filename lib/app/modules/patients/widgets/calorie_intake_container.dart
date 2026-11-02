import 'dart:math' as math;

import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// The tap tooltip's lines for a day's bar: `N kcal`, then the day
/// ("5 Oct"), then that day's target ("Target 1800 kcal") when it has one and
/// "N kcal over" when the day went past it. A day with nothing logged reads
/// "Not logged" then the day. A day with no target shows no target lines. An
/// older backend sends weekly or monthly bars; their `dateRange` is shown as
/// is, and a payload without `dateRange` shows the kcal only.
@visibleForTesting
List<String> calorieTooltipLines(CalorieDataPoint point) {
  final notLogged = point.daysLogged == 0;
  final headline = notLogged ? 'Not logged' : '${point.calories} kcal';
  final range = point.dateRange;
  final lines = [headline];
  if (range != null && range.isNotEmpty) {
    final ends = range.split(' - ');
    lines.add(ends.length == 2 && ends[0] == ends[1] ? ends[0] : range);
  }
  if (point.hasTarget) {
    lines.add('Target ${point.plannedCalories} kcal');
    final over = point.calories - point.plannedCalories;
    if (over > 0) lines.add('$over kcal over');
  }
  return lines;
}

/// Calorie intake bars - one bar per day, built on fl_chart's BarChart (same
/// as BmiChart), so tapping a bar shows its value in a tooltip bubble. The
/// bars scroll sideways and open on the latest day; the value axis is a
/// separate pinned column so the scale stays readable while scrolled.
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

  // One bar slot: a 10dp rod plus the 18dp groupsSpace. fl_chart lays the
  // bars out left-anchored.
  static const double _barStep = 28;
  static const double _rodWidth = 10;
  static const double _endPadding = 8;
  static const double _axisWidth = 36;
  static const double _chartHeight = 180;
  static const double _labelReserve = 34;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToEnd();
  }

  @override
  void didUpdateWidget(covariant CalorieIntakeContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _selectedIndex = null;
      _scheduleScrollToEnd();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Opens on the most recent day, at the right edge of the scroll area.
  void _scheduleScrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients || data.isEmpty) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
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

    return Semantics(
      container: true,
      label: 'Calorie intake, ${data.length} days, scrolls sideways',
      child: SizedBox(
        height: _chartHeight,
        // Without an explicit width, this shrink-wraps to its (possibly
        // narrow, single-bar) content - and the ambient Column around this
        // widget uses the default CrossAxisAlignment.center, so a shrunk box
        // gets centered instead of sitting flush against the left edge like
        // the axis/bars should.
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
            : Row(
                children: [
                  SizedBox(
                    width: _axisWidth,
                    child: _buildValueAxis(scaleStep, axisMax),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // At least the viewport, so one or two bars stay
                        // left-anchored instead of the chart shrinking.
                        final contentWidth = math.max(
                          constraints.maxWidth,
                          data.length * _barStep + _endPadding,
                        );
                        return SingleChildScrollView(
                          controller: _scroll,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: contentWidth,
                            child: _buildBars(scaleStep, chartMax, axisMax),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // The kcal scale, drawn by a bar-less chart with the same maxY and bottom
  // reserve as the bars so its labels line up with the bars' grid lines.
  Widget _buildValueAxis(int scaleStep, double axisMax) {
    return BarChart(
      BarChartData(
        maxY: axisMax,
        minY: 0,
        barGroups: const [],
        barTouchData: BarTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: scaleStep.toDouble(),
              reservedSize: _axisWidth,
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
          // Empty, but it reserves the same bottom space as the day labels.
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _labelReserve,
              getTitlesWidget: (value, meta) => const SizedBox.shrink(),
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
      ),
    );
  }

  Widget _buildBars(int scaleStep, double chartMax, double axisMax) {
    return BarChart(
      BarChartData(
        maxY: axisMax,
        minY: 0,
        alignment: BarChartAlignment.start,
        groupsSpace: _barStep - _rodWidth,
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            final tapped = response?.spot?.touchedBarGroupIndex;
            setState(() {
              _selectedIndex = tapped == _selectedIndex ? null : tapped;
            });
          },
          // About 46dp wide tap target around the 10dp rod.
          touchExtraThreshold: const EdgeInsets.symmetric(horizontal: 18),
          allowTouchBarBackDraw: true,
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
              final lines = calorieTooltipLines(data[groupIndex]);
              return BarTooltipItem(
                lines.first,
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  for (final line in lines.skip(1))
                    TextSpan(
                      text: '\n$line',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
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
          // The value axis is the pinned column beside the scroll area.
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: _labelReserve,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                // No today bar (-1: the range ended before today, or an older
                // backend) means nothing is highlighted.
                final isHighlighted = index == currentIndex;
                final color = isHighlighted
                    ? const Color(0xffF670CA)
                    : const Color(0xff94A3B8);
                // Day labels are "28 Jul" - split into a day line and a
                // month line so neighbouring bars don't run into each
                // other. A single-word label (an older backend's monthly
                // bar, "Jul") just renders on the top line.
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
              point.hasTarget && point.calories > point.plannedCalories;

          final showing = _selectedIndex == index ? const [0] : const <int>[];

          if (!hasData) {
            return BarChartGroupData(
              x: index,
              showingTooltipIndicators: showing,
              barRods: [
                BarChartRodData(
                  toY: chartMax * 0.02,
                  width: _rodWidth,
                  borderRadius: BorderRadius.circular(20),
                  color: _noDataColor,
                  // The stub is too small to tap, so a transparent full-height
                  // rod behind it (hit-tested through allowTouchBarBackDraw)
                  // makes the whole day column tappable without drawing.
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: chartMax,
                    color: Colors.transparent,
                  ),
                ),
              ],
            );
          }

          // No target that day: a plain bar of what was eaten, nothing to
          // judge it against. Over-planned: bar height = actual consumed,
          // with the amount over plan stacked on top of the on-plan portion.
          // Under/at-planned: bar height = the planned target, with how much
          // was actually consumed stacked below the remaining portion.
          final rodTop = !point.hasTarget || isOverPlanned
              ? point.calories.toDouble()
              : point.plannedCalories.toDouble();
          final stackItems = !point.hasTarget
              ? [
                  BarChartRodStackItem(
                    0,
                    point.calories.toDouble(),
                    _consumedColor,
                  ),
                ]
              : isOverPlanned
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
                width: _rodWidth,
                borderRadius: BorderRadius.circular(20),
                rodStackItems: stackItems,
              ),
            ],
          );
        }),
      ),
    );
  }
}
