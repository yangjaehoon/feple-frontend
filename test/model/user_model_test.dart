import 'package:feple/model/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser.fromJson', () {
    test('ageVerificationRequired 필드를 파싱한다', () {
      final user = AppUser.fromJson({
        'id': 1,
        'nickname': 'tester',
        'ageVerificationRequired': true,
      });

      expect(user.ageVerificationRequired, isTrue);
    });

    test('ageVerificationRequired 키가 없으면 false로 폴백한다', () {
      final user = AppUser.fromJson({'id': 1, 'nickname': 'tester'});

      expect(user.ageVerificationRequired, isFalse);
    });

    test('toJson → fromJson 라운드트립에서 플래그가 보존된다', () {
      final original = AppUser(
        id: 7,
        nickname: 'tester',
        ageVerificationRequired: true,
      );

      final restored = AppUser.fromJson(original.toJson());

      expect(restored.ageVerificationRequired, isTrue);
    });
  });

  group('AppUser.copyWith', () {
    test('ageVerificationRequired만 바꾸고 나머지는 유지한다', () {
      final user = AppUser(
        id: 3,
        nickname: 'tester',
        bio: 'hi',
        level: 'LV1',
        ageVerificationRequired: true,
      );

      final updated = user.copyWith(ageVerificationRequired: false);

      expect(updated.ageVerificationRequired, isFalse);
      expect(updated.id, 3);
      expect(updated.nickname, 'tester');
      expect(updated.bio, 'hi');
      expect(updated.level, 'LV1');
    });

    test('인자를 주지 않으면 기존 값을 유지한다', () {
      final user = AppUser(id: 1, ageVerificationRequired: true);

      expect(user.copyWith().ageVerificationRequired, isTrue);
    });
  });
}
