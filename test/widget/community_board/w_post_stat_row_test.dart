import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/community_board/w_post_stat_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  int likeCount = 3,
  int commentCount = 5,
  int? scrapCount,
  bool compact = true,
}) async {
  await tester.pumpWidget(
    CustomThemeHolder(
      theme: CustomTheme.light,
      changeTheme: (_) {},
      child: MaterialApp(
        home: Scaffold(
          body: PostStatRow(
            likeCount: likeCount,
            commentCount: commentCount,
            scrapCount: scrapCount,
            compact: compact,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PostStatRow 렌더링', () {
    testWidgets('좋아요/댓글 수를 보여준다', (tester) async {
      await _pump(tester, likeCount: 3, commentCount: 5);

      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsNothing);
    });

    testWidgets('scrapCount가 있으면 별 아이콘과 함께 보여준다', (tester) async {
      await _pump(tester, likeCount: 1, commentCount: 2, scrapCount: 7);

      expect(find.text('7'), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    });
  });
}
