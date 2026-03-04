import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:flutter/material.dart';

class FollowArtistsWidget extends StatefulWidget {
  final int userId;
  const FollowArtistsWidget({super.key, required this.userId});

  @override
  State<FollowArtistsWidget> createState() => _FollowArtistsWidgetState();
}

class _FollowArtistsWidgetState extends State<FollowArtistsWidget> {
  late Future<List<_FollowedArtist>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchFollowing();
  }

  Future<List<_FollowedArtist>> _fetchFollowing() async {
    final resp = await DioClient.dio.get('/users/${widget.userId}/following');
    return (resp.data as List).map((e) => _FollowedArtist.fromJson(e)).toList();
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
                width: 3, height: 20,
                decoration: BoxDecoration(
                  color: colors.sectionBarColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '팔로우 아티스트 ',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: colors.textTitle,
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<List<_FollowedArtist>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator(color: colors.loadingIndicator)),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text('팔로우한 아티스트가 없습니다.', style: TextStyle(color: colors.textSecondary)),
              );
            }
            final artists = snapshot.data!;
            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];
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
                                color: colors.cardShadow.withOpacity(0.2),
                                blurRadius: 8, offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: colors.backgroundMain,
                              backgroundImage: (artist.profileImageUrl != null && artist.profileImageUrl!.isNotEmpty)
                                  ? NetworkImage(artist.profileImageUrl!)
                                  : null,
                              child: (artist.profileImageUrl == null || artist.profileImageUrl!.isEmpty)
                                  ? Icon(Icons.person_rounded, size: 40, color: colors.textSecondary)
                                  : null,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            artist.name,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTitle),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FollowedArtist {
  final int id;
  final String name;
  final String? profileImageUrl;

  const _FollowedArtist({required this.id, required this.name, this.profileImageUrl});

  factory _FollowedArtist.fromJson(Map<String, dynamic> json) {
    return _FollowedArtist(
      id: json['id'] as int,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
