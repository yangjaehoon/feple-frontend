import 'package:feple/common/util/share_helper.dart';
import 'package:feple/common/util/sharer.dart';
import 'package:feple/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

class _FakeSharer implements Sharer {
  _FakeSharer({this.onShare});

  final Future<void> Function(ShareParams params)? onShare;
  ShareParams? captured;

  @override
  Future<void> share(ShareParams params) async {
    captured = params;
    if (onShare != null) await onShare!(params);
  }
}

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
  late _FakeSharer sharer;

  void registerSharer(_FakeSharer s) {
    sharer = s;
    if (sl.isRegistered<Sharer>()) sl.unregister<Sharer>();
    sl.registerSingleton<Sharer>(s);
  }

  tearDown(() {
    if (sl.isRegistered<Sharer>()) sl.unregister<Sharer>();
  });

  testWidgets('카드가 없으면 텍스트만 공유하고 true를 반환한다', (tester) async {
    registerSharer(_FakeSharer());
    final ctx = await _pumpContext(tester);

    final ok = await shareContent(ctx, text: 'hello world');

    expect(ok, isTrue);
    expect(sharer.captured, isNotNull);
    expect(sharer.captured!.text, 'hello world');
    expect(sharer.captured!.files ?? const [], isEmpty);
  });

  testWidgets('공유가 예외를 던지면 rethrow 없이 false를 반환한다', (tester) async {
    registerSharer(_FakeSharer(
      onShare: (_) async => throw Exception('share sheet unavailable'),
    ));
    final ctx = await _pumpContext(tester);

    final ok = await shareContent(ctx, text: 'hello');

    expect(ok, isFalse);
  });

  testWidgets('카드 캡처가 실패해도 텍스트 공유는 진행되고 true를 반환한다', (tester) async {
    // Overlay 없는 트리 → captureWidgetAsPng 내부에서 Overlay.of 가 던짐.
    // 이 예외는 삼켜지고 파일 없이 텍스트만 공유돼야 한다.
    registerSharer(_FakeSharer());
    final ctx = await _pumpContext(tester, withOverlay: false);

    final ok = await shareContent(
      ctx,
      text: 'hello',
      cardToCapture: const SizedBox(width: 10, height: 10),
    );

    expect(ok, isTrue);
    expect(sharer.captured!.text, 'hello');
    expect(sharer.captured!.files ?? const [], isEmpty);
  });
}
