import 'package:feple/model/certification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CertStatus.fromValue', () {
    test('APPROVED → CertStatus.approved', () {
      expect(CertStatus.fromValue('APPROVED'), CertStatus.approved);
    });

    test('PENDING → CertStatus.pending', () {
      expect(CertStatus.fromValue('PENDING'), CertStatus.pending);
    });

    test('REJECTED → CertStatus.rejected', () {
      expect(CertStatus.fromValue('REJECTED'), CertStatus.rejected);
    });

    test('알 수 없는 값 → CertStatus.pending 폴백', () {
      expect(CertStatus.fromValue('UNKNOWN'), CertStatus.pending);
    });

    test('null → CertStatus.pending 폴백', () {
      expect(CertStatus.fromValue(null), CertStatus.pending);
    });
  });

  group('CertificationModel.fromJson', () {
    test('정상 필드 파싱', () {
      final json = {
        'festivalId': 1,
        'status': 'APPROVED',
        'festivalTitle': '록페스티벌',
        'festivalPosterUrl': 'https://example.com/poster.jpg',
        'rejectionMessage': null,
        'createdAt': '2025-08-01T12:00:00',
      };

      final model = CertificationModel.fromJson(json);

      expect(model.festivalId, 1);
      expect(model.status, CertStatus.approved);
      expect(model.festivalTitle, '록페스티벌');
      expect(model.posterUrl, 'https://example.com/poster.jpg');
      expect(model.rejectionMessage, isNull);
    });

    test('festivalPosterUrl null이면 photoUrl 폴백', () {
      final json = {
        'festivalId': 2,
        'status': 'PENDING',
        'festivalTitle': '페스티벌',
        'festivalPosterUrl': null,
        'photoUrl': 'https://example.com/photo.jpg',
        'createdAt': null,
      };

      final model = CertificationModel.fromJson(json);

      expect(model.posterUrl, 'https://example.com/photo.jpg');
    });

    test('둘 다 null이면 posterUrl null', () {
      final json = {
        'festivalId': 3,
        'status': 'REJECTED',
        'festivalTitle': '페스티벌',
        'festivalPosterUrl': null,
        'photoUrl': null,
        'createdAt': null,
      };

      final model = CertificationModel.fromJson(json);

      expect(model.posterUrl, isNull);
    });

    test('null 필드 기본값 적용', () {
      final json = {
        'festivalId': null,
        'status': null,
        'festivalTitle': null,
        'festivalPosterUrl': null,
        'photoUrl': null,
        'rejectionMessage': null,
        'createdAt': null,
      };

      final model = CertificationModel.fromJson(json);

      expect(model.festivalId, 0);
      expect(model.status, CertStatus.pending);
      expect(model.festivalTitle, '');
      expect(model.posterUrl, isNull);
    });
  });

  group('CertificationModel.formattedDate', () {
    test('createdAt null이면 null 반환', () {
      const model = CertificationModel(
        id: 1,
        festivalId: 1,
        status: CertStatus.approved,
        festivalTitle: '페스티벌',
        createdAt: null,
      );

      expect(model.formattedDate, isNull);
    });

    test('10자 이상이면 앞 10자(날짜 부분)만 반환', () {
      const model = CertificationModel(
        id: 1,
        festivalId: 1,
        status: CertStatus.approved,
        festivalTitle: '페스티벌',
        createdAt: '2025-08-01T12:00:00',
      );

      expect(model.formattedDate, '2025-08-01');
    });

    test('10자 미만이면 그대로 반환', () {
      const model = CertificationModel(
        id: 1,
        festivalId: 1,
        status: CertStatus.approved,
        festivalTitle: '페스티벌',
        createdAt: '2025-08',
      );

      expect(model.formattedDate, '2025-08');
    });

    test('정확히 10자이면 그대로 반환', () {
      const model = CertificationModel(
        id: 1,
        festivalId: 1,
        status: CertStatus.approved,
        festivalTitle: '페스티벌',
        createdAt: '2025-08-01',
      );

      expect(model.formattedDate, '2025-08-01');
    });
  });
}
