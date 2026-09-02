import 'package:get/get.dart';

/// The single email/phone form validators for the whole app. Every
/// `validator:` on an email or phone field routes through these so the
/// rules and messages can't drift apart across screens.

/// Form-field validator for an email address. Returns an error message, or
/// null when [value] is a non-empty, well-formed email.
String? validateEmail(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Please enter your email';
  if (!GetUtils.isEmail(v)) return 'Enter a valid email';
  return null;
}

/// Digit-count rule for a phone / WhatsApp number: 6-15 digits once
/// non-digit characters (spaces, +, -, country-code punctuation) are
/// stripped. Returns an error message, or null when it looks valid.
String? validatePhone(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Enter the number';
  final digits = v.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 6 || digits.length > 15) return 'Enter a valid number';
  return null;
}
