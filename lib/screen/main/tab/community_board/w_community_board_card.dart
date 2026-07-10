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
  State<CommunityBoardCard> createState() => CommunityBoardCardState();
}

class CommunityBoardCardState extends State<CommunityBoardCard> {
  final PostService _postService = sl<PostService>();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchPosts(widget.serviceBoardType);
    AppEvents.postChanged.addListener(_onPostChangedEvent);
  }

  void _onPostChangedEvent() => refresh();

  /// 실제 데이터 갱신이 끝날 때까지 기다릴 수 있는 새로고침.
  /// 부모(CommunityBoardFragment)가 GlobalKey로 직접 호출해 완료 시점을 알 수 있음 —
  /// 예전엔 AppEvents.postChanged만 던지고 Future.delayed(고정 시간)로 대충
  /// 끝났다고 가정했음.
  Future<void> refresh() async {
    final future = _postService.fetchPosts(widget.serviceBoardType);
    if (mounted) setState(() => _postsFuture = future);
    try { await future; } catch (_) {}
  }

  @override
  void dispose() {
    AppEvents.postChanged.removeListener(_onPostChangedEvent);
    super.dispose();
  }

  Future<void> _handleWriteTap() async {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.currentUserId;
    if (userId == null) {
      context.showInfoSnackbar('no_login_info'.tr());
      return;
    }
    await Navigator.push(
      context,
      SlideRoute(
        builder: (_) => WritePost(
          title: 'write_post'.tr(),
          onSubmit: (title, content, anonymous, imageObjectKey) async {
            await _postService.createPost(
              boardType: widget.serviceBoardType,
              title: title,
              content: content,
              anonymous: anonymous,
              imageObjectKey: imageObjectKey,
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
      onRetry: refresh,
      onWriteTap: widget.showWriteButton ? _handleWriteTap : null,
    );
  }
}
