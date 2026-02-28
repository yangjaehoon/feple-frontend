import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../config.dart';
import '../../../../provider/user_provider.dart';

class EnralgePost extends StatefulWidget {
  String boardname;
  int id;
  String nickname;
  String title;
  String content;
  int heart;

  EnralgePost({
    super.key,
    required this.boardname,
    required this.id,
    required this.nickname,
    required this.title,
    required this.content,
    required this.heart,
  });

  @override
  State<EnralgePost> createState() => _EnralgePostState();
}

class _EnralgePostState extends State<EnralgePost> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _comments = [];
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final uri = Uri.parse('$baseUrl/comments/post/${widget.id}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> parsed = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _comments = parsed.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _commentSubmit() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('댓글을 입력해주세요.'),
      ));
      return;
    }

    final user = context.read<UserProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final body = {
      'content': comment,
      'postId': widget.id,
      'userId': user.id,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        _commentController.clear();
        await _fetchComments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 등록되었습니다.')),
        );
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 등록에 실패했습니다.\n$e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleLike() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final uri = Uri.parse('$baseUrl/posts/${widget.id}/like?userId=${user.id}');
    try {
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        final bool liked = json.decode(response.body) as bool;
        setState(() {
          _liked = liked;
          widget.heart = liked ? widget.heart + 1 : widget.heart - 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('좋아요 처리에 실패했습니다.\n$e')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardname),
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                widget.nickname,
                style: const TextStyle(fontSize: 13, color: Colors.white54),
              ),
              const Divider(
                thickness: 2,
                height: 24,
                color: Color.fromARGB(255, 110, 110, 110),
              ),
              Text(
                widget.content,
                style: const TextStyle(color: Colors.white),
              ),
              const Divider(
                thickness: 2,
                height: 40,
                color: Color.fromARGB(255, 110, 110, 110),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: _liked ? const Color(0xFFFF6B9D) : Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.heart.toString(),
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    _comments.length.toString(),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 댓글 목록
              if (_comments.isNotEmpty)
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _comments.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Color.fromARGB(255, 60, 60, 60),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final c = _comments[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User ${c['userId']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c['content'] as String,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              // 댓글 입력
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(50, 255, 255, 255),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '댓글을 입력하세요.',
                          hintStyle: TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            onPressed: _commentSubmit,
                            icon: const Icon(Icons.send, color: Colors.white),
                          ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
