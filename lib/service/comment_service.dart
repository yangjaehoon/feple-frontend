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
}
