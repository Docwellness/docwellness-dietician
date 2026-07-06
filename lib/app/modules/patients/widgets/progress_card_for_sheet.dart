import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  final int intake;
  final int remaining;
  final int exercise;
  final int totalPlanned;
  final double carbsConsumed;
  final double carbsPlanned;
  final double proteinConsumed;
  final double proteinPlanned;
  final double fiberConsumed;
  final double fiberPlanned;
  final double fatConsumed;
  final double fatPlanned;

  const ProgressCard({
    super.key,
    this.intake = 0,
    this.remaining = 0,
    this.exercise = 0,
    this.totalPlanned = 0,
    this.carbsConsumed = 0,
    this.carbsPlanned = 0,
    this.proteinConsumed = 0,
    this.proteinPlanned = 0,
    this.fiberConsumed = 0,
    this.fiberPlanned = 0,
    this.fatConsumed = 0,
    this.fatPlanned = 0,
  });

  @override
  Widget build(BuildContext context) {
    final double progressValue = totalPlanned > 0
        ? (intake / totalPlanned).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xffFDF2FA)),
        color: const Color(0xffFEF6FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ---------- HEADER ----------
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xffFCCEEF),
                  borderRadius: BorderRadius.circular(64),
                ),
                child: Center(
                  child: Icon(
                    Icons.trending_up,
                    color: Color(0xff9F1561),
                    size: 21,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Your progress",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff530630),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          /// ---------- MIDDLE SECTION (CALORIES + CIRCLE) ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// LEFT INTAKE
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      text: "Intake",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff530630),
                    ),
                    CustomText(
                      text: "$intake",
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff530630),
                    ),
                  ],
                ),

                _CircularProgress(value: progressValue, calories: remaining),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      text: "Exercise",

                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff530630),
                    ),
                    CustomText(
                      text: "$exercise",

                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff530630),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: CustomHorizontalIndicator(
                    subTitle:
                        '${carbsConsumed.round()}/${carbsPlanned.round()}g',
                    title: "Net Carbs",
                    progress: carbsPlanned > 0
                        ? (carbsConsumed / carbsPlanned).clamp(0.0, 1.0)
                        : 0.0,
                  ),
                ),
                SizedBox(width: 58),
                Expanded(
                  child: CustomHorizontalIndicator(
                    subTitle:
                        '${proteinConsumed.round()}/${proteinPlanned.round()}g',
                    title: "Protein",
                    progress: proteinPlanned > 0
                        ? (proteinConsumed / proteinPlanned).clamp(0.0, 1.0)
                        : 0.0,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: CustomHorizontalIndicator(
                    subTitle:
                        '${fiberConsumed.round()}/${fiberPlanned.round()}g',
                    title: "Fiber",
                    progress: fiberPlanned > 0
                        ? (fiberConsumed / fiberPlanned).clamp(0.0, 1.0)
                        : 0.0,
                  ),
                ),
                SizedBox(width: 58),
                Expanded(
                  child: CustomHorizontalIndicator(
                    subTitle: '${fatConsumed.round()}/${fatPlanned.round()}g',
                    title: "Fat",
                    progress: fatPlanned > 0
                        ? (fatConsumed / fatPlanned).clamp(0.0, 1.0)
                        : 0.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// ---------- CIRCULAR PROGRESS WIDGET ----------
class _CircularProgress extends StatelessWidget {
  final double value;
  final int calories;

  const _CircularProgress({required this.value, required this.calories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(120, 120),
            painter: _FullCirclePainter(
              progress: value,
              backgroundColor: const Color(0xffFCE7F6),
              progressColor: const Color(0xffDE2493),
              strokeWidth: 16,
            ),
          ),

          /// Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: "$calories",
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xff530630),
              ),
              CustomText(
                text: "calories",
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xff530630),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ------------------ FULL 360° ROUND CIRCLE ------------------

class _FullCirclePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _FullCirclePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    /// Background ring (full circle)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // <-- Rounded edges

    canvas.drawArc(rect, 0, 2 * 3.1415926535, false, bgPaint);

    /// Progress ring (full circle based on progress)
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -3.14 / 2,
      (2 * 3.1415926535) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CustomHorizontalIndicator extends StatelessWidget {
  final double progress;
  final String title;
  final String subTitle;

  const CustomHorizontalIndicator({
    super.key,
    required this.progress,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: title,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Color(0xff530630),
        ),
        const SizedBox(height: 8),

        // --- PROGRESS BAR ---
        Row(
          children: [
            // Dark side (progress)
            Expanded(
              flex: (progress * 100).toInt(),
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xff530630),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Light side (remaining)
            Expanded(
              flex: ((1 - progress) * 100).toInt(),
              child: Container(
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xffFCCEEF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        CustomText(
          text: subTitle,
          fontWeight: FontWeight.w400,
          fontSize: 10,
          color: Color(0xff9DA4AE),
        ),
      ],
    );
  }
}
