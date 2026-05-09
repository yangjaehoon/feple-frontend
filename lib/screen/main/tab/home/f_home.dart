import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/home/home_state_notifier.dart';
import 'package:feple/screen/main/tab/home/w_boards_section_skeleton.dart';
import 'package:feple/screen/main/tab/home/w_favorite_boards_section.dart';
import 'package:feple/screen/main/tab/home/w_home_artists_section.dart';
import 'package:feple/screen/main/tab/home/w_home_festivals_section.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/app_events.dart';
import '../../../../provider/user_provider.dart';

class HomeFragment extends StatefulWidget {
  const HomeFragment({super.key});

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
  final _notifier = HomeStateNotifier();

  @override
  void initState() {
    super.initState();
    AppEvents.likeChanged.addListener(_onLikeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>().user;
    if (user != null && _notifier.userId != user.id) {
      _notifier.init(user.id);
    }
  }

  @override
  void dispose() {
    AppEvents.likeChanged.removeListener(_onLikeChanged);
    _notifier.dispose();
    super.dispose();
  }

  void _onLikeChanged() => _notifier.refresh();

  void _openArtistOrderSettings() {
    final artists = _notifier.artists;
    if (artists == null || artists.isEmpty) return;
    final items = _notifier
        .applyOrder(artists, _notifier.artistOrder, (a) => a.id)
        .map((a) =>
            ReorderItem(id: a.id, name: a.name, imageUrl: a.profileImageUrl))
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReorderSheet(
        title: 'followed_artists'.tr(),
        items: items,
        onSave: _notifier.saveArtistOrder,
      ),
    );
  }

  void _openFestivalOrderSettings() {
    final festivals = _notifier.festivals;
    if (festivals == null || festivals.isEmpty) return;
    final items = _notifier
        .applyOrder(festivals, _notifier.festivalOrder, (f) => f.id)
        .map((f) =>
            ReorderItem(id: f.id, name: f.title, imageUrl: f.posterUrl))
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReorderSheet(
        title: 'liked_festivals'.tr(),
        items: items,
        onSave: _notifier.saveFestivalOrder,
      ),
    );
  }

  List<FollowedArtist>? get _orderedArtists {
    final artists = _notifier.artists;
    return artists == null
        ? null
        : _notifier.applyOrder(artists, _notifier.artistOrder, (x) => x.id);
  }

  List<FestivalModel>? get _orderedFestivals {
    final festivals = _notifier.festivals;
    return festivals == null
        ? null
        : _notifier.applyOrder(festivals, _notifier.festivalOrder, (x) => x.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        if (_notifier.userId == null) {
          return Container(
            color: colors.backgroundMain,
            child: Center(
                child: CircularProgressIndicator(
                    color: colors.loadingIndicator)),
          );
        }

        return Container(
          color: colors.backgroundMain,
          child: Stack(
            children: [
              RefreshIndicator(
                color: colors.activate,
                onRefresh: () async => _notifier.refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: AppDimens.scrollPaddingTop,
                    bottom: AppDimens.scrollPaddingBottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeSectionHeader(
                        title: 'followed_artists'.tr(),
                        onSettings: _notifier.artists != null &&
                                _notifier.artists!.isNotEmpty
                            ? _openArtistOrderSettings
                            : null,
                      ),
                      HomeArtistsSection(
                        artists: _orderedArtists,
                        onTap: (artist) => Navigator.push(
                          context,
                          SlideRoute(
                            builder: (_) => ArtistPage(
                              artistId: artist.id,
                              artistName: artist.name,
                              followerCounter: 0,
                            ),
                          ),
                        ).then((_) => _notifier.refresh()),
                      ),
                      const SizedBox(height: 8),
                      HomeSectionHeader(
                        title: 'liked_festivals'.tr(),
                        onSettings: _notifier.festivals != null &&
                                _notifier.festivals!.isNotEmpty
                            ? _openFestivalOrderSettings
                            : null,
                      ),
                      HomeFestivalsSection(
                        festivals: _orderedFestivals,
                        onTap: (festival) => Navigator.push(
                          context,
                          SlideRoute(
                            builder: (_) => FestivalInformationFragment(
                                poster: festival),
                          ),
                        ).then((_) => _notifier.refresh()),
                      ),
                      const SizedBox(height: 8),
                      if (_notifier.boards == null)
                        const BoardsSectionSkeleton()
                      else
                        FavoriteBoardsSection(
                          allBoards: _notifier.boards!,
                          userId: _notifier.userId!,
                        ),
                    ],
                  ),
                ),
              ),
              const FepleAppBar("Feple"),
            ],
          ),
        );
      },
    );
  }
}
