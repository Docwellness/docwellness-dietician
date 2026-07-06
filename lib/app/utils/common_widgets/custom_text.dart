import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomText extends StatelessWidget {
  final String text;
  final FontWeight fontWeight;
  final double fontSize;
  final Color color;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextAlign? textAlign;
  final double ?height;

  const CustomText({
    super.key,
    required this.text,
    required this.fontWeight,
    required this.fontSize,
    required this.color,
    this.overflow,
    this.maxLines,
    this.textAlign,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      
      style: GoogleFonts.roboto(
        height: height,
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
      ),
    );
  }
}
