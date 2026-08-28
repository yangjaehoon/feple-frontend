import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/bounded_responsive_size.dart';
import 'package:feple/common/util/url_validator.dart';
import 'package:feple/model/song_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SongListTile extends StatelessWidget {
  final SongModel song;
  final int index;

  const SongListTile({super.key, required this.song, required this.index});

  Future<void> _open(BuildContext context) async {
    if (!isValidYoutubeUrl(song.youtubeUrl)) {
      context.showErrorSnackbar('youtube_open_failed'.tr());
      return;
    }
    final uri = Uri.parse(song.youtubeUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        context.showErrorSnackbar('youtube_open_failed'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // w_artist_songs.dart의 미리보기 영역은 스크롤 없는 Column이라
    // boundedResponsiveSize로 태블릿급 너비에서의 오버플로를 막는다.
    final thumbnailSize = boundedResponsiveSize(context, 52);
    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingHorizontal,
          vertical: 12,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space10),
            _buildThumbnail(song.thumbnailUrl, colors, thumbnailSize),
            const SizedBox(width: AppDimens.space12),
            Expanded(child: _buildInfo(colors)),
            const SizedBox(width: AppDimens.space8),
            Icon(
              Icons.open_in_new_rounded,
              size: 14,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? url, AbstractThemeColors colors, double size) {
    if (url == null) return _placeholder(colors, size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        memCacheWidth: 104,
        fit: BoxFit.cover,
        fadeInDuration: AppDimens.animXFast,
        fadeOutDuration: AppDimens.animTapFeedback,
        placeholder: (_, _) => _placeholder(colors, size),
        errorWidget: (_, _, _) => _placeholder(colors, size),
      ),
    );
  }

  Widget _buildInfo(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: FontWeight.w500,
            color: colors.textTitle,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (song.festivalCount > 0) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.activate.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
            child: Text(
              'festival_performed_count'.tr(
                args: [song.festivalCount.toString()],
              ),
              style: TextStyle(
                fontSize: AppDimens.fontSizeTiny,
                fontWeight: FontWeight.w600,
                color: colors.activate,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder(AbstractThemeColors colors, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: 18,
        color: colors.textSecondary,
      ),
    );
  }
}

/// 곡 목록 아이템 사이 구분선 — 프리뷰 카드와 전체 목록 화면에서 공용으로 사용.
/// [height]는 화면마다 다른 항목 간격을 그대로 유지하기 위한 파라미터.
class SongListDivider extends StatelessWidget {
  final double height;

  const SongListDivider({super.key, this.height = 16});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: 1,
      color: context.appColors.listDivider,
      indent: AppDimens.paddingHorizontal,
      endIndent: AppDimens.paddingHorizontal,
    );
  }
}
