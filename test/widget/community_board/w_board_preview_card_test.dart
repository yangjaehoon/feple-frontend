import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Post _post({int id = 1, String title = '글'}) =>
    Post(id: id, title: title, content: '내용', likeCount: 0, scrapCount: 0, commentCount: 0, nickname: '작성자');

// 위젯 인자로 넘기기 전에 즉시 평가되는 Future.error는, pump 헬퍼 내부의
// await(EasyLocalization 초기화)를 건너는 사이 아직 리스너가 붙지 않아
// "unhandled exception"으로 잡힌다 — ignore()로 존을 통과시키고
// FutureBuilder가 별도로 붙이는 리스너에서 정상적으로 에러를 받게 한다.
Future<List<Post>> _errorFuture() {
  final future = Future<List<Post>>.error(Exception('네트워크 오류'));
  future.ignore();
  return future;
}

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<Post>> future,
  void Function(BuildContext, Post)? onPostTap,
  VoidCallback? onHeaderTap,
  VoidCallback? onRetry,
  VoidCallback? onWriteTap,
  String? emptyHint,
}) async {
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
        child: MaterialApp(
          home: Scaffold(
            body: BoardPreviewCard(
              future: future,
              headerIcon: Icons.forum_rounded,
              headerTitle: '자유 게시판',
              headerColor: Colors.blue,
              onHeaderTap: onHeaderTap ?? () {},
              onPostTap: onPostTap ?? (_, _) {},
              onRetry: onRetry,
              onWriteTap: onWriteTap,
              emptyHint: emptyHint,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BoardPreviewCard 렌더링', () {
    testWidgets('게시글 목록을 보여준다', (tester) async {
      await _pump(tester, future: Future.value([_post(title: '인기글')]));
      await tester.pump();

      expect(find.text('인기글'), findsOneWidget);
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      await _pump(
        tester,
        future: Future.value(<Post>[]),
        emptyHint: '아직 글이 없어요',
      );
      await tester.pump();

      expect(find.text('아직 글이 없어요'), findsOneWidget);
    });

    testWidgets('emptyHint 없으면 기본 문구를 보여준다', (tester) async {
      await _pump(tester, future: Future.value(<Post>[]));
      await tester.pump();

      expect(find.text('no_posts_yet'.tr()), findsOneWidget);
    });

    testWidgets('로드 실패 시 에러 상태를 보여준다', (tester) async {
      await _pump(tester, future: _errorFuture(), onRetry: () {});
      await tester.pump();

      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('BoardPreviewCard 재시도', () {
    testWidgets('재시도 버튼을 탭하면 onRetry가 호출된다', (tester) async {
      var retried = false;
      await _pump(
        tester,
        future: _errorFuture(),
        onRetry: () => retried = true,
      );
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(retried, isTrue);
    });
  });

  group('BoardPreviewCard 글쓰기', () {
    testWidgets('빈 목록에서 글쓰기 버튼을 탭하면 onWriteTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        future: Future.value(<Post>[]),
        onWriteTap: () => tapped = true,
      );
      await tester.pump();

      await tester.tap(find.text('write_post'.tr()));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('BoardPreviewCard 게시글 탭', () {
    testWidgets('게시글을 탭하면 onPostTap이 호출된다', (tester) async {
      Post? tappedPost;
      await _pump(
        tester,
        future: Future.value([_post(id: 7, title: '탭할 글')]),
        onPostTap: (_, post) => tappedPost = post,
      );
      await tester.pump();

      await tester.tap(find.text('탭할 글'));
      await tester.pump();

      expect(tappedPost?.id, 7);
    });
  });

  group('BoardPreviewCard 헤더', () {
    testWidgets('헤더를 탭하면 onHeaderTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        future: Future.value(<Post>[]),
        onHeaderTap: () => tapped = true,
      );
      await tester.pump();

      await tester.tap(find.text('자유 게시판'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
