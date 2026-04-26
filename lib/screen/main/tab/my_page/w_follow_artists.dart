import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';

class FollowArtistsWidget extends StatefulWidget {
  final int userId;
  const FollowArtistsWidget({super.key, required this.userId});

  @override
  State<FollowArtistsWidget> createState() => _FollowArtistsWidgetState();
}

class _FollowArtistsWidgetState extends State<FollowArtistsWidget> {
  List<_FollowedArtist> _artists = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final data = await UserService().fetchFollowing(widget.userId);
      final list = data.map((e) => _FollowedArtist.fromJson(e)).toList();
      if (mounted) setState(() { _artists = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.sectionBarColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'follow_artists'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: _loading
              ? _buildSkeleton()
              : _hasError
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 28,
                              color: colors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text('retry'.tr(),
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    )
                  : _artists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_search_rounded,
                                  size: 32,
                                  color: colors.textSecondary.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              Text('no_followed_artists'.tr(),
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _artists.length,
                          itemBuilder: (context, index) {
                            final artist = _artists[index];
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.followRingColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.cardShadow
                                              .withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colors.surface),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: colors.backgroundMain,
                                        backgroundImage: (artist.profileImageUrl !=
                                                    null &&
                                                artist.profileImageUrl!.isNotEmpty)
                                            ? CachedNetworkImageProvider(
                                                artist.profileImageUrl!)
                                            : null,
                                        child: (artist.profileImageUrl == null ||
                                                artist.profileImageUrl!.isEmpty)
                                            ? Icon(Icons.person_rounded,
                                                size: 40,
                                                color: colors.textSecondary)
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      artist.name,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textTitle),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: const [
            SkeletonBox(
              width: 106,
              height: 106,
              borderRadius: BorderRadius.all(Radius.circular(53)),
            ),
            SizedBox(height: 8),
            SkeletonBox(width: 60, height: 11),
          ],
        ),
      ),
    );
  }
}

class _FollowedArtist {
  final int id;
  final String name;
  final String? profileImageUrl;

  const _FollowedArtist(
      {required this.id, required this.name, this.profileImageUrl});

  factory _FollowedArtist.fromJson(Map<String, dynamic> json) {
    return _FollowedArtist(
      id: json['id'] as int,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
