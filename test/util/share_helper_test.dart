import 'package:feple/common/util/share_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

Future<BuildContext> _pumpContext(
  WidgetTester tester, {
  bool withOverlay = true,
}) async {
  late BuildContext ctx;
  final child = Builder(
    builder: (context) {
      ctx = context;
      return const SizedBox();
    },
  );
  await tester.pumpWidget(
    withOverlay
        ? MaterialApp(home: child)
        : Directionality(textDirection: TextDirection.ltr, child: child),
  );
  return ctx;
}

void main() {
  testWidgets('카드가 없으면 텍스트만 공유하고 true를 반환한다', (tester) async {
    final ctx = await _pumpContext(tester);
    ShareParams? captured;

    final ok = await shareContent(
      ctx,
      text: 'hello world',
      shareOverride: (p) async {
        captured = p;
      },
    );

    expect(ok, isTrue);
    expect(captured, isNotNull);
    expect(captured!.text, 'hello world');
    expect(captured!.files ?? const [], isEmpty);
  });

  testWidgets('공유가 예외를 던지면 rethrow 없이 false를 반환한다', (tester) async {
    final ctx = await _pumpContext(tester);

    final ok = await shareContent(
      ctx,
      text: 'hello',
      shareOverride: (_) async {
        throw Exception('share sheet unavailable');
      },
    );

    expect(ok, isFalse);
  });

  testWidgets('카드 캡처가 실패해도 텍스트 공유는 진행되고 true를 반환한다', (tester) async {
    // Overlay 없는 트리 → captureWidgetAsPng 내부에서 Overlay.of 가 던짐.
    // 이 예외는 삼켜지고 파일 없이 텍스트만 공유돼야 한다.
    final ctx = await _pumpContext(tester, withOverlay: false);
    ShareParams? captured;

    final ok = await shareContent(
      ctx,
      text: 'hello',
      cardToCapture: const SizedBox(width: 10, height: 10),
      shareOverride: (p) async {
        captured = p;
      },
    );

    expect(ok, isTrue);
    expect(captured!.text, 'hello');
    expect(captured!.files ?? const [], isEmpty);
  });
}
