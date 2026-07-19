import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/email_validator.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/common/widget/w_icon_circle.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isSending = false;
  bool _sent = false;
  String? _emailError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final email = _emailController.text.trim();
    final emailError = EmailValidator.validate(email);
    if (emailError != null) {
      setState(() => _emailError = emailError);
      return;
    }
    setState(() { _emailError = null; _errorMessage = null; _isSending = true; });
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // user-not-found를 별도 처리하면 "다음 화면으로 넘어가는지"가 그 자체로
      // 계정 존재 여부를 노출하는 신호가 됨(계정 목록 탐지) — 가입된 이메일과
      // 동일하게 전송 완료 화면으로 넘긴다. invalid-email은 형식 오류일 뿐
      // 계정 존재 여부와 무관하므로 그대로 필드 에러로 표시
      if (e.code == 'user-not-found') {
        setState(() => _sent = true);
        return;
      }
      final msg = AuthService.instance.firebaseErrorMessage(e.code);
      setState(() {
        if (e.code == 'invalid-email') {
          _emailError = msg;
        } else {
          _errorMessage = msg;
        }
      });
    } catch (e) {
      debugPrint('[ForgotPw] 예외: $e');
      if (mounted) setState(() => _errorMessage = 'unknown_error'.tr());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textTitle, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: KeyboardDismiss(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _sent ? _buildSentState(colors) : _buildInputState(colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputState(AbstractThemeColors colors) {
    return AutofillGroup(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const IconCircle(icon: Icons.lock_reset_rounded),
          const SizedBox(height: 28),
          Text(
            'reset_password'.tr(),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'reset_password_subtitle'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          AppTextField(
            controller: _emailController,
            hintText: 'registered_email'.tr(),
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onSend(),
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null || _errorMessage != null) {
                setState(() { _emailError = null; _errorMessage = null; });
              }
            },
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: colors.error, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeXs,
                        color: colors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          LoadingButton(
            label: 'send'.tr(),
            onPressed: _isSending ? null : _onSend,
            isLoading: _isSending,
            backgroundColor: colors.activate,
          ),
        ],
      ),
    );
  }

  Widget _buildSentState(AbstractThemeColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const IconCircle(icon: Icons.mark_email_read_rounded),
        const SizedBox(height: 28),
        Text(
          'password_reset_sent_title'.tr(),
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
          'password_reset_sent_desc'.tr(args: [_emailController.text.trim()]),
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        LoadingButton(
          label: 'go_to_login'.tr(),
          onPressed: () => Navigator.pop(context),
          isLoading: false,
          backgroundColor: colors.activate,
        ),
      ],
    );
  }

}
