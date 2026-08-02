import 'package:feple/common/app_events.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_artists_fetcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFestivalArtistsFetcher extends Mock implements FestivalArtistsFetcher {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}

FestivalArtistItem _artist(int id, String name) =>
    FestivalArtistItem(artistId: id, artistName: name);

void main() {
  late MockFestivalArtistsFetcher mockFestivalArtistsFetcher;
  late MockArtistFollowService mockFollowService;

  setUp(() {
    mockFestivalArtistsFetcher = MockFestivalArtistsFetcher();
    mockFollowService = MockArtistFollowService();
  });

  FestivalArtistsNotifier make({int? userId}) => FestivalArtistsNotifier(
        festivalId: 10,
        userId: userId,
        festivalService: mockFestivalArtistsFetcher,
        followService: mockFollowService,
      );

  group('fetch', () {
    test('팔로우한 아티스트를 앞으로 정렬', () async {
      final artists = [_artist(1, 'A'), _artist(2, 'B'), _artist(3, 'C')];
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenAnswer((_) async => artists);
      when(() => mockFollowService.fetchFollowingIds(99))
          .thenAnswer((_) async => {2, 3});

      final notifier = make(userId: 99);
      await notifier.fetch();

      expect(notifier.artists.first.artistId, anyOf(2, 3));
      expect(notifier.artists.last.artistId, 1);
      expect(notifier.followedIds, {2, 3});
      expect(notifier.isLoading, false);
    });

    test('userId null이면 fetchFollowingIds 호출 안 함', () async {
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenAnswer((_) async => [_artist(1, 'A')]);

      final notifier = make(userId: null);
      await notifier.fetch();

      verifyNever(() => mockFollowService.fetchFollowingIds(any()));
      expect(notifier.followedIds, isEmpty);
    });

    test('fetchFestivalArtists 예외 시 isLoading false, hasError true', () async {
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenThrow(Exception('network'));

      final notifier = make();
      await notifier.fetch();

      expect(notifier.isLoading, false);
      expect(notifier.hasError, true);
      expect(notifier.artists, isEmpty);
    });

    test('팔로우 없는 경우 원래 순서 유지', () async {
      final artists = [_artist(1, 'A'), _artist(2, 'B')];
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenAnswer((_) async => artists);
      when(() => mockFollowService.fetchFollowingIds(99))
          .thenAnswer((_) async => {});

      final notifier = make(userId: 99);
      await notifier.fetch();

      expect(notifier.artists.map((a) => a.artistId).toList(), [1, 2]);
    });

    test('아티스트 목록이 빈 배열이면 artists 비어있고 isLoading false', () async {
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenAnswer((_) async => []);
      when(() => mockFollowService.fetchFollowingIds(99))
          .thenAnswer((_) async => {});

      final notifier = make(userId: 99);
      await notifier.fetch();

      expect(notifier.artists, isEmpty);
      expect(notifier.isLoading, false);
    });

    test('모든 아티스트가 팔로우된 경우 원래 순서 유지', () async {
      final artists = [_artist(1, 'A'), _artist(2, 'B'), _artist(3, 'C')];
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenAnswer((_) async => artists);
      when(() => mockFollowService.fetchFollowingIds(99))
          .thenAnswer((_) async => {1, 2, 3});

      final notifier = make(userId: 99);
      await notifier.fetch();

      expect(notifier.artists.map((a) => a.artistId).toList(), [1, 2, 3]);
      expect(notifier.followedIds, {1, 2, 3});
    });

    test('fetchFollowingIds 예외 시 아티스트 데이터도 버려지고 hasError true', () async {
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenAnswer((_) async => [_artist(1, 'A')]);
      when(() => mockFollowService.fetchFollowingIds(99))
          .thenThrow(Exception('network'));

      final notifier = make(userId: 99);
      await notifier.fetch();

      expect(notifier.artists, isEmpty);
      expect(notifier.isLoading, false);
      expect(notifier.hasError, true);
    });
  });

  group('artistFollowChanged 이벤트', () {
    test('다른 화면에서 팔로우 상태가 바뀌면 followedIds 재조회', () async {
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenAnswer((_) async => [_artist(1, 'A')]);
      when(() => mockFollowService.fetchFollowingIds(99))
          .thenAnswer((_) async => {});

      final notifier = make(userId: 99);
      await notifier.fetch();
      expect(notifier.followedIds, isEmpty);

      when(() => mockFollowService.fetchFollowingIds(99))
          .thenAnswer((_) async => {1});
      AppEvents.artistFollowChanged.value++;
      await Future<void>.delayed(Duration.zero);

      expect(notifier.followedIds, {1});
      notifier.dispose();
    });

    test('userId null이면 이벤트 발생해도 재조회 안 함', () async {
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenAnswer((_) async => [_artist(1, 'A')]);

      final notifier = make(userId: null);
      await notifier.fetch();

      AppEvents.artistFollowChanged.value++;
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockFollowService.fetchFollowingIds(any()));
      notifier.dispose();
    });

    test('dispose 후에는 이벤트가 와도 리스너가 반응하지 않음', () async {
      when(() => mockFestivalArtistsFetcher.fetchFestivalArtists(10))
          .thenAnswer((_) async => [_artist(1, 'A')]);
      when(() => mockFollowService.fetchFollowingIds(99))
          .thenAnswer((_) async => {});

      final notifier = make(userId: 99);
      await notifier.fetch();
      notifier.dispose();

      AppEvents.artistFollowChanged.value++;
      await Future<void>.delayed(Duration.zero);

      verify(() => mockFollowService.fetchFollowingIds(99)).called(1);
    });
  });
}
