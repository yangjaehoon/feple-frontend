import 'dart:async';

import 'package:feple/common/util/navigation_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _GuardedWidget extends StatefulWidget {
  final Future<void> Function() action;
  const _GuardedWidget({required this.action});

  @override
  State<_GuardedWidget> createState() => _GuardedWidgetState();
}

class _GuardedWidgetState extends State<_GuardedWidget> with NavigationGuard {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => guardedNavigate(widget.action),
      child: const Text('이동'),
    );
  }
}

void main() {
  group('NavigationGuard.guardedNavigate', () {
    testWidgets('진행 중이 아니면 action을 실행한다', (tester) async {
      var callCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: _GuardedWidget(action: () async => callCount++),
        ),
      );

      await tester.tap(find.text('이동'));
      await tester.pump();

      expect(callCount, 1);
    });

    testWidgets('이미 진행 중이면 중복 호출을 무시한다', (tester) async {
      var callCount = 0;
      final completer = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: _GuardedWidget(action: () {
            callCount++;
            return completer.future;
          }),
        ),
      );

      await tester.tap(find.text('이동'));
      await tester.pump();
      await tester.tap(find.text('이동'));
      await tester.pump();

      expect(callCount, 1);

      completer.complete();
      await tester.pump();
    });

    testWidgets('action 완료 후에는 다시 호출할 수 있다', (tester) async {
      var callCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: _GuardedWidget(action: () async => callCount++),
        ),
      );

      await tester.tap(find.text('이동'));
      await tester.pump();
      await tester.tap(find.text('이동'));
      await tester.pump();

      expect(callCount, 2);
    });
  });
}
