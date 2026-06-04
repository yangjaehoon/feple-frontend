import 'package:dio/dio.dart';
import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:feple/model/comment_model.dart';
import 'package:feple/network/dio_client.dart';

class CommentService {
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await DioClient.dio.get('/comments/$postId');
    return response.toModelList(Comment.fromJson);
  }

  Future<void> deleteComment(int commentId) async {
    final response = await DioClient.dio.delete('/comments/$commentId');
    if (response.statusCode != 204) {
      throw StateError('Unexpected delete response: ${response.statusCode}');
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
  }) async {
    try {
      await DioClient.dio.post('/comments', data: {
        'content': content,
        'postId': postId,
        if (parentId != null) 'parentId': parentId,
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data['code'] == 'BAD_WORD') {
          throw BannedWordException(data['field'] as String? ?? 'content');
        }
      }
      rethrow;
    }
  }

  Future<({bool liked, int likeCount})> toggleCommentLike(int commentId) async {
    final response = await DioClient.dio.post('/comments/$commentId/like');
    final data = response.data as Map<String, dynamic>;
    return (
      liked: data['liked'] as bool,
      likeCount: (data['likeCount'] as num).toInt(),
    );
  }

  Future<void> updateComment(int commentId, String content) async {
    try {
      await DioClient.dio.put('/comments/$commentId', data: {'content': content});
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data['code'] == 'BAD_WORD') {
          throw BannedWordException(data['field'] as String? ?? 'content');
        }
      }
      rethrow;
    }
  }
}
