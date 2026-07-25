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
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/model/user_model.dart';
import '../provider/user_provider.dart';

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

  bool get _isAnyLoading => _isEmailLoading || _isKakaoLoading || _isAppleLoading;

  Widget _buildSocialLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildKakaoIconButton(),
        const SizedBox(width: 20),
        _buildAppleIconButton(),
      ],
    );
  }

  Widget _buildKakaoIconButton() {
    return _SocialIconButton(
      label: 'kakao_login_btn'.tr(),
      isLoading: _isKakaoLoading,
      dimmed: _isEmailLoading || _isAppleLoading,
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
      dimmed: _isEmailLoading || _isKakaoLoading,
      disabled: _isAnyLoading,
      backgroundColor: isDark ? Colors.white : Colors.black,
      indicatorColor: fg,
      onPressed: signInWithApple,
      child: Icon(Icons.apple, color: fg, size: 26),
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
    FcmService.instance.initWithRationale().catchError((e) => debugPrint('[FCM] init failed: $e'));
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

  Future<void> signInWithApple() async {
    if (_isAnyLoading) return;
    final userProvider = context.read<UserProvider>();
    setState(() { _isAppleLoading = true; _clearErrors(); });
    try {
      final user = await AuthService.instance.loginWithApple();
      await _completeLogin(userProvider, user);
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
    if (_isAnyLoading) return;
    // async gap 전에 캡처 — 카카오 OAuth 브라우저/앱 복귀 시 mounted가 false일 수 있음
    final userProvider = context.read<UserProvider>();
    setState(() { _isKakaoLoading = true; _clearErrors(); });
    try {
      final user = await AuthService.instance.loginWithKakao();
      await _completeLogin(userProvider, user);
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
  });

  final String label;
  final bool isLoading;
  final bool dimmed;
  final bool disabled;
  final Color backgroundColor;
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
            shape: const CircleBorder(),
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
