import 'dart:convert';

import 'package:feple/model/app_config_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfigModel.fromJson', () {
    test('전체 필드를 파싱한다', () {
      final json = jsonDecode('''
        {
          "minSupportedVersion": "1.2.0",
          "latestVersion": "1.3.0",
          "maintenance": true,
          "maintenanceMessage": "점검 중",
          "noticeMessage": "공지"
        }
      ''') as Map<String, dynamic>;

      final config = AppConfigModel.fromJson(json);

      expect(config.minSupportedVersion, '1.2.0');
      expect(config.latestVersion, '1.3.0');
      expect(config.maintenance, isTrue);
      expect(config.maintenanceMessage, '점검 중');
      expect(config.noticeMessage, '공지');
    });

    test('누락·빈 필드는 안전한 기본값으로 채운다', () {
      final config = AppConfigModel.fromJson(<String, dynamic>{
        'maintenanceMessage': '  ',
        'noticeMessage': '',
      });

      expect(config.minSupportedVersion, '0.0.0');
      expect(config.latestVersion, '0.0.0');
      expect(config.maintenance, isFalse);
      expect(config.maintenanceMessage, isNull);
      expect(config.noticeMessage, isNull);
    });

    test('아직 소비하지 않는 필드(features 등)가 있어도 파싱은 그대로 성공한다', () {
      final json = jsonDecode('''
        {
          "minSupportedVersion": "1.0.0",
          "latestVersion": "1.0.0",
          "maintenance": false,
          "features": {"chatEnabled": true}
        }
      ''') as Map<String, dynamic>;

      expect(() => AppConfigModel.fromJson(json), returnsNormally);
    });
  });
}
