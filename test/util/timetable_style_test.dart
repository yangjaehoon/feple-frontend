import 'package:feple/common/constant/timetable_colors.dart';
import 'package:feple/screen/main/tab/search/festival_information/timetable_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timetableStageColor', () {
    test('stages 리스트 내 위치에 따라 순환 배정된다', () {
      final stages = ['메인', '서브', '인디'];

      expect(timetableStageColor('메인', stages), kStageColors[0]);
      expect(timetableStageColor('서브', stages), kStageColors[1]);
      expect(timetableStageColor('인디', stages), kStageColors[2]);
    });

    test('stages 개수가 색상 개수를 초과하면 순환한다', () {
      final stages = List.generate(kStageColors.length + 2, (i) => 'stage$i');

      expect(
        timetableStageColor('stage${kStageColors.length}', stages),
        kStageColors[0],
      );
      expect(
        timetableStageColor('stage${kStageColors.length + 1}', stages),
        kStageColors[1],
      );
    });

    test('목록에 없는 stage면 indexOf(-1)을 kStageColors 길이로 나눈 나머지 색상을 반환한다', () {
      // Dart의 %는 음수 피연산자에도 항상 0 이상을 반환하므로
      // -1 % kStageColors.length는 kStageColors.length - 1이 된다
      final stages = ['메인', '서브'];

      expect(
        timetableStageColor('없는스테이지', stages),
        kStageColors[kStageColors.length - 1],
      );
    });
  });
}
