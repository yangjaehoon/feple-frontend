import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/login/s_signup.dart';
import 'package:feple/login/s_verify_email.dart';
import 'package:feple/login/s_forgot_password.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:feple/service/auth_service.dart';
import 'package:feple/service/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:feple/common/theme/custom_theme.dart';
import '../provider/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isEmailLoading = false;
  bool _isKakaoLoading = false;
  bool _isAppleLoading = false;
  bool _isNavigating = false;
  String? _emailError;
  String? _passwordError;   // 빈 필드 → 빨간 테두리
  String? _authError;       // 인증 실패 → 텍스트만, 테두리 없음

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(themeColors),
                    _buildForm(themeColors),
                    const SizedBox(height: 12),
                    _buildForgotPassword(themeColors),
                    const SizedBox(height: 20),
                    IgnorePointer(
                      ignoring: _isAnyLoading,
                      child: Opacity(
                        opacity: (_isKakaoLoading || _isAppleLoading) ? 0.5 : 1.0,
                        child: LoadingButton(
                          label: 'login'.tr(),
                          onPressed: _loginWithEmail,
                          isLoading: _isEmailLoading,
                          backgroundColor: themeColors.activate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildOrDivider(themeColors),
                    const SizedBox(height: 20),
                    _buildKakaoLoginButton(),
                    const SizedBox(height: 12),
                    _buildAppleLoginButton(),
                    const SizedBox(height: 28),
                    _buildSignupRow(context, themeColors),
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
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
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
          keyboardType: TextInputType.visiblePassword,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loginWithEmail(),
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

  Widget _buildForgotPassword(AbstractThemeColors themeColors) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
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
    );
  }

  Widget _buildOrDivider(AbstractThemeColors themeColors) {
    return Row(
      children: [
        Expanded(child: Divider(color: themeColors.divider, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              color: themeColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: themeColors.divider, thickness: 1)),
      ],
    );
  }

  bool get _isAnyLoading => _isEmailLoading || _isKakaoLoading || _isAppleLoading;

  Widget _buildKakaoLoginButton() {
    return IgnorePointer(
      ignoring: _isAnyLoading,
      child: Opacity(
        opacity: (_isEmailLoading || _isAppleLoading) ? 0.5 : 1.0,
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

  Widget _buildAppleLoginButton() {
    final isDark = context.themeType == CustomTheme.dark;
    return IgnorePointer(
      ignoring: _isAnyLoading,
      child: Opacity(
        opacity: (_isEmailLoading || _isKakaoLoading) ? 0.5 : 1.0,
        child: _isAppleLoading
            ? LoadingButton(
                isLoading: true,
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                onPressed: () {},
                label: 'apple_login_btn'.tr(),
              )
            : SignInWithAppleButton(
                style: isDark
                    ? SignInWithAppleButtonStyle.white
                    : SignInWithAppleButtonStyle.black,
                text: 'apple_login_btn'.tr(),
                onPressed: signInWithApple,
              ),
      ),
    );
  }

  Widget _buildSignupRow(BuildContext context, AbstractThemeColors themeColors) {
    return Row(
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
            Navigator.push(context, SlideRoute(builder: (_) => const SignupScreen()))
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

    String? emailErr;
    if (email.isEmpty) {
      emailErr = 'enter_email'.tr();
    } else if (!_emailRegex.hasMatch(email)) {
      emailErr = 'enter_valid_email'.tr();
    }
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
          builder: (_) => VerifyEmailScreen(email: emailController.text.trim()),
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
    await Navigator.push(
      context,
      SlideRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: emailController.text.trim(),
        ),
      ),
    );
  }

  Future<void> signInWithApple() async {
    if (_isAnyLoading) return;
    final userProvider = context.read<UserProvider>();
    setState(() { _isAppleLoading = true; _clearErrors(); });
    try {
      final user = await AuthService.instance.loginWithApple();
      await userProvider.setUser(user);
      FcmService.instance.initWithRationale().catchError((e) => debugPrint('[FCM] init failed: $e'));
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('[Auth] Apple 로그인 취소/실패: $e');
      if (e.code != AuthorizationErrorCode.canceled && mounted) {
        setState(() => _authError = 'login_failed'.tr());
      }
    } catch (e) {
      debugPrint('[Auth] Apple 로그인 실패: $e');
      if (mounted) setState(() => _authError = 'login_failed'.tr());
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
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
