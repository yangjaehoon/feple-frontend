import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';
import 'post_detail_notifier.dart';
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
  late final PostDetailNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = PostDetailNotifier(
      postId: widget.id,
      initialHeartCount: widget.heart,
    );
    _notifier.onCommentPosted = (key) {
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: AppColors.skyBlue,
            content: Text(key.tr())));
      }
    };
    _notifier.onError = (msg) {
      if (!mounted) return;
      final parts = msg.split(':');
      final key = parts[0];
      final arg = parts.length > 1 ? parts.sublist(1).join(':') : '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.skyBlue,
          content: Text(key.tr(args: [arg]))));
    };
    _notifier.init();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final userId = context.read<UserProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardname),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) => Container(
          color: colors.backgroundMain,
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textTitle,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      widget.nickname,
                      style: TextStyle(
                          fontSize: 13, color: colors.textSecondary),
                    ),
                    if (widget.userRole == 'ADMIN') ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: '관리자',
                        child: Icon(Icons.shield_rounded,
                            size: 14, color: Colors.deepPurple),
                      ),
                    ] else if (widget.userRole == 'ARTIST') ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: '아티스트 인증',
                        child: Icon(Icons.verified_rounded,
                            size: 14, color: Colors.blue),
                      ),
                    ] else if (widget.certified) ...[
                      const SizedBox(width: 4),
                      const Tooltip(
                        message: '페스티벌 인증 완료',
                        child: Icon(Icons.verified_rounded,
                            size: 14, color: Colors.teal),
                      ),
                    ],
                  ],
                ),
                Divider(
                    thickness: 1, height: 24, color: colors.listDivider),
                Text(
                  widget.content,
                  style: TextStyle(color: colors.textTitle, fontSize: 15),
                ),
                Divider(
                    thickness: 1, height: 40, color: colors.listDivider),
                LikeCommentRow(
                  liked: _notifier.liked,
                  heartCount: _notifier.heartCount,
                  commentCount: _notifier.comments.length,
                  onLikeTap: () => _notifier.toggleLike(userId),
                ),
                const SizedBox(height: 24),
                CommentSection(
                  comments: _notifier.comments,
                  controller: _commentController,
                  isSubmitting: _notifier.isSubmitting,
                  onSubmit: () => _notifier.submitComment(
                      _commentController.text.trim(), userId),
                  errorText: _notifier.commentError?.tr(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
