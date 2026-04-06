import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/config.dart';
import 'package:fast_app_base/login/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart' as app;
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
    return Scaffold(
      backgroundColor: AppColors.backgroundCreamy,
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
                    color: AppColors.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'login_subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // ── 이메일 입력 ──
                _buildTextField(
                  controller: emailController,
                  hintText: 'email'.tr(),
                  icon: Icons.mail_outline_rounded,
                  onChanged: (_) { if (_loginError != null) setState(() => _loginError = null); },
                ),
                const SizedBox(height: 14),

                // ── 비밀번호 입력 ──
                _buildTextField(
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
                      backgroundColor: AppColors.skyBlue,
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
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(
                      color: AppColors.skyBlue,
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
                        color: AppColors.textMuted,
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
                          color: AppColors.skyBlue,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: AppColors.textMain),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.skyBlue, size: 22),
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.skyBlueLight.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.skyBlueLight.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.skyBlue, width: 2),
        ),
      ),
    );
  }

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
      setState(() => _loginError = '이메일과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() { _isLoading = true; _loginError = null; });
    final userProvider = context.read<UserProvider>();
    try {
      // 1. Firebase 이메일/비밀번호 로그인
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final idToken = await credential.user!.getIdToken();

      // 2. 백엔드에서 앱 JWT 발급
      final response = await http.post(
        Uri.parse('$baseUrl/auth/firebase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'login_failed'.tr());
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await TokenStore.saveAccessToken(json['accessToken'] as String);
      final refreshToken = json['refreshToken'] as String?;
      if (refreshToken != null) await TokenStore.saveRefreshToken(refreshToken);

      final user = app.User.fromJson(json['user'] as Map<String, dynamic>);
      if (!mounted) return;
      userProvider.setUser(user);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loginError = _firebaseErrorMessage(e.code));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => _loginError = msg.isNotEmpty ? msg : '로그인에 실패했습니다.');
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
        title: const Text('비밀번호 재설정',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: '가입한 이메일 주소',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                if (mounted) {
                  Fluttertoast.showToast(
                    msg: '비밀번호 재설정 이메일을 발송했습니다.',
                    backgroundColor: AppColors.skyBlue,
                    textColor: Colors.white,
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  Fluttertoast.showToast(
                    msg: _firebaseErrorMessage(e.code),
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              }
            },
            child: const Text('발송', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'too-many-requests':
        return '로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      default:
        return '로그인에 실패했습니다. ($code)';
    }
  }

  Future<void> signInWithKakao(BuildContext context) async {
    final userProvider = context.read<UserProvider>();

    try {
      OAuthToken token;

      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      final me = await sendAccessTokenToServer(token.accessToken);

      userProvider.setUser(me);

      Fluttertoast.showToast(
        msg: 'kakao_login_success'.tr(),
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
    } catch (e) {
      print('=== 카카오 로그인 실패 에러 ===\n$e\n======================');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('kakao_login_failed'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  Future<app.User> sendAccessTokenToServer(String accessToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/kakao'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Spring 서버 로그인 실패: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final ourJwt = json['accessToken'] as String;
    await TokenStore.saveAccessToken(ourJwt);

    final refreshToken = json['refreshToken'] as String?;
    if (refreshToken != null) {
      await TokenStore.saveRefreshToken(refreshToken);
    }

    final userJson = json['user'] as Map<String, dynamic>;
    return app.User.fromJson(userJson);
  }
}
