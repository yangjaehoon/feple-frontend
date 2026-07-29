import 'package:feple/common/util/asset_json_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('LocalJson.getJsonString', () {
    test('assets 경로의 파일 내용을 문자열로 읽는다', () async {
      final result = await LocalJson.getJsonString('json/licenses.json');

      expect(result, isNotEmpty);
    });
  });

  group('LocalJson.getPackages', () {
    test('licenses.json을 Package 리스트로 파싱한다', () async {
      final packages = await LocalJson.getPackages('json/licenses.json');

      expect(packages, isNotEmpty);
    });
  });
}
