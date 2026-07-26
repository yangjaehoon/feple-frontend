import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/home/home_state_notifier.dart';
import 'package:feple/service/cache_prefetch_service.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService extends Mock implements UserService {}
class MockFestivalCacheService extends Mock implements FestivalCacheService {}
class MockCachePrefetchService extends Mock implements CachePrefetchService {}

FollowedArtist _artist({int id = 1, String name = '아티스트'}) =>
    FollowedArtist(id: id, name: name);

FestivalModel _festival({int id = 1, String title = '축제', bool ended = false}) {
  final now = DateTime.now();
  final end = ended
      ? now.subtract(const Duration(days: 5))
      : now.add(const Duration(days: 5));
  return FestivalModel(
    id: id,
    title: title,
    description: '',
    location: '',
    startDate: now.toIso8601String(),
    endDate: end.toIso8601String(),
    posterUrl: '',
  );
}

void main() {
  late HomeStateNotifier notifier;
  late MockUserService mockUserService;
  late MockFestivalCacheService mockCacheService;
  late MockCachePrefetchService mockPrefetchService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() {
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    if (sl.isRegistered<FestivalCacheService>()) sl.unregister<FestivalCacheService>();
    if (sl.isRegistered<CachePrefetchService>()) sl.unregister<CachePrefetchService>();

    mockUserService = MockUserService();
    mockCacheService = MockFestivalCacheService();
    mockPrefetchService = MockCachePrefetchService();

    sl.registerSingleton<UserService>(mockUserService);
    sl.registerSingleton<FestivalCacheService>(mockCacheService);
    sl.registerSingleton<CachePrefetchService>(mockPrefetchService);

    // 캐시는 기본적으로 비어있음 — 개별 테스트에서 필요 시 override
    when(() => mockCacheService.loadHomeFestivals(any())).thenAnswer((_) async => null);
    when(() => mockCacheService.loadHomeArtists(any())).thenAnswer((_) async => null);
    when(() => mockCacheService.saveHomeFestivals(any(), any())).thenAnswer((_) async {});
    when(() => mockCacheService.saveHomeArtists(any(), any())).thenAnswer((_) async {});
    when(() => mockPrefetchService.prefetchForFestivals(any())).thenAnswer((_) async {});

    notifier = HomeStateNotifier();
  });

  tearDown(() {
    sl.unregister<UserService>();
    sl.unregister<FestivalCacheService>();
    sl.unregister<CachePrefetchService>();
  });

  group('HomeStateNotifier.init', () {
    test('성공하면 artists/festivals/boards가 채워진다', () async {
      when(() => mockUserService.fetchFollowingArtists(1))
          .thenAnswer((_) async => [_artist(id: 1, name: '아이유')]);
      when(() => mockUserService.fetchLikedFestivals(1))
          .thenAnswer((_) async => [_festival(id: 1, title: '서울재즈')]);

      await notifier.init(1);

      expect(notifier.artists?.length, 1);
      expect(notifier.festivals?.length, 1);
      expect(notifier.boards?.length, 2);
      expect(notifier.hasError, false);
    });

    test('실패하고 캐시도 없으면 hasError=true', () async {
      when(() => mockUserService.fetchFollowingArtists(1)).thenThrow(Exception('네트워크 오류'));
      when(() => mockUserService.fetchLikedFestivals(1)).thenThrow(Exception('네트워크 오류'));

      await notifier.init(1);

      expect(notifier.hasError, true);
      expect(notifier.artists, isNull);
    });

    test('캐시가 있으면 네트워크 실패해도 hasError=false (기존 표시 유지)', () async {
      when(() => mockCacheService.loadHomeFestivals(1))
          .thenAnswer((_) async => [_festival(title: '캐시축제')]);
      when(() => mockCacheService.loadHomeArtists(1))
          .thenAnswer((_) async => [_artist(name: '캐시아티스트')]);
      when(() => mockUserService.fetchFollowingArtists(1)).thenThrow(Exception('네트워크 오류'));
      when(() => mockUserService.fetchLikedFestivals(1)).thenThrow(Exception('네트워크 오류'));

      await notifier.init(1);

      expect(notifier.hasError, false);
      expect(notifier.artists?.first.name, '캐시아티스트');
    });
  });

  group('HomeStateNotifier.retry', () {
    test('상태를 초기화하고 다시 로드한다', () async {
      when(() => mockUserService.fetchFollowingArtists(1)).thenThrow(Exception('오류'));
      when(() => mockUserService.fetchLikedFestivals(1)).thenThrow(Exception('오류'));
      await notifier.init(1);
      expect(notifier.hasError, true);

      when(() => mockUserService.fetchFollowingArtists(1))
          .thenAnswer((_) async => [_artist()]);
      when(() => mockUserService.fetchLikedFestivals(1))
          .thenAnswer((_) async => [_festival()]);

      await notifier.retry();

      expect(notifier.hasError, false);
      expect(notifier.artists?.length, 1);
    });

    test('재시도가 성공하면 error도 함께 초기화된다 (hasError만 초기화되고 error가 남아있으면 화면 섹션이 계속 에러로 보임)', () async {
      when(() => mockUserService.fetchFollowingArtists(1)).thenThrow(Exception('오류'));
      when(() => mockUserService.fetchLikedFestivals(1)).thenThrow(Exception('오류'));
      await notifier.init(1);
      expect(notifier.error, isNotNull);

      when(() => mockUserService.fetchFollowingArtists(1)).thenAnswer((_) async => [_artist()]);
      when(() => mockUserService.fetchLikedFestivals(1)).thenAnswer((_) async => [_festival()]);

      await notifier.retry();

      expect(notifier.error, isNull);
    });
  });

  group('HomeStateNotifier.refresh', () {
    test('force=false이고 최근 로드했으면 재요청하지 않는다', () async {
      when(() => mockUserService.fetchFollowingArtists(1)).thenAnswer((_) async => [_artist()]);
      when(() => mockUserService.fetchLikedFestivals(1)).thenAnswer((_) async => [_festival()]);
      await notifier.init(1);

      await notifier.refresh();

      verify(() => mockUserService.fetchFollowingArtists(1)).called(1);
    });

    test('force=true면 항상 재요청한다', () async {
      when(() => mockUserService.fetchFollowingArtists(1)).thenAnswer((_) async => [_artist()]);
      when(() => mockUserService.fetchLikedFestivals(1)).thenAnswer((_) async => [_festival()]);
      await notifier.init(1);

      await notifier.refresh(force: true);

      verify(() => mockUserService.fetchFollowingArtists(1)).called(2);
    });
  });

  group('HomeStateNotifier.refreshFestivals/refreshArtists', () {
    test('refreshFestivals는 festivals만 갱신하고 festivalsChanges를 알린다', () async {
      when(() => mockUserService.fetchFollowingArtists(1)).thenAnswer((_) async => [_artist()]);
      when(() => mockUserService.fetchLikedFestivals(1))
          .thenAnswer((_) async => [_festival(title: '기존축제')]);
      await notifier.init(1);

      var notified = false;
      notifier.festivalsChanges.addListener(() => notified = true);
      when(() => mockUserService.fetchLikedFestivals(1))
          .thenAnswer((_) async => [_festival(title: '갱신축제')]);

      await notifier.refreshFestivals();

      expect(notifier.festivals?.first.title, '갱신축제');
      expect(notified, true);
    });

    test('refreshArtists는 artists만 갱신하고 artistsChanges를 알린다', () async {
      when(() => mockUserService.fetchFollowingArtists(1))
          .thenAnswer((_) async => [_artist(name: '기존아티스트')]);
      when(() => mockUserService.fetchLikedFestivals(1)).thenAnswer((_) async => [_festival()]);
      await notifier.init(1);

      var notified = false;
      notifier.artistsChanges.addListener(() => notified = true);
      when(() => mockUserService.fetchFollowingArtists(1))
          .thenAnswer((_) async => [_artist(name: '갱신아티스트')]);

      await notifier.refreshArtists();

      expect(notifier.artists?.first.name, '갱신아티스트');
      expect(notified, true);
    });
  });

  group('HomeStateNotifier.saveArtistOrder/saveFestivalOrder', () {
    test('saveArtistOrder는 artistOrder를 갱신하고 artistsChanges를 알린다', () async {
      var notified = false;
      notifier.artistsChanges.addListener(() => notified = true);

      await notifier.saveArtistOrder([3, 1, 2]);

      expect(notifier.artistOrder, [3, 1, 2]);
      expect(notified, true);
    });

    test('saveFestivalOrder는 festivalOrder를 갱신하고 festivalsChanges를 알린다', () async {
      var notified = false;
      notifier.festivalsChanges.addListener(() => notified = true);

      await notifier.saveFestivalOrder([2, 1]);

      expect(notifier.festivalOrder, [2, 1]);
      expect(notified, true);
    });
  });

  group('HomeStateNotifier.orderedFestivals', () {
    test('진행중 축제가 종료된 축제보다 항상 앞에 온다', () async {
      when(() => mockUserService.fetchFollowingArtists(1)).thenAnswer((_) async => []);
      when(() => mockUserService.fetchLikedFestivals(1)).thenAnswer((_) async => [
            _festival(id: 1, title: '종료축제', ended: true),
            _festival(id: 2, title: '진행중축제', ended: false),
          ]);

      await notifier.init(1);

      final ordered = notifier.orderedFestivals!;
      expect(ordered.map((f) => f.title).toList(), ['진행중축제', '종료축제']);
    });
  });

  group('HomeStateNotifier.applyOrder', () {
    int id(int item) => item;

    test('order 비어있으면 원래 순서 그대로 반환', () {
      final result = notifier.applyOrder([1, 2, 3], [], id);
      expect(result, [1, 2, 3]);
    });

    test('order가 전체 항목 포함 시 order 순으로 재배열', () {
      final result = notifier.applyOrder([1, 2, 3], [3, 1, 2], id);
      expect(result, [3, 1, 2]);
    });

    test('order가 일부 항목만 포함 시 order 항목 앞, 나머지 원래 순서대로 뒤에 추가', () {
      final result = notifier.applyOrder([1, 2, 3], [3], id);
      expect(result, [3, 1, 2]);
    });

    test('order에 items에 없는 ID 포함 시 해당 ID 스킵', () {
      final result = notifier.applyOrder([1, 2], [5, 1], id);
      expect(result, [1, 2]);
    });

    test('빈 items이면 빈 리스트 반환', () {
      final result = notifier.applyOrder(<int>[], [1, 2, 3], id);
      expect(result, isEmpty);
    });

    test('중복 없이 order 항목이 한 번씩만 나타남', () {
      final result = notifier.applyOrder([1, 2, 3], [2, 3], id);
      expect(result, [2, 3, 1]);
      expect(result.length, 3);
    });
  });
}
