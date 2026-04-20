import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/common/widget/w_nickname_field.dart';
import 'package:feple/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class _PasswordChecklist extends StatelessWidget {
  final String password;
  const _PasswordChecklist({required this.password});

  static const _rules = [
    (label: 'pw_rule_min', regex: null, minLen: 8),
    (label: 'pw_rule_upper', regex: r'[A-Z]', minLen: 0),
    (label: 'pw_rule_lower', regex: r'[a-z]', minLen: 0),
    (label: 'pw_rule_digit', regex: r'[0-9]', minLen: 0),
    (label: 'pw_rule_special', regex: r'[!@#$%^&*(),.?":{}|<>]', minLen: 0),
  ];

  bool _check(({String label, String? regex, int minLen}) rule) {
    if (rule.minLen > 0) return password.length >= rule.minLen;
    return RegExp(rule.regex!).hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: _rules.map((rule) {
          final ok = _check(rule);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: ok ? Colors.green : colors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  rule.label.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: ok ? Colors.green : colors.textSecondary,
                    fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}



class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  String _password = '';

  // 인라인 에러 메시지
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  // 닉네임 필드 상태 접근용 키
  final _nicknameKey = GlobalKey<NicknameFieldState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String password) {
    final missing = <String>[];
    if (password.length < 8) missing.add('password_min_length'.tr());
    if (password.length > 4096) missing.add('password_max_length'.tr());
    if (!password.contains(RegExp(r'[A-Z]'))) missing.add('password_uppercase'.tr());
    if (!password.contains(RegExp(r'[a-z]'))) missing.add('password_lowercase'.tr());
    if (!password.contains(RegExp(r'[0-9]'))) missing.add('password_digit'.tr());
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) missing.add('password_special'.tr());
    if (missing.isEmpty) return null;
    return missing.join(', ');
  }

  Future<void> _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final nicknameState = _nicknameKey.currentState;
    final nickname = nicknameState?.currentNickname ?? '';

    // 에러 초기화
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    // 인라인 유효성 검사
    bool hasError = false;

    if (email.isEmpty) {
      _emailError = 'enter_email'.tr();
      hasError = true;
    }
    if (password.isEmpty) {
      _passwordError = 'enter_password'.tr();
      hasError = true;
    } else {
      final pwError = _validatePassword(password);
      if (pwError != null) {
        _passwordError = pwError;
        hasError = true;
      }
    }
    if (nickname.isEmpty) {
      nicknameState?.showError('enter_nickname'.tr());
      hasError = true;
    } else if (nickname.length < 2 || nickname.length > 8) {
      nicknameState?.showError('nickname_length_error'.tr());
      hasError = true;
    } else if (nicknameState?.available == null ||
        nicknameState?.lastCheckedNickname != nickname) {
      nicknameState?.showError('nickname_check_req'.tr());
      hasError = true;
    } else if (nicknameState?.available == false) {
      nicknameState?.showError('nickname_invalid'.tr());
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.registerWithEmail(
        email, password, nickname,
      );
      if (!mounted) return;

      // 인증 이메일 발송 완료 → 안내 다이얼로그 표시 후 로그인 페이지로 이동
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text('signup'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Text('verification_email_sent'.tr()),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.activate,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('confirm'.tr()),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context); // 로그인 페이지로 돌아가기
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = AuthService.instance.firebaseErrorMessage(e.code);
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
          case 'invalid-email':
            _emailError = msg;
            break;
          case 'weak-password':
            _passwordError = msg;
            break;
          default:
            _generalError = msg;
        }
      });
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _generalError = errMsg.isEmpty ? 'unknown_error'.tr() : errMsg;
      });
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
                    if (_emailError != null || _generalError != null) {
                      setState(() {
                        _emailError = null;
                        _generalError = null;
                      });
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
                  onChanged: (v) {
                    setState(() {
                      _password = v;
                      if (_passwordError != null || _generalError != null) {
                        _passwordError = null;
                        _generalError = null;
                      }
                    });
                  },
                ),
                if (_password.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _PasswordChecklist(password: _password),
                ],
                const SizedBox(height: 14),

                // ── 닉네임 입력 + 중복 확인 ──
                NicknameField(
                  key: _nicknameKey,
                  onResult: (_, __) {},
                ),
                const SizedBox(height: 28),

                // ── 일반 에러 메시지 ──
                if (_generalError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _generalError!,
                      style: TextStyle(
                        fontSize: 13,
                        color: themeColors.activate,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

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
