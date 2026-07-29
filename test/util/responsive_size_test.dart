import 'package:feple/common/util/responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<ResponsiveSize> pump(WidgetTester tester, Size size) async {
    late ResponsiveSize rs;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: Builder(builder: (context) {
          rs = ResponsiveSize(context);
          return const SizedBox();
        }),
      ),
    );
    await tester.pump();
    return rs;
  }

  group('ResponsiveSize', () {
    testWidgets('기준 디자인 크기(390x844)에서는 값이 그대로 반환된다', (tester) async {
      final rs = await pump(tester, const Size(390, 844));

      expect(rs.w(60), 60);
      expect(rs.h(60), 60);
      expect(rs.sp(14), 14);
    });

    testWidgets('화면이 기준보다 2배 크면 값도 2배로 스케일된다', (tester) async {
      final rs = await pump(tester, const Size(780, 1688));

      expect(rs.w(60), 120);
      expect(rs.h(60), 120);
      expect(rs.sp(14), 28);
    });

    testWidgets('px는 수평 EdgeInsets를 반환한다', (tester) async {
      final rs = await pump(tester, const Size(390, 844));

      expect(rs.px(16), const EdgeInsets.symmetric(horizontal: 16));
    });

    testWidgets('py는 수직 EdgeInsets를 반환한다', (tester) async {
      final rs = await pump(tester, const Size(390, 844));

      expect(rs.py(16), const EdgeInsets.symmetric(vertical: 16));
    });
  });
}
