import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/screen/notification/notification_type_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AbstractThemeColors colors = CustomTheme.light.appColors;

  group('NotificationTypeStyle.iconData', () {
    test('타입별 아이콘을 반환한다', () {
      expect(NotificationType.certApproved.iconData, Icons.verified_rounded);
      expect(NotificationType.certRejected.iconData, Icons.cancel_outlined);
      expect(NotificationType.newComment.iconData, Icons.chat_bubble_rounded);
      expect(NotificationType.newReply.iconData, Icons.reply_rounded);
      expect(NotificationType.postLiked.iconData, Icons.favorite_rounded);
      expect(NotificationType.postDeletedByAdmin.iconData, Icons.delete_outline_rounded);
      expect(NotificationType.festivalReminder.iconData, Icons.event_rounded);
      expect(NotificationType.newFestival.iconData, Icons.festival_rounded);
      expect(NotificationType.songRequestApproved.iconData, Icons.music_note_rounded);
      expect(NotificationType.songRequestRejected.iconData, Icons.music_off_rounded);
      expect(NotificationType.artistSuggestionProcessed.iconData, Icons.person_add_rounded);
      expect(NotificationType.adminBroadcast.iconData, Icons.campaign_rounded);
      expect(NotificationType.adminPointGranted.iconData, Icons.paid_rounded);
    });
  });

  group('NotificationTypeStyle.iconColor', () {
    test('타입별 아이콘 색상을 반환한다', () {
      expect(NotificationType.certApproved.iconColor(colors), colors.certRingColor);
      expect(NotificationType.certRejected.iconColor(colors), colors.textSecondary);
      expect(NotificationType.newComment.iconColor(colors), colors.activate);
      expect(NotificationType.newReply.iconColor(colors), colors.activate);
      expect(NotificationType.postLiked.iconColor(colors), colors.certRingColor);
      expect(NotificationType.festivalReminder.iconColor(colors), AppColors.notificationReminder);
      expect(NotificationType.newFestival.iconColor(colors), colors.certRingColor);
      expect(NotificationType.songRequestApproved.iconColor(colors), colors.certRingColor);
      expect(NotificationType.songRequestRejected.iconColor(colors), AppColors.errorRed);
      expect(NotificationType.artistSuggestionProcessed.iconColor(colors), colors.activate);
      expect(NotificationType.postDeletedByAdmin.iconColor(colors), colors.textSecondary);
      expect(NotificationType.adminBroadcast.iconColor(colors), colors.accentColor);
      expect(NotificationType.adminPointGranted.iconColor(colors), colors.certRingColor);
    });
  });
}
