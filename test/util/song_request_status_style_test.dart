import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/model/song_request_model.dart';
import 'package:feple/screen/main/tab/my_page/song_request_status_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AbstractThemeColors colors = CustomTheme.light.appColors;

  group('SongRequestStatusStyle.labelKey', () {
    test('대기/승인/거절 상태별 라벨 키를 반환한다', () {
      expect(SongRequestStatus.pending.labelKey, 'song_status_pending');
      expect(SongRequestStatus.approved.labelKey, 'song_status_approved');
      expect(SongRequestStatus.rejected.labelKey, 'song_status_rejected');
    });
  });

  group('SongRequestStatusStyle.displayColor', () {
    test('대기는 textSecondary를 반환한다', () {
      expect(SongRequestStatus.pending.displayColor(colors), colors.textSecondary);
    });

    test('승인은 activate를 반환한다', () {
      expect(SongRequestStatus.approved.displayColor(colors), colors.activate);
    });

    test('거절은 errorRed를 반환한다', () {
      expect(SongRequestStatus.rejected.displayColor(colors), AppColors.errorRed);
    });
  });
}
