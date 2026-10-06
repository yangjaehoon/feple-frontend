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
import 'package:feple/common/widget/w_auth_header_text.dart';
import 'package:feple/common/widget/w_nickname_field.dart';
import 'package:feple/login/s_verify_email.dart';
import 'package:feple/login/w_password_checklist.dart';
import 'package:feple/model/auth_flow_result.dart';
import 'package:feple/model/nickname_check_result.dart';
import 'package:feple/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _exitDialogOpen = false;
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
    // 이중 탭이면 같은 다이얼로그가 두 장 쌓이고, 그 상태에서 확인을 누르면
    // 아래 pop이 이 화면이 아니라 두 번째 다이얼로그를 닫는다.
    if (_isLoading || _exitDialogOpen) return;
    if (!_isDirty) {
      _popSelf();
      return;
    }
    _exitDialogOpen = true;
    final bool confirmed;
    try {
      confirmed = await showConfirmDialog(
        context,
        title: 'discard_changes'.tr(),
        content: 'discard_changes_msg'.tr(),
        confirmLabel: 'discard'.tr(),
      );
    } finally {
      if (mounted) _exitDialogOpen = false;
    }
    if (confirmed && mounted) _popSelf();
  }

  /// 결과 없이 이 화면만 닫는다 — `Navigator.pop`은 최상단 라우트를 닫으므로,
  /// 확인 다이얼로그가 닫히는 사이 딥링크·FCM 화면이 올라오면 그쪽이 닫힌다.
  void _popSelf() => popRouteWithResult<AuthFlowResult?>(context, null);

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
      // 문구를 덮어쓰지 않는다 — NicknameField가 이미 구체적인 이유(중복·형식·
      // 금칙어)를 띄워놨고, 일반 문구로 바꾸면 무엇을 고쳐야 하는지 사라진다.
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
    // LoadingButton은 _isLoading 리빌드가 반영된 뒤에야 비활성화되므로, 같은
    // 프레임에 들어온 두 번째 탭은 그대로 통과한다.
    if (_isLoading) return;
    if (!_validateInput()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;
    final nickname = _nicknameKey.currentState?.currentNickname ?? '';

    // 재시도 시 이전 시도의 문구가 새 시도 중에 남아 있지 않게 한다.
    setState(() {
      _isLoading = true;
      _clearErrors();
    });
    try {
      await AuthService.instance.registerWithEmail(email, password, nickname);
      if (!mounted) return;
      await _openVerifyEmailForNewAccount(email);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // 아까 만든 미인증 계정으로 재시도한 경우 — register()는 signOut하지 않아
      // 세션이 살아 있으므로, 막다른 "이미 사용 중인 이메일" 대신 인증 화면으로
      // 돌려보낸다(그 화면에 재발송·이어하기 수단이 있다).
      if (e.code == 'email-already-in-use' &&
          AuthService.instance.isUnverifiedSessionFor(email)) {
        await _resumeUnverifiedSignup(email, nickname);
        return;
      }
      final msg = AuthService.instance.firebaseErrorKey(e.code).tr();
      setState(() {
        _clearErrors();
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
        _clearErrors();
        _generalError = 'unknown_error'.tr();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearErrors() {
    _emailError = null;
    _passwordError = null;
    _generalError = null;
  }

  /// 방금 만든 계정 → 인증 화면.
  Future<void> _openVerifyEmailForNewAccount(String email) async {
    // 자동완성 컨텍스트를 닫아 OS 비밀번호 관리자가 새 비밀번호 저장을 제안할 수
    // 있게 한다 — AutofillHints.newPassword를 선언만 하고 이걸 호출하지 않으면
    // 저장 제안이 오지 않는다. 이 화면을 떠난 뒤(LoginScreen)의 호출로는 이미
    // AutofillGroup이 dispose돼 늦으므로 여기서 해야 한다.
    TextInput.finishAutofillContext();
    await _pushVerifyEmail(email, deleteOnCancel: true);
  }

  /// 이미 존재하는 내 미인증 계정으로 재시도한 경우.
  ///
  /// 이 경로는 계정 생성 단계에서 실패해 **인증메일이 나가지 않았다**. 그대로
  /// 인증 화면으로 보내면 "메일을 보냈습니다"와 60초 재전송 쿨다운을 띄우게 되므로
  /// 먼저 재발송한다(닉네임을 바꿔 재시도했을 수 있어 displayName도 함께 갱신).
  ///
  /// 재발송이 실패해도(`too-many-requests` 등) 가입 폼에 묶어두지 않는다 —
  /// 인증 완료 폴링과 "인증 완료, 계속하기" 버튼이 인증 화면에만 있어서,
  /// 여기서 멈추면 메일함의 링크로 인증을 마쳐도 앱에서 이어갈 길이 없다.
  ///
  /// 자동완성 컨텍스트는 닫지 않는다 — 계정 비밀번호는 기존 것이 유지되므로 방금
  /// 입력한 값을 저장하면 실제 비밀번호와 어긋난다. 취소 시 계정도 지우지 않는다 —
  /// 이 세션이 이번 가입에서 만들어진 것인지 알 수 없다(로그인 화면에서 미인증
  /// 계정으로 로그인해도 세션이 유지된다).
  Future<void> _resumeUnverifiedSignup(String email, String nickname) async {
    var verificationEmailSent = true;
    try {
      await AuthService.instance.resumeUnverifiedSignup(nickname);
    } catch (e) {
      debugPrint('[Signup] 미인증 계정 인증메일 재발송 실패: $e');
      verificationEmailSent = false;
    }
    if (!mounted) return;
    await _pushVerifyEmail(
      email,
      deleteOnCancel: false,
      verificationEmailSent: verificationEmailSent,
    );
  }

  /// 인증 화면을 띄우고, 결과를 받으면 LoginScreen까지 그대로 넘기며 함께 닫는다.
  /// 뒤로가기(null)면 미인증 계정을 그대로 둔 것이므로 가입 폼을 유지한다.
  Future<void> _pushVerifyEmail(
    String email, {
    required bool deleteOnCancel,
    bool verificationEmailSent = true,
  }) async {
    final result = await Navigator.push<AuthFlowResult>(
      context,
      SlideRoute<AuthFlowResult>(
        builder: (_) => VerifyEmailScreen(
          email: email,
          deleteOnCancel: deleteOnCancel,
          verificationEmailSent: verificationEmailSent,
        ),
      ),
    );
    if (result != null && mounted) popRouteWithResult(context, result);
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
                            _buildHeader(),
                            _buildForm(),
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

  Widget _buildHeader() {
    final rs = ResponsiveSize(context);
    return Column(
      children: [
        const IconCircle(icon: Icons.person_add_rounded, sizeAt390: 76),
        SizedBox(height: rs.h(20)),
        AuthTitleText('signup'.tr()),
        SizedBox(height: rs.h(6)),
        AuthSubtitleText('signup_subtitle'.tr()),
        SizedBox(height: rs.h(26)),
      ],
    );
  }

  Widget _buildForm() {
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
