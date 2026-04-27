import 'package:flutter/material.dart';
import 'package:feple/service/comment_service.dart';

import '../model/comment_model.dart';

class CommentProvider with ChangeNotifier {
  CommentProvider(this._service);

  final CommentService _service;

  List<Comment> _comments = [];
  List<Comment> get comments => _comments;

  Future<void> fetchComments(int postId) async {
    _comments = await _service.fetchComments(postId);
    notifyListeners();
  }

  Future<void> deleteComment(int commentId) async {
    await _service.deleteComment(commentId);
    _comments.removeWhere((c) => c.id == commentId);
    notifyListeners();
  }
}
