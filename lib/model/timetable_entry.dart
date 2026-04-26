/// 타임테이블 항목 모델
class TimetableEntry {
  final int id;
  final String stageName;
  final int stageOrder;
  final String artistName;
  final String festivalDate;
  final String startTime;
  final String endTime;

  const TimetableEntry({
    required this.id,
    required this.stageName,
    required this.stageOrder,
    required this.artistName,
    required this.festivalDate,
    required this.startTime,
    required this.endTime,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> j) => TimetableEntry(
        id: (j['id'] as num).toInt(),
        stageName: j['stageName'] as String,
        stageOrder: (j['stageOrder'] as num?)?.toInt() ?? 999,
        artistName: j['artistName'] as String,
        festivalDate: j['festivalDate'] as String,
        startTime: _toHHmm(j['startTime']),
        endTime: _toHHmm(j['endTime']),
      );

  static String _toHHmm(dynamic val) {
    final s = val?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }
}
