import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 공유 카드(페스티벌/아티스트)의 캡처 고정 크기 — 두 카드가 동일하게 사용한다.
const double shareCardWidth = 360;
const double shareCardHeight = 540;

/// 공유 카드(페스티벌/아티스트)의 공통 프레임 — 배경 이미지, 어두운 그라디언트,
/// 우상단 [FepleBrandBadge], 좌하단 타이틀+정보 행. 카드별로 다른 부분(좌상단
/// 배지, 타이틀 텍스트, 정보 행 목록)만 파라미터로 받는다.
class ShareCardFrame extends StatelessWidget {
  final String imageUrl;
  final String title;
  final Widget? topLeft;
  final List<Widget> infoRows;

  const ShareCardFrame({
    super.key,
    required this.imageUrl,
    required this.title,
    this.topLeft,
    this.infoRows = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: shareCardWidth,
      height: shareCardHeight,
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
          if (topLeft != null) Positioned(top: 16, left: 16, child: topLeft!),
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
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                ..._buildInfoRows(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoRows() {
    if (infoRows.isEmpty) return [];
    return [
      const SizedBox(height: AppDimens.space10),
      for (var i = 0; i < infoRows.length; i++) ...[
        if (i > 0) const SizedBox(height: AppDimens.space4),
        infoRows[i],
      ],
    ];
  }
}

/// 공유 카드 우상단에 올라가는 FEPLE 브랜드 배지.
/// 어두운 반투명 pill 위에 흰색 핀 로고 + 'FEPLE' 텍스트.
class FepleBrandBadge extends StatelessWidget {
  const FepleBrandBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 흰색 핀 로고(투명 배경) — 어두운 배지 위에서 선명하게 보인다.
          Image.asset(
            'assets/image/feple_clear_960.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            cacheWidth: 60,
          ),
          const SizedBox(width: AppDimens.space4),
          const Text(
            'FEPLE',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// 공유 카드 하단의 아이콘 + 한 줄 텍스트 (흰색, 어두운 그라디언트 위).
class ShareCardInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const ShareCardInfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: AppDimens.space6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
