bool isFestivalEnded(String? endDate) {
  if (endDate == null || endDate.isEmpty) return false;
  final end = DateTime.tryParse(endDate);
  if (end == null) return false;
  // 종료일 당일 자정 넘겨 진행되는 공연 등을 고려한 하루 유예 —
  // 제거 시 종료일 당일 저녁부터 바로 "종료"로 표시됨
  return end.isBefore(DateTime.now().subtract(const Duration(days: 1)));
}

int? festivalDDaysUntil({required String startDate, required bool isEnded}) {
  if (isEnded || startDate.isEmpty) return null;
  final start = DateTime.tryParse(startDate);
  if (start == null) return null;
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final startDay = DateTime(start.year, start.month, start.day);
  return startDay.difference(todayDate).inDays;
}
