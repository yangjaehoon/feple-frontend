import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import '../../../../model/artist_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/injection.dart';
import '../../../../service/artist_service.dart';
import 'artist_page/f_artist_page.dart';

class CircleArtistWidget extends StatefulWidget {
  const CircleArtistWidget({super.key});

  @override
  State<CircleArtistWidget> createState() => _CircleArtistWidgetState();
}

class _CircleArtistWidgetState extends State<CircleArtistWidget> {
  late final Future<List<Artist>> _artistsFuture;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _artistsFuture = sl<ArtistService>().fetchArtists();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FutureBuilder<List<Artist>>(
      future: _artistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SkeletonBox(width: 72, height: 20),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: List.generate(
                      4,
                      (_) => const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SkeletonBox(
                          width: 60,
                          height: 36,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 6,
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
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'err_fetch_data'.tr(args: [snapshot.error.toString()]),
            onRetry: () => setState(() {
              _artistsFuture = sl<ArtistService>().fetchArtists();
            }),
          );
        }

        final allArtists = snapshot.data ?? [];
        final genres = allArtists.map((a) => a.genre).toSet().toList()..sort();
        final artists = _selectedGenre == null
            ? allArtists
            : allArtists.where((a) => a.genre == _selectedGenre).toList();

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'artist'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textTitle,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _GenreChip(
                      label: '전체',
                      selected: _selectedGenre == null,
                      onTap: () => setState(() => _selectedGenre = null),
                    ),
                    ...genres.map((genre) => _GenreChip(
                          label: genre,
                          selected: _selectedGenre == genre,
                          onTap: () => setState(() => _selectedGenre = genre),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: artists.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final artist = artists[index];

                  return AnimatedListItem(
                    index: index,
                    child: TapScale(
                    onTap: () {
                      Navigator.push(
                        context,
                        SlideRoute(
                          builder: (context) => ArtistPage(
                            artistName: artist.name,
                            artistId: artist.id,
                            followerCounter: artist.followerCount,
                            profileImageUrl: artist.profileImageUrl,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.cardShadow.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: 'artist_image_${artist.id}',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.0),
                                child: CachedNetworkImage(
                                  imageUrl: artist.profileImageUrl,
                                  memCacheWidth: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const SkeletonBox(height: double.infinity),
                                  errorWidget: (context, error, stack) =>
                                      Container(
                                    decoration: BoxDecoration(
                                      color: colors.activate.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: colors.activate,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artist.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textTitle,
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
            ],
          ),
        );
      },
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.activate : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.activate : colors.listDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
