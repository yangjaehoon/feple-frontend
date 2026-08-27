import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/model/artist_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_section.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_follow_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_board.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_schedule.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_songs.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_main_image_swiper.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_related_artists.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/forced_refresh.dart';

class ArtistScreen extends StatefulWidget {
  const ArtistScreen({
    super.key,
    required this.artistName,
    this.artistNameEn = '',
    required this.artistId,
    required this.followerCount,
    this.profileImageUrl,
  });

  /// 여러 화면에서 반복되던 Artist → ArtistScreen 필드 매핑을 공용화.
  factory ArtistScreen.fromArtist(Artist artist, {Key? key}) => ArtistScreen(
        key: key,
        artistId: artist.id,
        artistName: artist.name,
        artistNameEn: artist.nameEn,
        followerCount: artist.followerCount,
        profileImageUrl: artist.profileImageUrl,
      );

  factory ArtistScreen.fromFollowedArtist(FollowedArtist artist, {Key? key}) =>
      ArtistScreen(
        key: key,
        artistId: artist.id,
        artistName: artist.name,
        artistNameEn: artist.nameEn,
        followerCount: artist.followerCount,
        profileImageUrl: artist.profileImageUrl,
      );

  /// 페스티벌 컨텍스트의 아티스트는 팔로워 수를 내려주지 않아 0으로 고정.
  factory ArtistScreen.fromFestivalArtist(FestivalArtistItem artist, {Key? key}) =>
      ArtistScreen(
        key: key,
        artistId: artist.artistId,
        artistName: artist.artistName,
        artistNameEn: artist.artistNameEn,
        followerCount: 0,
        profileImageUrl: artist.profileImageUrl,
      );

  factory ArtistScreen.fromCoArtist(CoArtistInfo artist, {Key? key}) => ArtistScreen(
        key: key,
        artistId: artist.artistId,
        artistName: artist.artistName,
        artistNameEn: artist.artistNameEn,
        followerCount: 0,
        profileImageUrl: artist.profileImageUrl,
      );

  final String artistName;
  final String artistNameEn;
  final int artistId;
  final int followerCount;
  final String? profileImageUrl;

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  late final ArtistFollowNotifier _followNotifier;
  final _swiperKey = GlobalKey<MainImageSwiperState>();
  final _scheduleKey = GlobalKey<ArtistScheduleState>();
  final _boardKey = GlobalKey<BoardPreviewSectionState>();
  final _songsKey = GlobalKey<ArtistSongsState>();
  final _relatedKey = GlobalKey<RelatedArtistsState>();

  @override
  void initState() {
    super.initState();
    _followNotifier = ArtistFollowNotifier(
      artistId: widget.artistId,
      initialFollowerCount: widget.followerCount,
    )..init();
  }

  @override
  void dispose() {
    _followNotifier.dispose();
    super.dispose();
  }

  Future<void> _shareArtist(String displayName) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: 'artist_share_text'.tr(args: [displayName])),
      );
    } catch (e) {
      debugPrint('[ArtistScreen] share error: $e');
      if (mounted) context.showErrorSnackbar('share_failed'.tr());
    }
  }

  Future<void> _onRefresh() async {
    // 각 섹션의 refresh()가 실제로 끝날 때까지 기다려야 당겨서 새로고침
    // 스피너가 화면 갱신 완료와 맞물려 사라짐 (예전엔 팔로우 상태만 기다려서
    // 다른 섹션이 아직 로딩 중인데도 스피너가 먼저 사라졌음)
    await Future.wait([
      _swiperKey.currentState?.refresh() ?? Future.value(),
      _scheduleKey.currentState?.refresh() ?? Future.value(),
      _boardKey.currentState?.refresh() ?? Future.value(),
      _songsKey.currentState?.refresh() ?? Future.value(),
      _relatedKey.currentState?.refresh() ?? Future.value(),
      _followNotifier.init(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final displayName = context.isEnglish && widget.artistNameEn.isNotEmpty
        ? widget.artistNameEn
        : widget.artistName;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(
            title: displayName,
            actions: [
              IconButton(
                tooltip: 'action_share'.tr(),
                icon: Icon(Icons.share_rounded, color: colors.appBarIconColor),
                onPressed: () => _shareArtist(displayName),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: RefreshIndicator(
                color: colors.activate,
                onRefresh: () => withForcedRefresh(_onRefresh),
                child: _buildScrollBody(displayName),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollBody(String displayName) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          MainImageSwiper(
            key: _swiperKey,
            artistName: displayName,
            artistId: widget.artistId,
            followNotifier: _followNotifier,
            profileImageUrl: (widget.profileImageUrl?.isNotEmpty ?? false) ? widget.profileImageUrl : null,
          ),
          ArtistSchedule(
            key: _scheduleKey,
            artistId: widget.artistId,
            artistName: displayName,
          ),
          ArtistBoard(
            boardKey: _boardKey,
            artistId: widget.artistId,
            artistName: displayName,
          ),
          ArtistSongs(
            key: _songsKey,
            artistId: widget.artistId,
            artistName: displayName,
          ),
          RelatedArtists(
            key: _relatedKey,
            artistId: widget.artistId,
          ),
        ],
      ),
    );
  }
}
