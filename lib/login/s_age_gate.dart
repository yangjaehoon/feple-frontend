import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_icon_circle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 나이 확인 게이트 — 첫 로그인 직후 커뮤니티 진입 전에 생년월일을 1회 입력받는다.
/// 만 14세 이상이면 [onVerified]를 호출해 다음 단계(온보딩/홈)로 넘어가고,
/// 미만이면 서버가 계정을 파기하며 되돌아갈 수 없는 안내 화면으로 전환된다.
/// (Apple App Store 심사 가이드라인 5.1.1 대응)
class AgeGateScreen extends StatefulWidget {
  final VoidCallback onVerified;

  const AgeGateScreen({super.key, required this.onVerified});

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  DateTime? _birthDate;
  bool _loading = false;
  bool _restricted = false;
  String? _error;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // 초기값은 임계(만 14세)와 무관한 중립적 지점으로 둔다 — 특정 나이를 유도하지 않기 위함.
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'age_gate_picker_help'.tr(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _error = null;
      });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}. ${d.month.toString().padLeft(2, '0')}. ${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    final birthDate = _birthDate;
    if (birthDate == null || _loading) return;

    // 잘못 고른 날짜로 만 14세 미만이 되면 계정이 영구 차단되므로, 제출 전 한 번 확인한다.
    final confirmed = await showConfirmDialog(
      context,
      title: 'age_gate_confirm_title'.tr(),
      content: 'age_gate_confirm_content'.tr(args: [_formatDate(birthDate)]),
      confirmLabel: 'age_gate_confirm_ok'.tr(),
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.submitBirthDate(birthDate);
      if (mounted) widget.onVerified();
    } on AgeRestrictedException {
      if (mounted) setState(() => _restricted = true);
    } catch (e) {
      debugPrint('[AgeGate] submit failed: $e');
      if (mounted) setState(() => _error = 'age_gate_error'.tr());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exitAfterRestriction() async {
    // 계정은 서버에서 이미 파기됨 — 로컬 세션만 정리하고 게스트 화면으로 돌아간다.
    await context.read<UserProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.backgroundMain,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: _restricted
                  ? _RestrictedView(onConfirm: _exitAfterRestriction)
                  : _buildForm(colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AbstractThemeColors colors) {
    final rs = ResponsiveSize(context);
    final birthDate = _birthDate;
    return Column(
      children: [
        const IconCircle(icon: Icons.cake_outlined, sizeAt390: 76),
        SizedBox(height: rs.h(20)),
        Text(
          'age_gate_title'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppDimens.fontSizeDisplay,
            fontWeight: FontWeight.w800,
            color: colors.textTitle,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: rs.h(10)),
        Text(
          'age_gate_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            color: colors.textSecondary,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: rs.h(28)),
        InkWell(
          onTap: _loading ? null : _pickDate,
          borderRadius: BorderRadius.circular(AppDimens.shapeButton),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppDimens.shapeButton),
              border: Border.all(color: colors.actionBtnSecondaryBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 20, color: colors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  birthDate == null
                      ? 'age_gate_select_date'.tr()
                      : _formatDate(birthDate),
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: birthDate == null
                        ? colors.hintText
                        : colors.textTitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          SizedBox(height: rs.h(12)),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              color: colors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        SizedBox(height: rs.h(24)),
        AnimatedOpacity(
          opacity: birthDate == null ? 0.5 : 1.0,
          duration: AppDimens.animNormal,
          child: LoadingButton(
            label: 'age_gate_submit'.tr(),
            onPressed: _submit,
            isLoading: _loading,
            backgroundColor: colors.activate,
          ),
        ),
      ],
    );
  }
}

class _RestrictedView extends StatelessWidget {
  final Future<void> Function() onConfirm;

  const _RestrictedView({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rs = ResponsiveSize(context);
    return Column(
      children: [
        const IconCircle(icon: Icons.lock_outline_rounded, sizeAt390: 76),
        SizedBox(height: rs.h(20)),
        Text(
          'age_gate_restricted_title'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppDimens.fontSizeDisplay,
            fontWeight: FontWeight.w800,
            color: colors.textTitle,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: rs.h(10)),
        Text(
          'age_gate_restricted_message'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            color: colors.textSecondary,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: rs.h(28)),
        LoadingButton(
          label: 'confirm'.tr(),
          onPressed: onConfirm,
          backgroundColor: colors.activate,
        ),
      ],
    );
  }
}
