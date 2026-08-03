import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/email_validator.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_support_link_row.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/login/s_signup.dart';
import 'package:feple/login/s_verify_email.dart';
import 'package:feple/login/s_forgot_password.dart';
import 'package:feple/service/auth_service.dart';
import 'package:feple/service/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/model/user_model.dart';
import '../provider/user_provider.dart';

// 구글 공식 브랜드 가이드의 다색 "G" 로고 (developers.google.com/identity/branding-guidelines)
const _googleLogoSvg = '''
<svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
<path fill="#4285F4" d="M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4814h4.8436c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2581h2.9087c1.7018-1.5668 2.6836-3.8741 2.6836-6.615z"/>
<path fill="#34A853" d="M9 18c2.43 0 4.4673-.806 5.9564-2.1805l-2.9087-2.2581c-.8059.54-1.8368.8591-3.0477.8591-2.344 0-4.3282-1.5831-5.036-3.7104H.9573v2.3318C2.4382 15.9832 5.4818 18 9 18z"/>
<path fill="#FBBC05" d="M3.964 10.71c-.18-.54-.2822-1.1168-.2822-1.71s.1023-1.17.2822-1.71V4.9582H.9573C.3477 6.1732 0 7.5477 0 9s.3477 2.8268.9573 4.0418L3.964 10.71z"/>
<path fill="#EA4335" d="M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5813-2.5814C13.4632.8918 11.426 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9582L3.964 7.29c.7077-2.1273 2.692-3.7105 5.036-3.7105z"/>
</svg>
''';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with NavigationGuard {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isEmailLoading = false;
  bool _isKakaoLoading = false;
  bool _isAppleLoading = false;
  bool _isGoogleLoading = false;
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
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
                          _buildSocialLoginRow(),
                          const SizedBox(height: 28),
                          _buildSignupRow(context, themeColors),
                          const SizedBox(height: 32),
                          const SupportLinkRow(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors themeColors) {
    final logoSize = ResponsiveSize(context).w(120);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          child: Image.asset(
            'assets/image/login/feple_logo.png',
            width: logoSize,
            height: logoSize,
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
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
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

  bool get _isAnyLoading =>
      _isEmailLoading || _isKakaoLoading || _isAppleLoading || _isGoogleLoading;

  Widget _buildSocialLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildKakaoIconButton(),
        const SizedBox(width: 20),
        _buildAppleIconButton(),
        const SizedBox(width: 20),
        _buildGoogleIconButton(),
      ],
    );
  }

  Widget _buildKakaoIconButton() {
    return _SocialIconButton(
      label: 'kakao_login_btn'.tr(),
      isLoading: _isKakaoLoading,
      dimmed: _isEmailLoading || _isAppleLoading || _isGoogleLoading,
      disabled: _isAnyLoading,
      backgroundColor: AppColors.kakaoYellow,
      indicatorColor: const Color(0xFF3C1E1E),
      onPressed: signInWithKakao,
      // 카카오 공식 아이콘 로그인 버튼 에셋(19x20 talk 심볼) — kakao_flutter_sdk_user 패키지 번들
      child: SvgPicture.asset(
        'assets/images/icon_talk_login.svg',
        package: 'kakao_flutter_sdk_user',
        width: 22,
        height: 22,
      ),
    );
  }

  Widget _buildAppleIconButton() {
    final isDark = context.themeType == CustomTheme.dark;
    final fg = isDark ? Colors.black : Colors.white;
    return _SocialIconButton(
      label: 'apple_login_btn'.tr(),
      isLoading: _isAppleLoading,
      dimmed: _isEmailLoading || _isKakaoLoading || _isGoogleLoading,
      disabled: _isAnyLoading,
      backgroundColor: isDark ? Colors.white : Colors.black,
      indicatorColor: fg,
      onPressed: signInWithApple,
      child: Icon(Icons.apple, color: fg, size: 26),
    );
  }

  Widget _buildGoogleIconButton() {
    final themeColors = context.appColors;
    return _SocialIconButton(
      label: 'google_login_btn'.tr(),
      isLoading: _isGoogleLoading,
      dimmed: _isEmailLoading || _isKakaoLoading || _isAppleLoading,
      disabled: _isAnyLoading,
      backgroundColor: Colors.white,
      borderColor: themeColors.divider,
      indicatorColor: Colors.black54,
      onPressed: signInWithGoogle,
      // 구글 공식 브랜드 가이드의 다색 "G" 로고 (developers.google.com/identity 배포본)
      child: SvgPicture.string(_googleLogoSvg, width: 22, height: 22),
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
          onPressed: () => guardedNavigate(() =>
              Navigator.push(context, SlideRoute(builder: (_) => const SignupScreen()))),
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

  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
    _authError = null;
  }

  Future<void> _completeLogin(UserProvider userProvider, AppUser user) async {
    await userProvider.setUser(user);
    unawaited(FcmService.instance.initWithRationale());
  }

  Future<void> _handleLoginSuccess(AppUser user) async {
    if (!mounted) return;
    await _completeLogin(context.read<UserProvider>(), user);
  }

  Future<void> _loginWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    final emailErr = EmailValidator.validate(email);
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

  /// 소셜 로그인 3종(Apple/Google/Kakao)의 공통 흐름: 로딩 체크 → provider
  /// 캡처 → 로그인 → 취소 예외는 무시, 그 외 실패는 공통 에러 표시.
  Future<void> _runSocialLogin({
    required String label,
    required Future<AppUser> Function() login,
    required void Function(bool loading) setLoading,
    required bool Function(Object error) isCanceled,
  }) async {
    if (_isAnyLoading) return;
    // async gap 전에 캡처 — OAuth 시트/브라우저 복귀 시 mounted가 false일 수 있음
    final userProvider = context.read<UserProvider>();
    setState(() {
      setLoading(true);
      _clearErrors();
    });
    try {
      final user = await login();
      await _completeLogin(userProvider, user);
    } catch (e) {
      debugPrint('[Auth] $label 로그인 실패: $e');
      if (!isCanceled(e) && mounted) {
        setState(() => _authError = 'login_failed'.tr());
      }
    } finally {
      if (mounted) setState(() => setLoading(false));
    }
  }

  Future<void> signInWithApple() => _runSocialLogin(
    label: 'Apple',
    login: AuthService.instance.loginWithApple,
    setLoading: (v) => _isAppleLoading = v,
    isCanceled: (e) =>
        e is SignInWithAppleAuthorizationException &&
        e.code == AuthorizationErrorCode.canceled,
  );

  Future<void> signInWithGoogle() => _runSocialLogin(
    label: 'Google',
    login: AuthService.instance.loginWithGoogle,
    setLoading: (v) => _isGoogleLoading = v,
    isCanceled: (e) =>
        e is GoogleSignInException &&
        e.code == GoogleSignInExceptionCode.canceled,
  );

  Future<void> signInWithKakao() => _runSocialLogin(
    label: '카카오',
    login: AuthService.instance.loginWithKakao,
    setLoading: (v) => _isKakaoLoading = v,
    isCanceled: (e) => e is PlatformException && e.code == 'CANCELED',
  );
}

/// 소셜 로그인 원형 아이콘 버튼. [dimmed]는 다른 소셜 버튼이 로딩 중일 때
/// 이 버튼을 흐리게 표시, [disabled]는 어떤 로그인이든 진행 중이면 탭을 막는다.
class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.label,
    required this.isLoading,
    required this.dimmed,
    required this.disabled,
    required this.backgroundColor,
    required this.indicatorColor,
    required this.onPressed,
    required this.child,
    this.borderColor,
  });

  final String label;
  final bool isLoading;
  final bool dimmed;
  final bool disabled;
  final Color backgroundColor;
  final Color? borderColor;
  final Color indicatorColor;
  final VoidCallback onPressed;
  final Widget child;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: IgnorePointer(
        ignoring: disabled,
        child: Opacity(
          opacity: dimmed ? 0.5 : 1.0,
          child: Material(
            color: backgroundColor,
            shape: CircleBorder(
              side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                onPressed();
              },
              child: SizedBox(
                width: _size,
                height: _size,
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: indicatorColor,
                          ),
                        )
                      : child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
