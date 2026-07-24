import 'dart:convert';

import 'package:feple/model/my_timetable_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 페스티벌별 "내 일정" 목록의 로드/저장 — 날짜별 SharedPreferences JSON 직렬화.
/// 중첩된 `Map<날짜, List<MyTimetableEntry>>` 구조라 AppPreferences의 단순
/// 타입(String/int/`List<String>` 등)으로는 표현이 안 돼 자체 JSON 인코딩 사용.
class MyTimetableStore {
  MyTimetableStore(this.festivalId);

  final int festivalId;

  String get _prefKey => 'user_timetable_entries_$festivalId';

  Future<Map<String, List<MyTimetableEntry>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(
          k,
          (v as List).map((e) => MyTimetableEntry.fromJson(e as Map<String, dynamic>)).toList(),
        ),
      );
    } catch (e) {
      debugPrint('[Timetable] load user entries failed: $e');
      return {};
    }
  }

  Future<void> save(Map<String, List<MyTimetableEntry>> entriesByDate) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      entriesByDate.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
    );
    await prefs.setString(_prefKey, encoded);
  }
}
