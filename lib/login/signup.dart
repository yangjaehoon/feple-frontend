import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/config.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../auth/token_store.dart';
import '../model/user_model.dart' as app;
import '../provider/user_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();
  bool _isLoading = false;

  // 인라인 에러 메시지
  String? _emailError;
  String? _passwordError;

  // 닉네임 중복 확인 상태
  bool _isCheckingNickname = false;
  bool? _nicknameAvailable;
  String _nicknameCheckMessage = '';
  String _lastCheckedNickname = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> _checkNickname() async {
    final nickname = nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() {
        _nicknameAvailable = false;
        _nicknameCheckMessage = '닉네임을 입력해주세요.';
      });
      return;
    }
    if (nickname.length < 2 || nickname.length > 8) {
      setState(() {
        _nicknameAvailable = false;
        _nicknameCheckMessage = '닉네임은 2자 이상 8자 이하로 입력해주세요.';
      });
      return;
    }

    setState(() => _isCheckingNickname = true);
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/users/check-nickname?nickname=${Uri.encodeComponent(nickname)}'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        _nicknameAvailable = body['available'] as bool;
        _nicknameCheckMessage = body['message'] as String;
        _lastCheckedNickname = nickname;
      });
    } catch (e) {
      setState(() {
        _nicknameAvailable = false;
        _nicknameCheckMessage = '확인 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) setState(() => _isCheckingNickname = false);
    }
  }

  Future<void> _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final nickname = nicknameController.text.trim();

    // 인라인 유효성 검사
    bool hasError = false;
    String? emailErr;
    String? passwordErr;

    if (email.isEmpty) {
      emailErr = '이메일을 입력해주세요.';
      hasError = true;
    }
    if (password.isEmpty) {
      passwordErr = '비밀번호를 입력해주세요.';
      hasError = true;
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passwordErr;
    });

    if (hasError) return;

    if (nickname.isEmpty) {
      Fluttertoast.showToast(
        msg: '닉네임을 입력해주세요.',
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
      return;
    }
    if (nickname.length < 2 || nickname.length > 8) {
      Fluttertoast.showToast(
        msg: '닉네임은 2자 이상 8자 이하로 입력해주세요.',
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
      return;
    }

    if (_nicknameAvailable == null || _lastCheckedNickname != nickname) {
      Fluttertoast.showToast(
        msg: '닉네임 중복 확인을 해주세요.',
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
      return;
    }
    if (_nicknameAvailable == false) {
      Fluttertoast.showToast(
        msg: _nicknameCheckMessage,
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
          'nickname': nickname,
        }),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'signup_failed'.tr());
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      await TokenStore.saveAccessToken(json['accessToken'] as String);
      final refreshToken = json['refreshToken'] as String?;
      if (refreshToken != null) await TokenStore.saveRefreshToken(refreshToken);

      final user = app.User.fromJson(json['user'] as Map<String, dynamic>);
      if (!mounted) return;
      context.read<UserProvider>().setUser(user);

      Fluttertoast.showToast(
        msg: 'signup_success'.tr(),
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'signup_failed_detail'.tr(args: [e.toString()]),
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
                Text(
                  'signup'.tr(),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'signup_subtitle'.tr(),
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
                  hintText: 'email'.tr(),
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // ── 비밀번호 입력 ──
                _buildTextField(
                  controller: passwordController,
                  hintText: 'password'.tr(),
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  errorText: _passwordError,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // ── 닉네임 입력 + 중복 확인 ──
                _buildNicknameField(),
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
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'register'.tr(),
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
                    Text(
                      'already_have_account'.tr(),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'login'.tr(),
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

  Widget _buildNicknameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: nicknameController,
                maxLength: 8,
                onChanged: (_) {
                  if (_nicknameAvailable != null) {
                    setState(() {
                      _nicknameAvailable = null;
                      _nicknameCheckMessage = '';
                    });
                  }
                },
                style: const TextStyle(fontSize: 15, color: AppColors.textMain),
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: const Icon(Icons.badge_outlined,
                      color: AppColors.skyBlue, size: 22),
                  hintText: '닉네임 (2~8자)',
                  hintStyle:
                      const TextStyle(color: AppColors.textMuted, fontSize: 15),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.skyBlueLight.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: _nicknameAvailable == false
                            ? Colors.red
                            : _nicknameAvailable == true
                                ? Colors.green
                                : AppColors.skyBlueLight.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.skyBlue, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isCheckingNickname ? null : _checkNickname,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isCheckingNickname
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('중복 확인',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        if (_nicknameCheckMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _nicknameCheckMessage,
              style: TextStyle(
                fontSize: 12,
                color:
                    _nicknameAvailable == true ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: AppColors.textMain),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.skyBlue, size: 22),
            hintText: hintText,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 15),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.skyBlueLight.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red
                    : AppColors.skyBlueLight.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.skyBlue, width: 2),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
