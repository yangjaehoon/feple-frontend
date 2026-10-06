import 'dart:io';

import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/email_validator.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_support_link_row.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/common/widget/w_auth_header_text.dart';
import 'package:feple/login/s_signup.dart';
import 'package:feple/login/w_form_error_text.dart';
import 'package:feple/login/s_verify_email.dart';
import 'package:feple/login/s_forgot_password.dart';
import 'package:feple/service/auth_service.dart';
import 'package:feple/service/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'
    show AuthErrorCause, KakaoAuthException;
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/model/auth_flow_result.dart';
import 'package:feple/model/user_model.dart';
import '../provider/user_provider.dart';

// 구글 공식 브랜드 가이드의 다색 "G" 로고 (developers.google.com/identity/branding-guidelines)
const _googleLogoSvg = '''
<svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
<path fill="#4285F4" d="M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4814h4.8436c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2581h2.9087c1.7018-1.5668 2.6836-3.8741 2.6836-6.615z"/>
<path fill="#34A853" d="M9 18c2.43 0 4.4673-.806 5.9564-2.1805l-2.9087-2.2581c-.8059.54-1.8368.8591-3.0477.8591-2.344 0-4.3282-1.5831-5.036-3.7104H.9573v2.3318C2.4382 15.9832 5.4818 18 9 18z"/>
<path fill="#FBBC05" d="M3.964 10.71c-.18-.54-.2822-1.1168-.2822-1.71s.1023-1.17.2822-1.71V4.9582H.9573C.3477 6.1732 0 7.5477 0 9s.3477 2.8268.9573 4.0418L3.964 10.71z"/>
<path fill="#EA4335" d="M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5813-2.5814C13.4632.8918 11.426 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9582L3.964 7.29c.7077-2.1273 2.692-3.7105 5.036-3.7105z"/>
</svg>
''';

