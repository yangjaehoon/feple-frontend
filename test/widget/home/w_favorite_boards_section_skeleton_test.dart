import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/screen/main/tab/home/w_favorite_boards_section_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FavoriteBoardsSectionSkeleton 렌더링', () {
    testWidgets('스켈레톤 박스를 보여준다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: Scaffold(body: FavoriteBoardsSectionSkeleton()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });
}
