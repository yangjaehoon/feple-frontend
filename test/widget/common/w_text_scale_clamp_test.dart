import 'package:feple/common/widget/w_text_scale_clamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<TextScaler> pumpAndGetScaler(WidgetTester tester, double scaleFactor) async {
    late TextScaler result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scaleFactor)),
        child: Builder(
          builder: (context) => clampTextScaleBuilder(
            context,
            Builder(
              builder: (innerContext) {
                result = MediaQuery.of(innerContext).textScaler;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    return result;
  }

  group('clampTextScaleBuilder', () {
    testWidgets('1.0 미만이면 1.0으로 올린다', (tester) async {
      final scaler = await pumpAndGetScaler(tester, 0.5);

      expect(scaler.scale(10), 10);
    });

    testWidgets('2.0 초과면 2.0으로 제한한다', (tester) async {
      final scaler = await pumpAndGetScaler(tester, 3.0);

      expect(scaler.scale(10), 20);
    });

    testWidgets('1.0~2.0 사이면 그대로 유지한다', (tester) async {
      final scaler = await pumpAndGetScaler(tester, 1.5);

      expect(scaler.scale(10), 15);
    });
  });
}
