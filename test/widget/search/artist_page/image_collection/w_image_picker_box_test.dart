import 'dart:typed_data';

import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_picker_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1x1 투명 PNG
final _validPngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<void> _pump(
  WidgetTester tester, {
  Uint8List? imageData,
  required VoidCallback onTap,
  String? label,
}) async {
  await tester.pumpWidget(
    CustomThemeHolder(
      theme: CustomTheme.light,
      changeTheme: (_) {},
      child: MaterialApp(
        home: Scaffold(
          body: ImagePickerBox(imageData: imageData, onTap: onTap, label: label),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ImagePickerBox 렌더링', () {
    testWidgets('이미지가 없으면 안내 라벨과 아이콘을 보여준다', (tester) async {
      await _pump(tester, onTap: () {}, label: '사진 추가');

      expect(find.text('사진 추가'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate_rounded), findsOneWidget);
    });

    testWidgets('이미지가 있으면 미리보기와 변경 뱃지를 보여준다', (tester) async {
      await _pump(tester, imageData: _validPngBytes, onTap: () {});

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    });
  });

  group('ImagePickerBox 탭', () {
    testWidgets('탭하면 onTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(tester, onTap: () => tapped = true);

      await tester.tap(find.byType(ImagePickerBox));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
