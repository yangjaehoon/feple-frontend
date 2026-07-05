import 'package:feple/model/booth_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FestivalModel _festival(int id) => FestivalModel(
      id: id,
      title: 'Festival $id',
      description: '',
      location: 'Seoul',
      startDate: '2099-01-01',
      endDate: '2099-01-03',
      posterUrl: '',
    );

FestivalArtistItem _artist() => FestivalArtistItem(
      artistId: 1,
      artistName: 'Artist A',
    );

TimetableEntry _entry() => const TimetableEntry(
      id: 1,
      stageName: 'Main',
      stageOrder: 0,
      artistName: 'Artist A',
      festivalDate: '2099-01-01',
      startTime: '14:00',
      endTime: '15:00',
    );

FestivalSetlistEntry _setlistEntry() => const FestivalSetlistEntry(
      artistFestivalId: 1,
      artistId: 1,
      artistName: 'Artist A',
      songs: [],
    );

BoothModel _booth() => BoothModel(
      id: 1,
      name: 'Food Booth',
      boothType: 'FOOD',
      boothTypeName: '음식',
      latitude: 37.5,
      longitude: 127.0,
    );

FestivalPreview _preview(int id) => FestivalPreview(
      id: id,
      title: 'Preview $id',
      posterUrl: '',
      location: 'Seoul',
      startDate: '2099-01-01',
    );

FollowedArtist _followedArtist() => const FollowedArtist(
      id: 1,
      name: 'Artist A',
    );

void main() {
  late FestivalCacheService cache;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cache = FestivalCacheService();
  });

  group('artists round-trip', () {
    test('save 후 load하면 동일 아티스트 목록 반환', () async {
      await cache.saveArtists(1, [_artist()]);
      final loaded = await cache.loadArtists(1);

      expect(loaded, isNotNull);
      expect(loaded!.length, 1);
      expect(loaded.first.artistName, 'Artist A');
    });

    test('저장 없이 load하면 null 반환', () async {
      expect(await cache.loadArtists(99), isNull);
    });

    test('stale 상태에서 loadArtists는 null 반환', () async {
      final pastTs = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'fc_artists_time_1': pastTs});
      cache = FestivalCacheService();
      final loaded = await cache.loadArtists(1);
      expect(loaded, isNull);
    });
  });

  group('timetable round-trip', () {
    test('save 후 load하면 동일 엔트리 반환', () async {
      await cache.saveTimetable(1, [_entry()]);
      final loaded = await cache.loadTimetable(1);

      expect(loaded, isNotNull);
      expect(loaded!.first.startTime, '14:00');
    });

    test('stale 상태에서 loadTimetable은 null 반환', () async {
      final pastTs = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'fc_timetable_time_1': pastTs});
      cache = FestivalCacheService();
      expect(await cache.loadTimetable(1), isNull);
    });
  });

  group('setlist round-trip', () {
    test('save 후 load하면 동일 세트리스트 반환', () async {
      await cache.saveSetlist(1, [_setlistEntry()]);
      final loaded = await cache.loadSetlist(1);

      expect(loaded, isNotNull);
      expect(loaded!.first.artistName, 'Artist A');
    });

    test('stale 상태에서 loadSetlist는 null 반환', () async {
      final pastTs = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'fc_setlist_time_1': pastTs});
      cache = FestivalCacheService();
      expect(await cache.loadSetlist(1), isNull);
    });
  });

  group('booth round-trip', () {
    test('save 후 load하면 동일 부스 목록 반환', () async {
      await cache.saveBooths(1, [_booth()]);
      final loaded = await cache.loadBooths(1);

      expect(loaded, isNotNull);
      expect(loaded!.first.name, 'Food Booth');
    });

    test('stale 상태에서 loadBooths는 null 반환', () async {
      final pastTs = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'fc_booths_time_1': pastTs});
      cache = FestivalCacheService();
      expect(await cache.loadBooths(1), isNull);
    });
  });

  group('preview list round-trip', () {
    test('save 후 load하면 동일 preview 목록 반환', () async {
      await cache.savePreviewList([_preview(1), _preview(2)]);
      final loaded = await cache.loadPreviewList();

      expect(loaded, isNotNull);
      expect(loaded!.length, 2);
      expect(loaded.first.id, 1);
    });

    test('stale 상태에서 loadPreviewList는 null 반환', () async {
      final pastTs = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'fc_previews_time': pastTs});
      cache = FestivalCacheService();
      expect(await cache.loadPreviewList(), isNull);
    });
  });

  group('home data round-trip', () {
    test('saveHomeFestivals 후 load하면 반환', () async {
      await cache.saveHomeFestivals(42, [_festival(1)]);
      final loaded = await cache.loadHomeFestivals(42);

      expect(loaded, isNotNull);
      expect(loaded!.first.title, 'Festival 1');
    });

    test('saveHomeArtists 후 load하면 반환', () async {
      await cache.saveHomeFestivals(42, []);
      await cache.saveHomeArtists(42, [_followedArtist()]);
      final loaded = await cache.loadHomeArtists(42);

      expect(loaded, isNotNull);
      expect(loaded!.first.name, 'Artist A');
    });

    test('다른 userId는 별도 캐시 사용', () async {
      await cache.saveHomeFestivals(1, [_festival(1)]);
      await cache.saveHomeFestivals(2, [_festival(2)]);

      final user1 = await cache.loadHomeFestivals(1);
      final user2 = await cache.loadHomeFestivals(2);

      expect(user1!.first.id, 1);
      expect(user2!.first.id, 2);
    });
  });

  group('clear', () {
    test('clear(id) 후 해당 festival 캐시는 모두 비워짐', () async {
      await cache.saveArtists(1, [_artist()]);
      expect(await cache.loadArtists(1), isNotNull);

      await cache.clear(1);

      expect(await cache.loadArtists(1), isNull);
    });

    test('clearAll 후 모든 캐시 키 제거', () async {
      await cache.saveArtists(1, [_artist()]);
      await cache.saveArtists(2, [_artist()]);
      await cache.savePreviewList([_preview(1)]);

      await cache.clearAll();

      expect(await cache.loadArtists(1), isNull);
      expect(await cache.loadArtists(2), isNull);
      expect(await cache.loadPreviewList(), isNull);
    });

    test('clear(id)는 다른 festivalId 캐시에 영향 없음', () async {
      await cache.saveArtists(1, [_artist()]);
      await cache.saveArtists(2, [_artist()]);

      await cache.clear(1);

      expect(await cache.loadArtists(2), isNotNull);
    });
  });
}
