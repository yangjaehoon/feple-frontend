import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_blocking_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => CustomThemeHolder(
      theme: CustomTheme.light,
      changeTheme: (_) {},
      child: MaterialApp(home: child),
    );

void main() {
  group('BlockingNotice', () {
    testWidgets('제목·메시지·기본 버튼을 보여주고, 보조 버튼은 기본적으로 없다', (tester) async {
      await tester.pumpWidget(_host(
        BlockingNotice(
          icon: Icons.build_outlined,
          title: '점검 중',
          message: '잠시만요',
          primaryLabel: '다시 시도',
          onPrimary: () {},
        ),
      ));

      expect(find.text('점검 중'), findsOneWidget);
      expect(find.text('잠시만요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('기본 버튼을 누르면 onPrimary가 호출된다', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_host(
        BlockingNotice(
          icon: Icons.system_update,
          title: 'T',
          message: 'M',
          primaryLabel: '업데이트',
          onPrimary: () => tapped++,
        ),
      ));

      await tester.tap(find.text('업데이트'));
      expect(tapped, 1);
    });

    testWidgets('secondaryLabel을 주면 보조 버튼이 나타나고 onSecondary가 호출된다', (tester) async {
      var secondary = 0;
      await tester.pumpWidget(_host(
        BlockingNotice(
          icon: Icons.build_outlined,
          title: 'T',
          message: 'M',
          primaryLabel: 'P',
          onPrimary: () {},
          secondaryLabel: '문의하기',
          onSecondary: () => secondary++,
        ),
      ));

      await tester.tap(find.text('문의하기'));
      expect(secondary, 1);
    });

    testWidgets('뒤로가기로 빠져나갈 수 없다 (PopScope canPop=false)', (tester) async {
      await tester.pumpWidget(_host(
        BlockingNotice(
          icon: Icons.system_update,
          title: 'T',
          message: 'M',
          primaryLabel: 'P',
          onPrimary: () {},
        ),
      ));

      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });
  });
}
