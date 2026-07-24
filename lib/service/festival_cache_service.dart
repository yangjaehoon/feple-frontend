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

  // ── 공용 save/load — 모델 타입별 toJson/fromJson만 다름 ───────────

  Future<void> _saveList<T>(
    String dataKey,
    String tsKey,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final sp = await _sp;
    await sp.setString(dataKey, jsonEncode(items.map(toJson).toList()));
    await _touch(tsKey);
  }

  Future<List<T>?> _loadList<T>(
    String dataKey,
    String tsKey,
    T Function(Map<String, dynamic>) fromJson,
    String logLabel,
  ) async {
    if (await _isKeyStale(tsKey)) return null;
    final sp = await _sp;
    final s = sp.getString(dataKey);
    if (s == null) return null;
    try {
      return (jsonDecode(s) as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Cache] $logLabel 로드 실패: $e');
      return null;
    }
  }

  // ── artists ─────────────────────────────────────────────────────

  Future<void> saveArtists(int id, List<FestivalArtistItem> items) =>
      _saveList('${_p}_artists_$id', '${_p}_artists_time_$id', items,
          (e) => e.toJson());

  Future<List<FestivalArtistItem>?> loadArtists(int id) => _loadList(
      '${_p}_artists_$id', '${_p}_artists_time_$id',
      FestivalArtistItem.fromJson, 'artists');

  // ── timetable ───────────────────────────────────────────────────

  Future<void> saveTimetable(int id, List<TimetableEntry> entries) =>
      _saveList('${_p}_timetable_$id', '${_p}_timetable_time_$id', entries,
          (e) => e.toJson());

  Future<List<TimetableEntry>?> loadTimetable(int id) => _loadList(
      '${_p}_timetable_$id', '${_p}_timetable_time_$id',
      TimetableEntry.fromJson, 'timetable');

  // ── setlist ─────────────────────────────────────────────────────

  Future<void> saveSetlist(int id, List<FestivalSetlistEntry> entries) =>
      _saveList('${_p}_setlist_$id', '${_p}_setlist_time_$id', entries,
          (e) => e.toJson());

  Future<List<FestivalSetlistEntry>?> loadSetlist(int id) => _loadList(
      '${_p}_setlist_$id', '${_p}_setlist_time_$id',
      FestivalSetlistEntry.fromJson, 'setlist');

  // ── booths ──────────────────────────────────────────────────────

  Future<void> saveBooths(int id, List<BoothModel> booths) => _saveList(
      '${_p}_booths_$id', '${_p}_booths_time_$id', booths, (e) => e.toJson());

  Future<List<BoothModel>?> loadBooths(int id) => _loadList(
      '${_p}_booths_$id', '${_p}_booths_time_$id', BoothModel.fromJson,
      'booths');

  // ── festival preview list (탭2 목록, 필터 없는 첫 페이지) ──────────

  Future<void> savePreviewList(List<FestivalPreview> items) => _saveList(
      '${_p}_previews', '${_p}_previews_time', items, (e) => e.toJson());

  Future<List<FestivalPreview>?> loadPreviewList() => _loadList(
      '${_p}_previews', '${_p}_previews_time', FestivalPreview.fromJson,
      'previews');

  // ── home screen data (좋아요 페스티벌 + 팔로우 아티스트) ──────────

  Future<void> saveHomeFestivals(int userId, List<FestivalModel> items) =>
      _saveList('${_p}_home_festivals_$userId', '${_p}_home_time_$userId',
          items, (e) => e.toJson());

  Future<List<FestivalModel>?> loadHomeFestivals(int userId) => _loadList(
      '${_p}_home_festivals_$userId', '${_p}_home_time_$userId',
      FestivalModel.fromJson, 'home festivals');

  Future<void> saveHomeArtists(int userId, List<FollowedArtist> items) =>
      _saveList('${_p}_home_artists_$userId',
          '${_p}_home_artists_time_$userId', items, (e) => e.toJson());

  Future<List<FollowedArtist>?> loadHomeArtists(int userId) => _loadList(
      '${_p}_home_artists_$userId', '${_p}_home_artists_time_$userId',
      FollowedArtist.fromJson, 'home artists');

  // ── clear ───────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final sp = await _sp;
    final keys = sp.getKeys().where((k) => k.startsWith('${_p}_')).toList();
    await Future.wait(keys.map((k) => sp.remove(k)));
  }
}
