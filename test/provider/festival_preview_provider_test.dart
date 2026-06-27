import 'package:feple/model/festival_preview.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFestivalService extends Mock implements FestivalService {}

FestivalPreview _preview(int id) => FestivalPreview(
      id: id,
      title: '페스티벌 $id',
      location: '서울',
      posterUrl: 'https://example.com/poster.jpg',
      startDate: '2099-07-01', // 미래 날짜 → isEnded=false
    );

List<FestivalPreview> _pages(int count) =>
    List.generate(count, (i) => _preview(i + 1));

void main() {
  late MockFestivalService mockService;

  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  setUp(() {
    mockService = MockFestivalService();
  });

  void stubFetch(List<FestivalPreview> result) {
    when(() => mockService.fetchPreviews(
          page: any(named: 'page'),
          size: any(named: 'size'),
          includeEnded: any(named: 'includeEnded'),
          genres: any(named: 'genres'),
          regions: any(named: 'regions'),
          ageRestrictions: any(named: 'ageRestrictions'),
        )).thenAnswer((_) async => result);
  }

  void stubFetchCallback(List<FestivalPreview> Function(int page) fn) {
    var callCount = 0;
    when(() => mockService.fetchPreviews(
          page: any(named: 'page'),
          size: any(named: 'size'),
          includeEnded: any(named: 'includeEnded'),
          genres: any(named: 'genres'),
          regions: any(named: 'regions'),
          ageRestrictions: any(named: 'ageRestrictions'),
        )).thenAnswer((_) async => fn(callCount++));
  }

  void stubFetchThrow() {
    when(() => mockService.fetchPreviews(
          page: any(named: 'page'),
          size: any(named: 'size'),
          includeEnded: any(named: 'includeEnded'),
          genres: any(named: 'genres'),
          regions: any(named: 'regions'),
          ageRestrictions: any(named: 'ageRestrictions'),
        )).thenThrow(Exception('network error'));
  }

  Future<FestivalPreviewProvider> make() async {
    final p = FestivalPreviewProvider(mockService);
    await Future.delayed(Duration.zero); // 생성자의 비동기 refresh 완료 대기
    return p;
  }

  // ───────────────────────────────────────────────────
  // A. 초기 로드
  // ───────────────────────────────────────────────────
  group('A. 초기 로드', () {
    test('생성 시 fetchPreviews 호출되고 아이템 채워짐', () async {
      stubFetch(_pages(5));

      final notifier = await make();

      expect(notifier.items.length, 5);
      expect(notifier.isLoading, false);
      expect(notifier.error, isNull);
    });

    test('전체 페이지(20개) 수신 시 hasMore=true', () async {
      stubFetch(_pages(20));

      final notifier = await make();

      expect(notifier.hasMore, true);
    });

    test('부분 페이지(20개 미만) 수신 시 hasMore=false', () async {
      stubFetch(_pages(7));

      final notifier = await make();

      expect(notifier.hasMore, false);
    });

    test('서비스 예외 → error 설정, items 비어있음', () async {
      stubFetchThrow();

      final notifier = await make();

      expect(notifier.items, isEmpty);
      expect(notifier.error, isNotNull);
      expect(notifier.isLoading, false);
    });
  });

  // ───────────────────────────────────────────────────
  // B. 페이지네이션
  // ───────────────────────────────────────────────────
  group('B. 페이지네이션', () {
    test('fetchNext 호출 시 다음 페이지 아이템 추가', () async {
      stubFetchCallback((page) => page == 0 ? _pages(20) : _pages(5));

      final notifier = await make();
      expect(notifier.items.length, 20);

      await notifier.fetchNext();

      expect(notifier.items.length, 25);
      expect(notifier.hasMore, false);
    });

    test('hasMore=false이면 fetchNext 무시', () async {
      stubFetch(_pages(3));

      final notifier = await make();
      expect(notifier.hasMore, false);

      await notifier.fetchNext();

      verify(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).called(1); // 생성자의 1회만
    });

    test('page 0 재요청 시 기존 아이템 교체', () async {
      stubFetchCallback((page) => _pages(5));

      final notifier = await make();
      expect(notifier.items.length, 5);

      await notifier.refresh(force: true);

      expect(notifier.items.length, 5); // 교체 (추가 아님)
    });
  });

  // ───────────────────────────────────────────────────
  // C. 에러 처리
  // ───────────────────────────────────────────────────
  group('C. 에러 처리', () {
    test('기존 아이템 있을 때 에러 → error=null (조용한 실패)', () async {
      var callCount = 0;
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async {
        if (callCount++ == 0) return _pages(5);
        throw Exception('network error');
      });

      final notifier = await make();
      expect(notifier.items.length, 5);

      await notifier.refresh(force: true);

      expect(notifier.error, isNull); // 조용한 실패
      expect(notifier.isLoading, false);
    });

    test('아이템 없을 때 에러 → error 설정', () async {
      stubFetchThrow();

      final notifier = await make();

      expect(notifier.error, isNotNull);
    });
  });

  // ───────────────────────────────────────────────────
  // D. refresh
  // ───────────────────────────────────────────────────
  group('D. refresh', () {
    test('force=false이면 신선한 데이터 있을 때 skip', () async {
      stubFetch(_pages(5));

      final notifier = await make();
      await notifier.refresh(); // force=false, 5분 이내

      // 생성자 1회 + refresh 0회 = 1회
      verify(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).called(1);
    });

    test('force=true이면 항상 재요청', () async {
      stubFetch(_pages(5));

      final notifier = await make();
      await notifier.refresh(force: true);

      verify(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).called(2);
    });
  });

  // ───────────────────────────────────────────────────
  // E. 필터
  // ───────────────────────────────────────────────────
  group('E. 필터', () {
    test('toggleGenre로 장르 추가/제거', () async {
      stubFetch([]);

      final notifier = await make();

      notifier.toggleGenre('록');
      expect(notifier.selectedGenres, contains('록'));

      notifier.toggleGenre('록');
      expect(notifier.selectedGenres, isEmpty);
    });

    test('toggleRegion으로 지역 추가', () async {
      stubFetch([]);

      final notifier = await make();

      notifier.toggleRegion('서울');
      expect(notifier.selectedRegions, contains('서울'));
    });

    test('toggleAgeRestriction으로 연령 제한 추가', () async {
      stubFetch([]);

      final notifier = await make();

      notifier.toggleAgeRestriction('전체');
      expect(notifier.selectedAgeRestrictions, contains('전체'));
    });

    test('여러 장르 동시 선택 가능', () async {
      stubFetch([]);

      final notifier = await make();

      notifier.toggleGenre('록');
      notifier.toggleGenre('팝');

      expect(notifier.selectedGenres, containsAll(['록', '팝']));
    });

    test('clearFilters로 모든 필터 초기화', () async {
      stubFetch([]);

      final notifier = await make();

      notifier.toggleGenre('록');
      notifier.toggleRegion('서울');
      notifier.toggleAgeRestriction('전체');
      notifier.clearFilters();

      expect(notifier.selectedGenres, isEmpty);
      expect(notifier.selectedRegions, isEmpty);
      expect(notifier.selectedAgeRestrictions, isEmpty);
    });

    test('필터 변경 후 debounce 경과하면 API 재호출', () async {
      stubFetch([]);

      final notifier = await make();
      clearInteractions(mockService);

      notifier.toggleGenre('록');
      await Future.delayed(const Duration(milliseconds: 450)); // debounce(400ms) 경과

      verify(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).called(1);
    });

    test('debounce 내 연속 변경 → API 1회만 호출', () async {
      stubFetch([]);

      final notifier = await make();
      clearInteractions(mockService);

      notifier.toggleGenre('록');
      notifier.toggleRegion('서울');
      notifier.toggleAgeRestriction('전체');
      await Future.delayed(const Duration(milliseconds: 450));

      verify(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).called(1);
    });
  });

  // ───────────────────────────────────────────────────
  // F. dispose
  // ───────────────────────────────────────────────────
  group('F. dispose', () {
    test('dispose 후 safeNotify가 예외 없이 동작', () async {
      stubFetch([]);

      final notifier = await make();
      notifier.dispose();

      expect(notifier.isDisposed, true);
      // dispose 후 메서드 호출해도 크래시 없음
      notifier.toggleGenre('록');
    });
  });
}
