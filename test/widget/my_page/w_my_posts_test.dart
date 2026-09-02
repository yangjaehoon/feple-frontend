import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/my_page/w_my_posts.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserActivityService extends Mock implements UserActivityService {}

Post _post({
  int id = 1,
  String title = '글',
  String boardDisplayName = '자유 게시판',
  bool anonymous = false,
}) =>
    Post(
      id: id,
      title: title,
      content: '내용',
      likeCount: 4,
      commentCount: 3,
      nickname: '작성자',
      boardDisplayName: boardDisplayName,
      anonymous: anonymous,
    );

void main() {
  late MockUserActivityService mockService;

  setUp(() {
    mockService = MockUserActivityService();
    if (sl.isRegistered<UserActivityService>()) {
      sl.unregister<UserActivityService>();
    }
    sl.registerSingleton<UserActivityService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<UserActivityService>()) {
      sl.unregister<UserActivityService>();
    }
  });

  Future<void> pump(WidgetTester tester, {String? title}) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

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
          child: MaterialApp(home: MyPostsView(userId: 1, title: title)),
        ),
      ),
    );
    await tester.pump();
  }

  group('MyPostsView 렌더링', () {
    testWidgets('기본 제목과 게시글 목록을 보여준다', (tester) async {
      when(() => mockService.fetchPostsPage(
            1,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PostCursorPage(
            content: [_post(id: 1, title: '내 글1'), _post(id: 2, title: '내 글2')],
            hasNext: false,
          ));

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('my_posts'.tr()), findsOneWidget);
      expect(find.text('내 글1'), findsOneWidget);
      expect(find.text('내 글2'), findsOneWidget);
    });

    testWidgets('익명 글에는 익명 태그, 일반 글에는 없다', (tester) async {
      when(() => mockService.fetchPostsPage(
            1,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => PostCursorPage(
            content: [
              _post(id: 1, title: '익명 글', anonymous: true),
              _post(id: 2, title: '일반 글'),
            ],
            hasNext: false,
          ));

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('anonymous_tag'.tr()), findsOneWidget);
    });

    testWidgets('title을 지정하면 커스텀 제목을 보여준다', (tester) async {
      when(() => mockService.fetchPostsPage(
            1,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));

      await pump(tester, title: '작성한 글');
      await tester.pumpAndSettle();

      expect(find.text('작성한 글'), findsOneWidget);
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchPostsPage(
            1,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async => const PostCursorPage(content: [], hasNext: false));

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('no_posts'.tr()), findsOneWidget);
    });

    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchPostsPage(
            1,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return PostCursorPage(content: [_post(title: '복구된 글')], hasNext: false);
      });

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('복구된 글'), findsOneWidget);
    });
  });

  group('MyPostsView 새로고침', () {
    testWidgets('pull-to-refresh 시 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchPostsPage(
            1,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((_) async {
        callCount++;
        return PostCursorPage(content: [_post(title: '글 $callCount')], hasNext: false);
      });

      await pump(tester);
      await tester.pumpAndSettle();
      expect(callCount, 1);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pumpAndSettle();

      expect(callCount, 2);
    });
  });
}
