import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Weight trend line - built on fl_chart's LineChart (same library BMI's
/// bar chart uses) so tapping a point shows its value in the same default
/// tooltip bubble BMI already has, instead of being a purely decorative,
/// untappable custom painting.
class TargetWeightChart extends StatelessWidget {
  final List<WeightDataPoint> weightData;

  const TargetWeightChart({super.key, required this.weightData});

  @override
  Widget build(BuildContext context) {
    final nonZeroData = weightData.where((e) => e.weight > 0).toList();
    if (nonZeroData.isEmpty) {
      return const SizedBox(
        height: 125,
        child: Center(child: Text('No weight data available')),
      );
    }

    return _WeightLineChart(
      values: nonZeroData.map((e) => e.weight).toList(),
    );
  }
}

/// Legacy support: accepts List<double> directly
class TargetWeightChartFromValues extends StatelessWidget {
  final List<double> values;

  const TargetWeightChartFromValues({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(
        height: 125,
        child: Center(child: Text('No weight data available')),
      );
    }
    return _WeightLineChart(values: values);
  }
}

class _WeightLineChart extends StatelessWidget {
  final List<double> values;

  const _WeightLineChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    // Half-unit padding on both axes so a single point sits centered
    // vertically instead of pinned to the container's top/bottom.
    final minY = minVal - (maxVal - minVal < 1 ? 1 : (maxVal - minVal) * 0.2) - 0.5;
    final maxY = maxVal + (maxVal - minVal < 1 ? 1 : (maxVal - minVal) * 0.2) + 0.5;

    return Container(
      height: 125,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white,
            Color.fromARGB(97, 255, 227, 242),
          ],
        ),
      ),
      child: LineChart(
        LineChartData(
          // 0-anchored (not padded/centered) so a single reading sits at
          // the chart's left edge, same as every other chart's first bar -
          // not floating in the middle with nothing to its left or right.
          minX: 0,
          maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1,
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots
                  .map(
                    (spot) => LineTooltipItem(
                      spot.y.toStringAsFixed(1),
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: const Color(0xffEF45B2),
              barWidth: 1.4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xffEF45B2).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
