import 'package:feple/common/util/password_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasMinLength', () {
    test('8자 미만이면 false', () {
      expect(PasswordValidator.hasMinLength('Abc1!xy'), false);
    });

    test('정확히 8자이면 true', () {
      expect(PasswordValidator.hasMinLength('Abc1!xyz'), true);
    });

    test('8자 초과이면 true', () {
      expect(PasswordValidator.hasMinLength('Abc1!xyzw'), true);
    });

    test('빈 문자열이면 false', () {
      expect(PasswordValidator.hasMinLength(''), false);
    });
  });

  group('hasUppercase', () {
    test('대문자 포함 시 true', () {
      expect(PasswordValidator.hasUppercase('abcDef'), true);
    });

    test('대문자 없으면 false', () {
      expect(PasswordValidator.hasUppercase('abcdef1!'), false);
    });

    test('대문자만이어도 true', () {
      expect(PasswordValidator.hasUppercase('ABC'), true);
    });
  });

  group('hasLowercase', () {
    test('소문자 포함 시 true', () {
      expect(PasswordValidator.hasLowercase('ABCdef'), true);
    });

    test('소문자 없으면 false', () {
      expect(PasswordValidator.hasLowercase('ABCDEF1!'), false);
    });
  });

  group('hasDigit', () {
    test('숫자 포함 시 true', () {
      expect(PasswordValidator.hasDigit('abc123'), true);
    });

    test('숫자 없으면 false', () {
      expect(PasswordValidator.hasDigit('abcDEF!'), false);
    });
  });

  group('hasSpecial', () {
    test('특수문자 포함 시 true', () {
      for (final ch in ['!', '@', '#', r'$', '%', '^', '&', '*', '(', ')',
          ',', '.', '?', '"', ':', '{', '}', '|', '<', '>']) {
        expect(PasswordValidator.hasSpecial('abc$ch'), true,
            reason: 'expected true for "$ch"');
      }
    });

    test('특수문자 없으면 false', () {
      expect(PasswordValidator.hasSpecial('abcDEF1'), false);
    });

    test('공백은 특수문자 아님', () {
      expect(PasswordValidator.hasSpecial('abc def'), false);
    });
  });

  group('validate — 순수 규칙 충족 여부 (i18n 없이 호출 가능한 부분)', () {
    test('모든 규칙 충족 시 null 반환 (유효)', () {
      // validate()는 .tr() 호출이 있어 i18n 없이 예외 발생.
      // 개별 규칙 함수로 조합하여 검증한다.
      const pw = 'Abcdef1!';
      expect(PasswordValidator.hasMinLength(pw), true);
      expect(PasswordValidator.hasUppercase(pw), true);
      expect(PasswordValidator.hasLowercase(pw), true);
      expect(PasswordValidator.hasDigit(pw), true);
      expect(PasswordValidator.hasSpecial(pw), true);
    });

    test('단 하나의 조건 누락 시 나머지는 충족', () {
      // 특수문자 누락
      const pw = 'Abcdef12';
      expect(PasswordValidator.hasMinLength(pw), true);
      expect(PasswordValidator.hasUppercase(pw), true);
      expect(PasswordValidator.hasLowercase(pw), true);
      expect(PasswordValidator.hasDigit(pw), true);
      expect(PasswordValidator.hasSpecial(pw), false);
    });

    test('maxLength(4096) 경계 — 4096자는 통과', () {
      final pw = 'A' * 4096;
      expect(pw.length > PasswordValidator.maxLength, false);
    });

    test('4097자는 maxLength 초과', () {
      final pw = 'A' * 4097;
      expect(pw.length > PasswordValidator.maxLength, true);
    });
  });
}
