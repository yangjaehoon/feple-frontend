import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/screen/notification/notification_time_style.dart';
import 'package:feple/screen/notification/notification_type_style.dart';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;
  final bool isLoading;

  const NotificationCard({
    super.key,
    required this.item,
    required this.onTap,
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

  // 스와이프 삭제 시 카드 자체 테두리/그림자가 드래그 중간 지점에 뾰족한
  // 모서리로 떠 보이는 것을 막기 위해 border/shadow 없이 배경색+radius만 적용
  // (바깥 고정 프레임은 s_notification.dart의 ClipRRect가 담당)
  BoxDecoration _buildCardDecoration(AbstractThemeColors colors) {
    return BoxDecoration(
      color: item.read
          ? colors.surface
          : Color.alphaBlend(
              colors.activate.withValues(alpha: 0.10),
              colors.surface,
            ),
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
    );
  }

  Widget _buildIconBadge(AbstractThemeColors colors) {
    if (item.imageUrl != null) {
      return ClipOval(
        child: Image.network(
          item.imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, _) => _buildIconFallback(colors),
        ),
      );
    }
    return _buildIconFallback(colors);
  }

  Widget _buildIconFallback(AbstractThemeColors colors) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (item.type?.iconColor(colors) ?? colors.certRingColor)
            .withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        item.type?.iconData ?? Icons.festival_rounded,
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
