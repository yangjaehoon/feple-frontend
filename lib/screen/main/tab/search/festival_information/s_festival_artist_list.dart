import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_date_tab_bar.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/w_artist_card.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_artists_notifier.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/forced_refresh.dart';

class FestivalArtistListScreen extends StatefulWidget {
  final FestivalArtistsNotifier notifier;

  const FestivalArtistListScreen({super.key, required this.notifier});

  @override
  State<FestivalArtistListScreen> createState() =>
      _FestivalArtistListScreenState();
}

class _FestivalArtistListScreenState extends State<FestivalArtistListScreen> {
  FestivalArtistsNotifier get notifier => widget.notifier;

  @override
  void initState() {
    super.initState();
    notifier.addListener(_onNotifierChange);
  }

  @override
  void dispose() {
    notifier.removeListener(_onNotifierChange);
    super.dispose();
  }

  // 새로고침 실패 알림 — 예전엔 build 중에 refreshError를 읽고 clearRefreshError()로
  // notifier를 변경하던 것을 리스너 콜백으로 옮겼다.
  void _onNotifierChange() {
    if (!mounted) return;
    final err = notifier.refreshError;
    if (err == null) return;
    notifier.clearRefreshError();
    context.showErrorSnackbar(err);
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
              listenable: notifier,
              builder: (context, _) => _buildBody(context, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AbstractThemeColors colors) {
    if (notifier.isLoading) return _buildSkeleton();
    if (notifier.hasError) {
      return ErrorState.network(notifier.error!, onRetry: notifier.retry);
    }
    if (notifier.artists.isEmpty) {
      return RefreshIndicator(
        color: colors.activate,
        onRefresh: () => withForcedRefresh(notifier.refresh),
        child: _buildEmptyList(colors),
      );
    }
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: () => withForcedRefresh(notifier.refresh),
      child: _buildContent(colors),
    );
  }

  Widget _buildEmptyList(AbstractThemeColors colors) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Text(
              'no_participating_artists'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeMd,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    final displayed = notifier.displayedArtists;
    return Column(
      children: [
        if (notifier.hasDateFilter)
          DateTabBar(
            dates: notifier.allDates,
            selectedDate: notifier.selectedDate,
            onDateSelected: notifier.selectDate,
            allLabel: 'lineup_all'.tr(),
          ),
        Expanded(
          child: displayed.isEmpty
              ? Center(
                  child: Text(
                    'no_participating_artists'.tr(),
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeMd,
                      color: colors.textSecondary,
                    ),
                  ),
                )
              : GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: displayed.length,
                  itemBuilder: (context, index) {
                    final artist = displayed[index];
                    final isFollowed = notifier.isFollowed(artist.artistId);
                    return _buildArtistCard(context, index, artist, isFollowed);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArtistCard(
    BuildContext context,
    int index,
    FestivalArtistItem artist,
    bool isFollowed,
  ) {
    return AnimatedListItem(
      index: index,
      child: TapScale(
        onTap: () {
          if (ModalRoute.of(context)?.isCurrent != true) return;
          Navigator.push(
            context,
            SlideRoute(
              builder: (_) => ArtistScreen.fromFestivalArtist(artist),
            ),
          );
        },
        child: ArtistCard(
          profileImageUrl: artist.profileImageUrl,
          name: artist.displayName(context.isEnglish),
          isFollowed: isFollowed,
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, _) => const Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: SkeletonBox(
              height: double.infinity,
              borderRadius: BorderRadius.all(
                Radius.circular(AppDimens.cardRadiusTiny),
              ),
            ),
          ),
          SizedBox(height: AppDimens.space8),
          SkeletonBox(width: 60, height: 13),
        ],
      ),
    );
  }
}
