import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/user_stats_model.dart';
import 'package:feple/screen/main/tab/my_page/w_my_liked_posts.dart';
import 'package:feple/screen/main/tab/my_page/w_my_post_comment.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserActivityService extends Mock implements UserActivityService {}

UserStats _stats({
  int postCount = 1,
  int commentCount = 2,
  int certificationCount = 3,
  int scrapCount = 4,
  int likedPostCount = 5,
}) {
  return UserStats(
    postCount: postCount,
    commentCount: commentCount,
    certificationCount: certificationCount,
    scrapCount: scrapCount,
    likedPostCount: likedPostCount,
  );
}

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
          child: const MaterialApp(
            home: Scaffold(body: MyPostCommentView(userId: 1)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('MyPostCommentView 로딩', () {
    testWidgets('통계 조회 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<UserStats>();
      when(() => mockService.fetchStats(1)).thenAnswer((_) => completer.future);

      await pump(tester);

      expect(find.text('posts'.tr()), findsNothing);

      completer.complete(_stats());
      await tester.pump();
    });
  });

  group('MyPostCommentView 렌더링', () {
    testWidgets('통계 수치를 보여준다', (tester) async {
      when(() => mockService.fetchStats(1)).thenAnswer(
        (_) async => _stats(
          postCount: 11,
          commentCount: 22,
          certificationCount: 33,
          scrapCount: 44,
          likedPostCount: 55,
        ),
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('11'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.text('33'), findsOneWidget);
      expect(find.text('44'), findsOneWidget);
      expect(find.text('55'), findsOneWidget);
    });
  });

  group('MyPostCommentView 에러', () {
    testWidgets('조회 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchStats(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return _stats(postCount: 9);
      });

      await pump(tester);
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pump();

      expect(find.text('9'), findsOneWidget);
    });
  });

  group('MyPostCommentView 네비게이션', () {
    testWidgets('좋아요한 글 카드를 탭하면 해당 화면으로 이동한다', (tester) async {
      when(() => mockService.fetchStats(1)).thenAnswer((_) async => _stats());
      when(() => mockService.fetchLikedPosts(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('liked_posts'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(MyLikedPostsView), findsOneWidget);
    });
  });
}
