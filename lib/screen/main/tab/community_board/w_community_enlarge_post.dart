import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';
import 'package:feple/network/dio_client.dart';
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
  final bool certified;
  final String? userRole;

  const EnralgePost({
    super.key,
    required this.boardname,
    required this.id,
    required this.nickname,
    required this.title,
    required this.content,
    required this.heart,
    this.certified = false,
    this.userRole,
  });

  @override
  State<EnralgePost> createState() => _EnralgePostState();
}

class _EnralgePostState extends State<EnralgePost> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _commentError;
  List<Map<String, dynamic>> _comments = [];
  bool _liked = false;
  late int _heartCount;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _heartCount = widget.heart;
    _fetchComments();
    _loadPostState();
  }

  Future<void> _loadPostState() async {
    try {
      final results = await Future.wait([
        DioClient.dio.get('/posts/${widget.id}'),
        DioClient.dio.get('/posts/${widget.id}/liked'),
      ]);
      final freshLikeCount = (results[0].data['likeCount'] as num?)?.toInt() ?? _heartCount;
      final isLiked = results[1].data as bool? ?? _liked;
      if (mounted) {
        setState(() {
          _heartCount = freshLikeCount;
          _liked = isLiked;
        });
      }
    } catch (e) {
      debugPrint('loadPostState error: $e');
    }
  }

  // ── API 호출 ──

  Future<void> _fetchComments() async {
    try {
      final resp = await DioClient.dio.get('/comments/post/${widget.id}');
      setState(() {
        _comments =
            (resp.data as List).map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('fetchComments error: $e');
    }
  }

  Future<void> _commentSubmit() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      setState(() => _commentError = 'enter_comment_please'.tr());
      return;
    }
    setState(() => _commentError = null);

    if (context.read<UserProvider>().user == null) {
      setState(() => _commentError = 'no_login_info'.tr());
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await DioClient.dio.post('/comments', data: {
        'content': comment,
        'postId': widget.id,
      });
      _commentController.clear();
      await _fetchComments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: AppColors.skyBlue,
            content: Text('comment_posted'.tr())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: AppColors.skyBlue,
            content: Text('comment_failed'.tr(args: [e.toString()]))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_isToggling) return;
    if (context.read<UserProvider>().user == null) return;

    setState(() => _isToggling = true);
    try {
      final resp = await DioClient.dio.post('/posts/${widget.id}/like');
      final bool liked = resp.data as bool;
      setState(() {
        _liked = liked;
        _heartCount = liked ? _heartCount + 1 : _heartCount - 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: AppColors.skyBlue,
            content: Text('like_failed'.tr(args: [e.toString()]))),
      );
    } finally {
      if (mounted) setState(() => _isToggling = false);
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
              Row(
                children: [
                  Text(
                    widget.nickname,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  if (widget.userRole == 'ADMIN') ...[
                    const SizedBox(width: 4),
                    const Tooltip(
                      message: '관리자',
                      child: Icon(Icons.shield_rounded, size: 14, color: Colors.deepPurple),
                    ),
                  ] else if (widget.userRole == 'ARTIST') ...[
                    const SizedBox(width: 4),
                    const Tooltip(
                      message: '아티스트 인증',
                      child: Icon(Icons.verified_rounded, size: 14, color: Colors.blue),
                    ),
                  ] else if (widget.certified) ...[
                    const SizedBox(width: 4),
                    const Tooltip(
                      message: '페스티벌 인증 완료',
                      child: Icon(Icons.verified_rounded, size: 14, color: Colors.teal),
                    ),
                  ],
                ],
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
                errorText: _commentError,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
