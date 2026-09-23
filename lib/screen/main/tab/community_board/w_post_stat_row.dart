import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/constant/app_dimensions.dart';

/// 게시글 목록 타일 trailing용 읽기 전용 통계 행.
///
/// [scrapCount] 가 non-null 이면 별 아이콘을 하트와 댓글 사이에 표시한다.
/// [compact] — true(기본): 작은 사이즈(마이페이지 타일용), false: 큰 사이즈
class PostStatRow extends StatelessWidget {
  final int likeCount;
  final int commentCount;
  final int? scrapCount;
  final bool compact;

  const PostStatRow({
    super.key,
    required this.likeCount,
    required this.commentCount,
    this.scrapCount,
    this.compact = true,
  });

  // AppDimens의 iconSize* 는 이 행의 아이콘 크기와 맞는 값이 없어 여기서만 쓰는
  // 상수로 둔다. 하트·별은 같은 크기, 댓글 아이콘만 1px 작다(외곽선 두께 차이 보정).
  static const _iconSizeCompact = 16.0;
  static const _iconSizeLarge = 18.0;
  static const _commentIconSizeCompact = 15.0;
  static const _commentIconSizeLarge = 16.0;

  double get _heartSize => compact ? _iconSizeCompact : _iconSizeLarge;
  double get _starSize => compact ? _iconSizeCompact : _iconSizeLarge;
  double get _commentSize =>
      compact ? _commentIconSizeCompact : _commentIconSizeLarge;
  double get _fontSize =>
      compact ? AppDimens.fontSizeSm : AppDimens.fontSizeMd;
  FontWeight get _fontWeight => compact ? FontWeight.normal : FontWeight.w600;
  double get _spacing => compact ? AppDimens.space8 : AppDimens.space10;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final lang = context.locale.languageCode;
    final textStyle = TextStyle(
      fontSize: _fontSize,
      color: colors.textTitle,
      fontWeight: _fontWeight,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite_border_rounded,
            color: colors.likeActiveColor, size: _heartSize),
        const SizedBox(width: AppDimens.space4),
        Text(likeCount.toDisplayCount(lang), style: textStyle),
        if (scrapCount != null) ...[
          SizedBox(width: _spacing),
          Icon(Icons.star_border_rounded,
              color: colors.accentColor, size: _starSize),
          const SizedBox(width: AppDimens.space4),
          Text(scrapCount!.toDisplayCount(lang), style: textStyle),
        ],
        SizedBox(width: _spacing),
        Icon(Icons.chat_bubble_outline_rounded,
            color: colors.textSecondary, size: _commentSize),
        const SizedBox(width: AppDimens.space4),
        Text(commentCount.toDisplayCount(lang), style: textStyle),
      ],
    );
  }
}
