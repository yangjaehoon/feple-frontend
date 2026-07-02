import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/password_validator.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/common/widget/w_nickname_field.dart';
import 'package:feple/login/s_verify_email.dart';
import 'package:feple/login/w_password_checklist.dart';
import 'package:feple/model/nickname_check_result.dart';
import 'package:feple/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  String _password = '';

  // 인라인 에러 메시지
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  // 닉네임 필드 상태 접근용 키
  final _nicknameKey = GlobalKey<NicknameFieldState>();
  bool _nicknameAvailable = false;

  bool get _isFormComplete {
    final email = emailController.text.trim();
    final password = passwordController.text;
    return _emailRegex.hasMatch(email) &&
        password.isNotEmpty &&
        PasswordValidator.validate(password) == null &&
        _nicknameAvailable;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _validateInput() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final nicknameState = _nicknameKey.currentState;
    final nickname = nicknameState?.currentNickname ?? '';

    String? emailError;
    String? passwordError;
    bool hasError = false;

    if (email.isEmpty) {
      emailError = 'enter_email'.tr();
      hasError = true;
    } else if (!_emailRegex.hasMatch(email)) {
      emailError = 'enter_valid_email'.tr();
      hasError = true;
    }
    if (password.isEmpty) {
      passwordError = 'enter_password'.tr();
      hasError = true;
    } else {
      final pwError = PasswordValidator.validate(password);
      if (pwError != null) {
        passwordError = pwError;
        hasError = true;
      }
    }
    if (nickname.isEmpty) {
      nicknameState?.showError('enter_nickname'.tr());
      hasError = true;
    } else if (nickname.length < NicknameCheckResult.minLength ||
        nickname.length > NicknameCheckResult.maxLength) {
      nicknameState?.showError('nickname_length_error'.tr());
      hasError = true;
    } else if (nicknameState?.available == null ||
        nicknameState?.lastCheckedNickname != nickname) {
      nicknameState?.showError('nickname_check_req'.tr());
      hasError = true;
    } else if (nicknameState?.available == false) {
      nicknameState?.showError('nickname_invalid'.tr());
      hasError = true;
    }

    if (hasError) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
        _generalError = null;
      });
    }
    return !hasError;
  }

  Future<void> _register() async {
    if (!_validateInput()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;
    final nickname = _nicknameKey.currentState?.currentNickname ?? '';

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.registerWithEmail(
        email, password, nickname,
      );
      if (!mounted) return;

      await Navigator.push(
        context,
        SlideRoute(
          builder: (_) => VerifyEmailScreen(email: email, deleteOnCancel: true),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = AuthService.instance.firebaseErrorMessage(e.code);
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
          case 'invalid-email':
            _emailError = msg;
            break;
          case 'weak-password':
            _passwordError = msg;
            break;
          default:
            _generalError = msg;
        }
      });
    } catch (e) {
      debugPrint('[Signup] unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _generalError = 'unknown_error'.tr();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    return Scaffold(
      backgroundColor: themeColors.backgroundMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: themeColors.textTitle, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: KeyboardDismiss(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(themeColors),
                    _buildForm(themeColors),
                    const SizedBox(height: 28),
                    if (_generalError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _generalError!,
                          style: TextStyle(
                            fontSize: AppDimens.fontSizeSm,
                            color: themeColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    AnimatedOpacity(
                      opacity: _isFormComplete ? 1.0 : 0.5,
                      duration: AppDimens.animNormal,
                      child: LoadingButton(
                        label: 'register'.tr(),
                        onPressed: _register,
                        isLoading: _isLoading,
                        backgroundColor: themeColors.activate,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLoginLink(themeColors),
                    const SizedBox(height: 32),
                    _buildSupportLink(themeColors),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors themeColors) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: themeColors.activate.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_add_rounded, size: 40, color: themeColors.activate),
        ),
        const SizedBox(height: 24),
        Text(
          'signup'.tr(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: themeColors.textTitle,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'signup_subtitle'.tr(),
          style: TextStyle(fontSize: AppDimens.fontSizeMd, color: themeColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildForm(AbstractThemeColors themeColors) {
    return Column(
      children: [
        AppTextField(
          controller: emailController,
          hintText: 'email'.tr(),
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newUsername, AutofillHints.email],
          errorText: _emailError,
          onChanged: (_) {
            setState(() { _emailError = null; _generalError = null; });
          },
        ),
        const SizedBox(height: 14),
        NicknameField(
          key: _nicknameKey,
          onStateChanged: (available) {
            setState(() => _nicknameAvailable = available == true);
          },
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: passwordController,
          hintText: 'password'.tr(),
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _passwordError,
          onChanged: (v) {
            setState(() {
              _password = v;
              if (_passwordError != null || _generalError != null) {
                _passwordError = null;
                _generalError = null;
              }
            });
          },
        ),
        if (_password.isNotEmpty) ...[
          const SizedBox(height: 10),
          PasswordChecklist(password: _password),
        ],
      ],
    );
  }

  Widget _buildSupportLink(AbstractThemeColors themeColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'login_trouble'.tr(),
          style: TextStyle(color: themeColors.textSecondary, fontSize: AppDimens.fontSizeSm),
        ),
        TextButton(
          onPressed: _openSupport,
          style: TextButton.styleFrom(
            foregroundColor: themeColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(
            'contact_support'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: themeColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSupport() async {
    final uri = Uri.parse('https://open.kakao.com/o/guLhbJki');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) context.showErrorSnackbar('link_open_failed'.tr());
  }

  Widget _buildLoginLink(AbstractThemeColors themeColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'already_have_account'.tr(),
          style: TextStyle(color: themeColors.textSecondary, fontSize: AppDimens.fontSizeMd),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: themeColors.activate,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(
            'login'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppDimens.fontSizeMd),
          ),
        ),
      ],
    );
  }
}
