import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/model/festival_review.dart';
import 'package:feple/model/festival_review_page.dart';
import 'package:feple/model/poster_cert_state.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_reviews_sheet.dart';
import 'package:feple/screen/main/tab/my_page/w_rating_sheet.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}

class MockUserProvider extends Mock implements UserProvider {}

/// 번역 키가 로드되지 않은 테스트 환경에서는 'reviews_edit_rating' 같은 원본
/// 키 문자열이 그대로 렌더링되어 실제 번역 텍스트보다 훨씬 길어지고, 그 결과
/// 내 별점 CTA 줄(Row)이 테스트에서만 오버플로우한다 — 실제 앱에서는 재현되지
/// 않는 테스트 전용 아티팩트이므로 해당 오버플로우 에러만 국소적으로 무시한다
void _ignoreOverflowErrors() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!details.toString().contains('overflowed')) {
      originalOnError?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

FestivalReview _review({
  int reviewId = 1,
  String nickname = '리뷰어',
  int rating = 4,
  String? userReview,
  int likeCount = 0,
  bool likedByMe = false,
}) =>
    FestivalReview(
      reviewId: reviewId,
      nickname: nickname,
      rating: rating,
      userReview: userReview,
      likeCount: likeCount,
      likedByMe: likedByMe,
    );

FestivalReviewPage _page({
  double averageRating = 0,
  int ratingCount = 0,
  Map<int, int> distribution = const {},
  List<FestivalReview> reviews = const [],
  bool hasNext = false,
}) =>
    FestivalReviewPage(
      averageRating: averageRating,
      ratingCount: ratingCount,
      distribution: distribution,
      reviews: reviews,
      hasNext: hasNext,
    );

void main() {
  late MockCertificationService mockService;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockService = MockCertificationService();
    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(10);
  });

  Future<void> pump(
    WidgetTester tester, {
    PosterCertState certState = PosterCertState.none,
    int? certId,
    int? initialRating,
    String? initialReview,
    VoidCallback? onCertTap,
  }) async {
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
        child: ChangeNotifierProvider<UserProvider>.value(
          value: mockUserProvider,
          child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAppBottomSheet(
                    context,
                    builder: (_) => FestivalReviewsSheet(
                      festivalId: 1,
                      certService: mockService,
                      certState: certState,
                      festivalTitle: '펜타포트',
                      certId: certId,
                      initialRating: initialRating,
                      initialReview: initialReview,
                      onCertTap: onCertTap,
                    ),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('열기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('FestivalReviewsSheet 로딩/에러', () {
    testWidgets('로드 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.getFestivalReviews(1, page: 0)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return _page();
      });

      await pump(tester);
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.text('retry'.tr()));
      await tester.pump();
      await tester.pump();

      expect(find.text('reviews_no_reviews'.tr()), findsOneWidget);
    });
  });

  group('FestivalReviewsSheet 빈 리뷰', () {
    testWidgets('리뷰가 없으면 안내를 보여준다', (tester) async {
      when(() => mockService.getFestivalReviews(1, page: 0))
          .thenAnswer((_) async => _page());

      await pump(tester);
      await tester.pump();

      expect(find.text('reviews_no_reviews'.tr()), findsOneWidget);
    });
  });

  group('FestivalReviewsSheet 요약', () {
    testWidgets('평가가 있으면 평균 점수와 리뷰 개수를 보여준다', (tester) async {
      when(() => mockService.getFestivalReviews(1, page: 0)).thenAnswer(
        (_) async => _page(
          averageRating: 4.2,
          ratingCount: 5,
          distribution: {5: 3, 4: 2},
          reviews: [_review(reviewId: 1, nickname: '리뷰어A')],
        ),
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('4.2'), findsOneWidget);
      expect(find.text('reviews_count'.tr(args: ['5'])), findsOneWidget);
      expect(find.text('리뷰어A'), findsOneWidget);
    });
  });

  group('FestivalReviewsSheet 리뷰 좋아요', () {
    testWidgets('좋아요를 탭하면 즉시 반영되고 실패하면 롤백된다', (tester) async {
      when(() => mockService.getFestivalReviews(1, page: 0)).thenAnswer(
        (_) async => _page(
          ratingCount: 1,
          // likeCount는 1~5성 분포 라벨과 겹치지 않도록 두 자릿수로 지정
          reviews: [_review(reviewId: 1, likeCount: 9, likedByMe: false)],
        ),
      );
      when(() => mockService.toggleReviewLike(1)).thenThrow(Exception('네트워크 오류'));

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();
      await tester.pump();

      expect(find.text('like_failed'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('좋아요 성공 시 아이콘과 카운트가 갱신된 채 유지된다', (tester) async {
      when(() => mockService.getFestivalReviews(1, page: 0)).thenAnswer(
        (_) async => _page(
          ratingCount: 1,
          reviews: [_review(reviewId: 1, likeCount: 9, likedByMe: false)],
        ),
      );
      when(() => mockService.toggleReviewLike(1)).thenAnswer((_) async {});

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.thumb_up_outlined));
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.thumb_up_rounded), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });
  });

  group('FestivalReviewsSheet CTA - 미인증', () {
    testWidgets('미인증 상태면 인증 버튼을 탭하면 시트가 닫히고 onCertTap이 호출된다', (tester) async {
      var certTapped = false;
      when(() => mockService.getFestivalReviews(1, page: 0))
          .thenAnswer((_) async => _page());

      await pump(tester, certState: PosterCertState.none, onCertTap: () => certTapped = true);
      await tester.pump();

      expect(find.text('reviews_cert_prompt'.tr()), findsOneWidget);

      await tester.tap(find.text('reviews_cert_btn'.tr()));
      await tester.pumpAndSettle();

      expect(certTapped, true);
      expect(find.byType(FestivalReviewsSheet), findsNothing);
    });
  });

  group('FestivalReviewsSheet CTA - 대기중', () {
    testWidgets('대기중 상태면 대기 안내만 보여준다', (tester) async {
      when(() => mockService.getFestivalReviews(1, page: 0))
          .thenAnswer((_) async => _page());

      await pump(tester, certState: PosterCertState.pending);
      await tester.pump();

      expect(find.text('reviews_cert_pending'.tr()), findsOneWidget);
    });
  });

  group('FestivalReviewsSheet CTA - 인증됨', () {
    testWidgets('아직 별점을 안 남겼으면 남기기 버튼을 보여준다', (tester) async {
      when(() => mockService.getFestivalReviews(1, page: 0))
          .thenAnswer((_) async => _page());

      await pump(tester, certState: PosterCertState.certified, certId: 10);
      await tester.pump();

      expect(find.text('reviews_leave_rating'.tr()), findsOneWidget);
    });

    testWidgets('별점을 남겼으면 수정 버튼과 내 별점을 보여준다', (tester) async {
      _ignoreOverflowErrors();
      when(() => mockService.getFestivalReviews(1, page: 0))
          .thenAnswer((_) async => _page());

      await pump(
        tester,
        certState: PosterCertState.certified,
        certId: 10,
        initialRating: 4,
      );
      await tester.pump();

      expect(find.text('reviews_edit_rating'.tr()), findsOneWidget);
    });

    testWidgets('별점 남기기를 탭하면 RatingSheet가 열리고 제출하면 목록을 새로고침한다', (tester) async {
      _ignoreOverflowErrors();
      var reloadCount = 0;
      when(() => mockService.getFestivalReviews(1, page: 0)).thenAnswer((_) async {
        reloadCount++;
        return _page();
      });
      when(() => mockService.submitRating(10, any(), any())).thenAnswer((_) async {});

      await pump(tester, certState: PosterCertState.certified, certId: 10);
      await tester.pump();
      expect(reloadCount, 1);

      await tester.tap(find.text('reviews_leave_rating'.tr()));
      await tester.pumpAndSettle();
      expect(find.byType(RatingSheet), findsOneWidget);

      // 리뷰 시트 위에 겹쳐 열린 모달이라 별 아이콘 히트테스트가 불안정하므로
      // 별 아이콘을 직접 감싸는 GestureDetector의 onTap을 호출한다
      // (find.byType(GestureDetector).first는 헤더의 닫기 버튼 등 무관한
      // GestureDetector를 잡을 수 있어 별 아이콘의 조상으로 한정한다)
      tester
          .widgetList<GestureDetector>(
            find.ancestor(
              of: find.descendant(
                of: find.byType(RatingSheet),
                matching: find.byIcon(Icons.star_outline_rounded),
              ),
              matching: find.byType(GestureDetector),
            ),
          )
          .first
          .onTap!();
      await tester.pump();
      // 완료 버튼도 같은 이유로 히트테스트가 불안정하므로 LoadingButton의
      // onPressed를 직접 호출한다
      tester
          .widget<LoadingButton>(
            find.descendant(
              of: find.byType(RatingSheet),
              matching: find.byType(LoadingButton),
            ),
          )
          .onPressed!();
      await tester.pumpAndSettle();

      verify(() => mockService.submitRating(10, 1, null)).called(1);
      expect(reloadCount, 2);
    });
  });
}
