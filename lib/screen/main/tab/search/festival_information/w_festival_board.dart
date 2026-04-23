import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_post_list.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:flutter/material.dart';

/// 페스티벌 상세 페이지에 삽입되는 게시판 미리보기 카드
class FestivalBoard extends StatefulWidget {
  final int festivalId;
  final String festivalName;

  const FestivalBoard({
    super.key,
    required this.festivalId,
    required this.festivalName,
  });

  @override
  State<FestivalBoard> createState() => _FestivalBoardState();
}

class _FestivalBoardState extends State<FestivalBoard> {
  final PostService _postService = PostService();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchFestivalPosts(widget.festivalId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
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
            icon: Icons.festival_rounded,
            title: 'name_board'.tr(args: [widget.festivalName]),
            headerColor: colors.activate,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FestivalPostListScreen(
                    festivalId: widget.festivalId,
                    festivalName: widget.festivalName,
                  ),
                ),
              );
            },
          ),
          _buildPostList(colors),
        ],
      ),
    );
  }

  Widget _buildPostList(AbstractThemeColors colors) {
    return AsyncContentBuilder<List<Post>>(
      future: _postsFuture,
      useListViewForEmptyState: false,
      builder: (context, postDataList) {
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
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingHorizontal, vertical: 0),
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
                children: [
                  Icon(Icons.favorite_border_rounded,
                      color: colors.activate, size: AppDimens.iconSizeLg),
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
