import 'package:docwellnesdoc/app/utils/functions/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// Client-side password policy - mirrors
/// docwellness-backend/tests/passwordPolicy.test.js (minus the HIBP check).
void main() {
  group('validatePassword', () {
    test('accepts a strong password', () {
      expect(validatePassword('Correct-Horse-9Battery'), isNull);
      expect(validatePassword('lowerUPPER12345'), isNull); // exactly 3 classes
    });

    test('rejects empty / too short', () {
      expect(validatePassword(''), contains('enter a password'));
      expect(validatePassword('Ab1!x'), contains('at least 12'));
      expect(validatePassword('Abcdefghij1'), contains('at least 12')); // 11 chars
    });

    test('rejects fewer than 3 character classes', () {
      expect(validatePassword('alllowercaseletters'), contains('at least 3'));
      expect(validatePassword('nouppercase12345'), contains('at least 3'));
    });

    test('rejects a repeated short sequence', () {
      expect(validatePassword('Ab1!Ab1!Ab1!'), contains('repeating'));
      expect(validatePassword('AbC-AbC-AbC-AbC-'), contains('repeating'));
    });

    test('rejects a password containing the email local-part', () {
      expect(
        validatePassword('john.doe-Str0ng!', email: 'john.doe@example.com'),
        contains('email address'),
      );
    });

    test('rejects a password containing a name token', () {
      expect(
        validatePassword('Priya-is-Str0ng!', name: 'Priya Sharma'),
        contains('your name'),
      );
    });

    test('a <3 char name token is not matched', () {
      expect(validatePassword('AbXyZ-9-plenty', name: 'Al B'), isNull);
    });

    test('rejects longer than 128', () {
      expect(validatePassword('Aa1!${'x' * 130}'), contains('at most 128'));
    });
  });
}
