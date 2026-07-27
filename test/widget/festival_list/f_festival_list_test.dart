import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/festival_list/f_festival_list.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_suggestion_sheet.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFestivalService extends Mock implements FestivalService {}
class MockUserProvider extends Mock implements UserProvider {}
class MockNotificationCountable extends Mock implements NotificationCountable {}

FestivalPreview _festival({int id = 1, String title = '페스티벌'}) => FestivalPreview(
      id: id,
      title: title,
      location: '서울',
      posterUrl: '',
      startDate: DateTime.now().toIso8601String(),
    );

Future<void> _pump(
  WidgetTester tester, {
  required FestivalPreviewProvider festivalPreviewProvider,
  int? currentUserId = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final userProvider = MockUserProvider();
  when(() => userProvider.currentUserId).thenReturn(currentUserId);

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
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<FestivalPreviewProvider>.value(
              value: festivalPreviewProvider,
            ),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(body: FestivalListFragment()),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFestivalService mockService;
  late MockNotificationCountable mockNotificationCountable;

  setUp(() {
    mockService = MockFestivalService();
    mockNotificationCountable = MockNotificationCountable();
    if (sl.isRegistered<NotificationCountable>()) {
      sl.unregister<NotificationCountable>();
    }
    sl.registerSingleton<NotificationCountable>(mockNotificationCountable);
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
    sl.registerFactory<NotificationCountNotifier>(() => NotificationCountNotifier());
    when(() => mockNotificationCountable.getUnreadCount()).thenAnswer((_) async => 0);

    when(() => mockService.fetchPreviews(
          page: any(named: 'page'),
          size: any(named: 'size'),
          includeEnded: any(named: 'includeEnded'),
          genres: any(named: 'genres'),
          regions: any(named: 'regions'),
          ageRestrictions: any(named: 'ageRestrictions'),
        )).thenAnswer((_) async => [_festival()]);
  });

  tearDown(() {
    if (sl.isRegistered<NotificationCountable>()) {
      sl.unregister<NotificationCountable>();
    }
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
  });

  group('FestivalListFragment 렌더링', () {
    testWidgets('AppBar 제목을 보여준다', (tester) async {
      await _pump(
        tester,
        festivalPreviewProvider: FestivalPreviewProvider(mockService),
      );

      expect(find.text('festival_schedule'.tr()), findsOneWidget);
    });
  });

  group('FestivalListFragment 필터 패널', () {
    testWidgets('필터 헤더를 탭하면 펼쳐지고 장르 칩을 탭하면 provider에 반영된다', (tester) async {
      final provider = FestivalPreviewProvider(mockService);
      await _pump(tester, festivalPreviewProvider: provider);

      expect(find.text('genre_hip_hop'.tr()), findsNothing);

      await tester.tap(find.text('btn_filter'.tr()));
      await tester.pump();

      expect(find.text('genre_hip_hop'.tr()), findsOneWidget);

      await tester.tap(find.text('genre_hip_hop'.tr()));
      await tester.pump();

      expect(provider.selectedGenres, contains('HIP_HOP'));
      expect(find.text('1'), findsOneWidget); // 활성 필터 개수 뱃지

      // toggleGenre가 예약한 400ms 디바운스 fetch 타이머를 흘려보낸다
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    });

    testWidgets('필터 초기화를 탭하면 선택된 필터가 모두 사라진다', (tester) async {
      final provider = FestivalPreviewProvider(mockService);
      await _pump(tester, festivalPreviewProvider: provider);

      await tester.tap(find.text('btn_filter'.tr()));
      await tester.pump();
      await tester.tap(find.text('genre_hip_hop'.tr()));
      await tester.pump();
      expect(provider.selectedGenres, isNotEmpty);

      await tester.tap(find.text('btn_reset'.tr()));
      await tester.pump();

      expect(provider.selectedGenres, isEmpty);

      // clearFilters도 400ms 디바운스 fetch 타이머를 예약하므로 흘려보낸다
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    });
  });

  group('FestivalListFragment 새로고침', () {
    testWidgets('pull-to-refresh 시 강제로 다시 불러온다', (tester) async {
      final provider = FestivalPreviewProvider(mockService);
      await _pump(tester, festivalPreviewProvider: provider);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pump();

      verify(() => mockService.fetchPreviews(
            page: any(named: 'page'),
            size: any(named: 'size'),
            includeEnded: any(named: 'includeEnded'),
            genres: any(named: 'genres'),
            regions: any(named: 'regions'),
            ageRestrictions: any(named: 'ageRestrictions'),
          )).called(greaterThanOrEqualTo(2));
    });
  });

  group('FestivalListFragment 페스티벌 제안 배너', () {
    testWidgets('로그인하지 않은 상태에서 탭하면 안내 스낵바를 보여준다', (tester) async {
      await _pump(
        tester,
        festivalPreviewProvider: FestivalPreviewProvider(mockService),
        currentUserId: null,
      );

      await tester.dragUntilVisible(
        find.text('festival_suggestion_banner'.tr()),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.tap(find.text('festival_suggestion_banner'.tr()));
      await tester.pump();

      expect(find.text('no_login_info'.tr()), findsOneWidget);
    });

    testWidgets('로그인한 상태에서 탭하면 제안 바텀시트가 열린다', (tester) async {
      await _pump(
        tester,
        festivalPreviewProvider: FestivalPreviewProvider(mockService),
      );

      await tester.dragUntilVisible(
        find.text('festival_suggestion_banner'.tr()),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.tap(find.text('festival_suggestion_banner'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(FestivalSuggestionSheet), findsOneWidget);
    });
  });
}
