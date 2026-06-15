import 'dart:convert';

import 'package:feple/model/booth_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 페스티벌 상세 데이터를 SharedPreferences에 JSON으로 저장하는 캐시.
/// 유효 시간: 24시간. 만료된 경우 null 반환.
class FestivalCacheService {
  static const _ttlHours = 24;
  static const _p = 'fc';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ── 유효성 ──────────────────────────────────────────────────────

  Future<bool> isStale(int festivalId) async {
    final sp = await _sp;
    final ts = sp.getInt('${_p}_time_$festivalId');
    if (ts == null) return true;
    return DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(ts))
            .inHours >=
        _ttlHours;
  }

  Future<void> _touch(int festivalId) async {
    final sp = await _sp;
    await sp.setInt(
        '${_p}_time_$festivalId', DateTime.now().millisecondsSinceEpoch);
  }

  // ── festival ────────────────────────────────────────────────────

  Future<void> saveFestival(int id, FestivalModel model) async {
    final sp = await _sp;
    await sp.setString('${_p}_festival_$id', jsonEncode(model.toJson()));
    await _touch(id);
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
}
