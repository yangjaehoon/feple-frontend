import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FestivalArtistListScreen extends StatefulWidget {
  final int festivalId;

  const FestivalArtistListScreen({super.key, required this.festivalId});

  @override
  State<FestivalArtistListScreen> createState() =>
      _FestivalArtistListScreenState();
}

class _FestivalArtistListScreenState extends State<FestivalArtistListScreen> {
  late final FestivalArtistsNotifier _notifier;

  @override
  void initState() {
    super.initState();
    final userId = context.read<UserProvider>().currentUserId;
    _notifier = FestivalArtistsNotifier(
      festivalId: widget.festivalId,
      userId: userId,
      festivalService: sl<FestivalDetailService>(),
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
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: 'participating_artists'.tr()),
          Expanded(
            child: ListenableBuilder(
              listenable: _notifier,
              builder: (context, _) {
                if (_notifier.isLoading) {
                  return _buildSkeleton();
                }
                if (_notifier.artists.isEmpty) {
                  return Center(
                    child: Text(
                      'no_participating_artists'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _notifier.artists.length,
                  itemBuilder: (context, index) {
                    final artist = _notifier.artists[index];
                    final isFollowed = _notifier.isFollowed(artist.artistId);
                    return AnimatedListItem(
                      index: index,
                      child: TapScale(
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
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  border: isFollowed
                                      ? Border.all(
                                          color: colors.activate,
                                          width: 2.5,
                                        )
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.cardShadow
                                          .withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      isFollowed ? 17.5 : 20.0),
                                  child: artist.profileImageUrl != null &&
                                          artist.profileImageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: artist.profileImageUrl!,
                                          memCacheWidth: 200,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) =>
                                              const SkeletonBox(
                                                  height: double.infinity),
                                          errorWidget: (_, __, ___) =>
                                              _placeholderBox(colors),
                                        )
                                      : _placeholderBox(colors),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              artist.artistName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isFollowed
                                    ? colors.activate
                                    : colors.textTitle,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBox(AbstractThemeColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.activate.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.person_rounded,
        color: colors.activate,
        size: 40,
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, __) => Column(
        children: const [
          Expanded(
            child: SkeletonBox(
              height: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          SizedBox(height: 8),
          SkeletonBox(width: 60, height: 13),
        ],
      ),
    );
  }
}
