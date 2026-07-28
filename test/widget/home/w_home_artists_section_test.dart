import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/home/w_home_artists_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FollowedArtist _artist({int id = 1, String name = '아티스트'}) =>
    FollowedArtist(id: id, name: name, nameEn: '');

Future<void> _pump(
  WidgetTester tester, {
  List<FollowedArtist>? artists,
  void Function(FollowedArtist)? onTap,
  Object? error,
  VoidCallback? onRetry,
  VoidCallback? onShowMore,
}) async {
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
        child: MaterialApp(
          home: Scaffold(
            body: HomeArtistsSection(
              artists: artists,
              onTap: onTap ?? (_) {},
              error: error,
              onRetry: onRetry,
              onShowMore: onShowMore,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('HomeArtistsSection 렌더링', () {
    testWidgets('artists가 null이면 스켈레톤을 보여준다', (tester) async {
      await _pump(tester, artists: null);

      expect(find.byType(SkeletonBox), findsWidgets);
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      await _pump(tester, artists: []);

      expect(find.text('no_followed_artists'.tr()), findsOneWidget);
    });

    testWidgets('아티스트 목록을 보여준다', (tester) async {
      await _pump(tester, artists: [_artist(name: '팔로우한아티스트')]);

      expect(find.text('팔로우한아티스트'), findsOneWidget);
    });

    testWidgets('에러가 있으면 에러 상태를 보여준다', (tester) async {
      await _pump(tester, artists: [_artist()], error: Exception('네트워크 오류'));

      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('아티스트'), findsNothing);
    });

    testWidgets('10명을 초과하면 더보기 항목을 보여준다', (tester) async {
      await _pump(
        tester,
        artists: List.generate(12, (i) => _artist(id: i, name: '아티스트$i')),
        onShowMore: () {},
      );
      await tester.drag(find.byType(ListView), const Offset(-2000, 0));
      await tester.pump();

      expect(find.text('+2'), findsOneWidget);
    });
  });

  group('HomeArtistsSection 탭', () {
    testWidgets('아티스트를 탭하면 onTap이 호출된다', (tester) async {
      FollowedArtist? tapped;
      await _pump(
        tester,
        artists: [_artist(id: 5, name: '탭할아티스트')],
        onTap: (a) => tapped = a,
      );

      await tester.tap(find.text('탭할아티스트'));
      await tester.pump();

      expect(tapped?.id, 5);
    });

    testWidgets('더보기를 탭하면 onShowMore가 호출된다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        artists: List.generate(12, (i) => _artist(id: i, name: '아티스트$i')),
        onShowMore: () => tapped = true,
      );

      await tester.drag(find.byType(ListView), const Offset(-2000, 0));
      await tester.pump();
      await tester.tap(find.text('+2'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
