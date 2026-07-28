import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomSheetHandle 렌더링', () {
    testWidgets('40x4 크기의 핸들을 보여준다', (tester) async {
      await tester.pumpWidget(
        CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(
            home: Scaffold(body: BottomSheetHandle()),
          ),
        ),
      );

      final size = tester.getSize(find.byType(Container));
      expect(size.width, 40);
      expect(size.height, 4);
    });
  });
}
