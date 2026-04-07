import 'package:easy_localization/easy_localization.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/common/widget/w_app_text_field.dart';
import 'package:fast_app_base/common/widget/w_nickname_field.dart';
import 'package:fast_app_base/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  // 인라인 에러 메시지
  String? _emailError;
  String? _passwordError;

  // 닉네임 필드 상태 접근용 키
  final _nicknameKey = GlobalKey<NicknameFieldState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final nicknameState = _nicknameKey.currentState;
    final nickname = nicknameState?.currentNickname ?? '';

    // 인라인 유효성 검사
    bool hasError = false;
    String? emailErr;
    String? passwordErr;

    if (email.isEmpty) {
      emailErr = 'enter_email'.tr();
      hasError = true;
    }
    if (password.isEmpty) {
      passwordErr = 'enter_password'.tr();
      hasError = true;
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passwordErr;
    });

    if (hasError) return;

    if (nickname.isEmpty) {
      Fluttertoast.showToast(
        msg: 'enter_nickname'.tr(),
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
      return;
    }
    if (nickname.length < 2 || nickname.length > 8) {
      Fluttertoast.showToast(
        msg: 'nickname_length_error'.tr(),
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
      return;
    }

    if (nicknameState?.available == null || nicknameState?.lastCheckedNickname != nickname) {
      Fluttertoast.showToast(
        msg: 'nickname_check_req'.tr(),
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
      return;
    }
    if (nicknameState?.available == false) {
      Fluttertoast.showToast(
        msg: 'nickname_invalid'.tr(),
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await AuthService.instance.registerWithEmail(
        email, password, nickname,
      );
      if (!mounted) return;
      context.read<UserProvider>().setUser(user);

      Fluttertoast.showToast(
        msg: 'signup_success'.tr(),
        backgroundColor: AppColors.skyBlue,
        textColor: Colors.white,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: '[${e.code}] ${e.message ?? ''}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      final errMsg = e.toString().replaceFirst('Exception: ', '');
      Fluttertoast.showToast(
        msg: 'signup_failed_detail'.tr(args: [errMsg.isEmpty ? 'unknown_error'.tr() : errMsg]),
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                // ── 아이콘 ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: themeColors.activate.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 40,
                    color: themeColors.activate,
                  ),
                ),
                const SizedBox(height: 24),

                // ── 환영 텍스트 ──
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
                  style: TextStyle(
                    fontSize: 14,
                    color: themeColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                // ── 이메일 입력 ──
                AppTextField(
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
                AppTextField(
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
                NicknameField(
                  key: _nicknameKey,
                  onResult: (_, __) {},
                ),
                const SizedBox(height: 28),

                // ── 가입 버튼 ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
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
                        color: themeColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'login'.tr(),
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
}
