import 'package:feple/model/comment_detail.dart';
import 'package:flutter_test/flutter_test.dart';

CommentDetail _comment({int? parentId, bool liked = false, int likeCount = 0}) =>
    CommentDetail(
      id: 1,
      postId: 1,
      userId: 10,
      nickname: 'user',
      content: '댓글',
      createdAt: DateTime(2025),
      certified: false,
      likeCount: likeCount,
      liked: liked,
      parentId: parentId,
    );

void main() {
  group('CommentDetail.fromJson', () {
    test('정상 필드 파싱', () {
      final json = {
        'id': 1,
        'postId': 2,
        'userId': 10,
        'nickname': 'user',
        'content': '댓글 내용',
        'createdAt': '2025-01-01T00:00:00',
        'certified': true,
        'userRole': 'ARTIST',
        'parentId': null,
        'likeCount': 5,
        'liked': true,
      };

      final comment = CommentDetail.fromJson(json);

      expect(comment.id, 1);
      expect(comment.postId, 2);
      expect(comment.userId, 10);
      expect(comment.nickname, 'user');
      expect(comment.content, '댓글 내용');
      expect(comment.certified, true);
      expect(comment.userRole, 'ARTIST');
      expect(comment.parentId, isNull);
      expect(comment.likeCount, 5);
      expect(comment.liked, true);
    });

    test('nickname null이면 기본값 "User"', () {
      final json = {
        'id': 1,
        'postId': 1,
        'userId': 10,
        'nickname': null,
        'content': '댓글',
        'createdAt': '2025-01-01T00:00:00',
        'certified': null,
        'likeCount': null,
        'liked': null,
      };

      final comment = CommentDetail.fromJson(json);

      expect(comment.nickname, 'User');
      expect(comment.certified, false);
      expect(comment.likeCount, 0);
      expect(comment.liked, false);
    });

    test('parentId 있으면 대댓글로 파싱', () {
      final json = {
        'id': 2,
        'postId': 1,
        'userId': 10,
        'nickname': 'user',
        'content': '대댓글',
        'createdAt': '2025-01-01T00:00:00',
        'certified': false,
        'parentId': 42,
        'likeCount': 0,
        'liked': false,
      };

      final comment = CommentDetail.fromJson(json);

      expect(comment.parentId, 42);
      expect(comment.isReply, true);
    });
  });

  group('CommentDetail.copyWith', () {
    test('liked만 변경, likeCount 유지', () {
      final updated = _comment().copyWith(liked: true);

      expect(updated.liked, true);
      expect(updated.likeCount, 0);
      expect(updated.id, 1);
    });

    test('likeCount만 변경, liked 유지', () {
      final updated = _comment().copyWith(likeCount: 10);

      expect(updated.likeCount, 10);
      expect(updated.liked, false);
    });

    test('liked·likeCount 동시 변경', () {
      final updated = _comment().copyWith(liked: true, likeCount: 3);

      expect(updated.liked, true);
      expect(updated.likeCount, 3);
    });

    test('인자 없으면 원래 값 유지', () {
      final original = _comment(liked: true, likeCount: 7);
      final copy = original.copyWith();

      expect(copy.liked, true);
      expect(copy.likeCount, 7);
    });
  });

  group('CommentDetail.isReply', () {
    test('parentId null이면 false', () {
      expect(_comment(parentId: null).isReply, false);
    });

    test('parentId 있으면 true', () {
      expect(_comment(parentId: 1).isReply, true);
    });
  });
}
