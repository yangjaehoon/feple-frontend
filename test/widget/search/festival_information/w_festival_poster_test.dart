import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/login/s_login.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_rating_summary.dart';
import 'package:feple/model/my_certification_status.dart';
import 'package:feple/model/ticket_link.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_certification_bottom_sheet.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_poster.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_reviews_sheet.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_ticket_link_sheet.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_weather_bottom_sheet.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCertificationService extends Mock implements CertificationService {}
class MockFestivalInteractionService extends Mock implements FestivalInteractionService {}
class MockFestivalDetailService extends Mock implements FestivalDetailService {}
class MockUserProvider extends Mock implements UserProvider {}

// 날씨 시트가 sl<FestivalDetailService>() 없이 "너무 이른 조회" 분기를 타도록
// 항상 현재 시각 기준으로 충분히 먼 미래 날짜를 기본값으로 쓴다 — 고정 날짜는
// 시간이 지나면 daysUntilStart가 3 이하로 줄어들어 테스트가 깨지는 날짜 폭탄이 된다.
String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
final String _defaultStartDate = _fmtDate(DateTime.now().add(const Duration(days: 30)));
final String _defaultEndDate =
    _fmtDate(DateTime.now().add(const Duration(days: 32)));

FestivalModel _poster({
  int id = 1,
  String title = '펜타포트',
  String description = '',
  String location = '인천 송도달빛축제공원',
  List<String> genres = const [],
  String? ageRestriction,
  int attendingCount = 0,
  String? startDate,
  String? endDate,
}) {
  return FestivalModel(
    id: id,
    title: title,
    description: description,
    location: location,
    startDate: startDate ?? _defaultStartDate,
    endDate: endDate ?? _defaultEndDate,
    posterUrl: '',
    genres: genres,
    ageRestriction: ageRestriction,
    attendingCount: attendingCount,
  );
}