enum _LoginMethod { email, kakao, apple, google }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with NavigationGuard {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  /// 진행 중인 로그인 수단(없으면 null). 수단별 bool을 따로 두면 "나머지가 로딩
  /// 중" 조건을 버튼마다 나열해야 해서 하나가 빠지기 쉽다(구글 추가 때 이메일
  /// 버튼의 dim 조건이 빠져 있었음).
  _LoginMethod? _loadingMethod;
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
    // 세로 간격은 화면 높이에 비례해 스케일한다(기준 iPhone 14, 844pt).
    // 작은 폰은 촘촘히, 큰 폰은 넉넉히 — 고정값으로 한 기기에만 맞추지 않도록.
    final rs = ResponsiveSize(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: themeColors.backgroundMain,
      body: KeyboardDismiss(
        child: SafeArea(
          child: Column(
            children: [
              // Center가 콘텐츠를 세로 중앙에 두고, 넘치면 SingleChildScrollView가
              // 스크롤한다. 문의 링크는 아래에 별도로 두어 항상 보이게 한다
              // (인증 흐름이 아닌 보조 링크). 입력 중(키보드)엔 숨겨 공간을 비운다.
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(28, rs.h(10), 28, rs.h(8)),
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          _buildHeader(rs),
                          _buildForm(rs),
                          SizedBox(height: rs.h(10)),
                          _buildForgotPassword(themeColors),
                          SizedBox(height: rs.h(14)),
                          _buildEmailLoginButton(themeColors),
                          SizedBox(height: rs.h(14)),
                          _buildOrDivider(themeColors),
                          SizedBox(height: rs.h(14)),
                          _buildSocialLoginRow(),
                          SizedBox(height: rs.h(14)),
                          _buildSignupRow(themeColors),
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
    );
  }

  Widget _buildHeader(ResponsiveSize rs) {
    final logoSize = rs.w(92);
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
        SizedBox(height: rs.h(18)),
        AuthTitleText('welcome'.tr()),
        SizedBox(height: rs.h(6)),
        AuthSubtitleText('login_subtitle'.tr()),
        SizedBox(height: rs.h(22)),
      ],
    );
  }

  Widget _buildForm(ResponsiveSize rs) {
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
          // 인증 실패 문구도 함께 지운다 — 아이디를 고쳐 다시 시도하는 흐름에서
          // 이전 실패 메시지가 남아 있으면 새 시도의 결과처럼 보인다.
          onChanged: (_) {
            if (_emailError != null || _authError != null) {
              setState(() { _emailError = null; _authError = null; });
            }
          },
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        SizedBox(height: rs.h(14)),
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
        if (_authError != null) FormErrorText(message: _authError!),
      ],
    );
  }

  Widget _buildForgotPassword(AbstractThemeColors themeColors) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        // 로그인 진행 중엔 막는다 — 소셜 시트가 닫힌 뒤 토큰 교환이 끝나기 전에
        // 다른 화면이 올라가면 로그인 완료 시 그 화면이 닫힌다.
        onPressed: _isAnyLoading ? null : _openForgotPassword,
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

  bool get _isAnyLoading => _loadingMethod != null;

  bool _isLoading(_LoginMethod method) => _loadingMethod == method;

  /// 다른 수단이 진행 중 — 이 버튼은 흐리게 표시하고 탭을 막는다.
  bool _isOtherLoading(_LoginMethod method) =>
      _isAnyLoading && _loadingMethod != method;

  Widget _buildEmailLoginButton(AbstractThemeColors themeColors) {
    const method = _LoginMethod.email;
    return IgnorePointer(
      ignoring: _isAnyLoading,
      child: Opacity(
        opacity: _isOtherLoading(method) ? 0.5 : 1.0,
        child: LoadingButton(
          label: 'login'.tr(),
          onPressed: _loginWithEmail,
          isLoading: _isLoading(method),
          backgroundColor: themeColors.activate,
        ),
      ),
    );
  }

  Widget _buildSocialLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildKakaoIconButton(),
        const SizedBox(width: AppDimens.space20),
        // 안드로이드는 네이티브 Apple 로그인 API가 없어 별도의 웹 인증 설정
        // (Services ID, 리다이렉트용 도메인)이 갖춰지기 전까지 버튼을 숨긴다.
        if (Platform.isIOS) ...[
          _buildAppleIconButton(),
          const SizedBox(width: AppDimens.space20),
        ],
        _buildGoogleIconButton(),
      ],
    );
  }

  Widget _buildKakaoIconButton() {
    const method = _LoginMethod.kakao;
    return _SocialIconButton(
      label: 'kakao_login_btn'.tr(),
      isLoading: _isLoading(method),
      otherLoading: _isOtherLoading(method),
      backgroundColor: AppColors.kakaoYellow,
      indicatorColor: AppColors.kakaoText,
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
    const method = _LoginMethod.apple;
    final isDark = context.themeType == CustomTheme.dark;
    final fg = isDark ? Colors.black : Colors.white;
    return _SocialIconButton(
      label: 'apple_login_btn'.tr(),
      isLoading: _isLoading(method),
      otherLoading: _isOtherLoading(method),
      backgroundColor: isDark ? Colors.white : Colors.black,
      indicatorColor: fg,
      onPressed: signInWithApple,
      child: Icon(Icons.apple, color: fg, size: 26),
    );
  }

  Widget _buildGoogleIconButton() {
    const method = _LoginMethod.google;
    final themeColors = context.appColors;
    return _SocialIconButton(
      label: 'google_login_btn'.tr(),
      isLoading: _isLoading(method),
      otherLoading: _isOtherLoading(method),
      backgroundColor: Colors.white,
      borderColor: themeColors.divider,
      indicatorColor: Colors.black54,
      onPressed: signInWithGoogle,
      // 구글 공식 브랜드 가이드의 다색 "G" 로고 (developers.google.com/identity 배포본)
      child: SvgPicture.string(_googleLogoSvg, width: 22, height: 22),
    );
  }

  Widget _buildSignupRow(AbstractThemeColors themeColors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'not_member_yet'.tr(),
          style: TextStyle(color: themeColors.textSecondary, fontSize: AppDimens.fontSizeMd),
        ),
        TextButton(
          onPressed: _isAnyLoading ? null : _openSignup,
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

  /// [userProvider]는 호출부가 async gap **전에** 캡처해 넘긴다. 토큰 교환이
  /// 끝난 시점엔 이 State가 이미 unmount일 수 있는데(교환 중 뒤로가기·엣지
  /// 스와이프로 이탈), 거기서 로그인을 중단하면 AuthTokenExchanger가 이미 저장한
  /// JWT만 남아 "토큰은 유효한데 앱은 게스트"인 상태가 콜드스타트까지 이어진다.
  /// 그래서 mounted 여부와 무관하게 setUser까지 끝낸다.
  Future<void> _completeLogin(UserProvider userProvider, AppUser user) async {
    // 자동완성 컨텍스트를 닫아 OS 비밀번호 관리자가 저장·갱신을 제안할 수 있게
    // 한다 — AutofillGroup만 선언하고 이걸 호출하지 않으면 힌트가 반쪽이 된다.
    TextInput.finishAutofillContext();
    await userProvider.setUser(user);
    unawaited(FcmService.instance.initWithRationale());
    _popToLoginCaller();
  }

  /// 로그인 완료 후 뒤에 있던 (이제 로그인된) 화면이 드러나도록 이 화면을 닫는다.
  /// pop 결과 `true`는 `openLoginScreen` 호출부가 원래 하려던 동작을 이어서
  /// 실행하는 신호로 쓰인다(의도 보존).
  ///
  /// 이 화면은 항상 `openLoginScreen`으로 루트 네비게이터에 push되므로 실제로는
  /// 늘 pop 대상이 있다.
  void _popToLoginCaller() {
    if (!mounted) return;
    popRouteWithResult(context, true);
  }

  Future<void> _loginWithEmail() async {
    // 비밀번호 필드의 onSubmitted(키보드 '완료')는 버튼을 감싼 IgnorePointer
    // 밖이고 AppTextField에는 enabled가 없어 로딩 중에도 다시 들어올 수 있다.
    // 토큰 교환이 두 번 일어나면 백엔드가 유저당 리프레시 토큰을 1개만 유지하므로
    // 나중에 저장된 쪽이 이미 무효화된 토큰일 수 있다(로그인 직후 세션 끊김).
    if (_isAnyLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    final emailErr = EmailValidator.validate(email);
    final passwordErr = password.isEmpty ? 'enter_password'.tr() : null;
    if (emailErr != null || passwordErr != null) {
      setState(() { _emailError = emailErr; _passwordError = passwordErr; });
      return;
    }

    setState(() { _loadingMethod = _LoginMethod.email; _clearErrors(); });
    // 서버 왕복 전에 캡처 — 교환 중 화면을 닫아도 로그인을 마무리한다([_completeLogin]).
    final userProvider = context.read<UserProvider>();
    try {
      final user = await AuthService.instance.loginWithEmail(email, password);
      await _completeLogin(userProvider, user);
    } on EmailNotVerifiedException catch (e) {
      await _openVerifyEmail(email, verificationEmailSent: e.verificationEmailSent);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = AuthService.instance.firebaseErrorKey(e.code).tr();
      if (e.code == 'invalid-email') {
        setState(() => _emailError = msg);
      } else {
        setState(() => _authError = msg);
      }
    } on AgeRestrictedException {
      _showAgeRestrictedMessage();
    } catch (e) {
      _showLoginFailure(_LoginMethod.email, e);
    } finally {
      if (mounted) setState(() => _loadingMethod = null);
    }
  }

  /// 미인증 계정 — 인증 화면으로 보내고, 인증까지 끝난 사용자를 받아오면 로그인을
  /// 마무리한다. 인증 화면이 올라가 있는 동안 이 화면을 로딩 상태로 잡아두지
  /// 않는다(뒤로가기로 돌아오면 버튼이 계속 돌고 있는 것처럼 보인다).
  Future<void> _openVerifyEmail(
    String email, {
    required bool verificationEmailSent,
  }) async {
    if (!mounted) return;
    setState(() => _loadingMethod = null);
    await _pushAuthFlow(VerifyEmailScreen(
      email: email,
      verificationEmailSent: verificationEmailSent,
    ));
  }

  Future<void> _openSignup() =>
      guardedNavigate(() => _pushAuthFlow(const SignupScreen()));

  Future<void> _openForgotPassword() => guardedNavigate(() => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => ForgotPasswordScreen(
            initialEmail: emailController.text.trim(),
          ),
        ),
      ));

  /// 인증 흐름 화면(가입·이메일 인증)을 push하고, 인증까지 끝난 사용자를 돌려받으면
  /// 로그인을 마무리한다 — 스택 정리를 중간 화면에 맡기지 않는 이유는
  /// [AuthFlowResult] 주석 참고.
  Future<void> _pushAuthFlow(Widget screen) async {
    // push 전에 캡처 — 인증 화면에서 돌아온 뒤엔 이 State가 살아 있지 않을 수
    // 있다([_completeLogin]).
    final userProvider = context.read<UserProvider>();
    final result = await Navigator.push<AuthFlowResult>(
      context,
      SlideRoute<AuthFlowResult>(builder: (_) => screen),
    );
    final user = result?.user;
    if (user == null) return;
    try {
      await _completeLogin(userProvider, user);
    } catch (e) {
      // 이 호출은 버튼 콜백에서 fire-and-forget으로 시작돼 예외를 받아줄 곳이
      // 없다 — 소셜 경로(_runSocialLogin)와 같은 문구로 화면에 표시한다.
      _showLoginFailure(_LoginMethod.email, e);
    }
  }

  /// 만 14세 미만으로 계정이 이미 파기된 사용자의 재로그인 시도 — 최초 나이확인
  /// 거부와 동일한 안내 문구를 보여준다 (일반 로그인 실패와 구분).
  void _showAgeRestrictedMessage() {
    if (mounted) setState(() => _authError = 'age_gate_restricted_message'.tr());
  }

  void _showLoginFailure(_LoginMethod method, Object error) {
    debugPrint('[Auth] ${method.name} 로그인 실패: $error');
    if (mounted) setState(() => _authError = 'login_failed'.tr());
  }

  /// 소셜 로그인 3종(Apple/Google/Kakao)의 공통 흐름: 로딩 체크 → provider
  /// 캡처 → 로그인 → 취소 예외는 무시, 그 외 실패는 공통 에러 표시.
  Future<void> _runSocialLogin({
    required _LoginMethod method,
    required Future<AppUser> Function() login,
    required bool Function(Object error) isCanceled,
  }) async {
    if (_isAnyLoading) return;
    // async gap 전에 캡처 — OAuth 시트/브라우저 복귀 시 mounted가 false일 수 있음
    final userProvider = context.read<UserProvider>();
    setState(() {
      _loadingMethod = method;
      _clearErrors();
    });
    try {
      final user = await login();
      await _completeLogin(userProvider, user);
    } on AgeRestrictedException {
      _showAgeRestrictedMessage();
    } catch (e) {
      if (isCanceled(e)) {
        debugPrint('[Auth] ${method.name} 로그인 취소');
      } else {
        _showLoginFailure(method, e);
      }
    } finally {
      if (mounted) setState(() => _loadingMethod = null);
    }
  }

  Future<void> signInWithApple() => _runSocialLogin(
    method: _LoginMethod.apple,
    login: AuthService.instance.loginWithApple,
    isCanceled: (e) =>
        e is SignInWithAppleAuthorizationException &&
        e.code == AuthorizationErrorCode.canceled,
  );

  Future<void> signInWithGoogle() => _runSocialLogin(
    method: _LoginMethod.google,
    login: AuthService.instance.loginWithGoogle,
    isCanceled: (e) =>
        e is GoogleSignInException &&
        e.code == GoogleSignInExceptionCode.canceled,
  );

  /// 카카오톡 앱/커스텀탭을 그냥 닫으면 `PlatformException(CANCELED)`, 웹 로그인
  /// 동의 화면에서 [취소]를 누르면 리다이렉트에 `error=access_denied`가 실려
  /// `KakaoAuthException`이 온다 — 둘 다 사용자가 그만둔 것이므로 에러 문구를
  /// 띄우지 않는다.
  Future<void> signInWithKakao() => _runSocialLogin(
    method: _LoginMethod.kakao,
    login: AuthService.instance.loginWithKakao,
    isCanceled: (e) =>
        (e is PlatformException && e.code == 'CANCELED') ||
        (e is KakaoAuthException && e.error == AuthErrorCause.accessDenied),
  );
}

/// 소셜 로그인 원형 아이콘 버튼. [otherLoading]은 다른 수단의 로그인이 진행
/// 중이라는 뜻으로, 이 버튼을 흐리게 표시하고 탭을 막는다.
class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.label,
    required this.isLoading,
    required this.otherLoading,
    required this.backgroundColor,
    required this.indicatorColor,
    required this.onPressed,
    required this.child,
    this.borderColor,
  });

  final String label;
  final bool isLoading;
  final bool otherLoading;
  final Color backgroundColor;
  final Color? borderColor;
  final Color indicatorColor;
  final VoidCallback onPressed;
  final Widget child;

  static const _size = 50.0;

  bool get _disabled => isLoading || otherLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: IgnorePointer(
        ignoring: _disabled,
        child: Opacity(
          opacity: otherLoading ? 0.5 : 1.0,
          child: Material(
            color: backgroundColor,
            shape: CircleBorder(
              side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none,
            ),
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
