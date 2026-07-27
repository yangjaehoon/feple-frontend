import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/my_page/w_my_scraps.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockScrapService extends Mock implements ScrapService {}

Post _post({int id = 1, String title = '글', String boardDisplayName = '자유 게시판'}) =>
    Post(
      id: id,
      title: title,
      content: '내용',
      likeCount: 5,
      commentCount: 1,
      nickname: '작성자',
      boardDisplayName: boardDisplayName,
    );

void main() {
  late MockScrapService mockService;

  setUp(() {
    mockService = MockScrapService();
    if (sl.isRegistered<ScrapService>()) sl.unregister<ScrapService>();
    sl.registerSingleton<ScrapService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<ScrapService>()) sl.unregister<ScrapService>();
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
          child: const MaterialApp(home: MyScrapsView()),
        ),
      ),
    );
    await tester.pump();
  }

  group('MyScrapsView 렌더링', () {
    testWidgets('제목과 스크랩 목록을 보여준다', (tester) async {
      when(() => mockService.fetchMyScraps()).thenAnswer(
        (_) async => [_post(id: 1, title: '스크랩한 글1'), _post(id: 2, title: '스크랩한 글2')],
      );

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('my_scraps'.tr()), findsOneWidget);
      expect(find.text('스크랩한 글1'), findsOneWidget);
      expect(find.text('스크랩한 글2'), findsOneWidget);
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchMyScraps()).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('no_scraps'.tr()), findsOneWidget);
    });

    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchMyScraps()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_post(title: '복구된 스크랩')];
      });

      await pump(tester);
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('복구된 스크랩'), findsOneWidget);
    });
  });
}
