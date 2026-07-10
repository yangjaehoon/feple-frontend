import 'package:feple/app.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/fcm_navigation_handler.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFestivalService extends Mock implements FestivalService {}

class MockPostService extends Mock implements PostService {}

class MockArtistService extends Mock implements ArtistService {}

class _RecordingObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route route, Route? previousRoute) {
    pushCount++;
  }
}

FestivalModel _festival(int id) => FestivalModel(
      id: id,
      title: 'festival $id',
      description: 'desc',
      location: 'seoul',
      startDate: '2026-01-01',
      endDate: '2026-01-02',
      posterUrl: 'https://example.com/poster.jpg',
    );

Post _post(int id) => Post(
      id: id,
      title: 'post $id',
      content: 'content',
      likeCount: 0,
      nickname: 'user',
    );

Artist _artist(int id) => Artist(
      id: id,
      name: 'artist $id',
      genre: 'kpop',
      profileImageUrl: 'https://example.com/profile.jpg',
      followerCount: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFestivalService mockFestivalService;
  late MockPostService mockPostService;
  late MockArtistService mockArtistService;
  late _RecordingObserver observer;
  late FcmNavigationHandler handler;

  setUp(() async {
    mockFestivalService = MockFestivalService();
    mockPostService = MockPostService();
    mockArtistService = MockArtistService();

    for (final unregister in [
      () => sl.isRegistered<FestivalService>() ? sl.unregister<FestivalService>() : null,
      () => sl.isRegistered<PostService>() ? sl.unregister<PostService>() : null,
      () => sl.isRegistered<ArtistService>() ? sl.unregister<ArtistService>() : null,
    ]) {
      unregister();
    }
    sl.registerSingleton<FestivalService>(mockFestivalService);
    sl.registerSingleton<PostService>(mockPostService);
    sl.registerSingleton<ArtistService>(mockArtistService);

    observer = _RecordingObserver();
    handler = FcmNavigationHandler();
  });

  tearDown(() {
    sl.unregister<FestivalService>();
    sl.unregister<PostService>();
    sl.unregister<ArtistService>();
  });

  Future<void> pumpNavHost(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: App.navigatorKey,
      navigatorObservers: [observer],
      home: const SizedBox(),
    ));
    // MaterialApp의 초기 라우트 push도 didPush를 한 번 발생시키므로 기준점을 리셋한다.
    observer.pushCount = 0;
  }

  testWidgets('festival 알림 타입 + 유효 linkId → 페스티벌 조회 후 push', (tester) async {
    await pumpNavHost(tester);
    when(() => mockFestivalService.fetchById(10)).thenAnswer((_) async => _festival(10));

    await handler.navigate({'type': 'NEW_FESTIVAL', 'festivalId': '10'});

    verify(() => mockFestivalService.fetchById(10)).called(1);
    verifyNever(() => mockPostService.fetchPost(any()));
    verifyNever(() => mockArtistService.fetchArtistById(any()));
    expect(observer.pushCount, 1);
  });

  testWidgets('festival 조회 실패 시 알림 화면으로 폴백', (tester) async {
    await pumpNavHost(tester);
    when(() => mockFestivalService.fetchById(10)).thenThrow(Exception('network'));

    await handler.navigate({'type': 'NEW_FESTIVAL', 'festivalId': '10'});

    verify(() => mockFestivalService.fetchById(10)).called(1);
    // 실패해도 알림 화면으로 폴백 push는 발생해야 함
    expect(observer.pushCount, 1);
  });

  testWidgets('comment 계열 알림 타입 + 유효 linkId → 게시글 조회 후 push', (tester) async {
    await pumpNavHost(tester);
    when(() => mockPostService.fetchPost(7)).thenAnswer((_) async => _post(7));

    await handler.navigate({'type': 'NEW_COMMENT', 'festivalId': '7'});

    verify(() => mockPostService.fetchPost(7)).called(1);
    verifyNever(() => mockFestivalService.fetchById(any()));
    verifyNever(() => mockArtistService.fetchArtistById(any()));
    expect(observer.pushCount, 1);
  });

  testWidgets('artist 내비게이션 타입(곡신청 승인) + 유효 linkId → 아티스트 조회 후 push', (tester) async {
    await pumpNavHost(tester);
    when(() => mockArtistService.fetchArtistById(3)).thenAnswer((_) async => _artist(3));

    await handler.navigate({'type': 'SONG_REQUEST_APPROVED', 'festivalId': '3'});

    verify(() => mockArtistService.fetchArtistById(3)).called(1);
    verifyNever(() => mockFestivalService.fetchById(any()));
    verifyNever(() => mockPostService.fetchPost(any()));
    expect(observer.pushCount, 1);
  });

  testWidgets('linkId가 없으면 서비스 호출 없이 알림 화면으로 폴백', (tester) async {
    await pumpNavHost(tester);

    await handler.navigate({'type': 'NEW_FESTIVAL'});

    verifyNever(() => mockFestivalService.fetchById(any()));
    expect(observer.pushCount, 1);
  });

  testWidgets('linkId가 빈 문자열이면 서비스 호출 없이 알림 화면으로 폴백', (tester) async {
    await pumpNavHost(tester);

    await handler.navigate({'type': 'NEW_FESTIVAL', 'festivalId': ''});

    verifyNever(() => mockFestivalService.fetchById(any()));
    expect(observer.pushCount, 1);
  });

  testWidgets('알 수 없는 타입은 서비스 호출 없이 알림 화면으로 폴백', (tester) async {
    await pumpNavHost(tester);

    await handler.navigate({'type': 'UNKNOWN_TYPE', 'festivalId': '10'});

    verifyNever(() => mockFestivalService.fetchById(any()));
    verifyNever(() => mockPostService.fetchPost(any()));
    verifyNever(() => mockArtistService.fetchArtistById(any()));
    expect(observer.pushCount, 1);
  });

  testWidgets('adminBroadcast는 festivalId가 있어도 알림 화면으로 폴백', (tester) async {
    await pumpNavHost(tester);

    await handler.navigate({'type': 'ADMIN_BROADCAST', 'festivalId': '10'});

    verifyNever(() => mockFestivalService.fetchById(any()));
    expect(observer.pushCount, 1);
  });
}
