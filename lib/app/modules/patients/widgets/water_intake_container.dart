import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:docwellnesdoc/app/utils/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WaterIntakeContainer extends StatefulWidget {
  final double totalAmount;
  final double goal;

  const WaterIntakeContainer({
    super.key,
    this.totalAmount = 0.0,
    this.goal = 2500,
  });

  @override
  State<WaterIntakeContainer> createState() => _WaterIntakeContainerState();
}

class _WaterIntakeContainerState extends State<WaterIntakeContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _updateProgress();
  }

  @override
  void didUpdateWidget(covariant WaterIntakeContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount ||
        oldWidget.goal != widget.goal) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    final goalLiters = widget.goal > 0 ? widget.goal : 2500;
    _controller.value = (widget.totalAmount / goalLiters).clamp(0.0, 1.0);
  }

  double get _totalLiters => widget.totalAmount / 1000;
  double get _goalLiters => widget.goal / 1000;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffFEF6FB),
        border: cardBorder,
        borderRadius: BorderRadius.circular(16),
        boxShadow: cardShadow,
      ),
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            height: 52,
            width: 45,
            child: Lottie.asset(
              'assets/images/water animation.json',
              controller: _controller,
              fit: BoxFit.contain,
              delegates: LottieDelegates(
                values: [
                  ValueDelegate.color(const [
                    '**',
                  ], value: const Color(0xFFDE2493)),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Water Intake',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xff384250),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(0xffFCE7F6),
                        border: Border.all(color: Color(0xffEF45B2)),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: CustomText(
                          text: '${_totalLiters.toStringAsFixed(2)} Liter',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xff851653),
                        ),
                      ),
                    ),
                    CustomText(
                      text: ' of ${_goalLiters.toStringAsFixed(1)} Liter ',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Color(0xff6C737F),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
