import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/future_refreshable.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_write_post.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_community_post.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/login_gate.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/util/write_post_submit_handler.dart';
import 'package:flutter/material.dart';

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
  State<CommunityBoardCard> createState() => CommunityBoardCardState();
}

class CommunityBoardCardState extends State<CommunityBoardCard>
    with
        FutureRefreshable<List<Post>, CommunityBoardCard>,
        NavigationGuard,
        RefreshableSection<CommunityBoardCard> {
  final PostService _postService = sl<PostService>();

  @override
  void initState() {
    super.initState();
    AppEvents.postChanged.addListener(_onPostChangedEvent);
  }

  void _onPostChangedEvent() => refresh();

  @override
  Future<void> refreshSection() => refresh();

  @override
  Future<List<Post>> fetchData() =>
      _postService.fetchPosts(widget.serviceBoardType);

  @override
  void dispose() {
    AppEvents.postChanged.removeListener(_onPostChangedEvent);
    super.dispose();
  }

  Future<void> _handleWriteTap() async {
    if (!mounted) return;
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;
    await Navigator.push(
      context,
      SlideRoute(
        builder: (_) => WritePost(
          title: 'write_post'.tr(),
          onSubmit: createPostSubmitHandler(_postService, widget.serviceBoardType),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsiveSize = ResponsiveSize(context);
    return BoardPreviewCard(
      future: future,
      headerIcon: widget.icon,
      headerTitle: widget.title,
      headerColor: widget.headerColorFn(colors),
      height: responsiveSize.h(AppDimens.boardCardHeight),
      emptyHint: widget.emptyHint ?? 'be_first_to_discuss'.tr(args: [widget.title]),
      maxItems: 5,
      onHeaderTap: () => guardedNavigate(() => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => CommunityPost(boardName: widget.boardName, boardType: widget.serviceBoardType),
        ),
      )),
      onPostTap: (context, post) => guardedNavigate(() => Navigator.of(context, rootNavigator: true).push(
        SlideRoute(
          builder: (_) => PostDetailCard.fromPost(
            boardName: widget.boardName,
            post: post,
          ),
        ),
      )),
      onRetry: refresh,
      onWriteTap: widget.showWriteButton ? _handleWriteTap : null,
    );
  }
}
