import 'package:feple/model/certification_model.dart';
import 'package:feple/model/cert_state_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CertStateResult.fromJson', () {
    test('certState가 null이면 none 반환', () {
      final result = CertStateResult.fromJson({'certState': null});

      expect(result.status, isNull);
      expect(result.certId, isNull);
      expect(result.myRating, isNull);
      expect(result.myReview, isNull);
    });

    test("certState가 'NONE'이면 none 반환 (다른 필드가 있어도 무시)", () {
      final result = CertStateResult.fromJson({
        'certState': 'NONE',
        'certId': 5,
        'myRating': 4,
        'myReview': '좋아요',
      });

      expect(result.status, isNull);
      expect(result.certId, isNull);
      expect(result.myRating, isNull);
      expect(result.myReview, isNull);
    });

    test('certState가 APPROVED이면 나머지 필드도 함께 파싱', () {
      final result = CertStateResult.fromJson({
        'certState': 'APPROVED',
        'certId': 5,
        'myRating': 4,
        'myReview': '좋아요',
      });

      expect(result.status, CertStatus.approved);
      expect(result.certId, 5);
      expect(result.myRating, 4);
      expect(result.myReview, '좋아요');
    });

    test('certId/myRating이 없으면 null로 유지', () {
      final result = CertStateResult.fromJson({'certState': 'PENDING'});

      expect(result.status, CertStatus.pending);
      expect(result.certId, isNull);
      expect(result.myRating, isNull);
      expect(result.myReview, isNull);
    });

    test('알 수 없는 certState 값은 CertStatus.fromValue의 기본값(pending)으로 매핑', () {
      final result = CertStateResult.fromJson({'certState': 'UNKNOWN'});

      expect(result.status, CertStatus.pending);
    });
  });

  test('CertStateResult.none은 모든 필드가 null', () {
    expect(CertStateResult.none.status, isNull);
    expect(CertStateResult.none.certId, isNull);
    expect(CertStateResult.none.myRating, isNull);
    expect(CertStateResult.none.myReview, isNull);
  });
}
