import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_auth_header_text.dart';
import 'package:feple/common/widget/w_icon_circle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/model/auth_flow_result.dart';
import 'package:feple/service/auth_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  /// true: 신규 가입 계정 — 취소 시 Firebase 계정 삭제
  /// false: 기존 미인증 계정 — 취소 시 signOut만
  final bool deleteOnCancel;

  /// 이 화면에 오기 전에 인증 메일이 실제로 발송됐는지. false면 "보냈습니다"
  /// 대신 발송 실패를 알리고 재발송을 안내한다 — 발송에 실패해도 이 화면까지는
  /// 와야 쿨다운 뒤 재발송·인증 완료 확인을 할 수 있다.
  final bool verificationEmailSent;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.deleteOnCancel = false,
    this.verificationEmailSent = true,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendCooldownSecs = 60;
  // 인증 완료 폴링 간격(초) — 점점 늘려 마지막은 30초. 상한 이후로는 마지막 값 유지.
  static const _pollBackoffSecs = [3, 5, 8, 12, 20, 30];
  // 이 시간이 지나면 폴링을 멈춘다 — 사용자는 하단 "인증 완료 확인" 버튼으로 확인.
  static const _maxPollDuration = Duration(minutes: 5);

  Timer? _resendTimer;
  Timer? _pollTimer;
  int _pollAttempt = 0;
  DateTime? _pollStartedAt;
  bool _completed = false;
  int _cooldown = 0;
  bool _isVerifying = false;
  bool _isCanceling = false;
  bool _isChangingEmail = false;
  bool _isResending = false;
  /// 재발송이 성공하면 뒤집힌다 — 그때부터는 "보냈습니다" 문구가 맞다.
  late bool _emailSent;
  // 폴링과 수동 "인증 완료 확인" 탭이 동시에 completeVerifiedLogin()을 호출하면
  // /auth/firebase 토큰 교환이 두 번 일어남 — 백엔드는 유저당 리프레시 토큰을
  // 1개만 유지하므로 두 응답 중 나중에 TokenStore에 저장되는 쪽이 서버가 이미
  // 무효화한 토큰일 수 있어 로그인 직후 세션이 깨질 수 있음. 이미 진행 중인 확인이
  // 있으면 새로 호출하지 않고 이 Future에 편승(await)해 같은 결과를 공유한다 —
  // 수동 탭이 폴링과 겹쳐도 조용히 무시되지 않고 로딩 표시 후 실제 결과를 반영한다.
  Future<void>? _inFlightCheck;
  String? _errorMessage;

  bool get _busy => _isVerifying || _isCanceling || _isChangingEmail || _isResending;

  @override
  void initState() {
    super.initState();
    _emailSent = widget.verificationEmailSent;
    if (_emailSent) {
      _startResendCooldown();
    } else {
      // 나간 메일이 없으니 쿨다운으로 잠그지 않는다 — 안내가 가리키는 재발송
      // 버튼이 60초간 비활성이면 복구할 방법이 없다.
      _errorMessage = 'verify_email_send_failed_hint'.tr();
    }
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
    _pollAttempt = 0;
    _pollStartedAt = DateTime.now();
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    if (!mounted || _completed) return;
    if (DateTime.now().difference(_pollStartedAt!) >= _maxPollDuration) return;
    final secs = _pollBackoffSecs[
        _pollAttempt.clamp(0, _pollBackoffSecs.length - 1)];
    _pollTimer = Timer(Duration(seconds: secs), () async {
      _pollAttempt++;
      await _tryComplete(silent: true);
      if (mounted) _scheduleNextPoll();
    });
  }

  Future<void> _tryComplete({bool silent = false}) async {
    // 이미 폴링 틱이 진행 중일 때 온 또 다른 폴링 틱은 기존 동작대로 건너뛴다.
    if (_inFlightCheck != null) {
      if (silent) return;
      await _awaitSharedCheck(_inFlightCheck!);
      return;
    }

    if (!silent) setState(() { _isVerifying = true; _errorMessage = null; });
    final check = _completeVerification(silent: silent);
    _inFlightCheck = check;
    try {
      await check;
    } finally {
      _inFlightCheck = null;
      if (!silent && mounted) setState(() => _isVerifying = false);
    }
  }

  /// 수동 탭이 진행 중인 폴링과 겹친 경우 — 새로 호출하지 않고 그 결과를 기다렸다가
  /// 그대로 반영한다(조용히 무시되지 않도록).
  Future<void> _awaitSharedCheck(Future<void> shared) async {
    setState(() { _isVerifying = true; _errorMessage = null; });
    await shared;
    if (!mounted) return;
    if (!_completed) _showNotYetVerified();
    setState(() => _isVerifying = false);
  }

  Future<void> _completeVerification({required bool silent}) async {
    try {
      final user = await AuthService.instance.completeVerifiedLogin();
      if (!mounted) return;
      if (user == null) {
        if (!silent) _showNotYetVerified();
        return;
      }
      _completed = true;
      _pollTimer?.cancel();
      _returnResult(AuthFlowResult.verified(user));
    } catch (e) {
      debugPrint('[VerifyEmail] completeVerifiedLogin 실패: $e');
      if (!silent && mounted) _showNotYetVerified();
    }
  }

  void _showNotYetVerified() => setState(() => _errorMessage = 'verify_email_not_yet'.tr());

  Future<void> _onVerifyTapped() => _tryComplete(silent: false);

  /// 결과를 push한 쪽에 넘기고 이 화면만 닫는다. setUser·스택 정리를 여기서
  /// 직접 하지 않는 이유는 [AuthFlowResult] 주석 참고.
  ///
  /// 폴링이 백그라운드에서 인증 완료를 감지하는 시점에 취소 확인 다이얼로그가
  /// 떠 있을 수 있어, 최상단이 아니라 **이 화면**을 닫아야 한다.
  void _returnResult(AuthFlowResult result) =>
      popRouteWithResult(context, result);

  Future<void> _onResendTapped() async {
    setState(() => _isResending = true);
    try {
      await AuthService.instance.resendVerificationEmail();
      if (!mounted) return;
      _startResendCooldown();
      setState(() { _emailSent = true; _errorMessage = null; });
      context.showSuccessSnackbar('verification_email_resent'.tr());
    } catch (e) {
      debugPrint('[VerifyEmail] 재발송 실패: $e');
      if (mounted) context.showErrorSnackbar('unknown_error'.tr());
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // deleteOnCancel(신규 가입 계정)이면 Firebase 계정 삭제, 아니면 signOut만
  Future<void> _deleteAccountOrSignOut() async {
    if (widget.deleteOnCancel) {
      await AuthService.instance.cancelUnverifiedSignup();
    } else {
      await AuthService.instance.signOut();
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
      await _deleteAccountOrSignOut();
      // 계정을 지웠거나 로그아웃했으니 인증 흐름은 여기서 끝 — 가입 폼으로
      // 돌아갈 이유가 없으므로, 중간 화면까지 함께 닫히도록 결과를 넘긴다.
      if (mounted) _returnResult(const AuthFlowResult.aborted());
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
      await _deleteAccountOrSignOut();
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
    // 세로 간격은 화면 높이에 비례(기준 iPhone 14, 844pt) — 고정값으로 한 기기에만
    // 맞추지 않도록.
    final rs = ResponsiveSize(context);
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // 계정을 지우지 않고 그냥 이전 화면(가입 폼)으로 돌아가는 안전한 경로 —
        // "취소"/"이메일 변경"은 계정을 삭제하는 반면, 이 버튼은 나중에 다시
        // 인증을 완료할 수 있도록 미인증 계정을 그대로 둔다.
        leading: IconButton(
          tooltip: 'back'.tr(),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: colors.textTitle,
            size: 20,
          ),
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: rs.h(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const IconCircle(icon: Icons.mark_email_unread_rounded),
                SizedBox(height: rs.h(20)),
                _buildTextSection(colors),
                SizedBox(height: rs.h(28)),
                if (_errorMessage != null) _buildError(colors),
                LoadingButton(
                  label: 'verify_email_done_btn'.tr(),
                  onPressed: _busy ? null : _onVerifyTapped,
                  isLoading: _isVerifying,
                  backgroundColor: colors.activate,
                ),
                SizedBox(height: rs.h(10)),
                _buildResendButton(colors),
                SizedBox(height: rs.h(20)),
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
    final rs = ResponsiveSize(context);
    return Column(
      children: [
        AuthTitleText('verify_email_title'.tr(), textAlign: TextAlign.center),
        SizedBox(height: rs.h(10)),
        _buildEmailHighlighted(colors),
        // 발송 실패 상태에서는 "메일의 링크를 클릭하라"는 안내가 거짓이 된다 —
        // 그때 할 일은 _errorMessage의 재발송 안내가 담당한다.
        if (_emailSent) ...[
          SizedBox(height: rs.h(6)),
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
      ],
    );
  }

  // 이메일 주소를 bold + textTitle 색상으로 강조
  Widget _buildEmailHighlighted(AbstractThemeColors colors) {
    final translated = (_emailSent ? 'verify_email_sent_to' : 'verify_email_send_failed_to')
        .tr(args: [widget.email]);
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
