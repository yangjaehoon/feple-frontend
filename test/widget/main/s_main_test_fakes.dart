import 'package:feple/model/user_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';

/// `MainScreen` 관련 테스트가 공통으로 쓰는 페이크·목 — 이 폴더의 여러
/// `testWidgets` 파일에서 중복 정의하지 않도록 여기 한 곳에 모은다.

class MockFestivalService extends Mock implements FestivalService {}

class MockNotificationCountable extends Mock implements NotificationCountable {}

/// 실제 UserProvider.logout()은 secure storage/FCM 등 플랫폼 채널을 기다려
/// 위젯 테스트에서 멈추므로, 로그인 상태만 토글하는 최소 페이크를 쓴다.
/// (MainScreen은 UserProvider 리스너로만 로그아웃을 감지한다.)
class FakeUserProvider extends ChangeNotifier implements UserProvider {
  AppUser? _user;

  @override
  AppUser? get user => _user;

  @override
  int? get currentUserId => _user?.id;

  @override
  String? get currentProfileImageUrl => _user?.profileImageUrl;

  void setUserForTest(AppUser? value) {
    _user = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
