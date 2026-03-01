import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../config.dart';
import '../../../../provider/user_provider.dart';

class EnralgePost extends StatefulWidget {
  final String boardname;
  final int id;
  final String nickname;
  final String title;
  final String content;
  final int heart;

  const EnralgePost({
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
  late int _heartCount;

  @override
  void initState() {
    super.initState();
    _heartCount = widget.heart;
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
          _heartCount = liked ? _heartCount + 1 : _heartCount - 1;
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
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardname),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: colors.backgroundMain,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle,
                ),
              ),
              const SizedBox(height: 4),
              // Author
              Text(
                widget.nickname,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              Divider(
                thickness: 1,
                height: 24,
                color: colors.listDivider,
              ),
              // Content
              Text(
                widget.content,
                style: TextStyle(color: colors.textTitle, fontSize: 15),
              ),
              Divider(
                thickness: 1,
                height: 40,
                color: colors.listDivider,
              ),
              // Like & comment count
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          _liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: AppColors.kawaiiPink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _heartCount.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textTitle,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.comment_rounded, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _comments.length.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textTitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Comment list
              if (_comments.isNotEmpty)
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _comments.length,
                  separatorBuilder: (_, __) => Divider(
                    color: colors.listDivider,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final c = _comments[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.activate,
                            child: const Icon(Icons.person,
                                size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User ${c['userId']}',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c['content'] as String,
                                  style: TextStyle(color: colors.textTitle),
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
              // Comment input
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.listDivider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '댓글을 입력하세요.',
                          hintStyle: TextStyle(color: colors.textSecondary),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        style: TextStyle(color: colors.textTitle),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _isSubmitting
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.activate,
                            ),
                          )
                        : IconButton(
                            onPressed: _commentSubmit,
                            icon: Icon(Icons.send_rounded,
                                color: colors.activate),
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
