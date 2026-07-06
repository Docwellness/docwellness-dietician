import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomPortionDropDown extends StatefulWidget {
  final String label;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final double? lableSize;
  final double? horizontalSpace;

  final Icon? prefixIcon;
  final Icon? suffixIcon;

  const CustomPortionDropDown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.lableSize,
    this.horizontalSpace,
  });

  @override
  State<CustomPortionDropDown> createState() => _CustomPortionDropDownState();
}

class _CustomPortionDropDownState extends State<CustomPortionDropDown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool isOpen = false;

  void openDropdown(FormFieldState<String> state) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 6),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: widget.items.map((item) {
                  return InkWell(
                    onTap: () {
                      widget.onChanged(item);
                      state.didChange(item);
                      closeDropdown();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        item,
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: const Color(0xff530630),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => isOpen = true);
  }

  void closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      builder: (state) {
        bool hasText = widget.value != null && widget.value!.isNotEmpty;
        bool isFocused = isOpen;

        Color borderColor = (isFocused || hasText)
            ? const Color(0xff530630)
            : const Color(0xff6C737F);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                onTap: () => isOpen ? closeDropdown() : openDropdown(state),
                child: InputDecorator(
                  isFocused: isFocused,
                  isEmpty: !hasText,

                  decoration: InputDecoration(
                    constraints: BoxConstraints(minHeight: 40, maxHeight: 40),
                    suffixIconConstraints: BoxConstraints(
                      minHeight: 30,
                      maxHeight: 30,
                      maxWidth: 30,
                      minWidth: 30,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isFocused || hasText ? 12 : 2,
                      vertical: 0,
                    ),

                    prefixIcon: widget.prefixIcon,
                    suffixIcon:
                        widget.suffixIcon ??
                        Icon(
                          isOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: const Color(0xff0D121C),
                        ),

                    // 🔥 SAME FLOATING LABEL AS YOUR OLD ONE
                    label: (isFocused || hasText)
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
                              text: widget.label,
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              color: const Color(0xff851653),
                            ),
                          )
                        : Text(
                            widget.label,
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff4D5761),
                            ),
                          ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),

                  child: Text(
                    widget.value ?? "",
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xff530630),
                    ),
                  ),
                ),
              ),
            ),

            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: Colors.red[900], fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
