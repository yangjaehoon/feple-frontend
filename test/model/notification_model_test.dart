import 'package:feple/model/notification_model.dart';
import 'package:feple/screen/notification/notification_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('모든 필드 정상 파싱', () {
      final json = {
        'id': 1,
        'type': 'CERT_APPROVED',
        'title': '인증이 승인됐어요!',
        'body': '록페스티벌 인증이 승인됐습니다.',
        'referenceId': 42,
        'read': false,
        'createdAt': '2025-05-01T10:00:00',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 1);
      expect(model.type, NotificationType.certApproved);
      expect(model.title, '인증이 승인됐어요!');
      expect(model.body, '록페스티벌 인증이 승인됐습니다.');
      expect(model.referenceId, 42);
      expect(model.read, false);
      expect(model.createdAt, '2025-05-01T10:00:00');
    });

    test('referenceId null이어도 파싱 성공', () {
      final json = {
        'id': 2,
        'type': 'NEW_COMMENT',
        'title': '댓글',
        'body': '본문',
        'referenceId': null,
        'read': true,
        'createdAt': null,
      };

      final model = NotificationModel.fromJson(json);

      expect(model.referenceId, isNull);
      expect(model.createdAt, isNull);
      expect(model.read, true);
    });

    test('알 수 없는 type은 null로 처리', () {
      final json = {
        'id': 3,
        'type': 'UNKNOWN_TYPE',
        'title': '제목',
        'body': '본문',
        'read': false,
      };

      final model = NotificationModel.fromJson(json);

      expect(model.type, isNull);
    });

    test('type null이어도 파싱 성공', () {
      final json = {
        'id': 4,
        'type': null,
        'title': '제목',
        'body': '본문',
        'read': false,
      };

      final model = NotificationModel.fromJson(json);

      expect(model.type, isNull);
    });

    test('모든 NotificationType 값 파싱', () {
      final cases = {
        'NEW_FESTIVAL': NotificationType.newFestival,
        'CERT_APPROVED': NotificationType.certApproved,
        'CERT_REJECTED': NotificationType.certRejected,
        'NEW_COMMENT': NotificationType.newComment,
        'FESTIVAL_REMINDER': NotificationType.festivalReminder,
      };

      for (final entry in cases.entries) {
        final model = NotificationModel.fromJson({
          'id': 1,
          'type': entry.key,
          'title': '',
          'body': '',
          'read': false,
        });
        expect(model.type, entry.value, reason: '${entry.key} 파싱 실패');
      }
    });
  });

  group('NotificationModel.copyWithRead', () {
    test('read만 true로 바뀌고 나머지는 유지', () {
      final original = NotificationModel(
        id: 10,
        type: NotificationType.certApproved,
        title: '원본 제목',
        body: '원본 본문',
        referenceId: 99,
        read: false,
        createdAt: '2025-01-01',
      );

      final updated = original.copyWithRead();

      expect(updated.read, true);
      expect(updated.id, 10);
      expect(updated.type, NotificationType.certApproved);
      expect(updated.title, '원본 제목');
      expect(updated.body, '원본 본문');
      expect(updated.referenceId, 99);
      expect(updated.createdAt, '2025-01-01');
    });

    test('원본 객체는 변경되지 않음', () {
      final original = NotificationModel(
        id: 1, type: null, title: '', body: '', read: false,
      );

      original.copyWithRead();

      expect(original.read, false);
    });
  });

  group('NotificationType.isFestivalType', () {
    test('NEW_FESTIVAL은 페스티벌 타입', () {
      expect(NotificationType.newFestival.isFestivalType, true);
    });

    test('FESTIVAL_REMINDER는 페스티벌 타입', () {
      expect(NotificationType.festivalReminder.isFestivalType, true);
    });

    test('CERT_APPROVED는 페스티벌 타입 아님', () {
      expect(NotificationType.certApproved.isFestivalType, false);
    });

    test('CERT_REJECTED는 페스티벌 타입 아님', () {
      expect(NotificationType.certRejected.isFestivalType, false);
    });

    test('NEW_COMMENT는 페스티벌 타입 아님', () {
      expect(NotificationType.newComment.isFestivalType, false);
    });
  });
}
