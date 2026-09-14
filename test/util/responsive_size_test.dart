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

    testWidgets('상한(480x~1038) 이내에서는 화면 크기에 비례해 스케일된다', (tester) async {
      // 390x844의 1.2배 — 상한(480, ~1038.77) 미만이라 클램프 없이 그대로 비례
      final rs = await pump(tester, const Size(468, 1012.8));

      expect(rs.w(60), closeTo(72, 0.0001));
      expect(rs.h(60), closeTo(72, 0.0001));
      expect(rs.sp(14), closeTo(16.8, 0.0001));
    });

    testWidgets('태블릿급 화면(펼친 폴더블 등)에서는 480 기준 상한으로 클램프된다', (tester) async {
      final rs = await pump(tester, const Size(900, 1600));
      final maxScale = 480 / 390;

      expect(rs.w(60), closeTo(60 * maxScale, 0.0001));
      expect(rs.h(60), closeTo(60 * maxScale, 0.0001));
      expect(rs.sp(14), closeTo(14 * maxScale, 0.0001));
    });

    testWidgets('너비와 높이는 서로 독립적으로 클램프된다(좁고 아주 긴 화면)', (tester) async {
      // 너비는 기준(390) 그대로라 클램프 없음, 높이만 상한(~1038.77)을 넘어 클램프됨
      final rs = await pump(tester, const Size(390, 2000));
      final maxHeightScale = (480 * 844 / 390) / 844;

      expect(rs.w(60), 60);
      expect(rs.h(60), closeTo(60 * maxHeightScale, 0.0001));
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
