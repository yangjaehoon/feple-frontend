import 'package:feple/common/util/widget_image_capturer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  testWidgets('네트워크 이미지 없이 순수 위젯을 PNG 바이트로 캡처한다', (tester) async {
    late BuildContext capturedContext;
    await pumpCommonWidget(
      tester,
      Builder(builder: (context) {
        capturedContext = context;
        return const SizedBox.shrink();
      }),
    );

    final bytes = await captureWidgetAsPng(
      capturedContext,
      Container(width: 100, height: 100, color: Colors.red),
    );

    expect(bytes, isNotNull);
    expect(bytes, isNotEmpty);
    // PNG 파일 시그니처(매직 바이트) 확인
    expect(bytes!.take(4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('캡처 후 오버레이 엔트리를 제거해 위젯 트리에 남기지 않는다', (tester) async {
    late BuildContext capturedContext;
    await pumpCommonWidget(
      tester,
      Builder(builder: (context) {
        capturedContext = context;
        return const SizedBox.shrink();
      }),
    );

    await captureWidgetAsPng(
      capturedContext,
      const Text('capture-target-marker'),
    );
    await tester.pump();

    expect(find.text('capture-target-marker'), findsNothing);
  });

  testWidgets('pixelRatio에 비례해 더 큰 이미지를 생성한다', (tester) async {
    late BuildContext capturedContext;
    await pumpCommonWidget(
      tester,
      Builder(builder: (context) {
        capturedContext = context;
        return const SizedBox.shrink();
      }),
    );

    final small = await captureWidgetAsPng(
      capturedContext,
      Container(width: 50, height: 50, color: Colors.blue),
      pixelRatio: 1.0,
    );
    final large = await captureWidgetAsPng(
      capturedContext,
      Container(width: 50, height: 50, color: Colors.blue),
      pixelRatio: 3.0,
    );

    expect(large!.length, greaterThan(small!.length));
  });
}
