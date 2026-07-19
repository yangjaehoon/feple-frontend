import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService extends Mock implements UserService {}

/// login/signup/forgot_password/verify_email 화면 테스트 공용 셋업.
/// TokenStore(flutter_secure_storage)를 목킹하지 않으면 UserProvider 생성자의
/// _loadFromSecureStorage가 플랫폼 채널 에러를 던지고(내부에서 캐치되긴 하지만)
/// 불필요한 콘솔 에러가 남으므로 빈 스토리지로 목킹해둔다.
void setUpSecureStorageMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'read':
          return null;
        case 'write':
        case 'delete':
        case 'deleteAll':
          return null;
        default:
          return null;
      }
    },
  );
}

void tearDownSecureStorageMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    null,
  );
}

Future<void> pumpLoginScreen(
  WidgetTester tester,
  Widget screen, {
  UserService? userService,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  // 로그인류 화면은 SingleChildScrollView 안에 버튼이 많아 기본 테스트 뷰포트
  // (800x600)로는 하단 버튼이 화면 밖으로 밀려 tap()이 hit-test에 실패한다.
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;

  // SignupScreen의 NicknameField 등 일부 위젯이 sl<UserService>()를 직접 사용
  final resolvedUserService = userService ?? MockUserService();
  if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
  sl.registerSingleton<UserService>(resolvedUserService);
  addTearDown(() {
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
  });

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: ChangeNotifierProvider(
        create: (_) => UserProvider(resolvedUserService),
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(home: screen),
        ),
      ),
    ),
  );
  await tester.pump();
}
