import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/login/s_signup.dart';
import 'package:feple/login/s_verify_email.dart';
import 'package:feple/login/w_forgot_password_dialog.dart';
import 'package:feple/service/auth_service.dart';
import 'package:feple/service/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isEmailLoading = false;
  bool _isKakaoLoading = false;
  bool _isNavigating = false;
  String? _emailError;
  String? _passwordError;   // 빈 필드 → 빨간 테두리
  String? _authError;       // 인증 실패 → 텍스트만, 테두리 없음

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    return Scaffold(
      backgroundColor: themeColors.backgroundMain,
      body: KeyboardDismiss(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(themeColors),
                  _buildForm(themeColors),
                  const SizedBox(height: 24),
                  IgnorePointer(
                    ignoring: _isEmailLoading || _isKakaoLoading,
                    child: Opacity(
                      opacity: _isKakaoLoading ? 0.5 : 1.0,
                      child: LoadingButton(
                        label: 'login'.tr(),
                        onPressed: _loginWithEmail,
                        isLoading: _isEmailLoading,
                        backgroundColor: themeColors.activate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildKakaoLoginButton(),
                  const SizedBox(height: 28),
                  _buildLinks(context, themeColors),
                ],
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
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          child: Image.asset(
            'assets/image/login/feple_logo.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'welcome'.tr(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: themeColors.textTitle,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'login_subtitle'.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeLg,
            color: themeColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),
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
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: 14),
        AppTextField(
          controller: passwordController,
          hintText: 'password'.tr(),
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null || _authError != null) {
              setState(() { _passwordError = null; _authError = null; });
            }
          },
        ),
        if (_authError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: themeColors.error, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _authError!,
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeXs,
                      color: themeColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLinks(BuildContext context, AbstractThemeColors themeColors) {
    return Column(
      children: [
        TextButton(
          onPressed: _showForgotPasswordDialog,
          style: TextButton.styleFrom(
            foregroundColor: themeColors.activate,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(
            'forgot_password'.tr(),
            style: const TextStyle(fontSize: AppDimens.fontSizeMd, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'not_member_yet'.tr(),
              style: TextStyle(color: themeColors.textSecondary, fontSize: AppDimens.fontSizeMd),
            ),
            TextButton(
              onPressed: () {
                if (_isNavigating) return;
                _isNavigating = true;
                Navigator.push(context, SlideRoute(builder: (_) => const SignupPage()))
                    .whenComplete(() { if (mounted) _isNavigating = false; });
              },
              style: TextButton.styleFrom(
                foregroundColor: themeColors.activate,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(
                'signup'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppDimens.fontSizeMd),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // _buildTextField 제거됨 → AppTextField 공통 위젯 사용

  Widget _buildKakaoLoginButton() {
    return IgnorePointer(
      ignoring: _isEmailLoading || _isKakaoLoading,
      child: Opacity(
        opacity: _isEmailLoading ? 0.5 : 1.0,
        child: LoadingButton(
          isLoading: _isKakaoLoading,
          backgroundColor: AppColors.kakaoYellow,
          foregroundColor: const Color(0xFF3C1E1E),
          onPressed: signInWithKakao,
          label: 'kakao_login_btn'.tr(),
        ),
      ),
    );
  }

  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
    _authError = null;
  }

  Future<void> _handleLoginSuccess(dynamic user) async {
    if (!mounted) return;
    await context.read<UserProvider>().setUser(user);
    FcmService.instance.initWithRationale().catchError((e) => debugPrint('[FCM] init failed: $e'));
  }

  Future<void> _loginWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    final emailErr = email.isEmpty ? 'enter_email'.tr() : null;
    final passwordErr = password.isEmpty ? 'enter_password'.tr() : null;
    if (emailErr != null || passwordErr != null) {
      setState(() { _emailError = emailErr; _passwordError = passwordErr; });
      return;
    }

    setState(() { _isEmailLoading = true; _clearErrors(); });
    try {
      final user = await AuthService.instance.loginWithEmail(email, password);
      await _handleLoginSuccess(user);
    } on EmailNotVerifiedException {
      if (!mounted) return;
      await Navigator.push(
        context,
        SlideRoute(
          builder: (_) => VerifyEmailPage(email: emailController.text.trim()),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = AuthService.instance.firebaseErrorMessage(e.code);
      if (e.code == 'invalid-email') {
        setState(() => _emailError = msg);
      } else {
        setState(() => _authError = msg);
      }
    } catch (e) {
      debugPrint('[Auth] 이메일 로그인 실패: $e');
      if (mounted) setState(() => _authError = 'login_failed'.tr());
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ForgotPasswordDialog(
        initialEmail: emailController.text.trim(),
      ),
    );
  }

  Future<void> signInWithKakao() async {
    if (_isEmailLoading || _isKakaoLoading) return;
    // async gap 전에 캡처 — 카카오 OAuth 브라우저/앱 복귀 시 mounted가 false일 수 있음
    final userProvider = context.read<UserProvider>();
    setState(() { _isKakaoLoading = true; _clearErrors(); });
    try {
      final user = await AuthService.instance.loginWithKakao();
      await userProvider.setUser(user);
      FcmService.instance.initWithRationale().catchError((e) => debugPrint('[FCM] init failed: $e'));
    } on PlatformException catch (e) {
      debugPrint('[Auth] 카카오 PlatformException: $e');
      if (e.code != 'CANCELED' && mounted) {
        setState(() => _authError = 'login_failed'.tr());
      }
    } catch (e) {
      debugPrint('[Auth] 카카오 로그인 실패: $e');
      if (mounted) setState(() => _authError = 'login_failed'.tr());
    } finally {
      if (mounted) setState(() => _isKakaoLoading = false);
    }
  }
}
