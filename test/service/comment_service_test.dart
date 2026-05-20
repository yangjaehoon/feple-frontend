import 'dart:io';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/comment_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_web_server/mock_web_server.dart';

void main() {
  final server = MockWebServer();
  final service = CommentService();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (_) async => null,
    );
    HttpOverrides.global = null;
    await server.start();
    DioClient.dio.options.baseUrl = 'http://127.0.0.1:${server.port}';
  });

  tearDownAll(() => server.shutdown());

  group('CommentService', () {
    test('fetchPostComments parses comment list', () async {
      server.enqueue(
        body: '[{"id":1,"postId":1,"userId":10,"nickname":"user","content":"comment",'
            '"createdAt":"2025-01-01T00:00:00","certified":false,"likeCount":2,"liked":true}]',
        headers: {'Content-Type': 'application/json'},
      );

      final comments = await service.fetchPostComments(1);

      expect(comments.length, 1);
      expect(comments.first.id, 1);
      expect(comments.first.likeCount, 2);
      expect(comments.first.liked, true);
    });

    test('fetchPostComments returns empty list', () async {
      server.enqueue(
        body: '[]',
        headers: {'Content-Type': 'application/json'},
      );

      final comments = await service.fetchPostComments(1);

      expect(comments, isEmpty);
    });

    test('submitComment completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(
        service.submitComment(content: 'hello', postId: 1),
        completes,
      );
    });

    test('submitComment with parentId completes normally', () async {
      server.enqueue(httpCode: 200);

      await expectLater(
        service.submitComment(content: 'reply', postId: 1, parentId: 42),
        completes,
      );
    });

    test('toggleCommentLike parses liked and likeCount record', () async {
      server.enqueue(
        body: '{"liked":true,"likeCount":3}',
        headers: {'Content-Type': 'application/json'},
      );

      final result = await service.toggleCommentLike(1);

      expect(result.liked, true);
      expect(result.likeCount, 3);
    });

    test('deleteComment completes on 204', () async {
      server.enqueue(httpCode: 204);

      await expectLater(service.deleteComment(1), completes);
    });

    test('deleteComment throws on non-204 status', () async {
      server.enqueue(httpCode: 200);

      await expectLater(service.deleteComment(1), throwsException);
    });
  });
}
