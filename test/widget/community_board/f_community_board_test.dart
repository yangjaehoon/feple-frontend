import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/f_community_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_post.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/service/notification_countable.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPostService extends Mock implements PostService {}
class MockNotificationCountable extends Mock implements NotificationCountable {}

Post _post({int id = 1, String title = '게시글'}) =>
    Post(id: id, title: title, content: '내용', likeCount: 0, nickname: '작성자');

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
        // CommunityBoardFragment는 탭 콘텐츠라 자체 Scaffold가 없음 — 실제 앱처럼
        // 부모(App)가 제공하는 Scaffold/Material 컨텍스트를 여기서 대신 감싸준다.
        child: const MaterialApp(home: Scaffold(body: CommunityBoardFragment())),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPostService mockPostService;
  late MockNotificationCountable mockNotificationCountable;

  setUp(() {
    mockPostService = MockPostService();
    mockNotificationCountable = MockNotificationCountable();

    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    sl.registerSingleton<PostService>(mockPostService);
    if (sl.isRegistered<NotificationCountable>()) sl.unregister<NotificationCountable>();
    sl.registerSingleton<NotificationCountable>(mockNotificationCountable);
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
    sl.registerFactory<NotificationCountNotifier>(() => NotificationCountNotifier());

    when(() => mockNotificationCountable.getUnreadCount()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    if (sl.isRegistered<NotificationCountable>()) sl.unregister<NotificationCountable>();
    if (sl.isRegistered<NotificationCountNotifier>()) {
      sl.unregister<NotificationCountNotifier>();
    }
  });

  group('CommunityBoardFragment 렌더링', () {
    testWidgets('세 게시판(인기/자유/동행)을 모두 보여준다', (tester) async {
      when(() => mockPostService.fetchPosts(BoardTypes.hot))
          .thenAnswer((_) async => [_post(id: 1, title: '인기글')]);
      when(() => mockPostService.fetchPosts(BoardTypes.free))
          .thenAnswer((_) async => [_post(id: 2, title: '자유글')]);
      when(() => mockPostService.fetchPosts(BoardTypes.mate))
          .thenAnswer((_) async => [_post(id: 3, title: '동행글')]);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('hot_board'.tr()), findsOneWidget);
      expect(find.text('free_board'.tr()), findsOneWidget);
      expect(find.text('companion_board'.tr()), findsOneWidget);
      expect(find.text('인기글'), findsOneWidget);
      expect(find.text('자유글'), findsOneWidget);
      expect(find.text('동행글'), findsOneWidget);
    });
  });

  group('CommunityBoardFragment 새로고침', () {
    testWidgets('pull-to-refresh 시 세 게시판 모두 다시 불러온다', (tester) async {
      var hotCalls = 0, freeCalls = 0, mateCalls = 0;
      when(() => mockPostService.fetchPosts(BoardTypes.hot)).thenAnswer((_) async {
        hotCalls++;
        return <Post>[];
      });
      when(() => mockPostService.fetchPosts(BoardTypes.free)).thenAnswer((_) async {
        freeCalls++;
        return <Post>[];
      });
      when(() => mockPostService.fetchPosts(BoardTypes.mate)).thenAnswer((_) async {
        mateCalls++;
        return <Post>[];
      });

      await _pump(tester);
      await tester.pumpAndSettle();
      expect(hotCalls, 1);
      expect(freeCalls, 1);
      expect(mateCalls, 1);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pumpAndSettle();

      expect(hotCalls, 2);
      expect(freeCalls, 2);
      expect(mateCalls, 2);
    });
  });

  group('CommunityBoardFragment 네비게이션', () {
    testWidgets('게시판 헤더를 탭하면 CommunityPost 목록 화면으로 이동한다', (tester) async {
      when(() => mockPostService.fetchPosts(BoardTypes.free))
          .thenAnswer((_) async => [_post(title: '자유글')]);
      when(() => mockPostService.fetchPostsPage(
            BoardTypes.free,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
            sort: any(named: 'sort'),
          )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));
      when(() => mockPostService.fetchPosts(BoardTypes.hot)).thenAnswer((_) async => []);
      when(() => mockPostService.fetchPosts(BoardTypes.mate)).thenAnswer((_) async => []);

      await _pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('free_board'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(CommunityPost), findsOneWidget);
    });
  });
}
