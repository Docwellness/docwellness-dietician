import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class PatientCard extends StatelessWidget {
  final List<double> values;
  final String totalPatientsText;
  final double changePercent;

  /// baseline between 0.0 (top) and 1.0 (bottom). 0.5 is center.
  final double baseline;

  const PatientCard({
    super.key,
    required this.values,
    this.baseline = 0.5,
    this.totalPatientsText = '0',
    this.changePercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: "Total patients",
            fontSize: 12,
            color: const Color(0xff4D5761),
            fontWeight: FontWeight.w500,
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              CustomText(
                text: totalPatientsText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xff020617),
              ),
              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffFDF2FA),
                  border: Border.all(color: const Color(0xffFCE7F6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      changePercent >= 0
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xffD60021),
                      size: 22,
                    ),
                    CustomText(
                      text: '${changePercent.abs().toStringAsFixed(1)}%',
                      fontSize: 10,
                      color: const Color(0xffD60021),
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart with baseline
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: RedLineChartPainter(values, baseline: baseline),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class RedLineChartPainter extends CustomPainter {
  final List<double> values;
  final double baseline; // 0..1 where 0 is top, 1 is bottom

  RedLineChartPainter(this.values, {this.baseline = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // --- dashed baseline paint ---
    final Paint dashedPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // draw dashed horizontal baseline
    final double yBaseline = baseline.clamp(0.0, 1.0) * size.height;
    const double dashWidth = 8;
    const double dashSpace = 6;
    double startX = 0;

    while (startX < size.width) {
      final double endX = (startX + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(startX, yBaseline),
        Offset(endX, yBaseline),
        dashedPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // --- red trend line paint ---
    final Paint redPaint = Paint()
      ..color = const Color(0xffff6660)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final int n = values.length;
    final double dx = n == 1 ? size.width : size.width / (n - 1);

    final Path path = Path();
    for (int i = 0; i < n; i++) {
      final double x = i * dx;
      final double v = values[i].clamp(0.0, 1.0);
      final double y = size.height - (v * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, redPaint);
  }

  @override
  bool shouldRepaint(covariant RedLineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.baseline != baseline;
  }
}
