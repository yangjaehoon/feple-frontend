import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_changed_event.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_community_board_card.dart';
import 'package:feple/screen/main/tab/community_board/w_community_post.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPostService extends Mock implements PostService {}
class MockUserProvider extends Mock implements UserProvider {}

Post _post({int id = 1, String title = '글'}) =>
    Post(id: id, title: title, content: '내용', likeCount: 0, scrapCount: 0, commentCount: 0, nickname: '작성자');

void main() {
  late MockPostService mockPostService;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockPostService = MockPostService();
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    sl.registerSingleton<PostService>(mockPostService);

    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(1);
  });

  tearDown(() {
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
  });

  Future<void> pump(WidgetTester tester, {GlobalKey<CommunityBoardCardState>? key}) async {
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
                body: CommunityBoardCard(
                  key: key,
                  title: '자유 게시판',
                  icon: Icons.edit_note_rounded,
                  headerColorFn: (colors) => colors.activate,
                  serviceBoardType: 'FREE',
                  boardName: '자유 게시판',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('CommunityBoardCard 렌더링', () {
    testWidgets('게시글 목록을 보여준다', (tester) async {
      when(() => mockPostService.fetchPosts('FREE'))
          .thenAnswer((_) async => [_post(title: '인기글')]);

      await pump(tester);
      await tester.pump();

      expect(find.text('자유 게시판'), findsOneWidget);
      expect(find.text('인기글'), findsOneWidget);
    });
  });

  group('CommunityBoardCard 네비게이션', () {
    testWidgets('헤더를 탭하면 게시판 전체 목록으로 이동한다', (tester) async {
      when(() => mockPostService.fetchPosts('FREE')).thenAnswer((_) async => []);
      when(() => mockPostService.fetchPostsPage('FREE',
              cursor: any(named: 'cursor'), size: any(named: 'size'), sort: any(named: 'sort')))
          .thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('자유 게시판'));
      await tester.pumpAndSettle();

      expect(find.byType(CommunityPost), findsOneWidget);
    });
  });

  group('CommunityBoardCard 글쓰기', () {
    testWidgets('로그인하지 않고 글쓰기를 탭하면 안내 스낵바를 보여준다', (tester) async {
      when(() => mockUserProvider.currentUserId).thenReturn(null);
      when(() => mockPostService.fetchPosts('FREE')).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('write_post'.tr()));
      await tester.pump();

      expect(find.text('no_login_info'.tr()), findsOneWidget);
    });

    testWidgets('로그인한 상태로 글쓰기를 탭하면 글쓰기 화면으로 이동한다', (tester) async {
      when(() => mockPostService.fetchPosts('FREE')).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('write_post'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(WritePost), findsOneWidget);
    });
  });

  group('CommunityBoardCard 새로고침', () {
    testWidgets('refresh를 호출하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockPostService.fetchPosts('FREE')).thenAnswer((_) async {
        callCount++;
        return [];
      });
      final key = GlobalKey<CommunityBoardCardState>();

      await pump(tester, key: key);
      await tester.pump();
      expect(callCount, 1);

      await key.currentState!.refresh();
      await tester.pump();

      expect(callCount, 2);
    });

    testWidgets('AppEvents.postChanged가 발생하면 자동으로 새로고침한다', (tester) async {
      var callCount = 0;
      when(() => mockPostService.fetchPosts('FREE')).thenAnswer((_) async {
        callCount++;
        return [];
      });

      await pump(tester);
      await tester.pump();
      expect(callCount, 1);

      AppEvents.postChanged.value = PostChangedEvent.refreshAll();
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
