import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/login/s_signup.dart';
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
                // ── 로고 영역 ──
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

                // ── 환영 텍스트 ──
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
                    fontSize: 15,
                    color: themeColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // ── 이메일 입력 ──
                AppTextField(
                  controller: emailController,
                  hintText: 'email'.tr(),
                  icon: Icons.mail_outline_rounded,
                  errorText: _emailError,
                  onChanged: (_) { if (_emailError != null) setState(() => _emailError = null); },
                ),
                const SizedBox(height: 14),

                // ── 비밀번호 입력 ──
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
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.errorRed, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _authError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.errorRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // ── 로그인 버튼 ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isEmailLoading || _isKakaoLoading ? null : _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColors.activate,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isEmailLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'login'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 카카오 로그인 ──
                _buildKakaoLoginButton(context),
                const SizedBox(height: 28),

                // ── 비밀번호 찾기 ──
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  style: TextButton.styleFrom(
                    foregroundColor: themeColors.activate,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'forgot_password'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── 회원가입 링크 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'not_member_yet'.tr(),
                      style: TextStyle(
                        color: themeColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        SlideRoute(builder: (context) => const SignupPage()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: themeColors.activate,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'signup'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // _buildTextField 제거됨 → AppTextField 공통 위젯 사용

  Widget _buildKakaoLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isEmailLoading || _isKakaoLoading ? null : () => signInWithKakao(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kakaoYellow,
          foregroundColor: AppColors.kakaoText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.shapeButton),
          ),
        ),
        child: _isKakaoLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/image/login/kakao_login_medium_narrow.png',
                      height: 24),
                  const SizedBox(width: 8),
                ],
              ),
      ),
    );
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

    setState(() { _isEmailLoading = true; _emailError = null; _passwordError = null; _authError = null; });
    final userProvider = context.read<UserProvider>();
    try {
      final user = await AuthService.instance.loginWithEmail(email, password);
      if (!mounted) return;
      await userProvider.setUser(user);
      FcmService.instance.init().catchError((e) => debugPrint('[FCM] init failed: $e'));
    } on EmailNotVerifiedException {
      if (mounted) setState(() => _emailError = 'email_not_verified'.tr());
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = AuthService.instance.firebaseErrorMessage(e.code);
      if (e.code == 'invalid-email') {
        setState(() => _emailError = msg);          // 형식 오류 → 이메일 필드 테두리
      } else {
        setState(() => _authError = msg);           // 인증 실패 → 테두리 없이 텍스트만
      }
    } catch (_) {
      if (mounted) setState(() => _authError = 'login_failed'.tr());
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('reset_password'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'registered_email'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appColors.activate,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await AuthService.instance.sendPasswordReset(email);
                if (mounted) {
                  context.showSuccessSnackbar('password_reset_sent'.tr());
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  context.showErrorSnackbar(AuthService.instance.firebaseErrorMessage(e.code));
                }
              }
            },
            child: Text('send'.tr()),
          ),
        ],
      ),
    ).then((_) => emailCtrl.dispose());
  }

  Future<void> signInWithKakao(BuildContext context) async {
    if (_isEmailLoading || _isKakaoLoading) return;
    setState(() { _isKakaoLoading = true; _emailError = null; _passwordError = null; _authError = null; });
    final userProvider = context.read<UserProvider>();
    try {
      final user = await AuthService.instance.loginWithKakao();
      if (!mounted) return;
      await userProvider.setUser(user);
      FcmService.instance.init().catchError((e) => debugPrint('[FCM] init failed: $e'));
    } on PlatformException catch (e) {
      debugPrint('=== 카카오 로그인 실패 에러 ===\n$e\n======================');
      if (e.code != 'CANCELED' && mounted) {
        setState(() => _authError = e.message ?? 'login_failed'.tr());
      }
    } catch (_) {
      debugPrint('=== 카카오 로그인 실패 ===');
      if (mounted) setState(() => _authError = 'login_failed'.tr());
    } finally {
      if (mounted) setState(() => _isKakaoLoading = false);
    }
  }
}
