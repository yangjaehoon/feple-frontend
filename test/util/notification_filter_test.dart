import 'package:feple/model/notification_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationFilterApi.typeGroup', () {
    test('all은 null을 반환한다', () {
      expect(NotificationFilter.all.typeGroup, isNull);
    });

    test('cert는 cert를 반환한다', () {
      expect(NotificationFilter.cert.typeGroup, 'cert');
    });

    test('comment는 comment를 반환한다', () {
      expect(NotificationFilter.comment.typeGroup, 'comment');
    });

    test('festival은 festival을 반환한다', () {
      expect(NotificationFilter.festival.typeGroup, 'festival');
    });
  });
}
