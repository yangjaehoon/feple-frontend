import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/screen/notification/notification_time_style.dart';
import 'package:feple/screen/notification/notification_type_style.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;
  final bool isLoading;
  // 화면 폭에 비례한 배지 크기 계산에 쓰는 값 — 화면(리스트) 단위에서 한 번만
  // MediaQuery.sizeOf(context)로 구해 내려받는다. 스크롤로 빠르게 생성/폐기되는
  // 카드마다 MediaQuery를 직접 구독하면(이전에 시도했다가) 큰 폭 스크롤 시 위젯이
  // 생성과 동시에 폐기되며 타이머가 정리되지 않는 문제가 있었다(위젯 테스트로 확인).
  final double screenWidth;

  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.screenWidth,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TapScale(
      onTap: isLoading ? null : onTap,
      // 읽음 상태는 카드 배경/폰트굵기/점 색상 등 시각적 표시로만 전달돼
      // 스크린리더에는 노출되지 않으므로 라벨로 보강 — 본문은 카드 내부의
      // Text들이 별도로 안내되므로 여기서는 안읽음 여부만 전달
      semanticsLabel: item.read ? null : 'unread_notification'.tr(),
      child: AnimatedContainer(
        duration: AppDimens.animQuick,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _buildCardDecoration(colors),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconBadge(colors),
            const SizedBox(width: 12),
            Expanded(child: _buildTextContent(context, colors)),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.activate,
                  ),
                ),
              )
            else if (!item.read)
              _buildUnreadDot(colors),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(AbstractThemeColors colors) {
    return BoxDecoration(
      color: item.read
          ? colors.surface
          : Color.alphaBlend(
              colors.activate.withValues(alpha: 0.10),
              colors.surface,
            ),
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
      border: Border.all(
        color: item.read
            ? colors.listDivider
            : colors.activate.withValues(alpha: 0.35),
        width: 1,
      ),
      boxShadow: CardShadows.subtle(colors),
    );
  }

  // 페스티벌 알림(festivalReminder/newFestival)의 이미지는 카드/상세화면 어디서나
  // 세로 포스터(2:3)로 보여주는 것과 같은 원본이라, 40x40 정사각형으로 자르면
  // 모서리만 둥글어졌을 뿐 여전히 포스터 대부분이 잘려나간다 — 실제 포스터
  // 비율(2:3)로 표시해야 다른 화면과 시각적으로 맞고, "원형=사람(상호작용),
  // 세로 직사각형=이벤트"로 한눈에 구분된다.
  // 화면 폭에 비례하는 크기(기준 390px)로 계산 — 다른 화면 카드들과 동일한 관례.
  static const double _avatarSizeRatio = 40 / 390;
  static const double _posterWidthRatio = 40 / 390;
  static const double _posterHeightRatio = 60 / 390; // 2:3

  Widget _buildIconBadge(AbstractThemeColors colors) {
    final isFestival = item.type?.isFestivalType ?? false;
    final width = (isFestival ? _posterWidthRatio : _avatarSizeRatio) * screenWidth;
    final height = (isFestival ? _posterHeightRatio : _avatarSizeRatio) * screenWidth;
    if (item.imageUrl != null) {
      final image = CachedNetworkImage(
        imageUrl: item.imageUrl!,
        width: width,
        height: height,
        memCacheWidth: 80,
        fit: BoxFit.cover,
        fadeInDuration: AppDimens.animXFast,
        fadeOutDuration: AppDimens.animTapFeedback,
        placeholder: (_, _) => _buildIconFallback(colors, isFestival, width, height),
        errorWidget: (_, _, _) => _buildIconFallback(colors, isFestival, width, height),
      );
      return isFestival
          ? ClipRRect(borderRadius: BorderRadius.circular(AppDimens.radiusSmall), child: image)
          : ClipOval(child: image);
    }
    return _buildIconFallback(colors, isFestival, width, height);
  }

  Widget _buildIconFallback(
    AbstractThemeColors colors,
    bool isFestival,
    double width,
    double height,
  ) {
    return Container(
      key: const Key('notification_icon_badge'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (item.type?.iconColor(colors) ?? colors.certRingColor)
            .withValues(alpha: 0.15),
        shape: isFestival ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isFestival ? BorderRadius.circular(AppDimens.radiusSmall) : null,
      ),
      child: Icon(
        // 타입을 알 수 없는 알림(백엔드가 앱이 아직 모르는 새 타입을 먼저 보낸 경우)은
        // isFestivalType이 항상 false라 원형 배지로 그려진다 — 기본 아이콘도 원형과
        // 어울리는 범용 알림 아이콘으로 맞춘다(페스티벌 아이콘을 원형 안에 넣지 않음).
        item.type?.iconData ?? Icons.notifications_rounded,
        color: item.type?.iconColor(colors) ?? colors.certRingColor,
        size: 20,
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, AbstractThemeColors colors) {
    final isEnglish = context.isEnglish;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.displayTitle(isEnglish),
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.displayBody(isEnglish),
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
            color: colors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          item.relativeTimeLabel,
          style: TextStyle(
            fontSize: AppDimens.fontSizeXxs,
            color: colors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadDot(AbstractThemeColors colors) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 4, left: 8),
      decoration: BoxDecoration(
        color: colors.certRingColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
