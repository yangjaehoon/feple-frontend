import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_share_card.dart';
import 'package:flutter/material.dart';

/// 아티스트 공유용으로 캡처되는 고정 크기 카드 — 앱 테마와 무관하게 항상 같은 모습.
/// 배경에 프로필 이미지가 필요하므로 imageUrl 이 있을 때만 생성한다.
class ArtistShareCard extends StatelessWidget {
  static const double width = 360;
  static const double height = 540;

  final String artistName;
  final String imageUrl;
  final int followerCount;

  const ArtistShareCard({
    super.key,
    required this.artistName,
    required this.imageUrl,
    this.followerCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          const Positioned(top: 16, right: 16, child: FepleBrandBadge()),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  artistName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (followerCount > 0) ...[
                  const SizedBox(height: AppDimens.space10),
                  ShareCardInfoRow(
                    icon: Icons.people_alt_rounded,
                    text: 'follower_count'.tr(args: ['$followerCount']),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
