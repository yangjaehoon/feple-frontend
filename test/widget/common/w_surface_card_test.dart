import 'package:feple/common/theme/color/light_app_colors.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardShadows 단계별 프리셋', () {
    const colors = LightAppColors();

    test('subtle/medium/elevated 순으로 blurRadius가 커진다', () {
      final subtle = CardShadows.subtle(colors).single;
      final medium = CardShadows.medium(colors).single;
      final elevated = CardShadows.elevated(colors).single;

      expect(subtle.blurRadius, lessThan(medium.blurRadius));
      expect(medium.blurRadius, lessThan(elevated.blurRadius));
    });

    test('subtle/medium/elevated 순으로 그림자가 진해진다', () {
      final subtleAlpha = CardShadows.subtle(colors).single.color.a;
      final mediumAlpha = CardShadows.medium(colors).single.color.a;
      final elevatedAlpha = CardShadows.elevated(colors).single.color.a;

      expect(subtleAlpha, lessThan(mediumAlpha));
      expect(mediumAlpha, lessThan(elevatedAlpha));
    });
  });

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
