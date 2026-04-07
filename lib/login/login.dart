import 'package:easy_localization/easy_localization.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/common/widget/w_app_text_field.dart';
import 'package:fast_app_base/login/signup.dart';
import 'package:fast_app_base/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  String? _loginError;

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── 로고 영역 ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
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
                  onChanged: (_) { if (_loginError != null) setState(() => _loginError = null); },
                ),
                const SizedBox(height: 14),

                // ── 비밀번호 입력 ──
                AppTextField(
                  controller: passwordController,
                  hintText: 'password'.tr(),
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  onChanged: (_) { if (_loginError != null) setState(() => _loginError = null); },
                ),
                const SizedBox(height: 24),

                // ── 로그인 버튼 ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColors.activate,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
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
                const SizedBox(height: 12),

                // ── 로그인 에러 메시지 ──
                if (_loginError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFE53E3E), size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _loginError!,
                            style: const TextStyle(
                              color: Color(0xFFE53E3E),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 2),

                // ── 카카오 로그인 ──
                _buildKakaoLoginButton(context),
                const SizedBox(height: 28),

                // ── 비밀번호 찾기 ──
                GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: Text(
                    'forgot_password'.tr(),
                    style: TextStyle(
                      color: themeColors.activate,
                      fontSize: 13,
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
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupPage()),
                      ),
                      child: Text(
                        'signup'.tr(),
                        style: TextStyle(
                          color: themeColors.activate,
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
    );
  }

  // _buildTextField 제거됨 → AppTextField 공통 위젯 사용

  Widget _buildKakaoLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => signInWithKakao(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xFF3C1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
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

    if (email.isEmpty || password.isEmpty) {
      setState(() => _loginError = 'enter_email_password'.tr());
      return;
    }

    setState(() { _isLoading = true; _loginError = null; });
    final userProvider = context.read<UserProvider>();
    try {
      final user = await AuthService.instance.loginWithEmail(email, password);
      if (!mounted) return;
      userProvider.setUser(user);
    } on EmailNotVerifiedException {
      if (mounted) {
        setState(() => _loginError = 'email_not_verified'.tr());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loginError = AuthService.instance.firebaseErrorMessage(e.code));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => _loginError = msg.isNotEmpty ? msg : 'login_failed'.tr());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await AuthService.instance.sendPasswordReset(email);
                if (mounted) {
                  Fluttertoast.showToast(
                    msg: 'password_reset_sent'.tr(),
                    backgroundColor: AppColors.skyBlue,
                    textColor: Colors.white,
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  Fluttertoast.showToast(
                    msg: AuthService.instance.firebaseErrorMessage(e.code),
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              }
            },
            child: Text('send'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> signInWithKakao(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    try {
      final user = await AuthService.instance.loginWithKakao();
      userProvider.setUser(user);

      Fluttertoast.showToast(
        msg: 'kakao_login_success'.tr(),
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
    } catch (e) {
      debugPrint('=== 카카오 로그인 실패 에러 ===\n$e\n======================');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('kakao_login_failed'.tr(args: [e.toString()]))),
        );
      }
    }
  }
}
