import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_tap_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TapLoadingIndicator 렌더링', () {
    testWidgets('기본 크기(16)로 렌더링된다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: Scaffold(body: TapLoadingIndicator()),
          ),
        ),
      );

      final size = tester.getSize(find.byType(CircularProgressIndicator));
      expect(size.width, 16);
      expect(size.height, 16);
    });

    testWidgets('size를 지정하면 해당 크기로 렌더링된다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: Scaffold(body: TapLoadingIndicator(size: 24)),
          ),
        ),
      );

      final size = tester.getSize(find.byType(CircularProgressIndicator));
      expect(size.width, 24);
    });
  });
}
