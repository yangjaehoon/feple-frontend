import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_level_badge.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/my_page/w_edit_profile.dart';
import 'package:feple/screen/main/tab/my_page/w_profile.dart';
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
  String nickname = '테스터',
  String? bio,
  String? level,
  String? profileImageUrl,
}) {
  return AppUser(
    id: id,
    nickname: nickname,
    bio: bio,
    level: level,
    profileImageUrl: profileImageUrl,
  );
}

void _setupSecureStorageMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'read':
          return null;
        default:
          return null;
      }
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserService mockUserService;

  setUp(() {
    mockUserService = MockUserService();
    _setupSecureStorageMock();
    // EditProfileWidget 안의 NicknameField가 필드 초기화 시점에 sl<UserService>()를
    // 동기적으로 조회하므로, 편집 화면 이동 테스트를 위해 등록해둔다
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

  Future<UserProvider> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    final provider = UserProvider(mockUserService);

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
            child: const MaterialApp(
              home: Scaffold(body: ProfileWidget(userId: 1)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return provider;
  }

  group('ProfileWidget 로딩', () {
    testWidgets('조회 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<AppUser>();
      when(() => mockUserService.fetchUser(1)).thenAnswer((_) => completer.future);

      await pump(tester);

      expect(find.byType(SkeletonBox), findsWidgets);

      completer.complete(_user());
      await tester.pump();
    });
  });

  group('ProfileWidget 렌더링', () {
    testWidgets('조회에 성공하면 닉네임과 레벨 뱃지를 보여준다', (tester) async {
      when(() => mockUserService.fetchUser(1))
          .thenAnswer((_) async => _user(nickname: '페플러', level: 'GOLD'));

      await pump(tester);
      await tester.pump();

      expect(find.text('페플러'), findsOneWidget);
      expect(find.byType(LevelBadge), findsOneWidget);
      expect(find.text('edit_profile'.tr()), findsOneWidget);
    });

    testWidgets('bio가 있으면 보여준다', (tester) async {
      when(() => mockUserService.fetchUser(1))
          .thenAnswer((_) async => _user(bio: '안녕하세요 반갑습니다'));

      await pump(tester);
      await tester.pump();

      expect(find.text('안녕하세요 반갑습니다'), findsOneWidget);
    });

    testWidgets('bio가 없으면 표시하지 않는다', (tester) async {
      when(() => mockUserService.fetchUser(1)).thenAnswer((_) async => _user());

      await pump(tester);
      await tester.pump();

      expect(find.text('안녕하세요 반갑습니다'), findsNothing);
    });
  });

  group('ProfileWidget 에러', () {
    testWidgets('캐시된 사용자가 없는 상태에서 조회 실패하면 에러 상태를 보여준다', (tester) async {
      when(() => mockUserService.fetchUser(1)).thenThrow(Exception('네트워크 오류'));

      await pump(tester);
      await tester.pump();

      expect(find.text('load_error'.tr()), findsOneWidget);
    });

    testWidgets('에러 상태에서 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockUserService.fetchUser(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return _user(nickname: '복구됨');
      });

      await pump(tester);
      await tester.pump();
      expect(find.text('load_error'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('복구됨'), findsOneWidget);
    });

    testWidgets('이미 캐시된 사용자가 있는 상태에서 새로고침 실패하면 화면 대신 스낵바만 보여준다', (tester) async {
      final callCount = <int>[0];
      when(() => mockUserService.fetchUser(1)).thenAnswer((_) async {
        callCount[0]++;
        if (callCount[0] == 1) return _user(nickname: '기존 유저');
        throw Exception('새로고침 실패');
      });

      final provider = await pump(tester);
      await tester.pump();
      expect(find.text('기존 유저'), findsOneWidget);

      final state = tester.state<ProfileWidgetState>(find.byType(ProfileWidget));
      unawaited(state.refreshSection());
      await tester.pump();

      expect(find.text('기존 유저'), findsOneWidget); // 화면은 유지
      expect(find.text('load_error'.tr()), findsNothing);
      expect(provider.user?.nickname, '기존 유저');
    });
  });

  group('ProfileWidget 프로필 편집', () {
    testWidgets('편집 버튼을 탭하면 편집 화면으로 이동을 시도한다', (tester) async {
      when(() => mockUserService.fetchUser(1)).thenAnswer((_) async => _user());

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('edit_profile'.tr()));
      await tester.pump(const Duration(milliseconds: 300)); // 화면 전환 애니메이션

      // 전환 애니메이션 중간이라 기본 skipOffstage(true)로는 못 찾음
      expect(
        find.byType(EditProfileWidget, skipOffstage: false),
        findsOneWidget,
      );
    });
  });
}
