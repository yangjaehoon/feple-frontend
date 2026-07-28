import 'package:feple/common/theme/color/abs_theme_colors.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/my_page/cert_status_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AbstractThemeColors colors = CustomTheme.light.appColors;

  group('CertStatusStyle.labelKey', () {
    test('승인/대기/거절 상태별 라벨 키를 반환한다', () {
      expect(CertStatus.approved.labelKey, 'cert_status_approved');
      expect(CertStatus.pending.labelKey, 'cert_status_pending');
      expect(CertStatus.rejected.labelKey, 'cert_status_rejected');
    });
  });

  group('CertStatusStyle.displayColor', () {
    test('승인은 certRingColor를 반환한다', () {
      expect(CertStatus.approved.displayColor(colors), colors.certRingColor);
    });

    test('대기는 statusPending을 반환한다', () {
      expect(CertStatus.pending.displayColor(colors), AppColors.statusPending);
    });

    test('거절은 textSecondary를 반환한다', () {
      expect(CertStatus.rejected.displayColor(colors), colors.textSecondary);
    });
  });
}
