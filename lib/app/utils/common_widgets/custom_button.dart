import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
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
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  bool get _isActive => widget.isLoading != true && !widget.isDisabled;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: !_isActive
          ? null
          : () {
              debugPrint('CustomButton tapped: ${widget.text}');
              widget.onTap();
            },
      onTapDown: !_isActive ? null : (_) => _setPressed(true),
      onTapUp: !_isActive ? null : (_) => _setPressed(false),
      onTapCancel: !_isActive ? null : () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isOutline == true
                  ? widget.outlineButtonColor ?? Color(0xff530630)
                  : Colors.transparent,
            ),
            color: widget.isOutline == true
                ? Colors.transparent
                : (widget.buttonColor ?? Color(0xff530630))
                    .withValues(alpha: widget.isDisabled ? 0.4 : 1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: widget.isLoading == true
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: widget.isOutline == true
                          ? widget.textColor ?? Color(0xff530630)
                          : Colors.white,
                    ),
                  )
                : CustomText(
                    text: widget.text,
                    fontWeight: FontWeight.w500,
                    fontSize: widget.fontSize ?? 16,
                    color: widget.isOutline == true
                        ? widget.textColor ?? Color(0xff530630)
                        : Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}
