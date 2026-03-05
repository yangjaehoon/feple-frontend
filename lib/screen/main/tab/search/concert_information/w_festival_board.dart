import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/common/util/responsive_size.dart';
import 'package:fast_app_base/model/post_model.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/w_festival_post_list.dart';
import 'package:fast_app_base/service/post_service.dart';
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
    final rs = ResponsiveSize(context);
    return Container(
      width: double.infinity,
      height: rs.h(AppDimens.boardCardHeight),
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
            title: '${widget.festivalName} 게시판',
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
          Expanded(child: _buildPostList(colors)),
        ],
      ),
    );
  }

  Widget _buildPostList(AbstractThemeColors colors) {
    return FutureBuilder<List<Post>>(
      future: _postsFuture,
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

        final postDataList = snapshot.data ?? [];
        if (postDataList.isEmpty) {
          return Center(
            child: Text('아직 게시글이 없습니다.',
                style: TextStyle(color: colors.textSecondary)),
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
                      color: colors.activate,
                      size: AppDimens.iconSizeLg),
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
                      color: colors.activate,
                      size: AppDimens.iconSizeMd),
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
