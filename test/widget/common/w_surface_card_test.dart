import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SurfaceCard 렌더링', () {
    testWidgets('child를 보여준다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: Scaffold(body: SurfaceCard(child: Text('내용'))),
          ),
        ),
      );

      expect(find.text('내용'), findsOneWidget);
    });

    testWidgets('width를 지정하면 Container에 반영된다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: Scaffold(body: SurfaceCard(width: 200, child: Text('내용'))),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 200);
    });

    testWidgets('clipContent가 true면 ClipRRect로 감싼다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: Scaffold(
              body: SurfaceCard(clipContent: true, child: Text('내용')),
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });
}
