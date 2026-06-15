import 'package:feple/model/timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/timetable_notifier.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFestivalDetailService extends Mock implements FestivalDetailService {}
class MockArtistFollowService extends Mock implements ArtistFollowService {}

TimetableEntry _entry({
  int id = 1,
  String stageName = 'Main',
  int stageOrder = 1,
  String artistName = 'Artist',
  String festivalDate = '2025-08-01',
  String startTime = '15:00',
  String endTime = '16:00',
}) =>
    TimetableEntry(
      id: id,
      stageName: stageName,
      stageOrder: stageOrder,
      artistName: artistName,
      festivalDate: festivalDate,
      startTime: startTime,
      endTime: endTime,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFestivalDetailService mockDetailService;
  late MockArtistFollowService mockFollowService;

  setUp(() {
    mockDetailService = MockFestivalDetailService();
    mockFollowService = MockArtistFollowService();
  });

  TimetableNotifier make({
    int festivalId = 1,
    int? userId,
    String startDate = '2025-08-01',
    String endDate = '2025-08-03',
  }) =>
      TimetableNotifier(
        festivalId: festivalId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        festivalService: mockDetailService,
        followService: mockFollowService,
      );

  group('_buildDates (생성자)', () {
    test('startDate~endDate 범위의 날짜 목록 생성, selectedDate는 첫 번째', () {
      final notifier = make(startDate: '2025-08-01', endDate: '2025-08-03');

      expect(notifier.dates, ['2025-08-01', '2025-08-02', '2025-08-03']);
      expect(notifier.selectedDate, '2025-08-01');
    });

    test('startDate == endDate이면 날짜 1개', () {
      final notifier = make(startDate: '2025-08-01', endDate: '2025-08-01');

      expect(notifier.dates, ['2025-08-01']);
    });

    test('startDate 빈 문자열이면 dates 비어있고 selectedDate null', () {
      final notifier = make(startDate: '', endDate: '');

      expect(notifier.dates, isEmpty);
      expect(notifier.selectedDate, isNull);
    });

    test('잘못된 날짜 형식이면 dates 비어있음', () {
      final notifier = make(startDate: 'not-a-date', endDate: '2025-08-03');

      expect(notifier.dates, isEmpty);
    });
  });

  group('fetch', () {
    test('성공 시 entries·followedNames 채워지고 isLoading false, error null', () async {
      when(() => mockDetailService.fetchTimetable(1))
          .thenAnswer((_) async => [_entry(id: 1), _entry(id: 2)]);
      when(() => mockFollowService.fetchFollowedArtistNames(42))
          .thenAnswer((_) async => {'Artist A', 'Artist B'});

      final notifier = make(userId: 42);
      await notifier.fetch();

      expect(notifier.entries.length, 2);
      expect(notifier.followedNames, {'Artist A', 'Artist B'});
      expect(notifier.isLoading, false);
      expect(notifier.error, isNull);
    });

    test('userId null이면 followService 미호출, entries 정상 로드', () async {
      when(() => mockDetailService.fetchTimetable(1))
          .thenAnswer((_) async => [_entry()]);

      final notifier = make(userId: null);
      await notifier.fetch();

      verifyNever(() => mockFollowService.fetchFollowedArtistNames(any()));
      expect(notifier.entries.length, 1);
      expect(notifier.followedNames, isEmpty);
    });

    test('followedArtistNames 실패해도 entries 정상 로드, error null', () async {
      when(() => mockDetailService.fetchTimetable(1))
          .thenAnswer((_) async => [_entry()]);
      when(() => mockFollowService.fetchFollowedArtistNames(42))
          .thenThrow(Exception('network'));

      final notifier = make(userId: 42);
      await notifier.fetch();

      expect(notifier.entries.length, 1);
      expect(notifier.followedNames, isEmpty);
      expect(notifier.isLoading, false);
      expect(notifier.error, isNull);
    });

    test('timetable fetch 실패 시 error 설정, isLoading false, entries 비어있음', () async {
      when(() => mockDetailService.fetchTimetable(1))
          .thenThrow(Exception('timeout'));

      final notifier = make(userId: null);
      await notifier.fetch();

      expect(notifier.error, isNotNull);
      expect(notifier.isLoading, false);
      expect(notifier.entries, isEmpty);
    });
  });

  group('selectDate', () {
    test('selectedDate 변경', () {
      final notifier = make(startDate: '2025-08-01', endDate: '2025-08-02');

      notifier.selectDate('2025-08-02');

      expect(notifier.selectedDate, '2025-08-02');
    });

    test('null 전달 시 selectedDate null', () {
      final notifier = make();

      notifier.selectDate(null);

      expect(notifier.selectedDate, isNull);
    });
  });

  group('retry', () {
    test('error 초기화 후 재요청, 성공 시 정상 상태 복구', () async {
      when(() => mockDetailService.fetchTimetable(1))
          .thenThrow(Exception('first'));

      final notifier = make(userId: null);
      await notifier.fetch();
      expect(notifier.error, isNotNull);

      when(() => mockDetailService.fetchTimetable(1))
          .thenAnswer((_) async => [_entry()]);

      await notifier.retry();

      expect(notifier.error, isNull);
      expect(notifier.entries.length, 1);
      expect(notifier.isLoading, false);
    });
  });
}
