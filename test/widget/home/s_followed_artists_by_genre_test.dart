import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/home/s_followed_artists_by_genre.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FollowedArtist _artist({int id = 1, String name = '아티스트', String? genre}) =>
    FollowedArtist(id: id, name: name, genre: genre);

Future<void> _pump(
  WidgetTester tester, {
  required List<FollowedArtist> artists,
  Future<void> Function(List<int>)? onSaveOrder,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
          home: FollowedArtistsByGenreScreen(artists: artists, onSaveOrder: onSaveOrder),
        ),
      ),
    ),
  );
  // AnimatedListItem의 순차 지연 애니메이션이 끝날 때까지 pumpAndSettle로 대기
  await tester.pumpAndSettle();
}

void main() {
  group('FollowedArtistsByGenreScreen 렌더링', () {
    testWidgets('아티스트 카드를 보여준다', (tester) async {
      await _pump(tester, artists: [_artist(name: '팔로우한아티스트')]);

      expect(find.text('팔로우한아티스트'), findsOneWidget);
    });

    testWidgets('장르가 있으면 필터 칩을 보여준다', (tester) async {
      await _pump(tester, artists: [
        _artist(id: 1, genre: 'KPOP'),
        _artist(id: 2, genre: 'ROCK'),
      ]);

      expect(find.text('filter_all'.tr()), findsOneWidget);
      expect(find.text('KPOP'), findsOneWidget);
      expect(find.text('ROCK'), findsOneWidget);
    });

    testWidgets('장르가 없으면 필터 칩을 보여주지 않는다', (tester) async {
      await _pump(tester, artists: [_artist()]);

      expect(find.text('filter_all'.tr()), findsNothing);
    });

    testWidgets('onSaveOrder가 없으면 설정 아이콘이 없다', (tester) async {
      await _pump(tester, artists: [_artist()]);

      expect(find.byIcon(Icons.settings_rounded), findsNothing);
    });

    testWidgets('onSaveOrder가 있으면 설정 아이콘을 보여준다', (tester) async {
      await _pump(tester, artists: [_artist()], onSaveOrder: (_) async {});

      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    });
  });

  group('FollowedArtistsByGenreScreen 장르 필터', () {
    testWidgets('장르 칩을 탭하면 해당 장르만 보여준다', (tester) async {
      await _pump(tester, artists: [
        _artist(id: 1, name: '케이팝가수', genre: 'KPOP'),
        _artist(id: 2, name: '락밴드', genre: 'ROCK'),
      ]);

      await tester.tap(find.text('ROCK'));
      await tester.pumpAndSettle();

      expect(find.text('락밴드'), findsOneWidget);
      expect(find.text('케이팝가수'), findsNothing);
    });

    testWidgets('전체 칩을 탭하면 필터가 해제된다', (tester) async {
      await _pump(tester, artists: [
        _artist(id: 1, name: '케이팝가수', genre: 'KPOP'),
        _artist(id: 2, name: '락밴드', genre: 'ROCK'),
      ]);

      await tester.tap(find.text('ROCK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('filter_all'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('락밴드'), findsOneWidget);
      expect(find.text('케이팝가수'), findsOneWidget);
    });
  });

  group('FollowedArtistsByGenreScreen 순서 변경', () {
    testWidgets('설정 아이콘을 탭하면 순서 변경 시트가 열린다', (tester) async {
      await _pump(
        tester,
        artists: [_artist(name: '아티스트1')],
        onSaveOrder: (_) async {},
      );

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ReorderSheet), findsOneWidget);
    });
  });
}
