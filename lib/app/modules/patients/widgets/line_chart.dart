import 'package:docwellnesdoc/app/models/tracking_data_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TargetWeightChart extends StatelessWidget {
  final List<WeightDataPoint> weightData;

  const TargetWeightChart({super.key, required this.weightData});

  @override
  Widget build(BuildContext context) {
    if (weightData.isEmpty) {
      return const SizedBox(
        height: 125,
        child: Center(child: Text('No weight data available')),
      );
    }

    // Only include non-zero weight points for the chart line
    final nonZeroData = weightData.where((e) => e.weight > 0).toList();
    if (nonZeroData.isEmpty) {
      return const SizedBox(
        height: 125,
        child: Center(child: Text('No weight data available')),
      );
    }

    final values = nonZeroData.map((e) => e.weight).toList();
    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );

    return Container(
      height: 125,
      width: double.infinity,
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
      child: CustomPaint(painter: ChartWithBarsPainter(spots)),
    );
  }
}

/// Legacy support: accepts List<double> directly
class TargetWeightChartFromValues extends StatelessWidget {
  final List<double> values;

  const TargetWeightChartFromValues({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );

    return Container(
      height: 125,
      width: double.infinity,
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
      child: CustomPaint(painter: ChartWithBarsPainter(spots)),
    );
  }
}

class ChartWithBarsPainter extends CustomPainter {
  final List<FlSpot> spots;
  ChartWithBarsPainter(this.spots);

  @override
  void paint(Canvas canvas, Size size) {
    if (spots.isEmpty) return;

    // Clip to bounds to prevent overflow
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    double minX = spots.first.x;
    double maxX = spots.last.x;
    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.5;
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.5;

    // Handle case where all values are the same
    if ((maxY - minY).abs() < 0.01) {
      minY = minY - 1;
      maxY = maxY + 1;
    }
    // Handle single point
    if ((maxX - minX).abs() < 0.01) {
      maxX = minX + 1;
    }

    // Convert spots to canvas coordinates
    List<Offset> points = spots.map((spot) {
      double px = (spot.x - minX) / (maxX - minX) * size.width;
      double py = size.height - ((spot.y - minY) / (maxY - minY) * size.height);
      return Offset(px, py);
    }).toList();

    // --------- 1️ Build clipped area under curve ----------
    Path areaPath = Path();
    areaPath.moveTo(points.first.dx, size.height);
    for (var p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();

    // --------- 2️⃣ Clip to area under the line ----------
    canvas.save();
    canvas.clipPath(areaPath);

    // --------- 3️⃣ Draw vertical white bars inside fill ----------
    Paint barPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2;

    double spacing = size.width / spots.length;
    for (int i = 0; i < spots.length; i++) {
      double x = i * spacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), barPaint);
    }

    canvas.restore();

    // --------- 4️⃣ Draw the main pink line on top ----------
    Paint linePaint = Paint()
      ..color = const Color(0xffEF45B2)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var p in points) {
      linePath.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(linePath, linePaint);

    // Restore the outer clip
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
