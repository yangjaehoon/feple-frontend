import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_circle_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? imageUrl,
  required bool isFollowed,
}) async {
  await tester.pumpWidget(
    CustomThemeHolder(
      theme: CustomTheme.light,
      changeTheme: (_) {},
      child: MaterialApp(
        home: Scaffold(
          body: ArtistCircleImage(imageUrl: imageUrl, isFollowed: isFollowed),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ArtistCircleImage 렌더링', () {
    testWidgets('이미지 URL이 없으면 기본 아이콘을 보여준다', (tester) async {
      await _pump(tester, imageUrl: null, isFollowed: false);

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('이미지 URL이 빈 문자열이면 기본 아이콘을 보여준다', (tester) async {
      await _pump(tester, imageUrl: '', isFollowed: false);

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('팔로우하지 않은 경우 일반 원형 컨테이너를 보여준다', (tester) async {
      await _pump(tester, isFollowed: false);

      expect(find.byType(ArtistCircleImage), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('팔로우한 경우 그라디언트 테두리가 있는 컨테이너를 보여준다', (tester) async {
      await _pump(tester, isFollowed: true);

      expect(find.byType(ArtistCircleImage), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any(
        (c) => (c.decoration as BoxDecoration?)?.gradient != null,
      );
      expect(hasGradient, isTrue);
    });
  });
}
