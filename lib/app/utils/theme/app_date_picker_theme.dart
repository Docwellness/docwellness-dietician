import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Applied once via ThemeData.datePickerTheme in main.dart, so every
// showDatePicker() call in the app is branded consistently without each
// call site needing to opt in individually.
const _primary = Color(0xff530630);
const _accent = Color(0xff851653);
const _bgLight = Color(0xffFEF6FB);
const _selectedChip = Color(0xffFCCEEF);
const _headerText = Color(0xff1F2A37);
const _bodyGray = Color(0xff4D5761);
const _mutedGray = Color(0xff6C737F);
const _divider = Color(0xffEAD4E8);

Color _dayForeground(Set<WidgetState> states) {
  if (states.contains(WidgetState.selected)) return Colors.white;
  if (states.contains(WidgetState.disabled)) return const Color(0xffD2D6DB);
  return _headerText;
}

Color _dayBackground(Set<WidgetState> states) {
  if (states.contains(WidgetState.selected)) return _accent;
  return Colors.transparent;
}

Color _hoverOverlay(Set<WidgetState> states) {
  if (states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.pressed) ||
      states.contains(WidgetState.focused)) {
    return _selectedChip;
  }
  return Colors.transparent;
}

Color _todayForeground(Set<WidgetState> states) {
  if (states.contains(WidgetState.selected)) return Colors.white;
  return _accent;
}

Color _todayBackground(Set<WidgetState> states) {
  if (states.contains(WidgetState.selected)) return _accent;
  return Colors.transparent;
}

Color _yearForeground(Set<WidgetState> states) {
  if (states.contains(WidgetState.selected)) return Colors.white;
  return _headerText;
}

Color _yearBackground(Set<WidgetState> states) {
  if (states.contains(WidgetState.selected)) return _accent;
  return Colors.transparent;
}

final DatePickerThemeData brandDatePickerTheme = DatePickerThemeData(
  backgroundColor: _bgLight,
  surfaceTintColor: Colors.transparent,
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  headerBackgroundColor: _primary,
  headerForegroundColor: Colors.white,
  headerHeadlineStyle: GoogleFonts.roboto(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
  headerHelpStyle: GoogleFonts.roboto(fontSize: 13, color: Colors.white70),
  weekdayStyle: GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: _mutedGray,
  ),
  dayStyle: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w400),
  dayForegroundColor: WidgetStateProperty.resolveWith(_dayForeground),
  dayBackgroundColor: WidgetStateProperty.resolveWith(_dayBackground),
  dayOverlayColor: WidgetStateProperty.resolveWith(_hoverOverlay),
  todayForegroundColor: WidgetStateProperty.resolveWith(_todayForeground),
  todayBackgroundColor: WidgetStateProperty.resolveWith(_todayBackground),
  todayBorder: const BorderSide(color: _accent, width: 1),
  yearStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400),
  yearForegroundColor: WidgetStateProperty.resolveWith(_yearForeground),
  yearBackgroundColor: WidgetStateProperty.resolveWith(_yearBackground),
  yearOverlayColor: WidgetStateProperty.resolveWith(_hoverOverlay),
  rangePickerBackgroundColor: _bgLight,
  rangePickerHeaderBackgroundColor: _primary,
  rangePickerHeaderForegroundColor: Colors.white,
  rangeSelectionBackgroundColor: _selectedChip,
  dividerColor: _divider,
  confirmButtonStyle: TextButton.styleFrom(foregroundColor: _primary),
  cancelButtonStyle: TextButton.styleFrom(foregroundColor: _bodyGray),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _accent, width: 1.5),
    ),
  ),
);
