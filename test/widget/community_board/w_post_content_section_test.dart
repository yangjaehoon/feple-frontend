import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/community_board/w_post_content_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  String content = '내용',
  List<String> imageUrls = const [],
  void Function(int)? onImageTap,
}) async {
  await tester.pumpWidget(
    CustomThemeHolder(
      theme: CustomTheme.light,
      changeTheme: (_) {},
      child: MaterialApp(
        home: Scaffold(
          body: PostContentSection(
            content: content,
            imageUrls: imageUrls,
            onImageTap: onImageTap,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PostContentSection 렌더링', () {
    testWidgets('내용을 보여준다', (tester) async {
      await _pump(tester, content: '이것은 게시글 내용입니다');

      expect(find.text('이것은 게시글 내용입니다'), findsOneWidget);
    });

    testWidgets('imageUrls가 없으면 이미지를 보여주지 않는다', (tester) async {
      await _pump(tester);

      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('imageUrls가 있으면 이미지를 보여준다', (tester) async {
      await _pump(tester, imageUrls: const ['https://example.com/img.jpg']);

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('이미지가 여러 장이면 페이지 인디케이터를 보여준다', (tester) async {
      await _pump(
        tester,
        imageUrls: const [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
        ],
      );

      expect(find.text('1/2'), findsOneWidget);
    });
  });

  group('PostContentSection 이미지 탭', () {
    testWidgets('이미지를 탭하면 onImageTap이 인덱스와 함께 호출된다', (tester) async {
      int? tappedIndex;
      await _pump(
        tester,
        imageUrls: const ['https://example.com/img.jpg'],
        onImageTap: (i) => tappedIndex = i,
      );

      await tester.tap(find.byType(CachedNetworkImage));
      await tester.pump();

      expect(tappedIndex, 0);
    });
  });
}
