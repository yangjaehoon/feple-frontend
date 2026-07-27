import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/my_comment_model.dart';
import 'package:feple/screen/main/tab/my_page/w_my_comments.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserActivityService extends Mock implements UserActivityService {}

MyComment _comment({
  int commentId = 1,
  String content = '댓글 내용',
  String postTitle = '원글 제목',
  String boardDisplayName = '자유 게시판',
}) {
  return MyComment(
    commentId: commentId,
    content: content,
    postId: 10,
    postTitle: postTitle,
    postContent: '원글 본문',
    postNickname: '작성자',
    postLikeCount: 0,
    boardDisplayName: boardDisplayName,
  );
}

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

  Future<void> pump(WidgetTester tester) async {
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
          child: const MaterialApp(home: MyCommentsView(userId: 1)),
        ),
      ),
    );
    await tester.pump();
  }

  group('MyCommentsView 렌더링', () {
    testWidgets('제목과 댓글 목록을 보여준다', (tester) async {
      when(() => mockService.fetchComments(1)).thenAnswer(
        (_) async => [
          _comment(commentId: 1, content: '댓글1'),
          _comment(commentId: 2, content: '댓글2', postTitle: '다른 글', boardDisplayName: '인기 게시판'),
        ],
      );

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('my_comments'.tr()), findsOneWidget);
      expect(find.text('댓글1'), findsOneWidget);
      expect(find.text('댓글2'), findsOneWidget);
      expect(find.text('인기 게시판 • 다른 글'), findsOneWidget);
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchComments(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('no_comments'.tr()), findsOneWidget);
    });
  });
}
