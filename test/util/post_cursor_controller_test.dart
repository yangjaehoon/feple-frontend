import 'dart:async';

import 'package:feple/common/post_cursor_controller.dart';
import 'package:feple/model/post_model.dart';
import 'package:flutter_test/flutter_test.dart';

Post _post(int id) => Post(id: id, title: '글$id', content: '내용', likeCount: 0, nickname: '작성자');

void main() {
  group('PostCursorController.load', () {
    test('성공하면 posts와 hasMore/nextCursor를 채운다', () async {
      final controller = PostCursorController(
        fetchPage: ({cursor, size = 20}) async => PostCursorPage(
          content: [_post(1), _post(2)],
          nextCursor: 2,
          hasNext: true,
        ),
      );

      await controller.load();

      expect(controller.posts.map((p) => p.id), [1, 2]);
      expect(controller.hasMore, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
    });

    test('실패하면 hasError를 true로 설정한다', () async {
      final controller = PostCursorController(
        fetchPage: ({cursor, size = 20}) async => throw Exception('실패'),
      );

      await controller.load();

      expect(controller.hasError, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.posts, isEmpty);
    });

    test('나중에 시작한 load만 최종 상태에 반영된다 (오래된 응답 무시)', () async {
      final firstCompleter = Completer<PostCursorPage>();
      var callCount = 0;
      final controller = PostCursorController(
        fetchPage: ({cursor, size = 20}) {
          callCount++;
          if (callCount == 1) return firstCompleter.future;
          return Future.value(
            PostCursorPage(content: [_post(99)], nextCursor: null, hasNext: false),
          );
        },
      );

      final firstLoad = controller.load();
      await controller.load();
      firstCompleter.complete(
        PostCursorPage(content: [_post(1)], nextCursor: null, hasNext: false),
      );
      await firstLoad;

      expect(controller.posts.map((p) => p.id), [99]);
    });
  });

  group('PostCursorController.refresh', () {
    test('성공하면 posts를 새로 채운다', () async {
      var callCount = 0;
      final controller = PostCursorController(
        fetchPage: ({cursor, size = 20}) async {
          callCount++;
          return PostCursorPage(content: [_post(callCount)], nextCursor: null, hasNext: false);
        },
      );

      await controller.load();
      await controller.refresh();

      expect(controller.posts.map((p) => p.id), [2]);
    });

    test('실패해도 예외를 던지지 않는다', () async {
      final controller = PostCursorController(
        fetchPage: ({cursor, size = 20}) async => throw Exception('실패'),
      );

      await expectLater(controller.refresh(), completes);
    });
  });

  group('PostCursorController.loadMore', () {
    test('기존 posts 뒤에 새 페이지를 이어붙인다', () async {
      var callCount = 0;
      final controller = PostCursorController(
        fetchPage: ({cursor, size = 20}) async {
          callCount++;
          if (callCount == 1) {
            return PostCursorPage(content: [_post(1)], nextCursor: 1, hasNext: true);
          }
          return PostCursorPage(content: [_post(2)], nextCursor: null, hasNext: false);
        },
      );

      await controller.load();
      await controller.loadMore();

      expect(controller.posts.map((p) => p.id), [1, 2]);
      expect(controller.hasMore, isFalse);
    });

    test('hasMore가 false면 추가 호출을 하지 않는다', () async {
      var callCount = 0;
      final controller = PostCursorController(
        fetchPage: ({cursor, size = 20}) async {
          callCount++;
          return const PostCursorPage(content: [], nextCursor: null, hasNext: false);
        },
      );

      await controller.load();
      await controller.loadMore();

      expect(callCount, 1);
    });
  });
}
