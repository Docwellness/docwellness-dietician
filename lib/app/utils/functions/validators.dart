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

const int kMinPasswordLength = 12;
const int kMaxPasswordLength = 128;

/// Client-side mirror of the backend password policy
/// (docwellness-backend/utils/passwordPolicy.js), minus the async HIBP
/// breach check the server also runs - so a password that passes here can
/// still be rejected with a "known data breach" message by the backend.
/// Keep the >=12 / 3-class / repeat rules and their wording in sync with
/// that file. Pass [email] (and [name] where known) so a password that
/// just echoes the user's identity is caught before submission too.
String? validatePassword(String? value, {String? email, String? name}) {
  final v = value ?? '';
  if (v.isEmpty) return 'Please enter a password';
  if (v.length < kMinPasswordLength) {
    return 'Password must be at least $kMinPasswordLength characters long';
  }
  if (v.length > kMaxPasswordLength) {
    return 'Password must be at most $kMaxPasswordLength characters long';
  }

  final classes = [
    RegExp(r'[a-z]'),
    RegExp(r'[A-Z]'),
    RegExp(r'[0-9]'),
    RegExp(r'[^A-Za-z0-9]'),
  ].where((re) => re.hasMatch(v)).length;
  if (classes < 3) {
    return 'Include at least 3 of: lowercase, uppercase, number, symbol';
  }

  if (RegExp(r'^(.{1,4})\1+$').hasMatch(v)) {
    return 'Avoid repeating a short sequence';
  }

  final lower = v.toLowerCase();

  final localPart = (email ?? '').split('@').first.toLowerCase();
  if (localPart.length >= 3 && lower.contains(localPart)) {
    return 'Password must not contain your email address';
  }

  if (name != null) {
    final parts = name
        .toLowerCase()
        .split(RegExp(r"[\s.,'-]+"))
        .where((p) => p.length >= 3);
    if (parts.any(lower.contains)) {
      return 'Password must not contain your name';
    }
  }

  return null;
}
