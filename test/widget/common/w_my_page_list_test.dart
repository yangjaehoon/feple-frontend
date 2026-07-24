import 'dart:async';

import 'package:feple/common/widget/w_my_page_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

Widget _buildList({
  required Future<List<String>> Function() loader,
}) {
  return MyPageList<String>(
    title: '내 게시글',
    loader: loader,
    skeletonBuilder: (colors) => const Center(child: Text('스켈레톤')),
    itemBuilder: (context, item, reload) => ListTile(title: Text(item)),
    emptyIcon: Icons.article_outlined,
    emptyTitle: '게시글이 없어요',
  );
}

void main() {
  group('MyPageList 로딩', () {
    testWidgets('로딩 중에는 skeletonBuilder를 보여준다', (tester) async {
      final completer = Completer<List<String>>();
      await pumpCommonWidget(tester, _buildList(loader: () => completer.future));

      expect(find.text('스켈레톤'), findsOneWidget);
      completer.complete(['글1']);
      await tester.pumpAndSettle();
    });
  });

  group('MyPageList 데이터 있음', () {
    testWidgets('데이터가 있으면 itemBuilder로 목록을 렌더링한다', (tester) async {
      await pumpCommonWidget(
        tester,
        _buildList(loader: () async => ['글1', '글2']),
      );
      await tester.pumpAndSettle();

      expect(find.text('글1'), findsOneWidget);
      expect(find.text('글2'), findsOneWidget);
      expect(find.text('내 게시글'), findsOneWidget);
    });
  });

  group('MyPageList 빈 목록', () {
    testWidgets('빈 목록이면 emptyIcon/emptyTitle을 보여준다', (tester) async {
      await pumpCommonWidget(
        tester,
        _buildList(loader: () async => <String>[]),
      );
      await tester.pumpAndSettle();

      expect(find.text('게시글이 없어요'), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });
  });

  group('MyPageList 에러', () {
    testWidgets('loader가 실패하면 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      await pumpCommonWidget(
        tester,
        _buildList(loader: () async {
          callCount++;
          if (callCount == 1) throw Exception('네트워크 오류');
          return ['재시도성공'];
        }),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('재시도성공'), findsOneWidget);
      expect(callCount, 2);
    });
  });

  group('MyPageList 새로고침', () {
    testWidgets('pull-to-refresh 시 loader를 다시 호출해 목록을 갱신한다', (tester) async {
      var callCount = 0;
      await pumpCommonWidget(
        tester,
        _buildList(loader: () async {
          callCount++;
          return callCount == 1 ? ['첫번째'] : ['새로고침됨'];
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('첫번째'), findsOneWidget);

      await tester.fling(find.text('첫번째'), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(find.text('새로고침됨'), findsOneWidget);
      expect(callCount, 2);
    });
  });
}
