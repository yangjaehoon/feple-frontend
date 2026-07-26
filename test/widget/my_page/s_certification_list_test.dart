import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/my_page/s_certification_list.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}
class MockFestivalService extends Mock implements FestivalService {}

CertificationModel _cert({
  int id = 1,
  CertStatus status = CertStatus.approved,
  String title = '페스티벌',
  int? rating,
  String? review,
  String? rejectionMessage,
}) =>
    CertificationModel(
      id: id,
      festivalId: id * 10,
      status: status,
      festivalTitle: title,
      myRating: rating,
      myReview: review,
      rejectionMessage: rejectionMessage,
    );

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: CustomThemeHolder(
        theme: CustomTheme.light,
        changeTheme: (_) {},
        child: const MaterialApp(home: CertificationListScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCertificationService mockCertService;
  late MockFestivalService mockFestivalService;

  setUp(() {
    mockCertService = MockCertificationService();
    mockFestivalService = MockFestivalService();
    if (sl.isRegistered<CertificationService>()) sl.unregister<CertificationService>();
    sl.registerSingleton<CertificationService>(mockCertService);
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
  });

  tearDown(() {
    if (sl.isRegistered<CertificationService>()) sl.unregister<CertificationService>();
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
  });

  group('CertificationListScreen 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<List<CertificationModel>>();
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) => completer.future);

      await _pump(tester);

      expect(find.byType(SkeletonBox), findsWidgets);
      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('CertificationListScreen 빈 목록', () {
    testWidgets('인증 내역이 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async => []);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('cert_no_history'.tr()), findsOneWidget);
    });
  });

  group('CertificationListScreen 목록 있음', () {
    testWidgets('인증 카드 제목과 상태 배지를 보여준다', (tester) async {
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async => [
            _cert(id: 1, title: '서울재즈', status: CertStatus.approved),
            _cert(id: 2, title: '펜타포트', status: CertStatus.pending),
          ]);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('서울재즈'), findsOneWidget);
      expect(find.text('펜타포트'), findsOneWidget);
      // 상태 라벨은 필터 칩 + 카드 배지 양쪽에 나타나므로 최소 1개 이상 존재
      expect(find.text('cert_status_approved'.tr()), findsWidgets);
      expect(find.text('cert_status_pending'.tr()), findsWidgets);
    });

    testWidgets('승인된 인증은 별점 등록 UI를 보여준다', (tester) async {
      when(() => mockCertService.getMyCertifications())
          .thenAnswer((_) async => [_cert(status: CertStatus.approved, rating: null)]);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('rating_submit'.tr()), findsOneWidget);
    });

    testWidgets('별점이 이미 있으면 별 아이콘과 리뷰를 보여준다', (tester) async {
      when(() => mockCertService.getMyCertifications()).thenAnswer(
          (_) async => [_cert(status: CertStatus.approved, rating: 4, review: '최고의 공연')]);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      expect(find.text('최고의 공연'), findsOneWidget);
    });

    testWidgets('반려된 인증은 반려 사유를 보여준다', (tester) async {
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async =>
          [_cert(status: CertStatus.rejected, rejectionMessage: '사진이 흐립니다')]);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('cert_rejection_reason'.tr(args: ['사진이 흐립니다'])), findsOneWidget);
    });
  });

  group('CertificationListScreen 필터', () {
    testWidgets('상태 필터를 선택하면 해당 상태만 표시된다', (tester) async {
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async => [
            _cert(id: 1, title: '승인된축제', status: CertStatus.approved),
            _cert(id: 2, title: '대기중축제', status: CertStatus.pending),
          ]);

      await _pump(tester);
      await tester.pumpAndSettle();
      expect(find.text('승인된축제'), findsOneWidget);
      expect(find.text('대기중축제'), findsOneWidget);

      await tester.tap(find.text('cert_status_pending'.tr()).first);
      await tester.pumpAndSettle();

      expect(find.text('승인된축제'), findsNothing);
      expect(find.text('대기중축제'), findsOneWidget);
    });
  });

  group('CertificationListScreen 에러', () {
    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여주고 재시도할 수 있다', (tester) async {
      var callCount = 0;
      when(() => mockCertService.getMyCertifications()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_cert(title: '재시도축제')];
      });

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('재시도축제'), findsOneWidget);
      expect(callCount, 2);
    });
  });
}
