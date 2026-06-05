import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FollowArtistsListScreen extends StatefulWidget {
  const FollowArtistsListScreen({super.key});

  @override
  State<FollowArtistsListScreen> createState() => _FollowArtistsListScreenState();
}

class _FollowArtistsListScreenState extends State<FollowArtistsListScreen> {
  List<FollowedArtist> _artists = [];
  bool _loading = true;
  bool _hasError = false;
  int? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<UserProvider>().currentUserId;
    if (uid != null && uid != _userId) {
      _userId = uid;
      _load();
    }
  }

  Future<void> _load() async {
    if (_userId == null) return;
    setState(() { _loading = true; _hasError = false; });
    try {
      final list = await sl<UserService>().fetchFollowingArtists(_userId!);
      if (mounted) setState(() { _artists = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Widget _buildScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: constraints.maxHeight, child: Center(child: child)),
      ),
    );
  }

  Widget _buildAppBar(AbstractThemeColors colors) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.backgroundMain,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textTitle),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                'follow_artists'.tr(),
                style: TextStyle(
                  color: colors.textTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => Divider(height: 1, color: colors.listDivider),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: const [
            SkeletonBox(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 100, height: 15),
                  SizedBox(height: 6),
                  SkeletonBox(width: 60, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return RefreshIndicator(
      onRefresh: _load,
      color: colors.activate,
      child: _loading
          ? _buildSkeleton(colors)
          : _hasError
              ? _buildScrollable(
                  ErrorState(
                    message: 'err_fetch_data'.tr(),
                    onRetry: _load,
                  ),
                )
              : _artists.isEmpty
                  ? _buildScrollable(
                      EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'no_followed_artists'.tr(),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _artists.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: colors.listDivider),
                      itemBuilder: (_, i) =>
                          _ArtistRow(artist: _artists[i], colors: colors),
                    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          _buildAppBar(colors),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }
}

class _ArtistRow extends StatelessWidget {
  final FollowedArtist artist;
  final AbstractThemeColors colors;

  const _ArtistRow({required this.artist, required this.colors});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => ArtistPage(
            artistId: artist.id,
            artistName: artist.name,
            followerCounter: artist.followerCount,
            profileImageUrl: artist.profileImageUrl,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: (artist.profileImageUrl != null &&
                        artist.profileImageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: artist.profileImageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: colors.backgroundMain,
                        child: Icon(Icons.person_rounded,
                            size: 26, color: colors.textSecondary),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                artist.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textTitle,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

