import 'package:feple/injection.dart';
import 'package:feple/model/follow_response.dart';
import 'package:feple/model/follow_status.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_follow_notifier.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockArtistFollowService extends Mock implements ArtistFollowService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockArtistFollowService mockService;
  late ArtistFollowNotifier notifier;

  setUp(() {
    mockService = MockArtistFollowService();
    if (sl.isRegistered<ArtistFollowService>()) {
      sl.unregister<ArtistFollowService>();
    }
    sl.registerSingleton<ArtistFollowService>(mockService);
    notifier = ArtistFollowNotifier(artistId: 42, initialFollowerCount: 100);
  });

  tearDown(() {
    sl.unregister<ArtistFollowService>();
  });

  group('init', () {
    test('서비스 상태로 isFollowed, followCount 갱신', () async {
      when(() => mockService.getFollowStatus(42))
          .thenAnswer((_) async => FollowStatus(followed: true, followerCount: 150));

      await notifier.init();

      expect(notifier.isFollowed, true);
      expect(notifier.followCount, 150);
    });

    test('서비스 예외 시 상태 유지 (크래시 없음)', () async {
      when(() => mockService.getFollowStatus(42)).thenThrow(Exception('network'));

      await expectLater(notifier.init(), completes);

      expect(notifier.isFollowed, false);
      expect(notifier.followCount, 100);
    });
  });

  group('toggle', () {
    test('팔로우 중이 아닐 때 follow() 호출, 상태 반영', () async {
      notifier.isFollowed = false;
      when(() => mockService.follow(42))
          .thenAnswer((_) async => FollowResponse(followed: true, followerCount: 101));

      await notifier.toggle();

      expect(notifier.isFollowed, true);
      expect(notifier.followCount, 101);
      expect(notifier.isLoading, false);
    });

    test('팔로우 중일 때 unfollow() 호출, 상태 반영', () async {
      notifier.isFollowed = true;
      notifier.followCount = 100;
      when(() => mockService.unfollow(42))
          .thenAnswer((_) async => FollowResponse(followed: false, followerCount: 99));

      await notifier.toggle();

      expect(notifier.isFollowed, false);
      expect(notifier.followCount, 99);
      expect(notifier.isLoading, false);
    });

    test('isLoading 중 toggle 재호출 시 무시', () async {
      notifier.isFollowed = false;
      // toggle 첫 호출은 시작만 하고 완료 안 된 상태 시뮬레이션
      when(() => mockService.follow(42))
          .thenAnswer((_) async => FollowResponse(followed: true, followerCount: 101));

      // 동시 호출 — 두 번째는 isLoading이 true라 무시되어야 함
      final f1 = notifier.toggle();
      final f2 = notifier.toggle();
      await Future.wait([f1, f2]);

      verify(() => mockService.follow(42)).called(1);
    });

    test('서비스 예외 시 isLoading false로 복구', () async {
      notifier.isFollowed = false;
      when(() => mockService.follow(42)).thenThrow(Exception('err'));

      await expectLater(notifier.toggle(), throwsException);

      expect(notifier.isLoading, false);
    });
  });
}
