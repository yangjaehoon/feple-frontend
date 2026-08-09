import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 셋리스트 아티스트 행(간략/전체 화면 공용)에서 반복되던 원형 아바타.
/// 이미지가 없거나 로드 실패 시 사람 아이콘 폴백을 보여준다.
class SetlistArtistAvatar extends StatelessWidget {
  final String? profileImageUrl;
  final double size;

  const SetlistArtistAvatar({
    super.key,
    required this.profileImageUrl,
    required this.size,
  });

  Widget _placeholder(AbstractThemeColors colors) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.55,
        color: colors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = profileImageUrl;
    if (url == null || url.isEmpty) return _placeholder(colors);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        memCacheWidth: (size * 2).round(),
        fit: BoxFit.cover,
        fadeInDuration: AppDimens.animXFast,
        fadeOutDuration: AppDimens.animTapFeedback,
        placeholder: (_, _) => _placeholder(colors),
        errorWidget: (_, _, _) => _placeholder(colors),
      ),
    );
  }
}
