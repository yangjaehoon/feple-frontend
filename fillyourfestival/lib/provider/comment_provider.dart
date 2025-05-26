import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../model/comment_model.dart';

class CommentProvider with ChangeNotifier{
  List<Comment> _comments = [];
  List<Comment> get comments => _comments;

  Future<void> fetchComments(int postId) async {
    final resp = await http.get(Uri.parse('$baseUrl/comments/$postId'));
    if (resp.statusCode == 200) {
      final List data = jsonDecode(resp.body);
      _comments = data.map((e) => Comment.fromJson(e)).toList();
      notifyListeners();
    } else {
      throw Exception('댓글 불러오기 실패');
    }
  }

  Future<void> deleteComment(int commentId) async {
    final resp = await http.delete(Uri.parse('$baseUrl/comments/$commentId'));
    if (resp.statusCode == 204) {
      // 로컬 리스트에서도 제거
      _comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
    } else {
      throw Exception('댓글 삭제 실패: ${resp.statusCode}');
    }
  }
}