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
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isLoading == true
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
              : buttonColor ?? Color(0xff530630),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: isLoading == true
              ? CircularProgressIndicator(color: Color(0xff851653))
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
