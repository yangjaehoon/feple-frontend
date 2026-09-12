import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/dart/extension/num_extension.dart';
import 'package:feple/common/widget/w_share_card_parts.dart';
import 'package:flutter/material.dart';

/// 아티스트 공유용으로 캡처되는 고정 크기 카드 — 앱 테마와 무관하게 항상 같은 모습.
/// 배경에 프로필 이미지가 필요하므로 imageUrl 이 있을 때만 생성한다.
class ArtistShareCard extends StatelessWidget {
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
    return ShareCardFrame(
      imageUrl: imageUrl,
      title: artistName,
      infoRows: followerCount > 0
          ? [
              ShareCardInfoRow(
                icon: Icons.people_alt_rounded,
                text: 'follower_count'.tr(
                  args: [followerCount.toDisplayCount(context.locale.languageCode)],
                ),
              ),
            ]
          : const [],
    );
  }
}
