import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:flutter/material.dart';

/// 아티스트·페스티벌·커뮤니티 게시판 카드에서 공유하는 미리보기 카드 위젯.
///
/// [future] 로 게시글을 로드하고, [headerIcon]/[headerTitle]/[headerColor]/[onHeaderTap]
/// 으로 헤더를 구성합니다. [trailingBuilder] 로 목록 아이템의 trailing을 커스터마이징하고,
/// [onPostTap] 으로 게시글 클릭 동작을 지정합니다.
///
/// [expandContent] 가 true 이면 컨텐츠가 Expanded로 감싸집니다 (고정 높이 카드용).
class BoardPreviewCard extends StatelessWidget {
  final Future<List<Post>> future;
  final IconData headerIcon;
  final String headerTitle;
  final Color headerColor;
  final VoidCallback onHeaderTap;
  final void Function(BuildContext context, Post post) onPostTap;
  final List<Widget> Function(Post post, AbstractThemeColors colors)
      trailingBuilder;
  final VoidCallback? onRetry;
  final double? height;

  const BoardPreviewCard({
    super.key,
    required this.future,
    required this.headerIcon,
    required this.headerTitle,
    required this.headerColor,
    required this.onHeaderTap,
    required this.onPostTap,
    required this.trailingBuilder,
    this.onRetry,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget content = _buildPostList(context, colors);
    if (height != null) content = Expanded(child: content);

    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingHorizontal,
          vertical: AppDimens.paddingVertical),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppDimens.cardRadius)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.12),
            blurRadius: AppDimens.cardRadius,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          BoardCardHeader(
            icon: headerIcon,
            title: headerTitle,
            headerColor: headerColor,
            onTap: onHeaderTap,
          ),
          content,
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Column(
      children: List.generate(3, (_) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingHorizontal, vertical: 10),
              child: Row(
                children: const [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 13),
                        SizedBox(height: 5),
                        SkeletonBox(width: 72, height: 10),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  SkeletonBox(width: 40, height: 13),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          ],
        );
      }),
    );
  }

  Widget _buildPostList(BuildContext context, AbstractThemeColors colors) {
    return AsyncContentBuilder<List<Post>>(
      future: future,
      useListViewForEmptyState: false,
      loadingBuilder: (_) => _buildSkeletonList(),
      onRetry: onRetry,
      emptyBuilder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.article_outlined,
                  size: 32,
                  color: colors.textSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text(
                'no_posts_yet'.tr(),
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      builder: (ctx, posts) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: posts.length,
        itemBuilder: (_, index) {
          final post = posts[index];
          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -3),
            minVerticalPadding: 0,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingHorizontal, vertical: 0),
            onTap: () => onPostTap(ctx, post),
            title: Text(
              post.title,
              style: TextStyle(
                color: colors.textTitle,
                fontWeight: FontWeight.w600,
                fontSize: AppDimens.fontSizeMd,
              ),
            ),
            subtitle: Text(
              post.nickname,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: AppDimens.fontSizeXs,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: trailingBuilder(post, colors),
            ),
          );
        },
        separatorBuilder: (_, __) => Divider(
          thickness: 1,
          color: colors.listDivider,
          indent: AppDimens.paddingHorizontal,
          endIndent: AppDimens.paddingHorizontal,
        ),
      ),
    );
  }
}
