import 'dart:convert';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/config.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart' as app;
import '../provider/user_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final nickname = nicknameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: '이메일과 비밀번호를 입력해주세요.',
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'nickname': nickname.isEmpty ? null : nickname,
        }),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? '회원가입 실패');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await TokenStore.saveAccessToken(json['accessToken'] as String);
      final refreshToken = json['refreshToken'] as String?;
      if (refreshToken != null) await TokenStore.saveRefreshToken(refreshToken);

      final user = app.User.fromJson(json['user'] as Map<String, dynamic>);
      if (!mounted) return;
      context.read<UserProvider>().setUser(user);

      Fluttertoast.showToast(
        msg: '회원가입 완료! 환영합니다 🎉',
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const App()),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: '회원가입 실패: $e',
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                // ── 아이콘 ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    size: 40,
                    color: AppColors.skyBlue,
                  ),
                ),
                const SizedBox(height: 24),

                // ── 환영 텍스트 ──
                const Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '페플에 가입하고 축제를 즐겨보세요!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                // ── 이메일 입력 ──
                _buildTextField(
                  controller: emailController,
                  hintText: '이메일',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // ── 비밀번호 입력 ──
                _buildTextField(
                  controller: passwordController,
                  hintText: '비밀번호',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 14),

                // ── 닉네임 입력 ──
                _buildTextField(
                  controller: nicknameController,
                  hintText: '닉네임 (선택)',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 28),

                // ── 가입 버튼 ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
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
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            '가입하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── 로그인 페이지 링크 ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '이미 계정이 있으신가요?',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        ' 로그인',
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
}
