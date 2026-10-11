import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Weight trend as a stock-style line chart: y-axis in kg, dated x-axis,
/// light grid, a solid line + dots for the patient's logged weigh-ins, a
/// dashed line for the dietician's planned trend, an optional target line,
/// and a touch tooltip with date + planned + logged values. A stat strip
/// above it gives the numbers at a glance (latest, change, target).
class TargetWeightChart extends StatelessWidget {
  final List<WeightDataPoint> weightData;
  final double? targetWeight;

  /// Weight at onboarding / plan start. Anchors the logged line at the
  /// chart's first date so it runs start -> latest instead of floating as a
  /// lone dot when only one weigh-in has been logged since.
  final double? startWeight;

  const TargetWeightChart({
    super.key,
    required this.weightData,
    this.targetWeight,
    this.startWeight,
  });

  static const _logged = Color(0xffD81B8C);
  static const _planned = Color(0xff9F1561);
  static const _target = Color(0xff1F8A5B);
  static const _ink = Color(0xff530630);
  static const _muted = Color(0xff6C737F);
  static const _grid = Color(0xffF2D9E8);

  @override
  Widget build(BuildContext context) {
    final points = weightData.where((e) => e.weight > 0).toList();
    if (points.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No weight data available')),
      );
    }

    final plannedSpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].weight),
    ];
    final loggedSpots = [
      for (var i = 0; i < points.length; i++)
        if (points[i].measuredWeight != null)
          FlSpot(i.toDouble(), points[i].measuredWeight!),
    ];
    final start = (startWeight != null && startWeight! > 0) ? startWeight : null;
    final anchorsStart =
        start != null && loggedSpots.isNotEmpty && loggedSpots.first.x > 0;
    if (anchorsStart) loggedSpots.insert(0, FlSpot(0, start));
    final hasLogged = loggedSpots.isNotEmpty;
    final target = (targetWeight != null && targetWeight! > 0)
        ? targetWeight
        : null;

    final all = [
      ...plannedSpots.map((s) => s.y),
      ...loggedSpots.map((s) => s.y),
      ?target,
    ];
    final lo = all.reduce((a, b) => a < b ? a : b);
    final hi = all.reduce((a, b) => a > b ? a : b);
    // Round the axis to whole kg with a little headroom, 4 gridlines.
    final span = (hi - lo) < 2 ? 2.0 : (hi - lo);
    final minY = (lo - span * 0.15).floorToDouble();
    final maxY = (hi + span * 0.15).ceilToDouble();
    final interval = ((maxY - minY) / 4).ceilToDouble().clamp(1, 1000).toDouble();

    final maxX = points.length > 1 ? (points.length - 1).toDouble() : 1.0;
    // ~4 evenly spread date labels, always including first and last.
    final labelStep = points.length <= 5 ? 1 : ((points.length - 1) / 4).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: _grid,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: interval,
                    getTitlesWidget: (v, meta) {
                      if (v == meta.min || v == meta.max) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10, color: _muted),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      final i = v.round();
                      if ((v - i).abs() > 0.01 ||
                          i < 0 ||
                          i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final isEdge = i == 0 || i == points.length - 1;
                      if (!isEdge && i % labelStep != 0) {
                        return const SizedBox.shrink();
                      }
                      // Drop a middle label that would crowd the last one.
                      if (!isEdge &&
                          (points.length - 1 - i) < labelStep / 2) {
                        return const SizedBox.shrink();
                      }
                      // fitInside nudges the first/last label back inside the
                      // chart so they never poke past the page margins.
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                        child: Text(
                          points[i].label,
                          style: const TextStyle(fontSize: 10, color: _muted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (target != null)
                    HorizontalLine(
                      y: target,
                      color: _target.withValues(alpha: 0.7),
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _target,
                        ),
                        labelResolver: (_) => 'Target',
                      ),
                    ),
                ],
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => _ink,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touched) {
                    // One tooltip per touched bar; only the first carries the
                    // combined text so planned/logged don't render twice.
                    return [
                      for (var k = 0; k < touched.length; k++)
                        if (k == 0)
                          _tooltip(points[touched[k].x.round()], isStart: anchorsStart && touched[k].x == 0)
                        else
                          null,
                    ];
                  },
                ),
              ),
              lineBarsData: [
                // Planned trend: always dotted, so it reads as a guide and
                // only the real (logged) readings are a solid line.
                LineChartBarData(
                  spots: plannedSpots,
                  isCurved: false,
                  color: _planned,
                  barWidth: 2.2,
                  isStrokeCapRound: true,
                  dashArray: [1, 5],
                  dotData: const FlDotData(show: false),
                ),
                if (hasLogged)
                  LineChartBarData(
                    spots: loggedSpots,
                    isCurved: loggedSpots.length > 2,
                    curveSmoothness: 0.15,
                    preventCurveOverShooting: true,
                    color: _logged,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: i == loggedSpots.length - 1 ? 5 : 3.5,
                        color: Colors.white,
                        strokeWidth: 2.2,
                        strokeColor: _logged,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _logged.withValues(alpha: 0.22),
                          _logged.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 16,
          runSpacing: 4,
          children: [
            if (hasLogged) const _Legend(color: _logged, label: 'Logged'),
            const _Legend(color: _planned, label: 'Planned trend', dashed: true),
            if (target != null) const _Legend(color: _target, label: 'Target', dashed: true),
          ],
        ),
      ],
    );
  }

  LineTooltipItem _tooltip(WeightDataPoint p, {bool isStart = false}) {
    const base = TextStyle(color: Colors.white, fontSize: 11);
    return LineTooltipItem(
      '${p.label}\n',
      base.copyWith(fontWeight: FontWeight.w700),
      textAlign: TextAlign.left,
      children: [
        if (isStart && startWeight != null)
          TextSpan(
            text: 'Start  ${startWeight!.toStringAsFixed(1)} kg\n',
            style: base.copyWith(fontWeight: FontWeight.w600),
          )
        else if (p.measuredWeight != null)
          TextSpan(
            text: 'Logged  ${p.measuredWeight!.toStringAsFixed(1)} kg\n',
            style: base.copyWith(fontWeight: FontWeight.w600),
          ),
        TextSpan(
          text: 'Planned  ${p.weight.toStringAsFixed(1)} kg',
          style: base.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _Legend({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 3,
          child: dashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(width: 4, height: 2, color: color),
                  ],
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: TargetWeightChart._muted),
        ),
      ],
    );
  }
}
