import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_post_list.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

/// 아티스트 페이지에 삽입되는 게시판 미리보기 카드
class ArtistBoard extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistBoard({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistBoard> createState() => _ArtistBoardState();
}

class _ArtistBoardState extends State<ArtistBoard> {
  final PostService _postService = sl<PostService>();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchArtistPosts(widget.artistId);
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
            icon: Icons.forum_rounded,
            title: 'name_board'.tr(args: [widget.artistName]),
            headerColor: colors.activate,
            onTap: () {
              Navigator.push(
                context,
                SlideRoute(
                  builder: (_) => ArtistPostListScreen(
                    artistId: widget.artistId,
                    artistName: widget.artistName,
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

  Widget _buildPostList(AbstractThemeColors colors) {
    return FutureBuilder<List<Post>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonList();
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ErrorState(
              message: 'err_fetch_data'.tr(args: ['']),
              onRetry: () => setState(() {
                _postsFuture = _postService.fetchArtistPosts(widget.artistId);
              }),
            ),
          );
        }

        final postDataList = snapshot.data ?? [];
        if (postDataList.isEmpty) {
          return Padding(
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
                  const Icon(Icons.favorite_border_rounded,
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
