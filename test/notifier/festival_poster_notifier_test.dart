import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/my_certification_status.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/model/ticket_link.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_poster_notifier.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}
class MockFestivalInteractionService extends Mock implements FestivalInteractionService {}
class MockFestivalDetailService extends Mock implements FestivalDetailService {}
class MockFestivalService extends Mock implements FestivalService {}

FestivalModel _testPoster(int id, {String title = '펜타포트'}) => FestivalModel(
      id: id,
      title: title,
      description: '',
      location: '인천 송도달빛축제공원',
      startDate: '2099-08-01',
      endDate: '2099-08-03',
      posterUrl: '',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCertificationService mockCertService;
  late MockFestivalInteractionService mockFestivalInteractionService;
  late MockFestivalDetailService mockDetailService;
  late MockFestivalService mockFestivalDataService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() {
    mockCertService = MockCertificationService();
    mockFestivalInteractionService = MockFestivalInteractionService();
    mockDetailService = MockFestivalDetailService();
    mockFestivalDataService = MockFestivalService();
  });

  FestivalPosterNotifier make(int festivalId, {FestivalModel? poster}) => FestivalPosterNotifier(
        poster: poster ?? _testPoster(festivalId),
        certService: mockCertService,
        festivalService: mockFestivalInteractionService,
        detailService: mockDetailService,
        festivalDataService: mockFestivalDataService,
      );

  group('loadMyCertificationStatus', () {
    test('해당 페스티벌에 APPROVED 인증 있으면 isCertified true', () async {
      when(() => mockCertService.getMyCertificationStatus(5)).thenAnswer((_) async =>
          MyCertificationStatus(status: CertStatus.approved, certId: 1, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadMyCertificationStatus();

      expect(notifier.isCertified, true);
      expect(notifier.isPending, false);
    });

    test('해당 페스티벌에 PENDING 인증 있으면 isPending true', () async {
      when(() => mockCertService.getMyCertificationStatus(5)).thenAnswer((_) async =>
          MyCertificationStatus(status: CertStatus.pending, certId: null, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadMyCertificationStatus();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, true);
    });

    test('인증 없으면 둘 다 false', () async {
      when(() => mockCertService.getMyCertificationStatus(5)).thenAnswer((_) async =>
          MyCertificationStatus(status: null, certId: null, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadMyCertificationStatus();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('REJECTED 인증이면 둘 다 false', () async {
      when(() => mockCertService.getMyCertificationStatus(5)).thenAnswer((_) async =>
          MyCertificationStatus(status: CertStatus.rejected, certId: null, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadMyCertificationStatus();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('서비스 예외 시 크래시 없이 기본값 유지', () async {
      when(() => mockCertService.getMyCertificationStatus(5)).thenThrow(Exception('err'));

      final notifier = make(5);
      await expectLater(notifier.loadMyCertificationStatus(), completes);

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('인증 없는 경우 isCertified false, isPending false', () async {
      when(() => mockCertService.getMyCertificationStatus(5)).thenAnswer((_) async =>
          MyCertificationStatus(status: null, certId: null, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadMyCertificationStatus();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('APPROVED 상태에서 isCertified true, isPending false 동시 검증', () async {
      when(() => mockCertService.getMyCertificationStatus(5)).thenAnswer((_) async =>
          MyCertificationStatus(status: CertStatus.approved, certId: 1, myRating: 4, myReview: '좋아요'));

      final notifier = make(5);
      await notifier.loadMyCertificationStatus();

      expect(notifier.isCertified, true);
      expect(notifier.isPending, false);
      expect(notifier.certId, 1);
      expect(notifier.myRating, 4);
      verify(() => mockCertService.getMyCertificationStatus(5)).called(1);
    });
  });

  group('loadLikeState', () {
    test('서비스가 true 반환 시 liked true', () async {
      when(() => mockFestivalInteractionService.isLiked(5)).thenAnswer((_) async => true);

      final notifier = make(5);
      await notifier.loadLikeState();

      expect(notifier.liked, true);
    });

    test('서비스가 false 반환 시 liked false', () async {
      when(() => mockFestivalInteractionService.isLiked(5)).thenAnswer((_) async => false);

      final notifier = make(5);
      await notifier.loadLikeState();

      expect(notifier.liked, false);
    });

    test('서비스 예외 시 liked 기본값 false 유지', () async {
      when(() => mockFestivalInteractionService.isLiked(5)).thenThrow(Exception('err'));

      final notifier = make(5);
      await expectLater(notifier.loadLikeState(), completes);

      expect(notifier.liked, false);
    });
  });

  group('refreshPoster', () {
    test('상세 API가 최신 정보를 반환하면 poster를 통째로 교체', () async {
      when(() => mockFestivalDataService.fetchById(5))
          .thenAnswer((_) async => _testPoster(5, title: '펜타포트 2026 최신판'));

      final notifier = make(5, poster: _testPoster(5, title: '캐시된 옛날 제목'));
      await notifier.refreshPoster();

      expect(notifier.poster.title, '펜타포트 2026 최신판');
    });

    test('서비스 예외 시 호출부가 넘겨준 poster를 그대로 유지 (hasInitError 미설정)', () async {
      when(() => mockFestivalDataService.fetchById(5)).thenThrow(Exception('err'));
      final seedPoster = _testPoster(5, title: '목록에서 넘어온 제목');

      final notifier = make(5, poster: seedPoster);
      await expectLater(notifier.refreshPoster(), completes);

      expect(notifier.poster.title, '목록에서 넘어온 제목');
      expect(notifier.hasInitError, false);
    });
  });

  group('loadTicketLinks', () {
    test('서비스가 링크 목록을 반환하면 ticketLinks에 반영', () async {
      when(() => mockDetailService.fetchTicketLinks(5)).thenAnswer((_) async => [
            TicketLink(label: '인터파크', url: 'https://tickets.interpark.com/example'),
          ]);

      final notifier = make(5);
      await notifier.loadTicketLinks();

      expect(notifier.ticketLinks, hasLength(1));
      expect(notifier.ticketLinks.first.label, '인터파크');
    });

    test('서비스 예외 시 크래시 없이 빈 목록 유지 (hasInitError 미설정)', () async {
      when(() => mockDetailService.fetchTicketLinks(5)).thenThrow(Exception('err'));

      final notifier = make(5);
      await expectLater(notifier.loadTicketLinks(), completes);

      expect(notifier.ticketLinks, isEmpty);
      expect(notifier.hasInitError, false);
    });
  });

  group('toggleLike', () {
    test('liked false → true로 전환', () async {
      when(() => mockFestivalInteractionService.toggleLike(5)).thenAnswer((_) async {});

      final notifier = make(5);
      notifier.liked = false;
      await notifier.toggleLike();

      expect(notifier.liked, true);
    });

    test('liked true → false로 전환', () async {
      when(() => mockFestivalInteractionService.toggleLike(5)).thenAnswer((_) async {});

      final notifier = make(5);
      notifier.liked = true;
      await notifier.toggleLike();

      expect(notifier.liked, false);
    });

    test('서비스 예외 시 liked 상태 변경 없음', () async {
      when(() => mockFestivalInteractionService.toggleLike(5)).thenThrow(Exception('err'));

      final notifier = make(5);
      notifier.liked = false;
      await notifier.toggleLike();

      expect(notifier.liked, false);
    });
  });

  group('toggleDesc', () {
    test('descExpanded true → false로 전환', () {
      final notifier = make(5);
      expect(notifier.descExpanded, true);

      notifier.toggleDesc();

      expect(notifier.descExpanded, false);
    });

    test('descExpanded false → true로 전환', () {
      final notifier = make(5);
      notifier.descExpanded = false;

      notifier.toggleDesc();

      expect(notifier.descExpanded, true);
    });
  });
}
