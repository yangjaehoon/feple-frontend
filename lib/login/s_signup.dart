import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/email_validator.dart';
import 'package:feple/common/util/password_validator.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_icon_circle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_support_link_row.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/common/widget/w_nickname_field.dart';
import 'package:feple/login/s_verify_email.dart';
import 'package:feple/login/w_password_checklist.dart';
import 'package:feple/model/nickname_check_result.dart';
import 'package:feple/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
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
  bool _nicknameAvailable = false;

  bool get _isFormComplete {
    final email = emailController.text.trim();
    final password = passwordController.text;
    return EmailValidator.hasValidFormat(email) &&
        password.isNotEmpty &&
        PasswordValidator.validate(password) == null &&
        _nicknameAvailable;
  }

  bool get _isDirty =>
      emailController.text.isNotEmpty ||
      passwordController.text.isNotEmpty ||
      (_nicknameKey.currentState?.currentNickname.isNotEmpty ?? false);

  Future<void> _confirmExit() async {
    if (_isLoading) return;
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: 'discard_changes'.tr(),
      content: 'discard_changes_msg'.tr(),
      confirmLabel: 'discard'.tr(),
    );
    if (confirmed && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _validateInput() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final nicknameState = _nicknameKey.currentState;
    final nickname = nicknameState?.currentNickname ?? '';

    String? emailError;
    String? passwordError;
    bool hasError = false;

    emailError = EmailValidator.validate(email);
    if (emailError != null) hasError = true;
    if (password.isEmpty) {
      passwordError = 'enter_password'.tr();
      hasError = true;
    } else {
      final pwError = PasswordValidator.validate(password);
      if (pwError != null) {
        passwordError = pwError;
        hasError = true;
      }
    }
    if (nickname.isEmpty) {
      nicknameState?.showError('enter_nickname'.tr());
      hasError = true;
    } else if (!NicknameCheckResult.isValidLength(nickname)) {
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
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
        _generalError = null;
      });
    }
    return !hasError;
  }

  Future<void> _register() async {
    if (!_validateInput()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;
    final nickname = _nicknameKey.currentState?.currentNickname ?? '';

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.registerWithEmail(email, password, nickname);
      if (!mounted) return;

      await Navigator.push(
        context,
        SlideRoute(
          builder: (_) => VerifyEmailScreen(email: email, deleteOnCancel: true),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = AuthService.instance.firebaseErrorMessage(e.code);
      setState(() {
        // 필드를 고치지 않고 바로 재시도하면 onChanged로 지워지지 않으므로,
        // 이전 시도의 에러가 새 에러와 함께 남지 않도록 항상 셋 다 먼저 초기화
        _emailError = null;
        _passwordError = null;
        _generalError = null;
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
      debugPrint('[Signup] unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _emailError = null;
        _passwordError = null;
        _generalError = 'unknown_error'.tr();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    // 세로 간격은 화면 높이에 비례해 스케일한다(기준 iPhone 14, 844pt) —
    // 고정값으로 한 기기에만 맞추지 않도록.
    final rs = ResponsiveSize(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: themeColors.backgroundMain,
        appBar: _buildAppBar(themeColors),
        body: KeyboardDismiss(
          child: SafeArea(
            child: Column(
              children: [
                // Center가 세로 중앙 배치, 넘치면 SingleChildScrollView가 스크롤.
                // 문의 링크는 인증 흐름이 아닌 보조 링크라 아래에 별도로 두고
                // 입력 중(키보드)엔 숨겨 공간을 비운다.
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(28, rs.h(8), 28, rs.h(8)),
                      child: AutofillGroup(
                        child: Column(
                          children: [
                            _buildHeader(themeColors),
                            _buildForm(themeColors),
                            SizedBox(height: rs.h(24)),
                            if (_generalError != null)
                              _buildGeneralError(themeColors),
                            _buildSubmitButton(themeColors),
                            SizedBox(height: rs.h(20)),
                            _buildLoginLink(themeColors),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!keyboardOpen)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(28, 2, 28, 4),
                    child: SupportLinkRow(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AbstractThemeColors colors) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        tooltip: 'back'.tr(),
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: colors.textTitle,
          size: 20,
        ),
        onPressed: _confirmExit,
      ),
    );
  }

  Widget _buildGeneralError(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        _generalError!,
        style: TextStyle(
          fontSize: AppDimens.fontSizeSm,
          color: colors.error,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubmitButton(AbstractThemeColors colors) {
    return AnimatedOpacity(
      opacity: _isFormComplete ? 1.0 : 0.5,
      duration: AppDimens.animNormal,
      child: LoadingButton(
        label: 'register'.tr(),
        onPressed: _register,
        isLoading: _isLoading,
        backgroundColor: colors.activate,
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors themeColors) {
    final rs = ResponsiveSize(context);
    return Column(
      children: [
        const IconCircle(icon: Icons.person_add_rounded, sizeAt390: 76),
        SizedBox(height: rs.h(20)),
        Text(
          'signup'.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeDisplay,
            fontWeight: FontWeight.w800,
            color: themeColors.textTitle,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: rs.h(6)),
        Text(
          'signup_subtitle'.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            color: themeColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: rs.h(26)),
      ],
    );
  }

  Widget _buildForm(AbstractThemeColors themeColors) {
    final rs = ResponsiveSize(context);
    return Column(
      children: [
        AppTextField(
          controller: emailController,
          hintText: 'email'.tr(),
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newUsername, AutofillHints.email],
          errorText: _emailError,
          onChanged: (_) {
            setState(() {
              _emailError = null;
              _generalError = null;
            });
          },
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        SizedBox(height: rs.h(14)),
        NicknameField(
          key: _nicknameKey,
          onStateChanged: (available) {
            setState(() => _nicknameAvailable = available == true);
          },
        ),
        SizedBox(height: rs.h(14)),
        AppTextField(
          controller: passwordController,
          hintText: 'password'.tr(),
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
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
          SizedBox(height: rs.h(10)),
          PasswordChecklist(password: _password),
        ],
      ],
    );
  }

  Widget _buildLoginLink(AbstractThemeColors themeColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'already_have_account'.tr(),
          style: TextStyle(
            color: themeColors.textSecondary,
            fontSize: AppDimens.fontSizeMd,
          ),
        ),
        TextButton(
          onPressed: _confirmExit,
          style: TextButton.styleFrom(
            foregroundColor: themeColors.activate,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(
            'login'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: AppDimens.fontSizeMd,
            ),
          ),
        ),
      ],
    );
  }
}
