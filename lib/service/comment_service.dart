import 'package:dio/dio.dart';
import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:feple/model/comment_model.dart';
import 'package:feple/network/dio_client.dart';

class CommentService {
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await DioClient.dio.get('/comments/$postId');
    final List data = response.data as List;
    return data.map((e) => Comment.fromJson(e)).toList();
  }

  Future<void> deleteComment(int commentId) async {
    final response = await DioClient.dio.delete('/comments/$commentId');
    if (response.statusCode != 204) {
      throw Exception('댓글 삭제 실패: ${response.statusCode}');
    }
  }

  /// 게시글 댓글 목록 조회 (상세 화면용 — liked/likeCount 포함)
  Future<List<CommentDetail>> fetchPostComments(int postId) async {
    final response = await DioClient.dio.get('/comments/post/$postId');
    return (response.data as List)
        .map((e) => CommentDetail.fromJson(e as Map<String, dynamic>))
        .toList();
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
        final msg = (data is Map ? data['message'] as String? : null) ?? '';
        if (msg.contains('금칙어')) throw const BannedWordException('content');
      }
      rethrow;
    }
  }

  Future<void> toggleCommentLike(int commentId) =>
      DioClient.dio.post('/comments/$commentId/like');

  Future<void> updateComment(int commentId, String content) =>
      DioClient.dio.put('/comments/$commentId', data: {'content': content});
}
