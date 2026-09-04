import 'package:feple/common/common.dart';
import 'package:feple/model/poster_cert_state.dart';
import 'package:feple/model/ticket_link.dart';
import 'package:feple/screen/main/tab/search/festival_information/festival_poster_style.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_action_button.dart';
import 'package:flutter/material.dart';

/// 페스티벌 포스터 아래 액션 버튼 줄: 좋아요 / 공유 / 날씨 / 캘린더 / 인증 / (예매).
class FestivalActionButtonsRow extends StatelessWidget {
  final bool liked;
  final bool isSharing;
  final PosterCertState certState;
  final List<TicketLink> ticketLinks;
  final VoidCallback onToggleLike;
  final VoidCallback onShare;
  final VoidCallback onWeather;
  final VoidCallback onCalendar;
  final VoidCallback onTicketLinks;

  /// 인증 미완료 상태에서 인증 버튼을 눌렀을 때 (인증 제출 시트).
  final VoidCallback onSubmitCert;

  const FestivalActionButtonsRow({
    super.key,
    required this.liked,
    required this.isSharing,
    required this.certState,
    required this.ticketLinks,
    required this.onToggleLike,
    required this.onShare,
    required this.onWeather,
    required this.onCalendar,
    required this.onTicketLinks,
    required this.onSubmitCert,
  });

  VoidCallback _certTap(BuildContext context) => switch (certState) {
        PosterCertState.certified => () =>
            context.showInfoSnackbar('cert_already_approved'.tr()),
        PosterCertState.pending => () =>
            context.showInfoSnackbar('cert_pending_notice'.tr()),
        PosterCertState.none => onSubmitCert,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: FestivalActionButton(
            onTap: onToggleLike,
            icon: liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: liked ? colors.likeActiveColor : Colors.white,
            bgColor: liked
                ? colors.likeActiveColor.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.15),
            label: 'action_like'.tr(),
          ),
        ),
        Expanded(
          child: FestivalActionButton(
            onTap: onShare,
            icon: Icons.share_outlined,
            label: 'action_share'.tr(),
            isLoading: isSharing,
          ),
        ),
        Expanded(
          child: FestivalActionButton(
            onTap: onWeather,
            icon: Icons.cloud_outlined,
            label: 'action_weather'.tr(),
          ),
        ),
        Expanded(
          child: FestivalActionButton(
            onTap: onCalendar,
            icon: Icons.event_available_rounded,
            label: 'action_calendar'.tr(),
          ),
        ),
        Expanded(
          child: FestivalActionButton(
            onTap: _certTap(context),
            icon: certState.icon,
            color: certState.color(colors),
            bgColor: certState.bgColor(colors),
            label: 'action_cert'.tr(),
          ),
        ),
        if (ticketLinks.isNotEmpty)
          Expanded(
            child: FestivalActionButton(
              onTap: onTicketLinks,
              icon: Icons.confirmation_number_outlined,
              label: 'action_ticket'.tr(),
            ),
          ),
      ],
    );
  }
}
