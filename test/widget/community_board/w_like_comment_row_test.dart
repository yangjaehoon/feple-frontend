import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/community_board/w_like_comment_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  required PostInteractionData interaction,
  required VoidCallback onLikeTap,
  required VoidCallback onScrapTap,
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
            body: LikeCommentRow(
              interaction: interaction,
              onLikeTap: onLikeTap,
              onScrapTap: onScrapTap,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('LikeCommentRow 렌더링', () {
    testWidgets('좋아요/스크랩/댓글 수를 보여준다', (tester) async {
      await _pump(
        tester,
        interaction: const PostInteractionData(
          liked: false,
          likeCount: 3,
          commentCount: 4,
          scraped: false,
          scrapCount: 5,
        ),
        onLikeTap: () {},
        onScrapTap: () {},
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    });

    testWidgets('좋아요/스크랩 상태면 채워진 아이콘을 보여준다', (tester) async {
      await _pump(
        tester,
        interaction: const PostInteractionData(
          liked: true,
          likeCount: 1,
          commentCount: 0,
          scraped: true,
          scrapCount: 1,
        ),
        onLikeTap: () {},
        onScrapTap: () {},
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });
  });

  group('LikeCommentRow 탭', () {
    testWidgets('좋아요 버튼을 탭하면 onLikeTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        interaction: const PostInteractionData(
          liked: false,
          likeCount: 0,
          commentCount: 0,
          scraped: false,
          scrapCount: 0,
        ),
        onLikeTap: () => tapped = true,
        onScrapTap: () {},
      );

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('스크랩 버튼을 탭하면 onScrapTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        interaction: const PostInteractionData(
          liked: false,
          likeCount: 0,
          commentCount: 0,
          scraped: false,
          scrapCount: 0,
        ),
        onLikeTap: () {},
        onScrapTap: () => tapped = true,
      );

      await tester.tap(find.byIcon(Icons.star_border_rounded));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
