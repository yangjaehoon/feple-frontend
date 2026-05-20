import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_circle_image.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_artist_list.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FestivalArtists extends StatefulWidget {
  final int festivalId;

  const FestivalArtists({super.key, required this.festivalId});

  @override
  State<FestivalArtists> createState() => _FestivalArtistsState();
}

class _FestivalArtistsState extends State<FestivalArtists> {
  late final FestivalArtistsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    final userId = context.read<UserProvider>().user?.id;
    _notifier = FestivalArtistsNotifier(
      festivalId: widget.festivalId,
      userId: userId,
      festivalService: sl<FestivalService>(),
      followService: sl<ArtistFollowService>(),
    );
    _notifier.fetch();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: AppDimens.paddingVertical,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppDimens.cardRadius)),
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
          _buildHeader(colors),
          _buildArtistListArea(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return BoardCardHeader(
      icon: Icons.music_note_rounded,
      title: 'participating_artists'.tr(),
      headerColor: colors.activate,
      onTap: () => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => FestivalArtistListScreen(
            festivalId: widget.festivalId,
          ),
        ),
      ),
    );
  }

  Widget _buildArtistListArea(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: 12,
      ),
      child: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) {
          if (_notifier.isLoading || _notifier.artists.isEmpty) {
            return _buildPlaceholderRow(colors);
          }
          return _buildArtistRow(colors);
        },
      ),
    );
  }

  Widget _buildArtistRow(AbstractThemeColors colors) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _notifier.artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final artist = _notifier.artists[index];
          final isFollowed = _notifier.followedIds.contains(artist.artistId);
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              SlideRoute(
                builder: (_) => ArtistPage(
                  artistId: artist.artistId,
                  artistName: artist.artistName,
                  followerCounter: 0,
                ),
              ),
            ),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  ArtistCircleImage(
                    imageUrl: artist.profileImageUrl,
                    isFollowed: isFollowed,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isFollowed ? colors.activate : colors.textTitle,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderRow(AbstractThemeColors colors) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.activate.withValues(alpha: 0.08),
                  border: Border.all(
                    color: colors.activate.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: colors.activate.withValues(alpha: 0.4),
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.activate.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
