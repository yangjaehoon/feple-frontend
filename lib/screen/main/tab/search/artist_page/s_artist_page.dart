import 'package:feple/common/common.dart';
import 'package:feple/common/constant/store_links.dart';
import 'package:feple/common/util/share_helper.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/model/festival_artist_item.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_follow_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_board.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_share_card.dart';
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
  bool _isSharing = false;
  final _refresh = RefreshCoordinator();

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

  // 아티스트 이름 + 프로필 이미지를 합성한 카드와 앱 링크를 함께 공유한다.
  // 프로필 이미지가 없거나 카드 생성이 실패하면 텍스트+링크만으로 공유된다.
  Future<void> _shareArtist(String displayName) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    final text = '${'artist_share_text'.tr(args: [displayName])}\n$kAppDownloadUrl';
    final imageUrl = widget.profileImageUrl;
    try {
      final ok = await shareContent(
        context,
        text: text,
        cardToCapture: (imageUrl != null && imageUrl.isNotEmpty)
            ? ArtistShareCard(
                artistName: displayName,
                imageUrl: imageUrl,
                followerCount: _followNotifier.followCount,
              )
            : null,
        precacheImageUrl: imageUrl,
        captureFileName: 'feple_artist.png',
        logTag: 'ArtistScreen',
      );
      if (!ok && mounted) context.showErrorSnackbar('share_failed'.tr());
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _onRefresh() async {
    // 모든 섹션 + 팔로우 상태가 실제로 끝날 때까지 기다려야 당겨서 새로고침
    // 스피너가 화면 갱신 완료와 맞물려 사라진다.
    await Future.wait([
      _refresh.refreshAll(),
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
                icon: _isSharing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.appBarIconColor,
                        ),
                      )
                    : Icon(Icons.share_rounded, color: colors.appBarIconColor),
                onPressed: _isSharing ? null : () => _shareArtist(displayName),
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
      child: RefreshScope(
        coordinator: _refresh,
        child: Column(
          children: [
            MainImageSwiper(
              artistName: displayName,
              artistId: widget.artistId,
              followNotifier: _followNotifier,
              profileImageUrl: (widget.profileImageUrl?.isNotEmpty ?? false) ? widget.profileImageUrl : null,
            ),
            ArtistSchedule(
              artistId: widget.artistId,
              artistName: displayName,
            ),
            ArtistBoard(
              artistId: widget.artistId,
              artistName: displayName,
            ),
            ArtistSongs(
              artistId: widget.artistId,
              artistName: displayName,
            ),
            RelatedArtists(
              artistId: widget.artistId,
            ),
          ],
        ),
      ),
    );
  }
}
