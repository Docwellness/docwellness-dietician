import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final bool isOutline;
  final VoidCallback onTap;
  final double? fontSize;
  final Color? buttonColor;
  final Color? outlineButtonColor;
  final Color? textColor;
  final bool? isLoading;
  final bool isDisabled;

  const CustomButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.isOutline,
    this.buttonColor,
    this.fontSize,
    this.outlineButtonColor,
    this.textColor,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (isLoading == true || isDisabled)
          ? null
          : () {
              debugPrint('CustomButton tapped: $text');
              onTap();
            },
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: isOutline == true
                ? outlineButtonColor ?? Color(0xff530630)
                : Colors.transparent,
          ),
          color: isOutline == true
              ? Colors.transparent
              : (buttonColor ?? Color(0xff530630)).withValues(alpha: isDisabled ? 0.4 : 1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: isLoading == true
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isOutline == true
                        ? textColor ?? Color(0xff530630)
                        : Colors.white,
                  ),
                )
              : CustomText(
                  text: text,
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize ?? 16,
                  color: isOutline == true
                      ? textColor ?? Color(0xff530630)
                      : Colors.white,
                ),
        ),
      ),
    );
  }
}
