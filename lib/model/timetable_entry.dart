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

/// 그리드 시작 시각(startHour)보다 이 시간(시) 이상 이른 항목은 자정을 넘긴
/// "다음날"로 본다. 반나절(12h)을 임계로 삼아 — 게이트 오픈처럼 몇 시간만 이른
/// 항목은 그대로 두고(상단 고정), 저녁 시작 페스티벌의 새벽 세트만 다음날로
/// 밀어(그리드 하단) 처리한다. 절대 시각이 아닌 startHour 상대값이므로
/// 밤샘 페스티벌(startHour 자체가 새벽)에서도 오작동하지 않는다.
const int _festivalDayWrapGapHours = 12;

/// [hour]를 "페스티벌 하루" 기준 시각으로 환산 — startHour보다 반나절 이상
/// 이르면 +24.
int hourInFestivalDay(int hour, int startHour) =>
    (hour < startHour && startHour - hour >= _festivalDayWrapGapHours)
        ? hour + 24
        : hour;

/// 'HH:mm' 시각을 그리드 시작 시각(startHour) 기준 Y좌표(px)로 환산.
/// 자정 넘김 항목은 다음날로 밀어 그리드 하단에, startHour보다 조금 이른 항목
/// (예: 저녁 공연 페스티벌의 "게이트 오픈")은 상단(0)에 고정한다.
double timetableMinutesToY(String time, int startHour, double pxPerMin) {
  final t = parseHHmm(time);
  final minutes =
      (hourInFestivalDay(t.hour, startHour) - startHour) * 60 + t.minute;
  return (minutes < 0 ? 0 : minutes) * pxPerMin;
}

/// 'HH:mm' 구간의 소요 분. end <= start면 자정을 넘긴 것으로 보고 +24h.
int hhmmDurationMinutes(String startTime, String endTime) {
  final s = parseHHmm(startTime);
  final e = parseHHmm(endTime);
  final start = s.hour * 60 + s.minute;
  final end = e.hour * 60 + e.minute;
  return end >= start ? end - start : (end + 24 * 60) - start;
}

/// [entries] 중 "그날 프로그램이 시작되는" 시각(시).
/// 어떤 항목이 다른 항목보다 반나절 이상 이르면(저녁 클러스터 + 새벽 세트처럼
/// 시간이 크게 벌어지면) 그 이른 항목은 자정을 넘긴 것으로 보고 후보에서 뺀다.
/// 그런 항목만 남으면(전부 새벽) 그중 최솟값을 쓴다. 항목이 없으면 null.
int? _dayStartHour(Iterable<TimetableEntry> entries) {
  final hours = <int>[
    for (final e in entries)
      if (int.tryParse(e.startTime.split(':')[0]) case final int h) h,
  ];
  if (hours.isEmpty) return null;
  final candidates = hours
      .where((h) => !hours.any((o) => o - h >= _festivalDayWrapGapHours))
      .toList();
  return (candidates.isEmpty ? hours : candidates)
      .reduce((a, b) => a < b ? a : b);
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

  // 그리드는 가장 이른 아티스트 공연 시각부터 시작한다. 아티스트 공연이 하나도
  // 없으면 가장 이른 운영 항목(📢, 게이트 오픈 등) 시각을, 그마저 없으면
  // (빈 타임테이블) defaultStart(12시)를 쓴다. 자정을 넘긴 새벽 세트는
  // startHour 계산에서 제외한다(_dayStartHour).
  final startHour = _dayStartHour(filtered.where((e) => !e.isOps)) ??
      _dayStartHour(filtered.where((e) => e.isOps)) ??
      defaultStart;

  // durationMinutes는 자정을 넘기는 공연도 감안해 실제 소요 시간을 계산하므로,
  // endTime을 그대로 파싱하는 대신 "시작 시각 + 소요 시간"으로 종료 시각을 구해야
  // 자정 넘김 카드가 그리드 하단에서 잘리지 않는다. 심야 시작 항목은 +24시간으로
  // 환산해 그리드가 다음날 시각까지 확장되게 한다.
  int endHour = startHour + 1;
  for (final e in filtered) {
    final start = parseHHmm(e.startTime);
    final endMinutes = hourInFestivalDay(start.hour, startHour) * 60 +
        start.minute +
        e.durationMinutes;
    final candidateEnd = (endMinutes / 60).ceil();
    if (candidateEnd > endHour) endHour = candidateEnd;
  }

  return TimetableRange(filtered: filtered, stages: stages, startHour: startHour, endHour: endHour);
}

/// 타임테이블 항목 모델
class TimetableEntry {
  /// 운영 항목(공지·게이트 오픈 등)을 나타내는 stageName 마커.
  static const String opsStageName = '📢';

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

  bool get isOps => stageName == opsStageName;

  String get timeRange => formatTimeRange(startTime, endTime);

  // 자정을 넘기는 공연(예: 23:30~00:30)도 종료가 시작보다 빠르면 다음날로 간주.
  int get durationMinutes => hhmmDurationMinutes(startTime, endTime);

  static String _toHHmm(dynamic val) {
    final s = val?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}
