import 'package:flutter/material.dart';
import 'package:fast_app_base/network/dio_client.dart';

import '../model/comment_model.dart';

class CommentProvider with ChangeNotifier{
  List<Comment> _comments = [];
  List<Comment> get comments => _comments;

  Future<void> fetchComments(int postId) async {
    final resp = await DioClient.dio.get('/comments/$postId');
    final List data = resp.data as List;
    _comments = data.map((e) => Comment.fromJson(e)).toList();
    notifyListeners();
  }

  Future<void> deleteComment(int commentId) async {
    final resp = await DioClient.dio.delete('/comments/$commentId');
    if (resp.statusCode == 204) {
      _comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
    } else {
      throw Exception('댓글 삭제 실패: ${resp.statusCode}');
    }
  }
}