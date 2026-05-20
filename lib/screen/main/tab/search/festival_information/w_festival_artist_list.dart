import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_circle_image.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/festival_service.dart';
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
                  return Center(
                    child: CircularProgressIndicator(color: colors.activate),
                  );
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
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _notifier.artists.length,
                  itemBuilder: (context, index) {
                    final artist = _notifier.artists[index];
                    final isFollowed =
                        _notifier.followedIds.contains(artist.artistId);
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              color: isFollowed
                                  ? AppColors.skyBlue
                                  : colors.textTitle,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
}
