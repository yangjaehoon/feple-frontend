import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/role_badge_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('roleBadgeStyleFor', () {
    test('관리자/아티스트/인증이 모두 아니면 null을 반환한다', () {
      expect(roleBadgeStyleFor(userRole: 'USER', certified: false), isNull);
      expect(roleBadgeStyleFor(userRole: null, certified: false), isNull);
    });

    test('관리자면 shield 아이콘의 뱃지를 반환한다', () {
      final style = roleBadgeStyleFor(userRole: 'ADMIN');

      expect(style, isNotNull);
      expect(style!.icon, Icons.shield_rounded);
    });

    test('아티스트면 verified 아이콘의 뱃지를 반환한다', () {
      final style = roleBadgeStyleFor(userRole: 'ARTIST');

      expect(style, isNotNull);
      expect(style!.icon, Icons.verified_rounded);
    });

    test('페스티벌 인증만 있으면 local_activity 아이콘의 뱃지를 반환한다', () {
      final style = roleBadgeStyleFor(userRole: null, certified: true);

      expect(style, isNotNull);
      expect(style!.icon, Icons.local_activity_rounded);
    });

    test('관리자가 우선순위를 갖는다', () {
      final style = roleBadgeStyleFor(userRole: 'ADMIN', certified: true);

      expect(style!.icon, Icons.shield_rounded);
    });

    test('관리자가 아니면 아티스트가 인증보다 우선한다', () {
      final style = roleBadgeStyleFor(userRole: 'ARTIST', certified: true);

      expect(style!.icon, Icons.verified_rounded);
    });
  });
}
