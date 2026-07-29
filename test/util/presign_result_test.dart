import 'package:feple/model/presign_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PresignResult.fromJson', () {
    test('uploadUrl과 objectKey를 파싱한다', () {
      final result = PresignResult.fromJson({
        'uploadUrl': 'https://s3.example.com/upload',
        'objectKey': 'images/abc.jpg',
      });

      expect(result.uploadUrl, 'https://s3.example.com/upload');
      expect(result.objectKey, 'images/abc.jpg');
    });
  });
}
