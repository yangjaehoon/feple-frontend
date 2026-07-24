import 'package:feple/common/constant/app_colors.dart';
import 'package:feple/common/widget/w_inline_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('InlineBadge', () {
    testWidgets('userRole null + certified false면 빈 위젯을 렌더링한다', (tester) async {
      await pumpCommonWidget(tester, const InlineBadge());

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('userRole이 ADMIN이면 shield 아이콘과 badgeAdmin 색을 사용한다', (tester) async {
      await pumpCommonWidget(tester, const InlineBadge(userRole: 'ADMIN'));

      final icon = tester.widget<Icon>(find.byIcon(Icons.shield_rounded));
      expect(icon.color, AppColors.badgeAdmin);
    });

    testWidgets('userRole이 ARTIST면 verified 아이콘과 badgeArtist 색을 사용한다', (tester) async {
      await pumpCommonWidget(tester, const InlineBadge(userRole: 'ARTIST'));

      final icon = tester.widget<Icon>(find.byIcon(Icons.verified_rounded));
      expect(icon.color, AppColors.badgeArtist);
    });

    testWidgets('certified=true이고 역할이 없으면 축제인증 아이콘을 사용한다', (tester) async {
      await pumpCommonWidget(tester, const InlineBadge(certified: true));

      final icon = tester.widget<Icon>(find.byIcon(Icons.local_activity_rounded));
      expect(icon.color, AppColors.badgeCertified);
    });

    testWidgets('ADMIN이 certified보다 우선한다', (tester) async {
      await pumpCommonWidget(
        tester,
        const InlineBadge(userRole: 'ADMIN', certified: true),
      );

      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
      expect(find.byIcon(Icons.local_activity_rounded), findsNothing);
    });

    testWidgets('size를 지정하면 아이콘 크기에 반영된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const InlineBadge(userRole: 'ADMIN', size: 24),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.shield_rounded));
      expect(icon.size, 24);
    });
  });
}
