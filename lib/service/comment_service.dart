import 'package:dio/dio.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:feple/network/dio_client.dart';

class CommentService {
  Future<void> deleteComment(int commentId) async {
    final response = await DioClient.dio.delete('/comments/$commentId');
    if (response.statusCode != 204) {
      throw Exception('deleteComment: expected 204 but got ${response.statusCode}');
    }
  }

  /// 게시글 댓글 목록 조회 (상세 화면용 — liked/likeCount 포함)
  Future<List<CommentDetail>> fetchPostComments(int postId) async {
    final response = await DioClient.dio.get('/comments/post/$postId');
    return response.toModelList(CommentDetail.fromJson);
  }

  /// 댓글 작성 (command only — CQS)
  Future<void> submitComment({
    required String content,
    required int postId,
    int? parentId,
    bool anonymous = false,
  }) async {
    try {
      await DioClient.dio.post('/comments', data: {
        'content': content,
        'postId': postId,
        'parentId': ?parentId,
        'anonymous': anonymous,
      });
    } on DioException catch (e) {
      throwIfBannedWord(e);
      rethrow;
    }
  }

  Future<void> toggleCommentLike(int commentId) =>
      DioClient.dio.post('/comments/$commentId/like');

  Future<void> updateComment(int commentId, String content) async {
    try {
      await DioClient.dio.put('/comments/$commentId', data: {'content': content});
    } on DioException catch (e) {
      throwIfBannedWord(e);
      rethrow;
    }
  }
}
