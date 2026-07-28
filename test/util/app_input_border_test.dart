import 'package:feple/common/widget/app_input_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appInputBorder', () {
    test('지정한 색상과 두께로 OutlineInputBorder를 생성한다', () {
      final border = appInputBorder(Colors.red, width: 2);

      expect(border.borderSide.color, Colors.red);
      expect(border.borderSide.width, 2);
    });

    test('width를 생략하면 기본값 1을 사용한다', () {
      final border = appInputBorder(Colors.blue);

      expect(border.borderSide.width, 1);
    });
  });
}
