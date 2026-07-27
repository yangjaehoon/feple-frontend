import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_nickname_field.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/nickname_check_result.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/w_edit_profile.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService extends Mock implements UserService {}

AppUser _user({
  int id = 1,
  String nickname = '기존닉네임',
  String? bio,
  DateTime? nicknameChangedAt,
}) {
  return AppUser(
    id: id,
    nickname: nickname,
    bio: bio,
    nicknameChangedAt: nicknameChangedAt,
  );
}

void _setupSecureStorageMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async => null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserService mockUserService;

  setUp(() {
    mockUserService = MockUserService();
    _setupSecureStorageMock();
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    sl.registerSingleton<UserService>(mockUserService);
  });

  tearDown(() {
    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  Future<UserProvider> pump(WidgetTester tester, {required AppUser user}) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = UserProvider(mockUserService);
    when(() => mockUserService.fetchUser(user.id)).thenAnswer((_) async => user);
    await provider.fetchUser(user.id);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('en')],
        startLocale: const Locale('ko'),
        fallbackLocale: const Locale('ko'),
        path: 'assets/translations',
        useOnlyLangCode: true,
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: ChangeNotifierProvider<UserProvider>.value(
            value: provider,
            // EditProfileWidget이 화면의 유일한 route면 Navigator.pop() 시
            // ScaffoldMessenger를 포함한 전체 트리가 사라져 성공 스낵바가 보이지
            // 않으므로, 실제 사용처럼 별도 화면에서 push해 진입시킨다.
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileWidget()),
                    ),
                    child: const Text('열기'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return provider;
  }

  group('EditProfileWidget 렌더링', () {
    testWidgets('기존 닉네임/bio를 미리 채운다', (tester) async {
      await pump(tester, user: _user(nickname: '홍길동', bio: '안녕하세요'));

      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('안녕하세요'), findsOneWidget);
    });

    testWidgets('닉네임 변경 잠금 기간이 아니면 닉네임 입력 필드가 보인다', (tester) async {
      await pump(tester, user: _user());

      expect(find.byType(NicknameField), findsOneWidget);
    });

    testWidgets('닉네임 변경 후 90일 이내면 잠긴 표시와 남은 일수를 보여준다', (tester) async {
      await pump(
        tester,
        user: _user(nicknameChangedAt: DateTime.now().subtract(const Duration(days: 10))),
      );

      expect(find.byType(NicknameField), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });
  });

  group('EditProfileWidget 저장 유효성 검사', () {
    testWidgets('닉네임을 변경하고 중복확인 없이 저장하면 에러가 표시되고 저장되지 않는다', (tester) async {
      await pump(tester, user: _user(nickname: '기존닉네임'));

      await tester.enterText(find.byType(TextField).first, '새닉네임');
      await tester.pump();
      await tester.tap(find.widgetWithText(LoadingButton, 'save'.tr()));
      await tester.pump();

      expect(find.text('nickname_check_req'.tr()), findsOneWidget);
      verifyNever(() => mockUserService.updateNickname(any(), any()));
    });
  });

  group('EditProfileWidget 저장 성공', () {
    testWidgets('bio만 변경하고 저장하면 updateBio가 호출되고 화면이 닫힌다', (tester) async {
      when(() => mockUserService.updateBio(1, '새로운 소개'))
          .thenAnswer((_) async {});
      when(() => mockUserService.fetchUser(1))
          .thenAnswer((_) async => _user(bio: '새로운 소개'));

      await pump(tester, user: _user(bio: '기존 소개'));

      await tester.enterText(
        find.widgetWithText(TextField, '기존 소개'),
        '새로운 소개',
      );
      await tester.tap(find.widgetWithText(LoadingButton, 'save'.tr()));
      await tester.pumpAndSettle();

      verify(() => mockUserService.updateBio(1, '새로운 소개')).called(1);
      expect(find.text('profile_updated'.tr()), findsOneWidget);
      expect(find.byType(EditProfileWidget), findsNothing);
    });

    testWidgets('닉네임을 변경하고 중복확인에 성공하면 저장된다', (tester) async {
      when(() => mockUserService.checkNicknameAvailability('새닉네임', excludeUserId: 1))
          .thenAnswer((_) async => const NicknameCheckResult(available: true, code: 'OK'));
      when(() => mockUserService.updateNickname(1, '새닉네임')).thenAnswer((_) async {});
      when(() => mockUserService.fetchUser(1))
          .thenAnswer((_) async => _user(nickname: '새닉네임'));

      await pump(tester, user: _user(nickname: '기존닉네임'));

      await tester.enterText(find.byType(TextField).first, '새닉네임');
      await tester.pump();
      await tester.tap(find.widgetWithText(LoadingButton, 'check_duplication'.tr()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(LoadingButton, 'save'.tr()));
      await tester.pumpAndSettle();

      verify(() => mockUserService.updateNickname(1, '새닉네임')).called(1);
      expect(find.text('profile_updated'.tr()), findsOneWidget);
    });
  });

  group('EditProfileWidget 저장 실패', () {
    testWidgets('금칙어 오류면 bio 필드에 에러가 표시된다', (tester) async {
      when(() => mockUserService.updateBio(1, '금칙어 포함'))
          .thenThrow(BannedWordException('bio'));

      await pump(tester, user: _user(bio: '기존 소개'));

      await tester.enterText(
        find.widgetWithText(TextField, '기존 소개'),
        '금칙어 포함',
      );
      await tester.tap(find.widgetWithText(LoadingButton, 'save'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('bio_banned_word'.tr()), findsOneWidget);
      expect(find.byType(EditProfileWidget), findsOneWidget); // 화면 유지
    });

    testWidgets('그 외 오류면 에러 스낵바를 보여주고 화면은 유지된다', (tester) async {
      when(() => mockUserService.updateBio(1, '새로운 소개'))
          .thenThrow(Exception('네트워크 오류'));
      when(() => mockUserService.fetchUser(1))
          .thenAnswer((_) async => _user(bio: '기존 소개'));

      await pump(tester, user: _user(bio: '기존 소개'));

      await tester.enterText(
        find.widgetWithText(TextField, '기존 소개'),
        '새로운 소개',
      );
      await tester.tap(find.widgetWithText(LoadingButton, 'save'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('save_failed'.tr()), findsOneWidget);
      expect(find.byType(EditProfileWidget), findsOneWidget);
    });
  });

  group('EditProfileWidget 뒤로가기', () {
    testWidgets('변경 사항이 없으면 확인 없이 바로 닫힌다', (tester) async {
      await pump(tester, user: _user());

      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileWidget), findsNothing);
    });

    testWidgets('변경 사항이 있으면 확인 다이얼로그를 보여준다', (tester) async {
      await pump(tester, user: _user(bio: '기존 소개'));

      await tester.enterText(
        find.widgetWithText(TextField, '기존 소개'),
        '변경된 소개',
      );
      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pumpAndSettle();

      expect(find.text('discard_changes'.tr()), findsOneWidget);
      expect(find.byType(EditProfileWidget), findsOneWidget);
    });
  });
}
