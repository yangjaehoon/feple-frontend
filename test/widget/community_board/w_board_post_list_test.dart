import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_post_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Post _post({int id = 1, String title = '글', int? userId = 5, String nickname = '작성자'}) =>
    Post(id: id, title: title, content: '내용', likeCount: 0, nickname: nickname, userId: userId);

Future<void> _pump(
  WidgetTester tester, {
  required Future<PostCursorPage> Function({int? cursor, int size}) fetchPage,
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
      child: CustomThemeHolder(
        theme: CustomTheme.light,
        changeTheme: (_) {},
        child: MaterialApp(
          home: BoardPostList(
            boardName: '자유 게시판',
            fetchPage: fetchPage,
            writeScreenTitle: '자유 게시판 글쓰기',
            onSubmitPost: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BoardPostList 렌더링', () {
    testWidgets('게시글 목록을 보여준다', (tester) async {
      await _pump(
        tester,
        fetchPage: ({cursor, size = 20}) async =>
            PostCursorPage(content: [_post(title: '글1'), _post(id: 2, title: '글2')], hasNext: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('자유 게시판'), findsOneWidget);
      expect(find.text('글1'), findsOneWidget);
      expect(find.text('글2'), findsOneWidget);
    });

    testWidgets('게시글이 없으면 안내 문구를 보여준다', (tester) async {
      await _pump(
        tester,
        fetchPage: ({cursor, size = 20}) async => const PostCursorPage(content: [], hasNext: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('no_posts_yet'.tr()), findsOneWidget);
    });

    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      await _pump(
        tester,
        fetchPage: ({cursor, size = 20}) async {
          callCount++;
          if (callCount == 1) throw Exception('네트워크 오류');
          return PostCursorPage(content: [_post(title: '복구된글')], hasNext: false);
        },
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('복구된글'), findsOneWidget);
    });
  });

  group('BoardPostList 새로고침', () {
    testWidgets('pull-to-refresh 시 다시 불러온다', (tester) async {
      var callCount = 0;
      await _pump(
        tester,
        fetchPage: ({cursor, size = 20}) async {
          callCount++;
          return PostCursorPage(content: [_post(title: '글 $callCount')], hasNext: false);
        },
      );
      await tester.pumpAndSettle();
      expect(callCount, 1);

      await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
      await tester.pumpAndSettle();

      expect(callCount, 2);
    });
  });

  // 게시글 탭 시 이동하는 PostDetailCard는 PostService/CommentService/ScrapService/
  // ReportService/BlockService 등 다수의 sl<> 의존성이 필요한 무거운 화면이라
  // 다른 위젯의 네비게이션 테스트에서는 깊이 들어가지 않는다(기존 컨벤션) —
  // PostDetailCard 자체는 별도 테스트 파일에서 다룰 것

  group('BoardPostList 글쓰기', () {
    testWidgets('글쓰기 버튼을 탭하면 글쓰기 화면으로 이동한다', (tester) async {
      await _pump(
        tester,
        fetchPage: ({cursor, size = 20}) async => const PostCursorPage(content: [], hasNext: false),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(WritePost), findsOneWidget);
    });
  });

  group('BoardPostList 무한 스크롤', () {
    testWidgets('스크롤이 끝에 도달하면 다음 페이지를 불러온다', (tester) async {
      await _pump(
        tester,
        fetchPage: ({cursor, size = 20}) async {
          if (cursor == null) {
            return PostCursorPage(
              content: List.generate(20, (i) => _post(id: i, title: '글$i')),
              nextCursor: 20,
              hasNext: true,
            );
          }
          return PostCursorPage(content: [_post(id: 100, title: '추가로드글')], hasNext: false);
        },
      );
      tester.view.physicalSize = const Size(1080, 700);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -100000));
      await tester.pumpAndSettle();

      expect(find.text('추가로드글'), findsOneWidget);
    });
  });
}
