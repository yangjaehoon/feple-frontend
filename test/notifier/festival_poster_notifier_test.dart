import 'package:feple/model/cert_state_result.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_poster_notifier.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}
class MockFestivalInteractionService extends Mock implements FestivalInteractionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCertificationService mockCertService;
  late MockFestivalInteractionService mockFestivalInteractionService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockCertService = MockCertificationService();
    mockFestivalInteractionService = MockFestivalInteractionService();
  });

  FestivalPosterNotifier make(int festivalId) => FestivalPosterNotifier(
        festivalId: festivalId,
        certService: mockCertService,
        festivalService: mockFestivalInteractionService,
      );

  group('loadCertState', () {
    test('해당 페스티벌에 APPROVED 인증 있으면 isCertified true', () async {
      when(() => mockCertService.getCertState(5)).thenAnswer((_) async =>
          CertStateResult(status: CertStatus.approved, certId: 1, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, true);
      expect(notifier.isPending, false);
    });

    test('해당 페스티벌에 PENDING 인증 있으면 isPending true', () async {
      when(() => mockCertService.getCertState(5)).thenAnswer((_) async =>
          CertStateResult(status: CertStatus.pending, certId: null, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, true);
    });

    test('인증 없으면 둘 다 false', () async {
      when(() => mockCertService.getCertState(5)).thenAnswer((_) async =>
          CertStateResult(status: null, certId: null, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('REJECTED 인증이면 둘 다 false', () async {
      when(() => mockCertService.getCertState(5)).thenAnswer((_) async =>
          CertStateResult(status: CertStatus.rejected, certId: null, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('서비스 예외 시 크래시 없이 기본값 유지', () async {
      when(() => mockCertService.getCertState(5)).thenThrow(Exception('err'));

      final notifier = make(5);
      await expectLater(notifier.loadCertState(), completes);

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('인증 없는 경우 isCertified false, isPending false', () async {
      when(() => mockCertService.getCertState(5)).thenAnswer((_) async =>
          CertStateResult(status: null, certId: null, myRating: null, myReview: null));

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('APPROVED 상태에서 isCertified true, isPending false 동시 검증', () async {
      when(() => mockCertService.getCertState(5)).thenAnswer((_) async =>
          CertStateResult(status: CertStatus.approved, certId: 1, myRating: 4, myReview: '좋아요'));

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, true);
      expect(notifier.isPending, false);
      expect(notifier.certId, 1);
      expect(notifier.myRating, 4);
      verify(() => mockCertService.getCertState(5)).called(1);
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
