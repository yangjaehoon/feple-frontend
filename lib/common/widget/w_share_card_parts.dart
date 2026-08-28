import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 공유 카드(페스티벌/아티스트)의 캡처 고정 크기 — 두 카드가 동일하게 사용한다.
const double shareCardWidth = 360;
const double shareCardHeight = 540;

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
