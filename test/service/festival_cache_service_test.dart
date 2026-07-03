import 'package:feple/model/booth_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
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

  group('isStale', () {
    test('저장된 타임스탬프 없으면 stale', () async {
      expect(await cache.isStale(1), true);
    });

    test('saveFestival 직후에는 stale 아님', () async {
      await cache.saveFestival(1, _festival(1));
      expect(await cache.isStale(1), false);
    });

    test('타임스탬프가 25시간 전이면 stale', () async {
      final pastTs = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'fc_time_1': pastTs});
      cache = FestivalCacheService();
      expect(await cache.isStale(1), true);
    });
  });

  group('festival round-trip', () {
    test('save 후 load하면 같은 festival 반환', () async {
      await cache.saveFestival(1, _festival(1));
      final loaded = await cache.loadFestival(1);

      expect(loaded, isNotNull);
      expect(loaded!.id, 1);
      expect(loaded.title, 'Festival 1');
    });

    test('stale 상태에서 load하면 null 반환', () async {
      final pastTs = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'fc_time_1': pastTs});
      cache = FestivalCacheService();

      final loaded = await cache.loadFestival(1);
      expect(loaded, isNull);
    });

    test('저장 없이 load하면 null 반환', () async {
      final loaded = await cache.loadFestival(99);
      expect(loaded, isNull);
    });
  });

  group('artists round-trip', () {
    test('save 후 load하면 동일 아티스트 목록 반환', () async {
      await cache.saveFestival(1, _festival(1));
      await cache.saveArtists(1, [_artist()]);
      final loaded = await cache.loadArtists(1);

      expect(loaded, isNotNull);
      expect(loaded!.length, 1);
      expect(loaded.first.artistName, 'Artist A');
    });

    test('stale 상태에서 loadArtists는 null 반환', () async {
      final pastTs = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'fc_time_1': pastTs});
      cache = FestivalCacheService();
      final loaded = await cache.loadArtists(1);
      expect(loaded, isNull);
    });
  });

  group('timetable round-trip', () {
    test('save 후 load하면 동일 엔트리 반환', () async {
      await cache.saveFestival(1, _festival(1));
      await cache.saveTimetable(1, [_entry()]);
      final loaded = await cache.loadTimetable(1);

      expect(loaded, isNotNull);
      expect(loaded!.first.startTime, '14:00');
    });
  });

  group('booth round-trip', () {
    test('save 후 load하면 동일 부스 목록 반환', () async {
      await cache.saveFestival(1, _festival(1));
      await cache.saveBooths(1, [_booth()]);
      final loaded = await cache.loadBooths(1);

      expect(loaded, isNotNull);
      expect(loaded!.first.name, 'Food Booth');
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
    test('clear(id) 후 해당 festival은 stale', () async {
      await cache.saveFestival(1, _festival(1));
      expect(await cache.isStale(1), false);

      await cache.clear(1);

      expect(await cache.isStale(1), true);
      expect(await cache.loadFestival(1), isNull);
    });

    test('clearAll 후 모든 캐시 키 제거', () async {
      await cache.saveFestival(1, _festival(1));
      await cache.saveFestival(2, _festival(2));
      await cache.savePreviewList([_preview(1)]);

      await cache.clearAll();

      expect(await cache.isStale(1), true);
      expect(await cache.isStale(2), true);
      expect(await cache.loadPreviewList(), isNull);
    });

    test('clear(id)는 다른 festivalId 캐시에 영향 없음', () async {
      await cache.saveFestival(1, _festival(1));
      await cache.saveFestival(2, _festival(2));

      await cache.clear(1);

      expect(await cache.loadFestival(2), isNotNull);
    });
  });
}
