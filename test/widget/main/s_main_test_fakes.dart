import 'package:feple/injection.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/cache_prefetch_service.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:mocktail/mocktail.dart';

/// `MainScreen` 관련 테스트가 공통으로 쓰는 페이크·목 — 이 폴더의 여러
/// `testWidgets` 파일에서 중복 정의하지 않도록 여기 한 곳에 모은다.

class MockFestivalService extends Mock implements FestivalService {}

class MockNotificationCountable extends Mock implements NotificationCountable {}

/// 홈 탭이 실제로 렌더되는 테스트에서 필요 — `HomeStateNotifier.init()`이
/// 이 서비스들을 바로 호출해서, 목이 없으면 Dio 요청이 살아남아
/// "A Timer is still pending" 으로 테스트가 깨진다.
class MockUserService extends Mock implements UserService {}

class MockArtistService extends Mock implements ArtistService {}

class MockFestivalCacheService extends Mock implements FestivalCacheService {}

class MockCachePrefetchService extends Mock implements CachePrefetchService {}

/// 홈 탭이 렌더되는 순간 `HomeStateNotifier.init()`이 바로 호출하는 서비스들을
/// 전부 목으로 바꾼다. 하나라도 빠지면 실제 구현이 살아 있어 위젯 테스트가
/// 운영 API로 Dio 요청을 쏘고, 타이머가 남아 "A Timer is still pending"으로
/// 깨진다(네트워크 상태에 따라 통과하기도 해서 CI에서 산발적으로 터진다).
///
/// 알림 개수 목만 호출 횟수를 세야 해서 밖으로 돌려준다. 카운터는 lazy
/// 싱글톤이라 한 번 만들어지면 첫 목을 계속 들고 있으므로 함께 다시 등록한다
/// (싱글톤 의미는 그대로 유지 — 여러 탭의 앱바가 같은 인스턴스를 봐야 한다).
MockNotificationCountable registerMainScreenTabMocks() {
  final notificationCountable = MockNotificationCountable();
  when(() => notificationCountable.getUnreadCount()).thenAnswer((_) async => 0);

  final userService = MockUserService();
  when(() => userService.fetchFollowingArtists(any())).thenAnswer((_) async => []);
  when(() => userService.fetchLikedFestivals(any())).thenAnswer((_) async => []);

  final artistService = MockArtistService();
  when(() => artistService.fetchArtists()).thenAnswer((_) async => []);

  final cacheService = MockFestivalCacheService();
  when(() => cacheService.loadHomeFestivals(any())).thenAnswer((_) async => null);
  when(() => cacheService.loadHomeArtists(any())).thenAnswer((_) async => null);
  when(() => cacheService.saveHomeFestivals(any(), any())).thenAnswer((_) async {});
  when(() => cacheService.saveHomeArtists(any(), any())).thenAnswer((_) async {});

  final prefetchService = MockCachePrefetchService();
  when(() => prefetchService.prefetchForFestivals(any())).thenAnswer((_) async {});

  void replace<T extends Object>(T mock) {
    if (sl.isRegistered<T>()) sl.unregister<T>();
    sl.registerSingleton<T>(mock);
  }

  replace<NotificationCountable>(notificationCountable);
  replace<UserService>(userService);
  replace<ArtistService>(artistService);
  replace<FestivalCacheService>(cacheService);
  replace<CachePrefetchService>(prefetchService);

  if (sl.isRegistered<NotificationCountNotifier>()) {
    sl.unregister<NotificationCountNotifier>();
  }
  sl.registerLazySingleton<NotificationCountNotifier>(
      () => NotificationCountNotifier());

  return notificationCountable;
}

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
