import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/my_page/w_my_liked_posts.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserActivityService extends Mock implements UserActivityService {}

Post _post({int id = 1, String title = '글', String boardDisplayName = '자유 게시판'}) =>
    Post(
      id: id,
      title: title,
      content: '내용',
      likeCount: 3,
      commentCount: 2,
      nickname: '작성자',
      boardDisplayName: boardDisplayName,
    );

void main() {
  late MockUserActivityService mockService;

  setUp(() {
    mockService = MockUserActivityService();
    if (sl.isRegistered<UserActivityService>()) {
      sl.unregister<UserActivityService>();
    }
    sl.registerSingleton<UserActivityService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<UserActivityService>()) {
      sl.unregister<UserActivityService>();
    }
  });

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

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
          child: const MaterialApp(home: MyLikedPostsView(userId: 1)),
        ),
      ),
    );
    await tester.pump();
  }

  group('MyLikedPostsView 렌더링', () {
    testWidgets('제목과 좋아요한 글 목록을 보여준다', (tester) async {
      when(() => mockService.fetchLikedPosts(1)).thenAnswer(
        (_) async => [_post(id: 1, title: '좋아요한 글1'), _post(id: 2, title: '좋아요한 글2')],
      );

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('my_liked_posts'.tr()), findsOneWidget);
      expect(find.text('좋아요한 글1'), findsOneWidget);
      expect(find.text('좋아요한 글2'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // 좋아요 수
      expect(find.text('2'), findsWidgets); // 댓글 수
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchLikedPosts(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('no_liked_posts'.tr()), findsOneWidget);
    });
  });
}
