import 'package:feple/common/common.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/auth_service.dart';
import 'package:feple/service/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;

  /// true: 신규 가입 계정 — 취소 시 Firebase 계정 삭제
  /// false: 기존 미인증 계정 — 취소 시 signOut만
  final bool deleteOnCancel;

  const VerifyEmailPage({
    super.key,
    required this.email,
    this.deleteOnCancel = false,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  static const _resendCooldownSecs = 60;
  static const _pollIntervalSecs = 3;

  Timer? _resendTimer;
  Timer? _pollTimer;
  int _cooldown = 0;
  bool _isVerifying = false;
  bool _isCanceling = false;
  String? _errorMessage;

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
    // setUser 전에 스택 정리 — LoginPage→SignupPage→VerifyEmailPage가 쌓인 상태에서
    // setUser만 호출하면 Consumer가 home을 교체해도 위 라우트들이 남아 화면이 안 바뀜
    final userProvider = context.read<UserProvider>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    await userProvider.setUser(user);
    FcmService.instance.init().catchError((e) => debugPrint('[FCM] init failed: $e'));
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final busy = _isVerifying || _isCanceling;
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
                Text(
                  'verify_email_sent_to'.tr(args: [widget.email]),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'verify_email_instruction'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                LoadingButton(
                  label: 'verify_email_done_btn'.tr(),
                  onPressed: busy ? null : _onVerifyTapped,
                  isLoading: _isVerifying,
                  backgroundColor: colors.activate,
                ),
                const SizedBox(height: 12),
                _buildResendButton(colors, busy),
                const SizedBox(height: 28),
                TextButton(
                  onPressed: busy ? null : _onCancelTapped,
                  child: _isCanceling
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textSecondary,
                          ),
                        )
                      : Text(
                          'verify_email_cancel'.tr(),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
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
      child: Icon(
        Icons.mark_email_unread_rounded,
        size: 44,
        color: colors.activate,
      ),
    );
  }

  Widget _buildResendButton(AbstractThemeColors colors, bool busy) {
    final canResend = _cooldown <= 0 && !busy;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        _cooldown > 0
            ? 'verify_email_resend_wait'.tr(args: [_cooldown.toString()])
            : 'verify_email_resend'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }
}
