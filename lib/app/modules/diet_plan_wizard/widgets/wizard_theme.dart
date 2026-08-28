import 'package:flutter/material.dart';

/// The diet plan wizard's shared visual language (openspec change
/// diet-wizard-portions-and-polish, capability
/// diet-plan-wizard/wizard-visual-language).
///
/// Direction: the professional counterpart to the patient app's Diet Plan
/// view - same DocWellness identity (`#530630` / `#851653`), but tighter and
/// more information-dense, with one signature structural device: the
/// [MealTimeline] rail. Every wizard screen (Generate review, Timeline &
/// Supplements, Review & Finalize) draws from this one token set and the
/// shared widgets in this folder rather than hand-rolling its own colours
/// and card styling.
class WizardPalette {
  WizardPalette._();

  /// Screen titles, primary buttons - unchanged brand plum.
  static const plum = Color(0xff530630);

  /// Actions, selected states, accents - unchanged brand magenta.
  static const magenta = Color(0xff851653);

  /// Body text.
  static const ink = Color(0xff1F2A37);

  /// Secondary text, meta lines, muted icons.
  static const muted = Color(0xff6C737F);

  /// Card fill - a touch warmer than a neutral grey so it sits with the
  /// pink tints instead of against them.
  static const surface = Color(0xffFBF7F9);

  /// Selected chips, summary panels.
  static const tint = Color(0xffFDF2FA);

  /// Hairline rails, card borders, dividers - the timeline spine.
  static const line = Color(0xffEBD9E4);

  /// Calorie-check states.
  static const ok = Color(0xff12B76A);
  static const warn = Color(0xffDC2626);

  static const cardRadius = 14.0;
  static const pillRadius = 999.0;
}
