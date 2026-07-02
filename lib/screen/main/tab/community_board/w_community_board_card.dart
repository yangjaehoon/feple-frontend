import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_community_post.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/model/post_changed_event.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 게시판 미리보기 카드 — 3개 게시판(인기/자유/동행)이 공유하는 공용 위젯
class CommunityBoardCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color Function(AbstractThemeColors) headerColorFn;
  final String serviceBoardType;
  final String boardName;
  final bool showWriteButton;
  final String? emptyHint;

  const CommunityBoardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.headerColorFn,
    required this.serviceBoardType,
    required this.boardName,
    this.showWriteButton = true,
    this.emptyHint,
  });

  @override
  State<CommunityBoardCard> createState() => _CommunityBoardCardState();
}

class _CommunityBoardCardState extends State<CommunityBoardCard> {
  final PostService _postService = sl<PostService>();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchPosts(widget.serviceBoardType);
    AppEvents.postChanged.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _postsFuture = _postService.fetchPosts(widget.serviceBoardType);
      });
    }
  }

  @override
  void dispose() {
    AppEvents.postChanged.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _handleWriteTap() async {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.currentUserId;
    if (userId == null) {
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
    await Navigator.push(
      context,
      SlideRoute(
        builder: (_) => WritePost(
          title: 'write_post'.tr(),
          onSubmit: (t, c, a, img) async {
            await _postService.createPost(
              boardType: widget.serviceBoardType,
              title: t,
              content: c,
              anonymous: a,
              imageObjectKey: img,
            );
            AppEvents.postChanged.value = PostChangedEvent.refreshAll();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsiveSize = ResponsiveSize(context);
    return BoardPreviewCard(
      future: _postsFuture,
      headerIcon: widget.icon,
      headerTitle: widget.title,
      headerColor: widget.headerColorFn(colors),
      height: responsiveSize.h(AppDimens.boardCardHeight),
      emptyHint: widget.emptyHint ?? 'be_first_to_discuss'.tr(args: [widget.title]),
      maxItems: 5,
      onHeaderTap: () => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => CommunityPost(boardName: widget.boardName, boardType: widget.serviceBoardType),
        ),
      ),
      onPostTap: (context, post) => Navigator.of(context, rootNavigator: true).push(
        SlideRoute(
          builder: (_) => PostDetailCard.fromPost(
            boardName: widget.boardName,
            post: post,
          ),
        ),
      ),
      onRetry: _refresh,
      onWriteTap: widget.showWriteButton ? _handleWriteTap : null,
    );
  }
}
