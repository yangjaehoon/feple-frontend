import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_inline_badge.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/common/widget/w_report_sheet.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/report_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';
import 'post_detail_notifier.dart';
import 'w_comment_input_bar.dart';
import 'w_comment_section.dart';
import 'w_like_comment_row.dart';

class EnlargePost extends StatefulWidget {
  final String boardname;
  final int id;
  final String nickname;
  final String title;
  final String content;
  final int heart;
  final bool certified;
  final String? userRole;

  const EnlargePost({
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

  EnlargePost.fromPost({
    super.key,
    required this.boardname,
    required Post post,
  })  : id = post.id,
        nickname = post.nickname,
        title = post.title,
        content = post.content,
        heart = post.likeCount,
        certified = post.certified,
        userRole = post.userRole;

  @override
  State<EnlargePost> createState() => _EnlargePostState();
}

class _EnlargePostState extends State<EnlargePost> {
  final _commentController = TextEditingController();
  late final PostDetailNotifier _notifier;
  int? _replyToCommentId;
  String? _replyToNickname;

  void _setReplyTo(int commentId, String nickname) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToNickname = nickname;
    });
    _commentController.clear();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToNickname = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _notifier = PostDetailNotifier(
      postId: widget.id,
      initialHeartCount: widget.heart,
    );
    _notifier.onCommentPosted = (key) {
      _commentController.clear();
      _cancelReply();
      if (mounted) context.showSuccessSnackbar(key.tr());
    };
    _notifier.onError = (msg) {
      if (!mounted) return;
      final parts = msg.split(':');
      final key = parts[0];
      final arg = parts.length > 1 ? parts.sublist(1).join(':') : '';
      context.showErrorSnackbar(key.tr(args: [arg]));
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
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) => CommentInputBar(
          controller: _commentController,
          isSubmitting: _notifier.isSubmitting,
          onSubmit: () => _notifier.submitComment(
            _commentController.text.trim(),
            userId,
            parentId: _replyToCommentId,
          ),
          errorText: _notifier.commentError?.tr(),
          replyToNickname: _replyToNickname,
          onCancelReply: _cancelReply,
        ),
      ),
      body: Column(
        children: [
          SecondaryAppBar(
            title: widget.boardname,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'report') {
                    showReportSheet(
                      context,
                      titleKey: 'report_post',
                      onSubmit: (reason, detail) =>
                          sl<ReportService>().submitReport(widget.id, reason, detail: detail),
                      duplicateErrorKey: 'report_duplicate',
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('report_post'.tr(),
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _notifier,
              builder: (context, _) => Container(
                color: colors.backgroundMain,
                child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                    InlineBadge(
                      userRole: widget.userRole,
                      certified: widget.certified,
                      size: 14,
                    ),
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
                  scraped: _notifier.scraped,
                  scrapCount: _notifier.scrapCount,
                  onLikeTap: () => _notifier.toggleLike(userId),
                  onScrapTap: () => _notifier.toggleScrap(userId),
                ),
                const SizedBox(height: 24),
                CommentSection(
                  comments: _notifier.comments,
                  currentUserId: userId,
                  onReport: (commentId) => showReportSheet(
                    context,
                    titleKey: 'report_comment',
                    onSubmit: (reason, detail) => sl<ReportService>()
                        .submitCommentReport(commentId, reason, detail: detail),
                    duplicateErrorKey: 'report_comment_duplicate',
                  ),
                  onReply: _setReplyTo,
                  onToggleLike: (commentId) =>
                      _notifier.toggleCommentLike(commentId, userId),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
            ),
          ),
        ],
      ),
    );
  }
}
