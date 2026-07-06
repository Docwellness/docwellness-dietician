import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomField extends StatefulWidget {
  final String? lable;
  final String? Function(String?)? validator;
  final void Function(String?)? onChange;

  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool? isPhoneNumber;
  final bool? hide;
  final String? hintText;
  final int? maxLines;
  final bool? changeBorderColor;
  final bool? isPoint;
  final bool? space;
  final bool? isPresent;
  final Color? changeTextColor;
  final bool? isDisable;

  const CustomField({
    super.key,
    this.validator,
    this.lable,
    required this.controller,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.isPhoneNumber = false,
    this.hide = false,
    this.hintText,
    this.maxLines,
    this.changeBorderColor = true,
    this.onChange,
    this.isPoint = false,
    this.space = true,
    this.isPresent = false,
    this.changeTextColor,
    this.isDisable = false,
  });

  @override
  State<CustomField> createState() => _CustomFieldState();
}

class _CustomFieldState extends State<CustomField> {
  final FocusNode _focusNode = FocusNode();

  late VoidCallback _controllerListener;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _controllerListener = () {
      if (mounted) setState(() {});
    };

    widget.controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _focusNode.dispose();

    widget.controller.removeListener(_controllerListener);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFocused = _focusNode.hasFocus;
    bool hasText = widget.controller.text.isNotEmpty;

    Color borderColor = (isFocused || hasText)
        ? widget.changeBorderColor == true
              ? const Color(0xff530630)
              : Color(0xff6C737F)
        : const Color(0xff6C737F);

    return TextFormField(
      readOnly: widget.isDisable ?? false,
      onChanged: widget.onChange,
      maxLines: widget.maxLines ?? 1,
      obscureText: widget.hide!,
      maxLength: widget.isPhoneNumber == true ? 15 : null,

      inputFormatters: [
        if (widget.keyboardType == TextInputType.phone)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
        if (widget.isPoint == true &&
            widget.keyboardType == TextInputType.number)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),

        if (widget.isPoint == false &&
            widget.keyboardType == TextInputType.number)
          FilteringTextInputFormatter.digitsOnly,
        if (widget.isPoint == false &&
            widget.keyboardType == TextInputType.text)
          FilteringTextInputFormatter.allow(RegExp(r'[a-z A-Z]')),
        if (widget.isPoint == false &&
            widget.keyboardType == TextInputType.emailAddress)
          FilteringTextInputFormatter.deny(' '),
        if (widget.space == false) FilteringTextInputFormatter.deny(' '),
      ],
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onTapOutside: (event) => FocusScope.of(context).unfocus(),
      cursorColor: Color(0xff530630),
      cursorErrorColor: Color(0xff530630),
      controller: widget.controller,

      style: GoogleFonts.roboto(
        color: widget.changeTextColor ?? const Color(0xff530630),
        fontWeight: FontWeight.w400,
        fontSize: 13,
      ),
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: GoogleFonts.roboto(
          color: const Color(0xff4D5761),
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        alignLabelWithHint: true,

        counterText: '',
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),

        label: (isFocused || hasText)
            ? widget.lable != null
                  ? Container(
                      height: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF6FB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: CustomText(
                        text: widget.lable!,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: const Color(0xff851653),
                      ),
                    )
                  : null
            : widget.lable == null
            ? null
            : Text(
                widget.lable!,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,

                  color: Color(0xff4D5761),
                ),
              ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            width: widget.isPresent == true ? 2 : 1,
            color: widget.isPresent == true ? Color(0xffB3261E) : borderColor,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            width: widget.isPresent == true ? 2 : 1,
            color: widget.isPresent == true ? Color(0xffB3261E) : borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            width: widget.isPresent == true ? 2 : 1,
            color: widget.isPresent == true ? Color(0xffB3261E) : borderColor,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            width: widget.isPresent == true ? 2 : 1,
            color: widget.isPresent == true ? Color(0xffB3261E) : borderColor,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            width: widget.isPresent == true ? 2 : 1,
            color: widget.isPresent == true ? Color(0xffB3261E) : borderColor,
          ),
        ),
        prefix: widget.prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 0),
                child: widget.prefixIcon,
              ),

        suffixIcon: widget.suffixIcon,
      ),
    );
  }
}
