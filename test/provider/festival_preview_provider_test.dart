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

    // 백엔드(/festivals)는 페이지네이션 없이 필터에 맞는 전체 목록을 매번
    // 한 번에 반환하므로, 몇 개를 받든 "다음 페이지"는 존재하지 않는다.
    test('20개 이상 수신해도 hasMore=false', () async {
      stubFetch(_pages(20));

      final notifier = await make();

      expect(notifier.hasMore, false);
    });

    test('20개 미만 수신 시에도 hasMore=false', () async {
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
  // B. 페이지네이션 (백엔드가 미지원 — 중복 방지 확인)
  // ───────────────────────────────────────────────────
  group('B. 페이지네이션', () {
    // 회귀 방지: 예전엔 hasMore가 응답 개수(20개 이상이면 true)로 결정돼서,
    // 스크롤로 fetchNext가 다시 호출되면 백엔드가 항상 돌려주는 같은 전체
    // 목록을 또 append해 페스티벌이 중복으로 보이는 버그가 있었다.
    test('초기 로드 이후 fetchNext를 다시 호출해도 중복 추가 안 됨', () async {
      stubFetchCallback((page) => _pages(20));

      final notifier = await make();
      expect(notifier.items.length, 20);

      await notifier.fetchNext();

      expect(notifier.items.length, 20);
      verify(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).called(1); // 생성자의 1회만 — fetchNext는 hasMore=false라 무시됨
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
    test('기존 아이템 있을 때 page 0 에러 → error=null, refreshError 설정', () async {
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

      expect(notifier.error, isNull); // 전체 화면 에러 없음
      expect(notifier.refreshError, isNotNull); // snackbar용 에러 설정
      expect(notifier.isLoading, false);
    });

    // 초기 로드 실패 시 hasMore가 기본값(true)으로 유지되므로, fetchNext를
    // 다시 호출하면 재시도가 된다 — "더 불러오기"가 아니라 실패한 최초 로드의
    // 재시도라는 점만 다를 뿐 동작은 동일한 코드 경로를 탄다.
    test('초기 로드 실패 후 fetchNext 재호출 시 재시도됨', () async {
      var callCount = 0;
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async {
        if (callCount++ == 0) throw Exception('network error');
        return _pages(5);
      });

      final notifier = await make();
      expect(notifier.items, isEmpty);
      expect(notifier.error, isNotNull);

      await notifier.fetchNext();

      expect(notifier.items.length, 5);
      expect(notifier.hasMore, false);
    });

    test('clearRefreshError 후 refreshError=null', () async {
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
      await notifier.refresh(force: true);
      expect(notifier.refreshError, isNotNull);

      notifier.clearRefreshError();

      expect(notifier.refreshError, isNull);
    });

    test('성공 시 refreshError 자동 초기화', () async {
      var callCount = 0;
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((_) async {
        final c = callCount++;
        if (c == 0) return _pages(5);
        if (c == 1) throw Exception('error');
        return _pages(5);
      });

      final notifier = await make();
      await notifier.refresh(force: true); // 실패 → refreshError 설정
      expect(notifier.refreshError, isNotNull);

      await notifier.refresh(force: true); // 성공 → refreshError 초기화
      expect(notifier.refreshError, isNull);
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

    test('진행 중인 요청 응답보다 필터 변경이 먼저 끝나도 필터 결과가 최종 반영됨', () async {
      // 첫 fetchNext(생성자 refresh)는 느리게, 필터 변경 후 fetchNext는 빠르게 응답
      var callCount = 0;
      when(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).thenAnswer((invocation) async {
        final isFirstCall = callCount++ == 0;
        if (isFirstCall) {
          await Future.delayed(const Duration(milliseconds: 500));
          return _pages(3); // 필터 적용 전(느리게 도착)
        }
        return [_preview(99)]; // 필터 적용 후(빠르게 도착)
      });

      final provider = FestivalPreviewProvider(mockService);
      // 생성자의 첫 fetchNext가 아직 진행 중일 때 필터 변경
      await Future.delayed(const Duration(milliseconds: 10));
      provider.toggleGenre('록');
      await Future.delayed(const Duration(milliseconds: 450)); // debounce + 필터 응답 완료
      await Future.delayed(const Duration(milliseconds: 200)); // 느린 첫 응답도 도착

      // 필터 응답(1개, id=99)이 최종 반영되어야 하고, 느리게 도착한 첫 응답(3개)에 덮어써지면 안 됨
      expect(provider.items.length, 1);
      expect(provider.items.first.id, 99);
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
