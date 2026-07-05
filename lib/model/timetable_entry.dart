class TimetableRange {
  final List<TimetableEntry> filtered;
  final List<String> stages;
  final int startHour;
  final int endHour;

  const TimetableRange({
    required this.filtered,
    required this.stages,
    required this.startHour,
    required this.endHour,
  });
}

TimetableRange computeTimetableRange(List<TimetableEntry> entries, String? date) {
  const defaultStart = 12;
  final filtered = date == null
      ? <TimetableEntry>[]
      : entries.where((e) => e.festivalDate == date).toList();

  // 운영 항목(📢)은 별도 열 없이 모든 스테이지에 표시하므로 stages에서 제외
  final seen = <String, int>{};
  for (final e in filtered) {
    if (!e.isOps) seen.putIfAbsent(e.stageName, () => e.stageOrder);
  }
  final stages = (seen.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
      .map((e) => e.key)
      .toList();

  int startHour = defaultStart;
  for (final e in filtered) {
    final hour = int.tryParse(e.startTime.split(':')[0]);
    if (hour != null && hour < startHour) startHour = hour;
  }

  int endHour = startHour + 1;
  for (final e in filtered) {
    final parts = e.endTime.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0');
    if (hour == null || minute == null) continue;
    final candidateEnd = minute > 0 ? hour + 1 : hour;
    if (candidateEnd > endHour) endHour = candidateEnd;
  }

  return TimetableRange(filtered: filtered, stages: stages, startHour: startHour, endHour: endHour);
}

/// 타임테이블 항목 모델
class TimetableEntry {
  static const String _opsStage = '📢';

  final int id;
  final String stageName;
  final int stageOrder;
  final String artistName;
  final String artistNameEn;
  final String festivalDate;
  final String startTime;
  final String endTime;
  final List<String> memberArtistNames;
  final List<String> memberArtistNameEnList;

  const TimetableEntry({
    required this.id,
    required this.stageName,
    required this.stageOrder,
    required this.artistName,
    this.artistNameEn = '',
    required this.festivalDate,
    required this.startTime,
    required this.endTime,
    this.memberArtistNames = const [],
    this.memberArtistNameEnList = const [],
  });

  String displayName(bool isEnglish) =>
      isEnglish && artistNameEn.isNotEmpty ? artistNameEn : artistName;

  List<String> memberDisplayNames(bool isEnglish) =>
      isEnglish && memberArtistNameEnList.isNotEmpty
          ? memberArtistNameEnList
          : memberArtistNames;

  bool isFollowedBy(Set<String> followedNames) {
    if (followedNames.contains(artistName)) return true;
    return memberArtistNames.any(followedNames.contains);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stageName': stageName,
        'stageOrder': stageOrder,
        'artistName': artistName,
        'artistNameEn': artistNameEn,
        'festivalDate': festivalDate,
        'startTime': startTime,
        'endTime': endTime,
        'memberArtistNames': memberArtistNames,
        'memberArtistNameEnList': memberArtistNameEnList,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> j) => TimetableEntry(
        id: (j['id'] as num?)?.toInt() ?? 0,
        stageName: j['stageName'] as String? ?? '',
        stageOrder: (j['stageOrder'] as num?)?.toInt() ?? 999,
        artistName: j['artistName'] as String? ?? '',
        artistNameEn: j['artistNameEn'] as String? ?? '',
        festivalDate: j['festivalDate'] as String? ?? '',
        startTime: _toHHmm(j['startTime']),
        endTime: _toHHmm(j['endTime']),
        memberArtistNames: (j['memberArtistNames'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        memberArtistNameEnList: (j['memberArtistNameEnList'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );

  bool get isOps => stageName == _opsStage;

  String get timeRange => '$startTime – $endTime';

  int get durationMinutes {
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      final start = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final end = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      // 자정을 넘기는 공연(예: 23:30~00:30) 대응 — 종료가 시작보다 빠르면 다음날로 간주
      return end >= start ? end - start : (end + 24 * 60) - start;
    } catch (_) {
      return 0;
    }
  }

  static String _toHHmm(dynamic val) {
    final s = val?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}
