import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_setlist_entry.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_predicted_setlist_badge.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_setlist_artist_avatar.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/future_refreshable.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_setlist_fullscreen.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/material.dart';

class FestivalSetlist extends StatefulWidget {
  final int festivalId;

  const FestivalSetlist({super.key, required this.festivalId});

  @override
  State<FestivalSetlist> createState() => FestivalSetlistState();
}

class FestivalSetlistState extends State<FestivalSetlist>
    with FutureRefreshable<List<FestivalSetlistEntry>, FestivalSetlist> {
  @override
  Future<List<FestivalSetlistEntry>> fetchData() =>
      sl<FestivalDetailService>().fetchSetlist(widget.festivalId);

  Future<void> _openFullPage() async {
    await Navigator.push<void>(
      context,
      SlideRoute(
        builder: (_) =>
            FestivalSetlistFullscreenScreen(festivalId: widget.festivalId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildHeader(colors), _buildContent(colors)],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: AppDimens.iconSizeMd,
            color: colors.activate,
          ),
          const SizedBox(width: 8),
          Text(
            'setlist_card_title'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeLg,
              fontWeight: FontWeight.w700,
              color: colors.textTitle,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _openFullPage,
            style: TextButton.styleFrom(
              foregroundColor: colors.activate,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              'view_all'.tr(),
              style: const TextStyle(
                fontSize: AppDimens.fontSizeXs,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    return AsyncContentBuilder<List<FestivalSetlistEntry>>(
      future: future,
      loadingBuilder: (_) => _buildSkeleton(),
      errorBuilder: (error) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ErrorState.network(
          error ?? Exception('unknown'),
          onRetry: refresh,
        ),
      ),
      emptyBuilder: (_) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EmptyState(
          icon: Icons.queue_music_rounded,
          title: 'no_setlist'.tr(),
        ),
      ),
      useListViewForEmptyState: false,
      builder: (_, entries) => _buildList(entries, colors),
    );
  }

  static const int _maxVisible = 5;

  Widget _buildList(
    List<FestivalSetlistEntry> entries,
    AbstractThemeColors colors,
  ) {
    final hasMore = entries.length > _maxVisible;
    final visible = hasMore ? entries.sublist(0, _maxVisible) : entries;
    return Column(
      children: [
        ...visible.asMap().entries.map((e) {
          final index = e.key;
          final entry = e.value;
          final isLast = index == visible.length - 1 && !hasMore;
          return _ArtistCompactRow(entry: entry, isLast: isLast);
        }),
        if (hasMore) _buildMoreButton(colors),
      ],
    );
  }

  Widget _buildMoreButton(AbstractThemeColors colors) {
    return InkWell(
      onTap: _openFullPage,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'see_more'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeSm,
                fontWeight: FontWeight.w600,
                color: colors.activate,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colors.activate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const SkeletonBox(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(height: 13, width: 100),
                    const SizedBox(height: 6),
                    SkeletonBox(height: 11, width: double.infinity),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ArtistCompactRow extends StatelessWidget {
  final FestivalSetlistEntry entry;
  final bool isLast;

  const _ArtistCompactRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final topSong = entry.songs.isNotEmpty ? entry.songs.first : null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SetlistArtistAvatar(profileImageUrl: entry.profileImageUrl, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextColumn(topSong, context.isEnglish, colors),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            thickness: 1,
            color: colors.listDivider,
            indent: 16,
            endIndent: 16,
            height: 1,
          ),
      ],
    );
  }

  Widget _buildTextColumn(
    SongModel? topSong,
    bool isEnglish,
    AbstractThemeColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                entry.displayName(isEnglish),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: colors.textTitle,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.predicted) ...[
              const SizedBox(width: 6),
              const PredictedSetlistBadge(),
            ],
          ],
        ),
        const SizedBox(height: 3),
        if (topSong != null)
          _buildTopSongRow(topSong, colors)
        else
          Text(
            'no_setlist'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: colors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildTopSongRow(SongModel topSong, AbstractThemeColors colors) {
    return Row(
      children: [
        if (topSong.thumbnailUrl != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: CachedNetworkImage(
                imageUrl: topSong.thumbnailUrl!,
                width: 20,
                height: 20,
                memCacheWidth: 40,
                fit: BoxFit.cover,
                fadeInDuration: AppDimens.animXFast,
                fadeOutDuration: AppDimens.animTapFeedback,
                placeholder: (_, _) => const SizedBox.shrink(),
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        Expanded(
          child: Text(
            topSong.title,
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (entry.songs.length > 1)
          Text(
            ' +${entry.songs.length - 1}',
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: colors.activate,
            ),
          ),
      ],
    );
  }
}
