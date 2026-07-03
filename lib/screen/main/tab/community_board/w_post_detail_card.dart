import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/model/post_changed_event.dart';
import 'package:share_plus/share_plus.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/popup_menu_item_builder.dart';
import 'package:feple/common/widget/w_inline_badge.dart';
import 'package:feple/common/widget/w_level_badge.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/common/widget/w_report_sheet.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/block_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/report_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';
import '../my_page/s_other_user_profile.dart';
import 'post_detail_notifier.dart';
import 'w_comment_input_bar.dart';
import 'w_comment_section.dart';
import 'w_edit_comment_dialog.dart';
import 'w_like_comment_row.dart';

class PostDetailCard extends StatefulWidget {
  final String boardName;
  final int id;
  final String nickname;
  final String title;
  final String content;
  final int heartCount;
  final int viewCount;
  final bool certified;
  final String? userRole;
  final String? profileImageUrl;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? postUserId;
  final bool anonymous;
  final String? authorLevel;

  const PostDetailCard({
    super.key,
    required this.boardName,
    required this.id,
    required this.nickname,
    required this.title,
    required this.content,
    required this.heartCount,
    this.viewCount = 0,
    this.certified = false,
    this.userRole,
    this.profileImageUrl,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.postUserId,
    this.anonymous = false,
    this.authorLevel,
  });

  PostDetailCard.fromPost({
    super.key,
    required this.boardName,
    required Post post,
  })  : id = post.id,
        nickname = post.nickname,
        title = post.title,
        content = post.content,
        heartCount = post.likeCount,
        viewCount = post.viewCount,
        certified = post.certified,
        userRole = post.userRole,
        profileImageUrl = post.profileImageUrl,
        imageUrl = post.imageUrl,
        createdAt = post.createdAt,
        updatedAt = post.updatedAt,
        postUserId = post.userId,
        anonymous = post.anonymous,
        authorLevel = post.authorLevel;

  @override
  State<PostDetailCard> createState() => _PostDetailCardState();
}

