import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/model/artist_schedule_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/event_type_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AbstractThemeColors colors = CustomTheme.light.appColors;

  group('EventTypeStyle.config', () {
    test('팬미팅은 하트 아이콘과 핑크 색상', () {
      final config = EventType.fanMeeting.config(colors);

      expect(config.icon, Icons.favorite_rounded);
      expect(config.color, AppColors.kawaiiPink);
    });

    test('TV 출연은 TV 아이콘과 퍼플 색상', () {
      final config = EventType.tvShow.config(colors);

      expect(config.icon, Icons.tv_rounded);
      expect(config.color, AppColors.kawaiiPurple);
    });

    test('페스티벌은 음표 아이콘과 테마 활성 색상', () {
      final config = EventType.festival.config(colors);

      expect(config.icon, Icons.music_note_rounded);
      expect(config.color, colors.activate);
    });
  });
}
