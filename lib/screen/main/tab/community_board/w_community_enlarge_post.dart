import 'package:dio/dio.dart';
import 'package:feple/common/common.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/report_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';
import 'post_detail_notifier.dart';
import 'w_comment_section.dart' show CommentSection, CommentInputBar;
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

  Future<void> _showReportSheet(BuildContext context) async {
    final colors = context.appColors;
    ReportReason? selected;
    final detailController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('report_post'.tr(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textTitle)),
                const SizedBox(height: 12),
                ...ReportReason.values.map((r) {
                  final label = switch (r) {
                    ReportReason.SPAM => 'report_reason_spam'.tr(),
                    ReportReason.ABUSE => 'report_reason_abuse'.tr(),
                    ReportReason.OBSCENE => 'report_reason_obscene'.tr(),
                    ReportReason.MISINFORMATION =>
                      'report_reason_misinformation'.tr(),
                    ReportReason.OTHER => 'report_reason_other'.tr(),
                  };
                  return RadioListTile<ReportReason>(
                    value: r,
                    groupValue: selected,
                    title: Text(label,
                        style: TextStyle(
                            fontSize: 14, color: colors.textTitle)),
                    onChanged: (v) => setS(() => selected = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const SizedBox(height: 8),
                TextField(
                  controller: detailController,
                  decoration: InputDecoration(
                    hintText: 'report_detail_hint'.tr(),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('report_cancel'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selected == null
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                try {
                                  await sl<ReportService>().submitReport(
                                    widget.id,
                                    selected!,
                                    detail: detailController.text.trim(),
                                  );
                                  if (mounted) {
                                    context.showSuccessSnackbar(
                                        'report_success'.tr());
                                  }
                                } on DioException catch (e) {
                                  if (!mounted) return;
                                  final msg =
                                      e.response?.data?['message'] as String?;
                                  context.showErrorSnackbar(
                                      msg ?? 'report_duplicate'.tr());
                                }
                              },
                        child: Text('report_submit'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
    detailController.dispose();
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'report') _showReportSheet(context);
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
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) => CommentInputBar(
          controller: _commentController,
          isSubmitting: _notifier.isSubmitting,
          onSubmit: () => _notifier.submitComment(
              _commentController.text.trim(), userId),
          errorText: _notifier.commentError?.tr(),
        ),
      ),
      body: ListenableBuilder(
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
                    if (widget.userRole == 'ADMIN') ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'badge_admin'.tr(),
                        child: const Icon(Icons.shield_rounded,
                            size: 14, color: AppColors.badgeAdmin),
                      ),
                    ] else if (widget.userRole == 'ARTIST') ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'badge_artist_certified'.tr(),
                        child: const Icon(Icons.verified_rounded,
                            size: 14, color: AppColors.badgeArtist),
                      ),
                    ] else if (widget.certified) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'badge_festival_certified'.tr(),
                        child: const Icon(Icons.verified_rounded,
                            size: 14, color: AppColors.badgeCertified),
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
                  scraped: _notifier.scraped,
                  scrapCount: _notifier.scrapCount,
                  onLikeTap: () => _notifier.toggleLike(userId),
                  onScrapTap: () => _notifier.toggleScrap(userId),
                ),
                const SizedBox(height: 24),
                CommentSection(comments: _notifier.comments),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
