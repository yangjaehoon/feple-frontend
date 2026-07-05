import 'dart:convert';

import 'package:feple/model/booth_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 페스티벌 상세 화면 전용 타입 스냅샷 캐시 (모델 객체 단위, TTL 24시간 고정).
///
/// [ApiCacheStore](../network/api_cache_store.dart)와는 역할이 다르다:
/// - [ApiCacheStore]는 Dio 인터셉터에 연결되어 모든 GET 요청을 URL 단위로
///   자동 캐싱하는 범용 인프라 캐시 (엔드포인트별 TTL, 호출부 수정 불필요).
/// - 이 클래스는 스플래시 프리패치/오프라인 폴백을 위해 특정 화면(홈, 페스티벌
///   상세)이 명시적으로 호출해 타입 있는 모델을 저장·조회하는 전용 캐시다.
///   같은 엔드포인트 데이터가 두 캐시에 동시에 존재할 수 있으며, 이는 각각
///   다른 소비자(인터셉터 vs 특정 화면)를 위한 것이라 정상이다.
class FestivalCacheService {
  static const _ttlHours = 24;
  static const _p = 'fc';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ── 유효성 ──────────────────────────────────────────────────────

  Future<bool> isStale(int festivalId) async =>
      _isKeyStale('${_p}_time_$festivalId');

  Future<bool> _isKeyStale(String tsKey) async {
    final sp = await _sp;
    final ts = sp.getInt(tsKey);
    if (ts == null) return true;
    return DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(ts))
            .inHours >=
        _ttlHours;
  }

  Future<void> _touch(String tsKey) async {
    final sp = await _sp;
    await sp.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ── festival detail ──────────────────────────────────────────────

  Future<void> saveFestival(int id, FestivalModel model) async {
    final sp = await _sp;
    await sp.setString('${_p}_festival_$id', jsonEncode(model.toJson()));
    await _touch('${_p}_time_$id');
  }

  Future<FestivalModel?> loadFestival(int id) async {
    final sp = await _sp;
    if (await isStale(id)) return null;
    final s = sp.getString('${_p}_festival_$id');
    if (s == null) return null;
    try {
      return FestivalModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[Cache] festival 로드 실패: $e');
      return null;
    }
  }

  // ── artists ─────────────────────────────────────────────────────

  Future<void> saveArtists(int id, List<FestivalArtistItem> items) async {
    final sp = await _sp;
    await sp.setString(
        '${_p}_artists_$id', jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<List<FestivalArtistItem>?> loadArtists(int id) async {
    final sp = await _sp;
    if (await isStale(id)) return null;
    final s = sp.getString('${_p}_artists_$id');
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List)
          .map((e) => FestivalArtistItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] artists 로드 실패: $e');
      return null;
    }
  }

  // ── timetable ───────────────────────────────────────────────────

  Future<void> saveTimetable(int id, List<TimetableEntry> entries) async {
    final sp = await _sp;
    await sp.setString('${_p}_timetable_$id',
        jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  Future<List<TimetableEntry>?> loadTimetable(int id) async {
    final sp = await _sp;
    if (await isStale(id)) return null;
    final s = sp.getString('${_p}_timetable_$id');
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List)
          .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] timetable 로드 실패: $e');
      return null;
    }
  }

  // ── setlist ─────────────────────────────────────────────────────

  Future<void> saveSetlist(int id, List<FestivalSetlistEntry> entries) async {
    final sp = await _sp;
    await sp.setString('${_p}_setlist_$id',
        jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  Future<List<FestivalSetlistEntry>?> loadSetlist(int id) async {
    final sp = await _sp;
    if (await isStale(id)) return null;
    final s = sp.getString('${_p}_setlist_$id');
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List)
          .map((e) =>
              FestivalSetlistEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] setlist 로드 실패: $e');
      return null;
    }
  }

  // ── booths ──────────────────────────────────────────────────────

  Future<void> saveBooths(int id, List<BoothModel> booths) async {
    final sp = await _sp;
    await sp.setString(
        '${_p}_booths_$id', jsonEncode(booths.map((e) => e.toJson()).toList()));
  }

  Future<List<BoothModel>?> loadBooths(int id) async {
    final sp = await _sp;
    if (await isStale(id)) return null;
    final s = sp.getString('${_p}_booths_$id');
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List)
          .map((e) => BoothModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] booths 로드 실패: $e');
      return null;
    }
  }

  // ── festival preview list (탭2 목록, 필터 없는 첫 페이지) ──────────

  Future<void> savePreviewList(List<FestivalPreview> items) async {
    final sp = await _sp;
    await sp.setString(
        '${_p}_previews', jsonEncode(items.map((e) => e.toJson()).toList()));
    await _touch('${_p}_previews_time');
  }

  Future<List<FestivalPreview>?> loadPreviewList() async {
    if (await _isKeyStale('${_p}_previews_time')) return null;
    final sp = await _sp;
    final s = sp.getString('${_p}_previews');
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List)
          .map((e) => FestivalPreview.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] previews 로드 실패: $e');
      return null;
    }
  }

  // ── home screen data (좋아요 페스티벌 + 팔로우 아티스트) ──────────

  Future<void> saveHomeFestivals(int userId, List<FestivalModel> items) async {
    final sp = await _sp;
    await sp.setString('${_p}_home_festivals_$userId',
        jsonEncode(items.map((e) => e.toJson()).toList()));
    await _touch('${_p}_home_time_$userId');
  }

  Future<List<FestivalModel>?> loadHomeFestivals(int userId) async {
    if (await _isKeyStale('${_p}_home_time_$userId')) return null;
    final sp = await _sp;
    final s = sp.getString('${_p}_home_festivals_$userId');
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List)
          .map((e) => FestivalModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] home festivals 로드 실패: $e');
      return null;
    }
  }

  Future<void> saveHomeArtists(int userId, List<FollowedArtist> items) async {
    final sp = await _sp;
    await sp.setString('${_p}_home_artists_$userId',
        jsonEncode(items.map((e) => e.toJson()).toList()));
    await _touch('${_p}_home_artists_time_$userId');
  }

  Future<List<FollowedArtist>?> loadHomeArtists(int userId) async {
    if (await _isKeyStale('${_p}_home_artists_time_$userId')) return null;
    final sp = await _sp;
    final s = sp.getString('${_p}_home_artists_$userId');
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List)
          .map((e) => FollowedArtist.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] home artists 로드 실패: $e');
      return null;
    }
  }

  // ── clear ───────────────────────────────────────────────────────

  Future<void> clear(int festivalId) async {
    final sp = await _sp;
    await Future.wait([
      sp.remove('${_p}_festival_$festivalId'),
      sp.remove('${_p}_artists_$festivalId'),
      sp.remove('${_p}_timetable_$festivalId'),
      sp.remove('${_p}_setlist_$festivalId'),
      sp.remove('${_p}_booths_$festivalId'),
      sp.remove('${_p}_time_$festivalId'),
    ]);
  }

  Future<void> clearAll() async {
    final sp = await _sp;
    final keys = sp.getKeys().where((k) => k.startsWith('${_p}_')).toList();
    await Future.wait(keys.map((k) => sp.remove(k)));
  }
}
