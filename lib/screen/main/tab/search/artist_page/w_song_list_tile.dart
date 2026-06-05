import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/song_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SongListTile extends StatelessWidget {
  final SongModel song;
  final int index;

  const SongListTile({super.key, required this.song, required this.index});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(song.youtubeUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) context.showErrorSnackbar('youtube_open_failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
            const SizedBox(width: 10),
            _buildThumbnail(song.thumbnailUrl, colors),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(colors)),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded, size: 14, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? url, AbstractThemeColors colors) {
    if (url == null) return _placeholder(colors);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _placeholder(colors),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'festival_performed_count'.tr(args: [song.festivalCount.toString()]),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.activate,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder(AbstractThemeColors colors) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      ),
      child: Icon(Icons.music_note_rounded, size: 18, color: colors.textSecondary),
    );
  }
}
