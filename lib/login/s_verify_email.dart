import 'package:feple/common/common.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/auth_service.dart';
import 'package:feple/service/fcm_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  /// true: 신규 가입 계정 — 취소 시 Firebase 계정 삭제
  /// false: 기존 미인증 계정 — 취소 시 signOut만
  final bool deleteOnCancel;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.deleteOnCancel = false,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendCooldownSecs = 60;
  static const _pollIntervalSecs = 3;

  Timer? _resendTimer;
  Timer? _pollTimer;
  int _cooldown = 0;
  bool _isVerifying = false;
  bool _isCanceling = false;
  bool _isChangingEmail = false;
  String? _errorMessage;

  bool get _busy => _isVerifying || _isCanceling || _isChangingEmail;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
    _startPolling();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() => _cooldown = _resendCooldownSecs);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) t.cancel();
      });
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: _pollIntervalSecs), (_) async {
      await _tryComplete(silent: true);
    });
  }

  Future<void> _tryComplete({bool silent = false}) async {
    try {
      final user = await AuthService.instance.completeVerifiedLogin();
      if (user == null) return;
      _pollTimer?.cancel();
      if (!mounted) return;
      await _navigateToApp(user);
    } catch (e) {
      debugPrint('[VerifyEmail] completeVerifiedLogin 실패: $e');
      if (!silent && mounted) {
        setState(() => _errorMessage = 'verify_email_not_yet'.tr());
      }
    }
  }

  Future<void> _onVerifyTapped() async {
    setState(() { _isVerifying = true; _errorMessage = null; });
    try {
      final user = await AuthService.instance.completeVerifiedLogin();
      if (!mounted) return;
      if (user == null) {
        setState(() => _errorMessage = 'verify_email_not_yet'.tr());
      } else {
        _pollTimer?.cancel();
        await _navigateToApp(user);
      }
    } catch (e) {
      debugPrint('[VerifyEmail] 인증 확인 실패: $e');
      if (mounted) setState(() => _errorMessage = 'verify_email_not_yet'.tr());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _navigateToApp(dynamic user) async {
    // setUser 전에 스택 정리 — LoginScreen→SignupScreen→VerifyEmailScreen가 쌓인 상태에서
    // setUser만 호출하면 Consumer가 home을 교체해도 위 라우트들이 남아 화면이 안 바뀜
    final userProvider = context.read<UserProvider>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    await userProvider.setUser(user);
    FcmService.instance.initWithRationale().catchError((e) => debugPrint('[FCM] init failed: $e'));
  }

  Future<void> _onResendTapped() async {
    try {
      await AuthService.instance.resendVerificationEmail();
      _startResendCooldown();
      if (mounted) context.showSuccessSnackbar('verification_email_resent'.tr());
    } catch (e) {
      debugPrint('[VerifyEmail] 재발송 실패: $e');
      if (mounted) context.showErrorSnackbar('unknown_error'.tr());
    }
  }

  Future<void> _onCancelTapped() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'verify_email_cancel_title'.tr(),
      content: 'verify_email_cancel_content'.tr(),
      confirmLabel: 'verify_email_cancel_confirm'.tr(),
    );
    if (!confirmed || !mounted) return;
    setState(() => _isCanceling = true);
    try {
      if (widget.deleteOnCancel) {
        await AuthService.instance.cancelUnverifiedSignup();
      } else {
        await AuthService.instance.signOut();
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('[VerifyEmail] 취소 처리 실패: $e');
    } finally {
      if (mounted) setState(() => _isCanceling = false);
    }
  }

  // 이메일 오타 시: 계정 삭제 후 회원가입 화면으로 복귀 (확인 없이 바로 진행)
  Future<void> _onChangeEmailTapped() async {
    setState(() => _isChangingEmail = true);
    try {
      if (widget.deleteOnCancel) {
        await AuthService.instance.cancelUnverifiedSignup();
      } else {
        await AuthService.instance.signOut();
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('[VerifyEmail] 이메일 변경 처리 실패: $e');
    } finally {
      if (mounted) setState(() => _isChangingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIcon(colors),
                const SizedBox(height: 28),
                _buildTextSection(colors),
                const SizedBox(height: 40),
                if (_errorMessage != null) _buildError(colors),
                LoadingButton(
                  label: 'verify_email_done_btn'.tr(),
                  onPressed: _busy ? null : _onVerifyTapped,
                  isLoading: _isVerifying,
                  backgroundColor: colors.activate,
                ),
                const SizedBox(height: 12),
                _buildResendButton(colors),
                const SizedBox(height: 28),
                if (widget.deleteOnCancel) _buildChangeEmailRow(colors),
                _buildCancelButton(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextSection(AbstractThemeColors colors) {
    return Column(
      children: [
        Text(
          'verify_email_title'.tr(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colors.textTitle,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _buildEmailHighlighted(colors),
        const SizedBox(height: 6),
        Text(
          'verify_email_instruction'.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
            color: colors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 이메일 주소를 bold + textTitle 색상으로 강조
  Widget _buildEmailHighlighted(AbstractThemeColors colors) {
    final translated = 'verify_email_sent_to'.tr(args: [widget.email]);
    final emailIdx = translated.indexOf(widget.email);
    final baseStyle = TextStyle(
      fontSize: AppDimens.fontSizeMd,
      color: colors.textSecondary,
      fontWeight: FontWeight.w500,
      height: 1.6,
    );

    if (emailIdx == -1) {
      return Text(translated, style: baseStyle, textAlign: TextAlign.center);
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: translated.substring(0, emailIdx)),
          TextSpan(
            text: widget.email,
            style: TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
          ),
          TextSpan(text: translated.substring(emailIdx + widget.email.length)),
        ],
      ),
    );
  }

  Widget _buildError(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        _errorMessage!,
        style: TextStyle(
          fontSize: AppDimens.fontSizeSm,
          color: colors.error,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildIcon(AbstractThemeColors colors) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: colors.activate.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.mark_email_unread_rounded, size: 44, color: colors.activate),
    );
  }

  Widget _buildResendButton(AbstractThemeColors colors) {
    final canResend = _cooldown <= 0 && !_busy;
    return OutlinedButton(
      onPressed: canResend ? _onResendTapped : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.activate,
        disabledForegroundColor: colors.textSecondary.withValues(alpha: 0.5),
        side: BorderSide(
          color: canResend
              ? colors.activate
              : colors.textSecondary.withValues(alpha: 0.3),
        ),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
      ),
      child: Text(
        _cooldown > 0
            ? 'verify_email_resend_wait'.tr(args: [_cooldown.toString()])
            : 'verify_email_resend'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppDimens.fontSizeLg),
      ),
    );
  }

  Widget _buildChangeEmailRow(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'verify_email_wrong_email'.tr(),
            style: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeMd),
          ),
          _buildTextLoadingButton(
            label: 'verify_email_change_email'.tr(),
            onPressed: _busy ? null : _onChangeEmailTapped,
            isLoading: _isChangingEmail,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(AbstractThemeColors colors) {
    return _buildTextLoadingButton(
      label: 'verify_email_cancel'.tr(),
      onPressed: _busy ? null : _onCancelTapped,
      isLoading: _isCanceling,
      colors: colors,
    );
  }

  Widget _buildTextLoadingButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    required AbstractThemeColors colors,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.textSecondary),
            )
          : Text(label, style: TextStyle(fontSize: AppDimens.fontSizeMd)),
    );
  }
}
