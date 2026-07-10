import 'dart:typed_data';
import 'package:feple/common/util/image_upload_helper.dart';
import 'package:feple/model/my_certification_status.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/model/festival_rating_summary.dart';
import 'package:feple/model/festival_review_page.dart';
import 'package:feple/network/dio_client.dart';

class CertificationService {
  /// 인증 사진 업로드 → 서버에 인증 신청
  Future<void> submit({
    required int festivalId,
    required Uint8List imageData,
  }) async {
    final presign = await ImageUploadHelper.compressAndUpload(
      presignEndpoint: '/certifications/presign',
      imageData: imageData,
    );
    await DioClient.dio.post(
      '/certifications',
      data: {
        'festivalId': festivalId,
        'photoKey': presign.objectKey,
      },
    );
  }

  /// 타 유저의 승인된 인증 뱃지 목록 조회 (공개)
  Future<List<CertificationModel>> getPublicCertifications(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/certifications');
    return (response.data as List)
        .cast<Map<String, dynamic>>()
        .map(CertificationModel.fromJson)
        .toList();
  }

  /// 내 인증 목록 조회
  Future<List<CertificationModel>> getMyCertifications() async {
    final response = await DioClient.dio.get('/certifications');
    return (response.data as List)
        .cast<Map<String, dynamic>>()
        .map(CertificationModel.fromJson)
        .toList();
  }

  /// 특정 페스티벌의 인증 상태 및 내 별점 정보 단건 조회
  Future<MyCertificationStatus> getCertState(int festivalId) async {
    final response = await DioClient.dio.get(
      '/certifications/cert-state',
      queryParameters: {'festivalId': festivalId},
    );
    return MyCertificationStatus.fromJson(response.data as Map<String, dynamic>);
  }

  /// 인증된 페스티벌에 별점 및 한줄 후기 제출
  Future<void> submitRating(int certId, int rating, String? review) async {
    await DioClient.dio.put(
      '/certifications/$certId/rating',
      data: {'rating': rating, 'review': review},
    );
  }

  /// 페스티벌 리뷰 목록 + 별점 통계 조회 (별점 시트용)
  Future<FestivalReviewPage> getFestivalReviews(int festivalId, {int page = 0}) async {
    final response = await DioClient.dio.get(
      '/certifications/festival/$festivalId/reviews',
      queryParameters: {'page': page},
    );
    return FestivalReviewPage.fromJson(response.data as Map<String, dynamic>);
  }

  /// 리뷰 추천 토글 — true: 추천됨, false: 취소됨
  Future<bool> toggleReviewLike(int reviewId) async {
    final response = await DioClient.dio.post('/certifications/$reviewId/review-like');
    return response.data['liked'] as bool;
  }

  /// 페스티벌의 평균 별점 및 평가 수 조회
  Future<FestivalRatingSummary> getFestivalRating(int festivalId) async {
    final response = await DioClient.dio.get('/certifications/festival/$festivalId/rating');
    return FestivalRatingSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
