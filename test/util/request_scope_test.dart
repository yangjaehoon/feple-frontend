import 'package:dio/dio.dart';
import 'package:feple/common/util/request_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('스코프 밖에서는 ambientCancelToken이 null', () {
    expect(ambientCancelToken, isNull);
  });

  test('withCancelScope 안에서는 해당 토큰이 노출된다', () async {
    final token = CancelToken();
    CancelToken? seen;
    await withCancelScope(token, () async {
      seen = ambientCancelToken;
    });
    expect(identical(seen, token), true);
    expect(ambientCancelToken, isNull); // 밖으로 나오면 사라짐
  });

  test('await 체인을 건너도 토큰이 전파된다', () async {
    final token = CancelToken();
    Future<CancelToken?> deep() async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      return ambientCancelToken;
    }

    expect(identical(await withCancelScope(token, deep), token), true);
  });
}