class _PostDetailCardState extends State<PostDetailCard> {
  final _postService = sl<PostService>();
  final _reportService = sl<ReportService>();
  final _blockService = sl<BlockService>();
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
      initialHeartCount: widget.heartCount,
      initialViewCount: widget.viewCount,
      onSuccess: (key) {
        _commentController.clear();
        _cancelReply();
        if (mounted) {
          FocusScope.of(context).unfocus();
          context.showSuccessSnackbar(key.tr());
        }
      },
      onError: (key) {
        if (!mounted) return;
        context.showErrorSnackbar(key.tr());
      },
      onPostDeleted: () {
        AppEvents.postChanged.value = PostChangedEvent.specific(widget.id);
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
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fadeInDuration: AppDimens.animXFast,
                  fadeOutDuration: AppDimens.animTapFeedback,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 56),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _showEditCommentDialog(
      BuildContext context, String currentContent) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditCommentDialog(initialContent: currentContent),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
      bool isOwn, AbstractThemeColors colors) {
    PopupMenuItem<String> item(String value, IconData icon, String label,
            {bool danger = false}) =>
        buildPopupMenuItem(
          value: value,
          icon: icon,
          label: label,
          colors: colors,
          danger: danger,
          height: 48,
          iconSize: 19,
          spacing: 12,
          fontSize: AppDimens.fontSizeMd,
          fontWeight: FontWeight.w500,
        );

    if (isOwn) {
      return [
        item('edit', Icons.edit_outlined, 'edit_post'.tr()),
        item('share', Icons.share_outlined, 'share'.tr()),
        const PopupMenuDivider(height: 1),
        item('delete', Icons.delete_outline_rounded, 'delete_post'.tr(),
            danger: true),
      ];
    } else {
      return [
        item('share', Icons.share_outlined, 'share'.tr()),
        const PopupMenuDivider(height: 1),
        item('report', Icons.flag_outlined, 'report_post'.tr(), danger: true),
        const PopupMenuDivider(height: 1),
        item('block', Icons.block_rounded, 'block_user'.tr(), danger: true),
      ];
    }
  }

  Future<void> _onMenuSelected(String value) async {
    switch (value) {
      case 'edit':
        await _onEditPost();
      case 'delete':
        await _onDeletePost();
      case 'report':
        _onReportPost();
      case 'block':
        await _onBlockUser();
      case 'share':
        SharePlus.instance.share(ShareParams(text: '$_title\n\n$_content'));
    }
  }

  Future<void> _onEditPost() async {
    await Navigator.push(
      context,
      SlideRoute(
        builder: (_) => WritePost(
          title: 'edit_post'.tr(),
          initialTitle: _title,
          initialContent: _content,
          initialImageUrl: _imageUrl,
          showAnonymous: false,
          onSubmit: (t, c, _, img) async {
            await _postService.updatePost(
              postId: widget.id,
              title: t,
              content: c,
              imageObjectKey: img,
            );
            AppEvents.postChanged.value = PostChangedEvent.specific(widget.id);
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
  }

  Future<void> _onDeletePost() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'delete_post'.tr(),
      content: 'delete_post_confirm'.tr(),
      confirmLabel: 'delete_post'.tr(),
    );
    if (confirmed) await _notifier.deletePost();
  }

  void _onReportPost() {
    showReportSheet(
      context,
      titleKey: 'report_post',
      onSubmit: (reason, detail) =>
          _reportService.submitReport(widget.id, reason, detail: detail),
      duplicateErrorKey: 'report_duplicate',
    );
  }

  Future<void> _onBlockUser() async {
    final authorId = widget.postUserId;
    if (authorId == null) return;
    final nickname = widget.nickname;
    final confirmed = await showConfirmDialog(
      context,
      title: 'block_title'.tr(),
      content: 'block_confirm'.tr(args: [nickname]),
      confirmLabel: 'block'.tr(),
    );
    if (!confirmed || !mounted) return;
    try {
      await _blockService.blockUser(authorId);
      if (!mounted) return;
      context.showSuccessSnackbar('block_success'.tr(args: [nickname]));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) context.showErrorSnackbar('block_failed'.tr());
    }
  }

  Widget _buildScrollContent(AbstractThemeColors colors, int? userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeaderSection(
            title: _title,
            nickname: widget.nickname,
            profileImageUrl: widget.profileImageUrl,
            certified: widget.certified,
            userRole: widget.userRole,
            anonymous: widget.anonymous,
            authorLevel: widget.authorLevel,
            createdAt: widget.createdAt,
            updatedAt: _updatedAt,
            onAuthorTap: () => navigateToUserProfile(
              context,
              userId: widget.postUserId,
              nickname: widget.nickname,
              profileImageUrl: widget.profileImageUrl,
              currentUserId: userId,
            ),
          ),
          Divider(thickness: 1, height: 24, color: colors.listDivider),
          _PostContentSection(
            content: _content,
            imageUrl: _imageUrl,
            onImageTap: _imageUrl != null
                ? () => _showImageViewer(context, _imageUrl!)
                : null,
          ),
          Divider(thickness: 1, height: 40, color: colors.listDivider),
          _buildInteractionArea(colors, userId),
          const SizedBox(height: 24),
          _buildCommentArea(userId),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 좋아요/스크랩/조회수 변경 시만 리빌드 — 댓글 리빌드와 분리
  Widget _buildInteractionArea(AbstractThemeColors colors, int? userId) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (_, __) => Column(
        children: [
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
          _buildViewCountRow(colors),
        ],
      ),
    );
  }

  // commentsVersion이 바뀔 때만 리빌드 — 댓글 좋아요가 상호작용 영역을 리빌드하지 않음
  Widget _buildCommentArea(int? userId) {
    return ListenableBuilder(
      listenable: _notifier.commentsVersion,
      builder: (_, __) => CommentSection(
        rootComments: _notifier.rootComments,
        repliesMap: _notifier.repliesMap,
        currentUserId: userId,
        onReport: (commentId) => showReportSheet(
          context,
          titleKey: 'report_comment',
          onSubmit: (reason, detail) => _reportService
              .submitCommentReport(commentId, reason, detail: detail),
          duplicateErrorKey: 'report_comment_duplicate',
        ),
        onReply: _setReplyTo,
        onToggleLike: (commentId) =>
            _notifier.toggleCommentLike(commentId, userId),
        onDeleteComment: (commentId) => _notifier.deleteComment(commentId),
        onEditComment: (commentId, currentContent) async {
          final result = await _showEditCommentDialog(context, currentContent);
          if (result != null && result.isNotEmpty) {
            await _notifier.updateComment(commentId, result);
          }
        },
        onAuthorTap: (authorId, nickname, profileImageUrl) =>
            navigateToUserProfile(
              context,
              userId: authorId,
              nickname: nickname,
              profileImageUrl: profileImageUrl,
              currentUserId: userId,
            ),
      ),
    );
  }

  Widget _buildViewCountRow(AbstractThemeColors colors) {
    return Row(
      children: [
        Icon(Icons.remove_red_eye_outlined,
            size: 14, color: colors.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          'view_count'.tr(args: [_notifier.viewCount.toString()]),
          style: TextStyle(
              fontSize: AppDimens.fontSizeXs,
              color: colors.textSecondary.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Widget _buildBottomBar(int? userId) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (_, __) => CommentInputBar(
        controller: _commentController,
        isSubmitting: _notifier.isSubmitting,
        onSubmit: (anonymous) {
          if (userId == null) {
            final userProvider = context.read<UserProvider>();
            context.showInfoSnackbar(
              'no_login_info'.tr(),
              extraButton: GestureDetector(
                onTap: () => userProvider.logout(),
                child: Text(
                  'login'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: AppDimens.fontSizeSm,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            );
            return;
          }
          _notifier.submitComment(
            _commentController.text.trim(),
            parentId: _replyToCommentId,
            anonymous: anonymous,
          );
        },
        errorText: _notifier.commentError?.tr(),
        replyToNickname: _replyToNickname,
        onCancelReply: _cancelReply,
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
      bottomNavigationBar: _buildBottomBar(userId),
      body: Column(
        children: [
          SecondaryAppBar(
            title: widget.boardName,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: _onMenuSelected,
                itemBuilder: (_) => _buildMenuItems(isOwn, colors),
                color: colors.surface,
                shadowColor: colors.cardShadow.withValues(alpha: 0.18),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.shapeDialog)),
                position: PopupMenuPosition.under,
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: colors.backgroundMain,
              child: _buildScrollContent(colors, userId),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostHeaderSection extends StatelessWidget {
  final String title;
  final String nickname;
  final String? profileImageUrl;
  final bool certified;
  final String? userRole;
  final bool anonymous;
  final String? authorLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final VoidCallback? onAuthorTap;

  const _PostHeaderSection({
    required this.title,
    required this.nickname,
    this.profileImageUrl,
    required this.certified,
    this.userRole,
    required this.anonymous,
    this.authorLevel,
    this.createdAt,
    this.updatedAt,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppDimens.fontSizeTitle,
            fontWeight: FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: (!anonymous && onAuthorTap != null) ? onAuthorTap : null,
              child: ProfileAvatar(
                imageUrl: profileImageUrl,
                nickname: nickname,
                certified: certified,
                userRole: userRole,
                radius: 16,
                anonymous: anonymous,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nickname,
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeSm,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InlineBadge(
                        userRole: userRole, certified: certified, size: 14),
                    if (!anonymous) ...[
                      const SizedBox(width: 5),
                      LevelBadge(authorLevel: authorLevel, fontSize: 10),
                    ],
                  ],
                ),
                if (createdAt != null)
                  Row(
                    children: [
                      Text(
                        createdAt!.relativeTime,
                        style: TextStyle(
                          fontSize: AppDimens.fontSizeXxs,
                          color:
                              colors.textSecondary.withValues(alpha: 0.65),
                        ),
                      ),
                      if (updatedAt != null &&
                          updatedAt!.difference(createdAt!).inSeconds >
                              10) ...[
                        const SizedBox(width: 4),
                        Text(
                          'edited'.tr(),
                          style: TextStyle(
                            fontSize: AppDimens.fontSizeTiny,
                            color: colors.textSecondary
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _PostContentSection extends StatelessWidget {
  final String content;
  final String? imageUrl;
  final VoidCallback? onImageTap;

  const _PostContentSection({
    required this.content,
    this.imageUrl,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style:
              TextStyle(color: colors.textTitle, fontSize: AppDimens.fontSizeLg),
        ),
        if (imageUrl != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                memCacheWidth: 800, // 최대 스크린 너비 기준
                fadeInDuration: AppDimens.animXFast,
                fadeOutDuration: AppDimens.animTapFeedback,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: colors.listDivider,
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  color: colors.listDivider,
                  child: Center(
                    child: Icon(Icons.broken_image_rounded, color: colors.textSecondary, size: 36),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