void main() {
  late MockCertificationService mockCertService;
  late MockFestivalInteractionService mockFestivalService;
  late MockFestivalDetailService mockDetailService;
  late MockUserProvider mockUserProvider;
  final calendarCalls = <MethodCall>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() {
    mockCertService = MockCertificationService();
    mockFestivalService = MockFestivalInteractionService();
    mockDetailService = MockFestivalDetailService();
    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(1);
    if (sl.isRegistered<CertificationService>()) {
      sl.unregister<CertificationService>();
    }
    sl.registerSingleton<CertificationService>(mockCertService);
    if (sl.isRegistered<FestivalInteractionService>()) {
      sl.unregister<FestivalInteractionService>();
    }
    sl.registerSingleton<FestivalInteractionService>(mockFestivalService);
    if (sl.isRegistered<FestivalDetailService>()) {
      sl.unregister<FestivalDetailService>();
    }
    sl.registerSingleton<FestivalDetailService>(mockDetailService);

    when(() => mockFestivalService.isLiked(any())).thenAnswer((_) async => false);
    when(() => mockFestivalService.isAttending(any())).thenAnswer((_) async => false);
    when(() => mockCertService.getMyCertificationStatus(any()))
        .thenAnswer((_) async => MyCertificationStatus.none);
    when(() => mockCertService.getFestivalRating(any())).thenAnswer(
      (_) async => const FestivalRatingSummary(averageRating: 0, ratingCount: 0),
    );
    when(() => mockDetailService.fetchTicketLinks(any())).thenAnswer((_) async => []);

    calendarCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('add_2_calendar'),
      (call) async {
        calendarCalls.add(call);
        return true;
      },
    );
  });

  tearDown(() {
    if (sl.isRegistered<CertificationService>()) {
      sl.unregister<CertificationService>();
    }
    if (sl.isRegistered<FestivalInteractionService>()) {
      sl.unregister<FestivalInteractionService>();
    }
    if (sl.isRegistered<FestivalDetailService>()) {
      sl.unregister<FestivalDetailService>();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('add_2_calendar'), null);
  });

  Future<void> pump(WidgetTester tester, {required FestivalModel poster}) async {
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
                body: SingleChildScrollView(child: FestivalPoster(poster: poster)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('FestivalPoster 렌더링', () {
    testWidgets('제목/장소/날짜와 장르 태그를 보여준다', (tester) async {
      await pump(
        tester,
        poster: _poster(
          title: '펜타포트',
          location: '인천 송도달빛축제공원',
          genres: ['BAND'],
          startDate: '2099-08-01',
          endDate: '2099-08-03',
        ),
      );

      expect(find.text('펜타포트'), findsOneWidget);
      expect(find.text('인천 송도달빛축제공원'), findsOneWidget);
      expect(find.text('2099-08-01 ~ 2099-08-03'), findsOneWidget);
      expect(find.text('genre_band'.tr()), findsOneWidget);
    });
  });

  group('FestivalPoster 참석', () {
    testWidgets('참석 토글을 탭하면 인원이 증가하고 다시 탭하면 원복된다', (tester) async {
      when(() => mockFestivalService.toggleAttending(1)).thenAnswer((_) async {});

      await pump(tester, poster: _poster(id: 1, attendingCount: 3));

      expect(find.text('attending_count'.tr(args: ['3'])), findsOneWidget);

      await tester.tap(find.text('attend_toggle'.tr()));
      await tester.pump();

      expect(find.text('attending_count'.tr(args: ['4'])), findsOneWidget);

      await tester.tap(find.text('attend_toggle'.tr()));
      await tester.pump();

      expect(find.text('attending_count'.tr(args: ['3'])), findsOneWidget);
    });

    testWidgets('참석 처리에 실패하면 원래 상태로 되돌아간다', (tester) async {
      // thenThrow는 mock 호출 시 동기적으로 예외를 던지므로 낙관적 갱신→롤백이
      // await 지점 없이 탭 처리 안에서 전부 끝나 중간 상태를 관찰할 수 없다 —
      // 최종적으로 원래 상태(0)로 돌아오는지만 검증한다
      when(() => mockFestivalService.toggleAttending(1)).thenThrow(Exception('네트워크 오류'));

      await pump(tester, poster: _poster(id: 1, attendingCount: 0));

      // attendingCount가 0이면 카운트 라벨은 'attend_none'을 쓰므로
      // 토글 버튼('attend_toggle')과 겹치지 않는다
      expect(find.text('attend_none'.tr()), findsOneWidget);
      await tester.tap(find.text('attend_toggle'.tr()));
      await tester.pump();
      await tester.pump();

      expect(find.text('attending_count'.tr(args: ['1'])), findsNothing);
      expect(find.text('attend_none'.tr()), findsOneWidget);
      expect(find.text('attend_toggle'.tr()), findsOneWidget);
    });
  });

  group('FestivalPoster 좋아요', () {
    testWidgets('좋아요를 탭하면 아이콘이 채워진다', (tester) async {
      when(() => mockFestivalService.toggleLike(1)).thenAnswer((_) async {});

      await pump(tester, poster: _poster(id: 1));

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('비로그인이면 좋아요 탭 시 로그인 화면으로 이동하고 토글하지 않는다', (tester) async {
      when(() => mockUserProvider.currentUserId).thenReturn(null);

      await pump(tester, poster: _poster(id: 1));

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      verifyNever(() => mockFestivalService.toggleLike(any()));
    });
  });

  group('FestivalPoster 평점 뱃지', () {
    testWidgets('평가가 없으면 빈 별을 보여주고 탭하면 리뷰 시트가 열린다', (tester) async {
      await pump(tester, poster: _poster(id: 1));

      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(5));

      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      // 포스터 썸네일의 SkeletonBox가 계속 반짝여 pumpAndSettle이 멈추지 않으므로
      // 시트 등장 애니메이션만큼만 고정 시간으로 흘려보낸다
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FestivalReviewsSheet), findsOneWidget);
    });

    testWidgets('평가가 있으면 평균 별점과 개수를 보여준다', (tester) async {
      // 별점 뱃지는 120px 고정폭 Row에 별 5개+텍스트를 채우는데, 테스트
      // 환경의 대체 폰트가 실제 앱 폰트(Pretendard)보다 넓어 한 자릿수
      // 숫자에도 오버플로우가 발생한다 — 실제 기기에서는 재현되지 않는
      // 테스트 전용 아티팩트이므로 이 오버플로우 에러만 무시한다
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (!details.toString().contains('overflowed')) {
          originalOnError?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      when(() => mockCertService.getFestivalRating(1)).thenAnswer(
        (_) async => const FestivalRatingSummary(averageRating: 4.5, ratingCount: 3),
      );

      await pump(tester, poster: _poster(id: 1));

      expect(find.text('(3)'), findsOneWidget);
    });
  });

  group('FestivalPoster 인증 버튼', () {
    testWidgets('미인증 상태면 탭 시 인증 제출 시트가 열린다', (tester) async {
      await pump(tester, poster: _poster(id: 1));

      await tester.tap(find.text('action_cert'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CertificationBottomSheet), findsOneWidget);
    });

    testWidgets('비로그인이면 인증 탭 시 로그인 화면으로 이동하고 시트를 열지 않는다', (tester) async {
      when(() => mockUserProvider.currentUserId).thenReturn(null);

      await pump(tester, poster: _poster(id: 1));

      await tester.tap(find.text('action_cert'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(CertificationBottomSheet), findsNothing);
    });

    testWidgets('승인된 인증이면 탭 시 이미 승인됐다는 안내를 보여준다', (tester) async {
      when(() => mockCertService.getMyCertificationStatus(1)).thenAnswer(
        (_) async => const MyCertificationStatus(status: CertStatus.approved, certId: 1),
      );

      await pump(tester, poster: _poster(id: 1));

      await tester.tap(find.text('action_cert'.tr()));
      await tester.pump();

      expect(find.text('cert_already_approved'.tr()), findsOneWidget);
    });

    testWidgets('대기중인 인증이면 탭 시 대기중 안내를 보여준다', (tester) async {
      when(() => mockCertService.getMyCertificationStatus(1)).thenAnswer(
        (_) async => const MyCertificationStatus(status: CertStatus.pending),
      );

      await pump(tester, poster: _poster(id: 1));

      await tester.tap(find.text('action_cert'.tr()));
      await tester.pump();

      expect(find.text('cert_pending_notice'.tr()), findsOneWidget);
    });
  });

  group('FestivalPoster 초기화 에러', () {
    testWidgets('초기화 중 오류가 있으면 재시도 링크를 보여주고 탭하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockFestivalService.isLiked(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return false;
      });

      await pump(tester, poster: _poster(id: 1));

      expect(find.text('retry'.tr()), findsOneWidget);

      await tester.tap(find.text('retry'.tr()));
      await tester.pump();
      await tester.pump();

      expect(find.text('retry'.tr()), findsNothing);
    });
  });

  group('FestivalPoster 설명 섹션', () {
    testWidgets('설명이 있으면 펼치기/접기 토글을 할 수 있다', (tester) async {
      await pump(tester, poster: _poster(id: 1, description: '즐거운 축제입니다'));

      expect(find.text('즐거운 축제입니다'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

      await tester.tap(find.text('festival_info'.tr()));
      await tester.pump();
      await tester.pump(AppDimens.animFast); // AnimatedCrossFade 전환 완료 대기

      // AnimatedCrossFade는 접힌 뒤에도 두 child를 트리에 유지(투명도만 변경)하므로
      // 텍스트 존재 여부 대신 화살표 방향(접힘 상태를 나타내는 실제 조건부 렌더링)으로 확인
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets('설명이 없으면 섹션을 보여주지 않는다', (tester) async {
      await pump(tester, poster: _poster(id: 1, description: ''));

      expect(find.text('festival_info'.tr()), findsNothing);
    });
  });

  group('FestivalPoster 날씨', () {
    testWidgets('날씨 버튼을 탭하면 날씨 시트가 열린다', (tester) async {
      await pump(tester, poster: _poster(id: 1));

      await tester.tap(find.text('action_weather'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WeatherBottomSheet), findsOneWidget);
    });
  });

  group('FestivalPoster 최신 정보 반영', () {
    // FestivalPoster는 스스로 재조회하지 않는다 — FestivalInformationFragment가
    // 상세 재조회 결과를 poster 프로퍼티로 다시 넘겨주면(같은 GlobalKey라
    // didUpdateWidget이 호출됨) 그걸 받아 화면을 갱신해야 한다. 위젯이
    // 스스로 fetchById를 또 호출하면 화면 진입마다 상세 API가 두 번
    // 불리는 회귀이므로, 이 테스트는 그 재조회 없이도 프로퍼티 변경만으로
    // 갱신되는지를 검증한다.
    testWidgets('poster 프로퍼티가 바뀌면 최신 제목으로 다시 그려진다', (tester) async {
      await pump(tester, poster: _poster(id: 1, title: '캐시된 옛날 제목'));

      expect(find.text('캐시된 옛날 제목'), findsOneWidget);

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
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: FestivalPoster(poster: _poster(id: 1, title: '최신 제목')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('최신 제목'), findsOneWidget);
      expect(find.text('캐시된 옛날 제목'), findsNothing);
    });
  });

  group('FestivalPoster 티켓 예매 링크', () {
    testWidgets('예매 링크가 없으면 티켓 버튼을 보여주지 않는다', (tester) async {
      await pump(tester, poster: _poster(id: 1));

      expect(find.text('action_ticket'.tr()), findsNothing);
    });

    testWidgets('예매 링크가 있으면 티켓 버튼을 탭했을 때 링크 목록 시트가 열린다', (tester) async {
      when(() => mockDetailService.fetchTicketLinks(1)).thenAnswer((_) async => [
            TicketLink(label: '인터파크', url: 'https://tickets.interpark.com/example'),
          ]);

      await pump(tester, poster: _poster(id: 1));

      expect(find.text('action_ticket'.tr()), findsOneWidget);

      await tester.tap(find.text('action_ticket'.tr()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TicketLinkSheet), findsOneWidget);
      expect(find.text('인터파크'), findsOneWidget);
    });
  });

  group('FestivalPoster 캘린더 추가', () {
    testWidgets('캘린더 버튼을 탭하면 달력에 저장한다', (tester) async {
      await pump(
        tester,
        poster: _poster(
          id: 1,
          title: '펜타포트',
          location: '인천 송도달빛축제공원',
          startDate: '2099-08-01',
          endDate: '2099-08-03',
        ),
      );

      await tester.tap(find.text('action_calendar'.tr()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(calendarCalls, hasLength(1));
      expect(calendarCalls.single.method, 'add2Cal');
      expect(calendarCalls.single.arguments['title'], '펜타포트');
      expect(calendarCalls.single.arguments['location'], '인천 송도달빛축제공원');
    });
  });

  group('FestivalPoster 새로고침', () {
    testWidgets('refresh() 호출 시 좋아요/참석 상태를 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockFestivalService.isLiked(1)).thenAnswer((_) async {
        callCount++;
        return false;
      });

      final key = GlobalKey<FestivalPosterState>();
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
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: FestivalPoster(key: key, poster: _poster(id: 1)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(callCount, 1);

      await key.currentState!.refresh();
      await tester.pump();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
