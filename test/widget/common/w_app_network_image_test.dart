import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

void main() {
  group('AppNetworkImage 빈 URL', () {
    testWidgets('imageUrl이 null이면 에러 아이콘을 보여준다', (tester) async {
      await pumpCommonWidget(tester, const AppNetworkImage(imageUrl: null));

      expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('imageUrl이 빈 문자열이면 에러 아이콘을 보여준다', (tester) async {
      await pumpCommonWidget(tester, const AppNetworkImage(imageUrl: ''));

      expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
    });

    testWidgets('errorIcon/errorIconSize를 지정하면 반영된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const AppNetworkImage(
          imageUrl: null,
          errorIcon: Icons.person,
          errorIconSize: 40,
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.person));
      expect(icon.size, 40);
    });
  });

  group('AppNetworkImage 유효한 URL', () {
    testWidgets('CachedNetworkImage에 fit/width/height가 전달된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const AppNetworkImage(
          imageUrl: 'https://example.com/a.png',
          fit: BoxFit.contain,
          width: 50,
          height: 60,
        ),
      );

      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.imageUrl, 'https://example.com/a.png');
      expect(image.fit, BoxFit.contain);
      expect(image.width, 50);
      expect(image.height, 60);
      expect(image.memCacheWidth, 100);
    });

    testWidgets('width 미지정 시 memCacheWidth 기본값은 400이다', (tester) async {
      await pumpCommonWidget(
        tester,
        const AppNetworkImage(imageUrl: 'https://example.com/a.png'),
      );

      final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.memCacheWidth, 400);
    });

    testWidgets('borderRadius를 지정하면 ClipRRect로 감싼다', (tester) async {
      await pumpCommonWidget(
        tester,
        const AppNetworkImage(
          imageUrl: 'https://example.com/a.png',
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('semanticsLabel을 지정하면 Semantics로 감싼다', (tester) async {
      await pumpCommonWidget(
        tester,
        const AppNetworkImage(
          imageUrl: 'https://example.com/a.png',
          semanticsLabel: '프로필 사진',
        ),
      );

      expect(find.bySemanticsLabel('프로필 사진'), findsOneWidget);
    });

    testWidgets('excludeFromSemantics=true면 시맨틱스에서 제외된다', (tester) async {
      await pumpCommonWidget(
        tester,
        const AppNetworkImage(
          imageUrl: 'https://example.com/a.png',
          semanticsLabel: '프로필 사진',
          excludeFromSemantics: true,
        ),
      );

      expect(find.bySemanticsLabel('프로필 사진'), findsNothing);
    });
  });
}
