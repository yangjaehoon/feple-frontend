import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/model/post_model.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';
import 'package:fast_app_base/service/post_service.dart';
import 'package:flutter/material.dart';

/// 게시판 미리보기 카드 — 3개 게시판(인기/자유/동행)이 공유하는 공용 위젯
class CommunityBoardCard extends StatefulWidget {
  /// 헤더에 표시할 제목
  final String title;

  /// 헤더 앞 아이콘
  final IconData icon;

  /// 헤더 배경색 (context.appColors에서 가져옴)
  final Color Function(AbstractThemeColors) headerColorFn;

  /// PostService에 넘길 boardType (예: 'HotBoard')
  final String serviceBoardType;

  /// CommunityPost 페이지에 넘길 boardname (예: 'HotBoard')
  final String boardname;

  const CommunityBoardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.headerColorFn,
    required this.serviceBoardType,
    required this.boardname,
  });

  @override
  State<CommunityBoardCard> createState() => _CommunityBoardCardState();
}

class _CommunityBoardCardState extends State<CommunityBoardCard> {
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      height: AppDimens.boardCardHeight,
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingHorizontal, vertical: AppDimens.paddingVertical),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppDimens.cardRadius)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withOpacity(0.12),
            blurRadius: AppDimens.cardRadius,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          _buildHeader(context, colors),
          // ── Post list ──
          Expanded(child: _buildPostList(colors)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AbstractThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingHorizontal, vertical: 10),
      width: double.infinity,
      height: AppDimens.boardHeaderHeight,
      decoration: BoxDecoration(
        color: widget.headerColorFn(colors),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimens.cardRadius),
          topRight: Radius.circular(AppDimens.cardRadius),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityPost(boardname: widget.boardname),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: Colors.white, size: AppDimens.iconSizeLg),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: AppDimens.fontSizeLg,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Row(
              children: [
                Text(
                  "더보기",
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeSm,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: AppDimens.iconSizeSm),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostList(AbstractThemeColors colors) {
    return FutureBuilder<List<dynamic>>(
      future: _postService.fetchPosts(widget.serviceBoardType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colors.loadingIndicator),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load data: ${snapshot.error}',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          );
        }

        final postDataList = snapshot.data!;
        if (postDataList.isEmpty) {
          return Center(
            child: Text(
              'No data available.',
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: postDataList.length,
          itemBuilder: (_, index) {
            final Post post = postDataList[index];
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -3),
              minVerticalPadding: 0,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppDimens.paddingHorizontal, vertical: 0),
              title: Text(
                post.title,
                style: TextStyle(
                  color: colors.textTitle,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                post.nickname,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      color: AppColors.kawaiiPink, size: AppDimens.iconSizeLg),
                  const SizedBox(width: 4),
                  Text(
                    post.likeCount.toString(),
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeMd,
                      color: colors.textTitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chat_bubble_outline_rounded,
                      color: colors.activate, size: AppDimens.iconSizeMd),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => Divider(
            thickness: 1,
            color: colors.listDivider,
            indent: AppDimens.paddingHorizontal,
            endIndent: AppDimens.paddingHorizontal,
          ),
        );
      },
    );
  }
}
