import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/model/post_changed_event.dart';
import 'package:share_plus/share_plus.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/block_action_helper.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/popup_menu_item_builder.dart';
import 'package:feple/common/widget/w_page_indicator_pill.dart';
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
import 'w_post_content_section.dart';
import 'w_post_header_section.dart';

class PostDetailCard extends StatefulWidget {
  final String boardName;
  final int id;
  final String nickname;
  final String title;
  final String content;
  final int likeCount;
  final int viewCount;
  final bool certified;
  final String? userRole;
  final String? profileImageUrl;
  final List<String> imageUrls;
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
    required this.likeCount,
    this.viewCount = 0,
    this.certified = false,
    this.userRole,
    this.profileImageUrl,
    this.imageUrls = const [],
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
  }) : id = post.id,
       nickname = post.nickname,
       title = post.title,
       content = post.content,
       likeCount = post.likeCount,
       viewCount = post.viewCount,
       certified = post.certified,
       userRole = post.userRole,
       profileImageUrl = post.profileImageUrl,
       imageUrls = post.imageUrls,
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
  late List<String> _imageUrls;
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
    _imageUrls = widget.imageUrls;
    _updatedAt = widget.updatedAt;
    _notifier = PostDetailNotifier(
      postId: widget.id,
      initialLikeCount: widget.likeCount,
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

  void _showImageViewer(BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => _ImageViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  Future<String?> _showEditCommentDialog(
    BuildContext context,
    String currentContent,
  ) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditCommentDialog(initialContent: currentContent),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    bool isOwn,
    AbstractThemeColors colors,
  ) {
    PopupMenuItem<String> item(
      String value,
      IconData icon,
      String label, {
      bool danger = false,
    }) => buildPopupMenuItem(
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
        item(
          'delete',
          Icons.delete_outline_rounded,
          'delete_post'.tr(),
          danger: true,
        ),
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
        unawaited(SharePlus.instance.share(ShareParams(text: '$_title\n\n$_content')));
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
          initialImageUrls: _imageUrls,
          showAnonymous: false,
          onSubmit: (draft) async {
            final t = draft.title;
            final c = draft.content;
            await _postService.updatePost(
              postId: widget.id,
              title: t,
              content: c,
              imageObjectKeys: draft.imageObjectKeys,
            );
            AppEvents.postChanged.value = PostChangedEvent.specific(widget.id);
            // updatePost는 응답 바디가 없어 서버가 계산한 imageUrls를 알 수 없음 —
            // 새 이미지를 올린 경우 imgs는 CDN URL이 아닌 S3 objectKey라 그대로 쓰면
            // 화면에 깨진 이미지가 보이므로 갱신된 게시글을 다시 조회해 교체한다
            List<String> resolvedImageUrls = _imageUrls;
            bool imageRefreshFailed = false;
            try {
              resolvedImageUrls = (await _postService.fetchPost(
                widget.id,
              )).imageUrls;
            } catch (e) {
              // 재조회 실패해도 제목·내용 수정 자체는 서버에 이미 반영됐으므로 폐기하지
              // 않는다 — 다만 화면 피드백 없이 옛 이미지로 조용히 남는 것을 막기 위해
              // 별도 안내 문구로 알린다
              debugPrint('post refetch after update error: $e');
              imageRefreshFailed = true;
            }
            if (mounted) {
              setState(() {
                _title = t;
                _content = c;
                _imageUrls = resolvedImageUrls;
                _updatedAt = DateTime.now();
              });
              if (imageRefreshFailed) {
                context.showErrorSnackbar('post_updated_image_refresh_failed'.tr());
              } else {
                context.showSuccessSnackbar('post_updated'.tr());
              }
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
    final success = await confirmAndToggleBlock(
      context,
      blockService: _blockService,
      userId: authorId,
      nickname: widget.nickname,
      block: true,
    );
    if (success && mounted) Navigator.pop(context);
  }

  Widget _buildScrollContent(AbstractThemeColors colors, int? userId) {
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: _notifier.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostHeaderSection(
              title: _title,
              nickname: widget.nickname,
              profileImageUrl: widget.profileImageUrl,
              certified: widget.certified,
              userRole: widget.userRole,
              anonymous: widget.anonymous,
              authorLevel: widget.authorLevel,
              createdAt: widget.createdAt,
              updatedAt: _updatedAt,
              onAuthorTap: () => navigateToPostAuthor(
                context,
                userId: widget.postUserId,
                nickname: widget.nickname,
                profileImageUrl: widget.profileImageUrl,
              ),
            ),
            Divider(thickness: 1, height: 24, color: colors.listDivider),
            PostContentSection(
              content: _content,
              imageUrls: _imageUrls,
              onImageTap: (i) => _showImageViewer(context, _imageUrls, i),
            ),
            Divider(thickness: 1, height: 40, color: colors.listDivider),
            _buildInteractionArea(colors, userId),
            const SizedBox(height: 24),
            _buildCommentArea(userId),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 좋아요/스크랩/조회수 변경 시만 리빌드 — 댓글 리빌드와 분리
  Widget _buildInteractionArea(AbstractThemeColors colors, int? userId) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (_, _) => Column(
        children: [
          LikeCommentRow(
            interaction: PostInteractionData(
              liked: _notifier.liked,
              likeCount: _notifier.likeCount,
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

  // commentsVersion은 댓글 추가/수정/삭제 시에만 증가 — 좋아요 토글은
  // CommentSection의 _LikeButton이 로컬 상태로 처리하므로 이 리빌드에 관여하지 않음
  Widget _buildCommentArea(int? userId) {
    return ListenableBuilder(
      listenable: _notifier.commentsVersion,
      builder: (_, _) => CommentSection(
        rootComments: _notifier.rootComments,
        repliesMap: _notifier.repliesMap,
        currentUserId: userId,
        onReport: (commentId) => showReportSheet(
          context,
          titleKey: 'report_comment',
          onSubmit: (reason, detail) => _reportService.submitCommentReport(
            commentId,
            reason,
            detail: detail,
          ),
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
        Icon(
          Icons.remove_red_eye_outlined,
          size: 14,
          color: colors.textSecondary.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 4),
        Text(
          'view_count'.tr(args: [_notifier.viewCount.toDisplayCount(context.locale.languageCode)]),
          style: TextStyle(
            fontSize: AppDimens.fontSizeXs,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(int? userId) {
    // 좋아요/스크랩 토글(전체 notifier)이 아니라 isSubmitting/commentError만
    // 담긴 inputBarState를 구독 — 포스트 좋아요를 눌러도 입력창은 안 그려짐
    return ValueListenableBuilder(
      valueListenable: _notifier.inputBarState,
      builder: (_, state, _) => CommentInputBar(
        controller: _commentController,
        isSubmitting: state.isSubmitting,
        onSubmit: (anonymous) {
          if (userId == null) {
            context.showInfoSnackbar('no_login_info'.tr());
            return;
          }
          _notifier.submitComment(
            _commentController.text.trim(),
            parentId: _replyToCommentId,
            anonymous: anonymous,
          );
        },
        errorText: state.commentError?.tr(),
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
                  borderRadius: BorderRadius.circular(AppDimens.shapeDialog),
                ),
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

class _ImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageViewer({required this.images, required this.initialIndex});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final _pageController = PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, i) => Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.images[i],
                    fadeInDuration: AppDimens.animXFast,
                    fadeOutDuration: AppDimens.animTapFeedback,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white38,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.images.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: PageIndicatorPill(
                  currentIndex: _currentIndex,
                  total: widget.images.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
