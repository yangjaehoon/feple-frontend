import 'package:feple/common/util/forced_refresh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('기본 컨텍스트에서는 강제 새로고침 Zone이 아니다', () {
    expect(isForcedRefreshZone, false);
  });

  test('withForcedRefresh 내부에서는 Zone 플래그가 true', () async {
    var seenInside = false;
    await withForcedRefresh(() async {
      seenInside = isForcedRefreshZone;
    });
    expect(seenInside, true);
    // 밖으로 나오면 다시 false
    expect(isForcedRefreshZone, false);
  });

  test('await 체인을 건너도 Zone 플래그가 전파된다', () async {
    Future<bool> deep() async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 1));
      return isForcedRefreshZone;
    }

    final result = await withForcedRefresh(deep);
    expect(result, true);
  });

  test('반환값이 그대로 전달된다', () async {
    final v = await withForcedRefresh(() async => 42);
    expect(v, 42);
  });
}
