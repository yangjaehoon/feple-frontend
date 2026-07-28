import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/search/w_artist_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? profileImageUrl,
  String name = '아티스트',
  bool isFollowed = false,
}) async {
  await tester.pumpWidget(
    CustomThemeHolder(
      theme: CustomTheme.light,
      changeTheme: (_) {},
      child: MaterialApp(
        home: Scaffold(
          // 실제 사용처(GridView 셀)처럼 너비를 제한 — 무제한 너비에서는
          // AspectRatio(1.0)가 화면 높이보다 큰 정사각형을 요구해 오버플로우가 난다.
          body: SizedBox(
            width: 120,
            child: ArtistCard(
              profileImageUrl: profileImageUrl,
              name: name,
              isFollowed: isFollowed,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ArtistCard 렌더링', () {
    testWidgets('이름을 보여준다', (tester) async {
      await _pump(tester, name: '팔로우아티스트');

      expect(find.text('팔로우아티스트'), findsOneWidget);
    });

    testWidgets('이미지가 없으면 기본 아이콘을 보여준다', (tester) async {
      await _pump(tester);

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('이미지가 있으면 CachedNetworkImage를 보여준다', (tester) async {
      await _pump(tester, profileImageUrl: 'https://example.com/a.jpg');

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });
}
