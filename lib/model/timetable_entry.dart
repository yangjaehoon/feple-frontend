import 'json_reader.dart';
import 'localized_text.dart';

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

String formatTimeRange(String startTime, String endTime) => '$startTime – $endTime';

/// 'HH:mm' 문자열을 (hour, minute)으로 파싱. 형식이 잘못되면 0으로 처리.
({int hour, int minute}) parseHHmm(String time) {
  final parts = time.split(':');
  return (
    hour: int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
    minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
  );
}

/// 'HH:mm' 시각을 그리드 시작 시각(startHour) 기준 Y좌표(px)로 환산.
double timetableMinutesToY(String time, int startHour, double pxPerMin) {
  final t = parseHHmm(time);
  return ((t.hour - startHour) * 60 + t.minute) * pxPerMin;
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

  // 그리드는 첫 아티스트 공연 시각부터 시작한다. 운영 항목(📢, 게이트 오픈 등)은
  // 기준에서 제외하며, 공연이 하나도 없으면 defaultStart(12시)로 폴백한다.
  int? firstArtistHour;
  for (final e in filtered) {
    if (e.isOps) continue;
    final hour = int.tryParse(e.startTime.split(':')[0]);
    if (hour != null && (firstArtistHour == null || hour < firstArtistHour)) {
      firstArtistHour = hour;
    }
  }
  final startHour = firstArtistHour ?? defaultStart;

  // durationMinutes는 자정을 넘기는 공연도 감안해 실제 소요 시간을 계산하므로,
  // endTime을 그대로 파싱하는 대신 "시작 시각 + 소요 시간"으로 종료 시각을 구해야
  // 자정 넘김 카드가 그리드 하단에서 잘리지 않는다.
  int endHour = startHour + 1;
  for (final e in filtered) {
    final start = parseHHmm(e.startTime);
    final endMinutesFromMidnight = start.hour * 60 + start.minute + e.durationMinutes;
    final candidateEnd = (endMinutesFromMidnight / 60).ceil();
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

  String displayName(bool isEnglish) => pickLocalized(isEnglish, artistName, artistNameEn);

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
        id: j.integer('id'),
        stageName: j.str('stageName'),
        stageOrder: j.integer('stageOrder', 999),
        artistName: j.str('artistName'),
        artistNameEn: j.str('artistNameEn'),
        festivalDate: j.str('festivalDate'),
        startTime: _toHHmm(j['startTime']),
        endTime: _toHHmm(j['endTime']),
        memberArtistNames: j.stringList('memberArtistNames'),
        memberArtistNameEnList: j.stringList('memberArtistNameEnList'),
      );

  bool get isOps => stageName == _opsStage;

  String get timeRange => formatTimeRange(startTime, endTime);

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
