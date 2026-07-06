import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DatePickerField extends StatefulWidget {
  final String? label;
  final TextEditingController controller;
  final Icon? prefixIcon;
  final Icon? suffixIcon;
  final Color? suffixIconColor;
  final String? Function(String?)? validator;
  final String? hintText;
  final Color? changeTextColor;
  final Color? changeBorderColor;

  const DatePickerField({
    super.key,
    this.label,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.hintText,
    this.suffixIconColor,
    this.changeBorderColor,
    this.changeTextColor,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  final FocusNode _focusNode = FocusNode();

  // We store listeners as functions so we can remove them later
  late VoidCallback _focusListener;
  late VoidCallback _controllerListener;

  @override
  void initState() {
    super.initState();

    _focusListener = () {
      if (mounted) setState(() {});
    };

    _controllerListener = () {
      if (mounted) setState(() {});
    };

    _focusNode.addListener(_focusListener);
    widget.controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusListener);
    widget.controller.removeListener(_controllerListener);

    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      widget.controller.text =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFocused = _focusNode.hasFocus;
    bool hasText = widget.controller.text.isNotEmpty;

    Color borderColor = (isFocused || hasText)
        ? const Color(0xff530630)
        : const Color(0xff6C737F);

    return TextFormField(
      validator: widget.validator,
      controller: widget.controller,
      readOnly: true,
      focusNode: _focusNode,
      onTap: _pickDate,
      style: GoogleFonts.roboto(
        color: widget.changeTextColor ?? Color(0xff530630),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        label: (isFocused || hasText)
            ? widget.label != null
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
                        text: widget.label!,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                        color: const Color(0xff851653),
                      ),
                    )
                  : null
            : widget.label == null
            ? null
            : Text(
                widget.label!,
                style: const TextStyle(fontSize: 13, color: Color(0xff4D5761)),
              ),
        hintText: widget.hintText,
        hintStyle: GoogleFonts.roboto(
          color: const Color(0xff4D5761),
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: widget.changeBorderColor ?? borderColor,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: widget.changeBorderColor ?? borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: widget.changeBorderColor ?? borderColor,
          ),
        ),
        prefixIcon: widget.prefixIcon,
        suffixIconConstraints: const BoxConstraints(
          minHeight: 36,
          minWidth: 36,
          maxHeight: 36,
          maxWidth: 36,
        ),
        suffixIcon:
            widget.suffixIcon ??
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: SizedBox(
                child: Image.asset(
                  'assets/icons/Calendar.png',
                  color: widget.suffixIconColor,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
      ),
      onTapOutside: (event) => FocusScope.of(context).unfocus(),
    );
  }
}
