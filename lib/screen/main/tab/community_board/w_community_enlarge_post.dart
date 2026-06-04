import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/app_events.dart';
import 'package:share_plus/share_plus.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_inline_badge.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/common/widget/w_write_post_screen.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/common/widget/w_report_sheet.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
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
  final int viewCount;
  final bool certified;
  final String? userRole;
  final String? profileImageUrl;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? postUserId;
  final bool anonymous;

  const EnlargePost({
    super.key,
    required this.boardname,
    required this.id,
    required this.nickname,
    required this.title,
    required this.content,
    required this.heart,
    this.viewCount = 0,
    this.certified = false,
    this.userRole,
    this.profileImageUrl,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.postUserId,
    this.anonymous = false,
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
        viewCount = post.viewCount,
        certified = post.certified,
        userRole = post.userRole,
        profileImageUrl = post.profileImageUrl,
        imageUrl = post.imageUrl,
        createdAt = post.createdAt,
        updatedAt = post.updatedAt,
        postUserId = post.userId,
        anonymous = post.anonymous;

  @override
  State<EnlargePost> createState() => _EnlargePostState();
}

class _EnlargePostState extends State<EnlargePost> {
  final _commentController = TextEditingController();
  late final PostDetailNotifier _notifier;
  int? _replyToCommentId;
  String? _replyToNickname;

  late String _title;
  late String _content;
  String? _imageUrl;
  DateTime? _updatedAt;

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
    _title = widget.title;
    _content = widget.content;
    _imageUrl = widget.imageUrl;
    _updatedAt = widget.updatedAt;
    _notifier = PostDetailNotifier(
      postId: widget.id,
      initialHeartCount: widget.heart,
      initialViewCount: widget.viewCount,
      onSuccess: (key) {
        _commentController.clear();
        _cancelReply();
        if (mounted) context.showSuccessSnackbar(key.tr());
      },
      onError: (key) {
        if (!mounted) return;
        context.showErrorSnackbar(key.tr());
      },
      onPostDeleted: () {
        AppEvents.postChanged.value++;
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      },
    );
    _notifier.init();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  void _showImageViewer(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(imageUrl: imageUrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showEditCommentDialog(BuildContext context, String currentContent) {
    final controller = TextEditingController(text: currentContent);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('edit_comment'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: null,
          decoration: InputDecoration(hintText: 'enter_comment'.tr()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('done'.tr()),
          ),
        ],
      ),
    ).then((result) {
      controller.dispose();
      return result;
    });
  }

  List<PopupMenuEntry<String>> _buildMenuItems(bool isOwn) {
    if (isOwn) {
      return [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit_outlined, size: 18),
            const SizedBox(width: 8),
            Text('edit_post'.tr()),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Text('delete_post'.tr(), style: const TextStyle(color: Colors.red)),
          ]),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(children: [
            const Icon(Icons.share_outlined, size: 18),
            const SizedBox(width: 8),
            Text('share'.tr()),
          ]),
        ),
      ];
    } else {
      return [
        PopupMenuItem(
          value: 'report',
          child: Row(children: [
            const Icon(Icons.flag_outlined, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Text('report_post'.tr(), style: const TextStyle(color: Colors.red)),
          ]),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(children: [
            const Icon(Icons.share_outlined, size: 18),
            const SizedBox(width: 8),
            Text('share'.tr()),
          ]),
        ),
      ];
    }
  }

  Future<void> _onMenuSelected(String value) async {
    if (value == 'edit') {
      await Navigator.push(
        context,
        SlideRoute(
          builder: (_) => WritePostScreen(
            title: 'edit_post'.tr(),
            initialTitle: _title,
            initialContent: _content,
            initialImageUrl: _imageUrl,
            showAnonymous: false,
            onSubmit: (t, c, _, img) async {
              await sl<PostService>().updatePost(
                postId: widget.id,
                title: t,
                content: c,
                imageObjectKey: img,
              );
              AppEvents.postChanged.value++;
              if (mounted) {
                setState(() {
                  _title = t;
                  _content = c;
                  _imageUrl = img;
                  _updatedAt = DateTime.now();
                });
                context.showSuccessSnackbar('post_updated'.tr());
              }
            },
          ),
        ),
      );
    } else if (value == 'delete') {
      final confirmed = await showConfirmDialog(
        context,
        title: 'delete_post'.tr(),
        content: 'delete_post_confirm'.tr(),
        confirmLabel: 'delete_post'.tr(),
      );
      if (confirmed) await _notifier.deletePost();
    } else if (value == 'report') {
      showReportSheet(
        context,
        titleKey: 'report_post',
        onSubmit: (reason, detail) =>
            sl<ReportService>().submitReport(widget.id, reason, detail: detail),
        duplicateErrorKey: 'report_duplicate',
      );
    } else if (value == 'share') {
      Share.share('${widget.title}\n\n${widget.content}');
    }
  }

  Widget _buildScrollContent(AbstractThemeColors colors, int? userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textTitle),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ProfileAvatar(
                imageUrl: widget.profileImageUrl,
                nickname: widget.nickname,
                certified: widget.certified,
                userRole: widget.userRole,
                radius: 16,
                anonymous: widget.anonymous,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.nickname,
                        style: TextStyle(fontSize: 13, color: colors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      InlineBadge(userRole: widget.userRole, certified: widget.certified, size: 14),
                    ],
                  ),
                  if (widget.createdAt != null)
                    Row(
                      children: [
                        Text(
                          widget.createdAt!.relativeTime,
                          style: TextStyle(fontSize: 11, color: colors.textSecondary.withValues(alpha: 0.65)),
                        ),
                        if (_updatedAt != null && _updatedAt!.difference(widget.createdAt!).inSeconds > 10) ...[
                          const SizedBox(width: 4),
                          Text(
                            'edited'.tr(),
                            style: TextStyle(fontSize: 10, color: colors.textSecondary.withValues(alpha: 0.45)),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ],
          ),
          Divider(thickness: 1, height: 24, color: colors.listDivider),
          Text(_content, style: TextStyle(color: colors.textTitle, fontSize: 15)),
          if (_imageUrl != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showImageViewer(context, _imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(imageUrl: _imageUrl!, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          ],
          Divider(thickness: 1, height: 40, color: colors.listDivider),
          LikeCommentRow(
            data: PostInteractionData(
              liked: _notifier.liked,
              heartCount: _notifier.heartCount,
              commentCount: _notifier.comments.length,
              scraped: _notifier.scraped,
              scrapCount: _notifier.scrapCount,
            ),
            onLikeTap: () => _notifier.toggleLike(userId),
            onScrapTap: () => _notifier.toggleScrap(userId),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 14, color: colors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                'view_count'.tr(args: [_notifier.viewCount.toString()]),
                style: TextStyle(fontSize: 12, color: colors.textSecondary.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          CommentSection(
            rootComments: _notifier.rootComments,
            repliesMap: _notifier.repliesMap,
            currentUserId: userId,
            onReport: (commentId) => showReportSheet(
              context,
              titleKey: 'report_comment',
              onSubmit: (reason, detail) => sl<ReportService>()
                  .submitCommentReport(commentId, reason, detail: detail),
              duplicateErrorKey: 'report_comment_duplicate',
            ),
            onReply: _setReplyTo,
            onToggleLike: (commentId) => _notifier.toggleCommentLike(commentId, userId),
            onDeleteComment: (commentId) => _notifier.deleteComment(commentId),
            onEditComment: (commentId, currentContent) async {
              final result = await _showEditCommentDialog(context, currentContent);
              if (result != null && result.isNotEmpty) {
                await _notifier.updateComment(commentId, result);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final userId = context.read<UserProvider>().currentUserId;
    final bool isOwn = userId != null && userId == widget.postUserId;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: ListenableBuilder(
        listenable: _notifier,
        builder: (_, __) => CommentInputBar(
          controller: _commentController,
          isSubmitting: _notifier.isSubmitting,
          onSubmit: () {
            if (userId == null) {
              context.showInfoSnackbar('no_login_info'.tr());
              return;
            }
            _notifier.submitComment(
              _commentController.text.trim(),
              parentId: _replyToCommentId,
            );
          },
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
                onSelected: _onMenuSelected,
                itemBuilder: (_) => _buildMenuItems(isOwn),
              ),
            ],
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _notifier,
              builder: (_, __) => Container(
                color: colors.backgroundMain,
                child: _buildScrollContent(colors, userId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
