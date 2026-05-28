import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_poster_notifier.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}
class MockFestivalInteractionService extends Mock implements FestivalInteractionService {}

CertificationModel _cert(int festivalId, CertStatus status) =>
    CertificationModel(
      festivalId: festivalId,
      status: status,
      festivalTitle: '록페스티벌',
    );

void main() {
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
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async => [
            _cert(5, CertStatus.approved),
            _cert(99, CertStatus.approved),
          ]);

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, true);
      expect(notifier.isPending, false);
    });

    test('해당 페스티벌에 PENDING 인증 있으면 isPending true', () async {
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async => [
            _cert(5, CertStatus.pending),
          ]);

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, true);
    });

    test('다른 페스티벌 인증만 있으면 둘 다 false', () async {
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async => [
            _cert(99, CertStatus.approved),
          ]);

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('REJECTED 인증만 있으면 둘 다 false', () async {
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async => [
            _cert(5, CertStatus.rejected),
          ]);

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('서비스 예외 시 크래시 없이 기본값 유지', () async {
      when(() => mockCertService.getMyCertifications()).thenThrow(Exception('err'));

      final notifier = make(5);
      await expectLater(notifier.loadCertState(), completes);

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('인증 목록 비어있으면 둘 다 false', () async {
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async => []);

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, false);
      expect(notifier.isPending, false);
    });

    test('동일 페스티벌에 APPROVED와 PENDING 둘 다 있으면 isCertified 우선', () async {
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async => [
            _cert(5, CertStatus.approved),
            _cert(5, CertStatus.pending),
          ]);

      final notifier = make(5);
      await notifier.loadCertState();

      expect(notifier.isCertified, true);
      expect(notifier.isPending, false);
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
      when(() => mockFestivalInteractionService.toggleLike(5))
          .thenAnswer((_) async => true);

      final notifier = make(5);
      notifier.liked = false;
      await notifier.toggleLike();

      expect(notifier.liked, true);
    });

    test('liked true → false로 전환', () async {
      when(() => mockFestivalInteractionService.toggleLike(5))
          .thenAnswer((_) async => false);

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
