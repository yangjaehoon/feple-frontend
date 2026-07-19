import 'package:feple/common/constant/app_colors.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('ProfileAvatar 기본 렌더링', () {
    testWidgets('imageUrl 없으면 닉네임 첫 글자를 보여준다', (tester) async {
      await pumpCommonWidget(tester, const ProfileAvatar(nickname: '테스터'));

      expect(find.text('테'), findsOneWidget);
    });

    testWidgets('nickname이 빈 문자열이면 물음표를 보여준다', (tester) async {
      await pumpCommonWidget(tester, const ProfileAvatar(nickname: ''));

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('anonymous면 기본 로고 이미지를 사용한다', (tester) async {
      await pumpCommonWidget(
        tester,
        const ProfileAvatar(nickname: '테스터', anonymous: true),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundImage, isA<AssetImage>());
      expect(find.text('테'), findsNothing);
    });

    testWidgets('radius를 지정하면 CircleAvatar에 반영된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const ProfileAvatar(nickname: '테스터', radius: 30),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, 30);
    });
  });

  group('ProfileAvatar 배지', () {
    testWidgets('배지 조건이 없으면 뱃지 아이콘이 없다', (tester) async {
      await pumpCommonWidget(tester, const ProfileAvatar(nickname: '테스터'));

      expect(find.byIcon(Icons.shield_rounded), findsNothing);
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
      expect(find.byIcon(Icons.local_activity_rounded), findsNothing);
    });

    testWidgets('userRole=ADMIN이면 shield 배지가 오버레이된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const ProfileAvatar(nickname: '테스터', userRole: 'ADMIN'),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.shield_rounded));
      expect(icon.color, Colors.white);
      final container = tester.widget<Container>(
        find.ancestor(of: find.byIcon(Icons.shield_rounded), matching: find.byType(Container)),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.badgeAdmin);
    });

    testWidgets('userRole=ARTIST면 verified 배지가 오버레이된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const ProfileAvatar(nickname: '테스터', userRole: 'ARTIST'),
      );

      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('certified=true면 인증 배지가 오버레이된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const ProfileAvatar(nickname: '테스터', certified: true),
      );

      expect(find.byIcon(Icons.local_activity_rounded), findsOneWidget);
    });

    testWidgets('badgeSize는 radius에 비례한다', (tester) async {
      await pumpCommonWidget(
        tester,
        const ProfileAvatar(nickname: '테스터', userRole: 'ADMIN', radius: 25),
      );

      final container = tester.widget<Container>(
        find.ancestor(of: find.byIcon(Icons.shield_rounded), matching: find.byType(Container)),
      );
      expect(container.constraints, const BoxConstraints.tightFor(width: 20, height: 20));
    });
  });

  testWidgets('다크 테마에서도 렌더링에 실패하지 않는다', (tester) async {
    await pumpCommonWidget(
      tester,
      const ProfileAvatar(nickname: '테스터', certified: true),
      theme: CustomTheme.dark,
    );

    expect(find.byType(ProfileAvatar), findsOneWidget);
  });
}
