import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';
import 'w_comment_section.dart';
import 'w_like_comment_row.dart';

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

  // ── API 호출 ──

  Future<void> _fetchComments() async {
    try {
      final resp = await DioClient.dio.get('/comments/post/${widget.id}');
      setState(() {
        _comments = (resp.data as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _commentSubmit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력해주세요.')),
      );
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

    try {
      await DioClient.dio.post('/comments', data: {
        'content': comment,
        'postId': widget.id,
        'userId': user.id,
      });
      _commentController.clear();
      await _fetchComments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 등록되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 등록에 실패했습니다.\n$e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleLike() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    try {
      final resp = await DioClient.dio.post(
        '/posts/${widget.id}/like',
        queryParameters: {'userId': user.id},
      );
      final bool liked = resp.data as bool;
      setState(() {
        _liked = liked;
        _heartCount = liked ? _heartCount + 1 : _heartCount - 1;
      });
    } catch (e) {
      if (!mounted) return;
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

  // ── UI ──

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
              // 제목
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle,
                ),
              ),
              const SizedBox(height: 4),
              // 작성자
              Text(
                widget.nickname,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              Divider(thickness: 1, height: 24, color: colors.listDivider),
              // 본문
              Text(
                widget.content,
                style: TextStyle(color: colors.textTitle, fontSize: 15),
              ),
              Divider(thickness: 1, height: 40, color: colors.listDivider),
              // 좋아요 + 댓글 수
              LikeCommentRow(
                liked: _liked,
                heartCount: _heartCount,
                commentCount: _comments.length,
                onLikeTap: _toggleLike,
              ),
              const SizedBox(height: 24),
              // 댓글 섹션
              CommentSection(
                comments: _comments,
                controller: _commentController,
                isSubmitting: _isSubmitting,
                onSubmit: _commentSubmit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
