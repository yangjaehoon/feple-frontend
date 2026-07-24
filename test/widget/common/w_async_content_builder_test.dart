import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('AsyncContentBuilder 로딩', () {
    testWidgets('완료 전에는 로딩 인디케이터를 보여준다', (tester) async {
      final completer = Completer<String>();
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<String>(
          future: completer.future,
          builder: (context, data) => Text(data),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete('done');
      await tester.pumpAndSettle();
    });

    testWidgets('loadingBuilder를 지정하면 커스텀 로딩 위젯을 사용한다', (tester) async {
      final completer = Completer<String>();
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<String>(
          future: completer.future,
          builder: (context, data) => Text(data),
          loadingBuilder: (context) => const Text('로딩중'),
        ),
      );

      expect(find.text('로딩중'), findsOneWidget);
      completer.complete('done');
      await tester.pumpAndSettle();
    });
  });

  group('AsyncContentBuilder 데이터 있음', () {
    testWidgets('데이터가 있으면 builder를 렌더링한다', (tester) async {
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<String>(
          future: Future.value('안녕'),
          builder: (context, data) => Text(data),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('안녕'), findsOneWidget);
    });
  });

  group('AsyncContentBuilder 빈 데이터', () {
    testWidgets('빈 리스트면 기본 empty 상태를 보여준다', (tester) async {
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<List<int>>(
          future: Future.value(<int>[]),
          builder: (context, data) => Text('개수 ${data.length}'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('no_posts_yet'.tr()), findsOneWidget);
      expect(find.text('개수 0'), findsNothing);
    });

    testWidgets('emptyBuilder를 지정하면 커스텀 empty 위젯을 사용한다', (tester) async {
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<List<int>>(
          future: Future.value(<int>[]),
          builder: (context, data) => Text('개수 ${data.length}'),
          emptyBuilder: (context) => const Text('텅 비었어요'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('텅 비었어요'), findsOneWidget);
    });

    testWidgets('isEmpty 콜백으로 커스텀 empty 판정을 할 수 있다', (tester) async {
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<int>(
          future: Future.value(0),
          builder: (context, data) => Text('값 $data'),
          isEmpty: (data) => data == 0,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('no_posts_yet'.tr()), findsOneWidget);
      expect(find.text('값 0'), findsNothing);
    });

    testWidgets('future가 null을 반환하면(hasData=false) empty 상태를 보여준다', (tester) async {
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<String?>(
          future: Future.value(null),
          builder: (context, data) => Text('데이터: $data'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('no_posts_yet'.tr()), findsOneWidget);
    });
  });

  group('AsyncContentBuilder 에러', () {
    testWidgets('future가 실패하면 기본 ErrorState를 보여준다', (tester) async {
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<String>(
          future: (Future<String>.error(Exception('네트워크 오류'))..ignore()),
          builder: (context, data) => Text(data),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('err_fetch_data'.tr()), findsOneWidget);
    });

    testWidgets('errorBuilder를 지정하면 커스텀 에러 위젯을 사용한다', (tester) async {
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<String>(
          future: (Future<String>.error(Exception('네트워크 오류'))..ignore()),
          builder: (context, data) => Text(data),
          errorBuilder: (error) => Text('에러: $error'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('에러:'), findsOneWidget);
    });

    testWidgets('onRetry를 지정하면 재시도 버튼이 나타나고 탭할 수 있다', (tester) async {
      var retried = false;
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<String>(
          future: (Future<String>.error(Exception('네트워크 오류'))..ignore()),
          builder: (context, data) => Text(data),
          onRetry: () => retried = true,
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      expect(retried, true);
    });

    testWidgets('useListViewForEmptyState=false면 ErrorState를 ListView 없이 렌더링한다', (tester) async {
      await pumpCommonWidget(
        tester,
        AsyncContentBuilder<String>(
          future: (Future<String>.error(Exception('네트워크 오류'))..ignore()),
          builder: (context, data) => Text(data),
          useListViewForEmptyState: false,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(ErrorState), findsOneWidget);
    });
  });
}
