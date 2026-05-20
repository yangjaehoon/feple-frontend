import 'package:feple/model/comment_detail.dart';
import 'package:feple/model/comment_model.dart';
import 'package:feple/network/dio_client.dart';

class CommentService {
  Future<List<Comment>> fetchComments(int postId) async {
    final resp = await DioClient.dio.get('/comments/$postId');
    final List data = resp.data as List;
    return data.map((e) => Comment.fromJson(e)).toList();
  }

  Future<void> deleteComment(int commentId) async {
    final resp = await DioClient.dio.delete('/comments/$commentId');
    if (resp.statusCode != 204) {
      throw Exception('댓글 삭제 실패: ${resp.statusCode}');
    }
  }

  /// 게시글 댓글 목록 조회 (상세 화면용 — liked/likeCount 포함)
  Future<List<CommentDetail>> fetchPostComments(int postId) async {
    final resp = await DioClient.dio.get('/comments/post/$postId');
    return (resp.data as List)
        .map((e) => CommentDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 댓글 작성 (command only — CQS)
  Future<void> submitComment({
    required String content,
    required int postId,
    int? parentId,
  }) =>
      DioClient.dio.post('/comments', data: {
        'content': content,
        'postId': postId,
        if (parentId != null) 'parentId': parentId,
      });

  /// 댓글 좋아요 토글 → 서버 반환 상태로 UI 즉시 반영
  Future<({bool liked, int likeCount})> toggleCommentLike(int commentId) async {
    final resp = await DioClient.dio.post('/comments/$commentId/like');
    return (
      liked: resp.data['liked'] as bool,
      likeCount: (resp.data['likeCount'] as num).toInt(),
    );
  }
}
