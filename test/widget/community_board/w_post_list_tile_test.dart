import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Post _post({
  int id = 1,
  String title = '제목',
  String content = '내용',
  String nickname = '작성자',
  bool anonymous = false,
  String? imageUrl,
}) =>
    Post(
      id: id,
      title: title,
      content: content,
      likeCount: 1,
      scrapCount: 2,
      commentCount: 3,
      nickname: nickname,
      anonymous: anonymous,
      imageUrl: imageUrl,
    );

Future<void> _pump(
  WidgetTester tester, {
  required Post post,
  required VoidCallback onTap,
  VoidCallback? onAuthorTap,
  String? highlightKeyword,
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
            body: PostListTile(
              post: post,
              onTap: onTap,
              onAuthorTap: onAuthorTap,
              highlightKeyword: highlightKeyword,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PostListTile 렌더링', () {
    testWidgets('제목, 내용, 통계를 보여준다', (tester) async {
      await _pump(
        tester,
        post: _post(title: '제목입니다', content: '내용입니다'),
        onTap: () {},
      );

      expect(find.text('제목입니다'), findsOneWidget);
      expect(find.text('내용입니다'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('imageUrl이 있으면 썸네일을 보여준다', (tester) async {
      await _pump(
        tester,
        post: _post(imageUrl: 'https://example.com/img.jpg'),
        onTap: () {},
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });

  group('PostListTile 탭', () {
    testWidgets('행을 탭하면 onTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(tester, post: _post(), onTap: () => tapped = true);

      await tester.tap(find.text('제목'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('작성자 프로필을 탭하면 onAuthorTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        post: _post(),
        onTap: () {},
        onAuthorTap: () => tapped = true,
      );

      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('익명 게시글이면 작성자 프로필을 탭할 수 없다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        post: _post(anonymous: true),
        onTap: () {},
        onAuthorTap: () => tapped = true,
      );

      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump();

      expect(tapped, isFalse);
    });
  });
}
