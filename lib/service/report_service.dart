import 'package:feple/model/report_reason.dart';
import 'package:feple/network/dio_client.dart';

export 'package:feple/model/report_reason.dart';

class ReportService {
  Future<void> submitReport(int postId, ReportReason reason, {String? detail}) async {
    await DioClient.dio.post('/posts/$postId/report', data: {
      'reason': reason.name.toUpperCase(),
      if (detail != null && detail.isNotEmpty) 'detail': detail,
    });
  }

  Future<void> submitCommentReport(int commentId, ReportReason reason, {String? detail}) async {
    await DioClient.dio.post('/comments/$commentId/report', data: {
      'reason': reason.name.toUpperCase(),
      if (detail != null && detail.isNotEmpty) 'detail': detail,
    });
  }

  Future<void> submitPhotoReport(int artistId, int photoId, ReportReason reason, {String? detail}) async {
    await DioClient.dio.post('/artists/$artistId/photos/$photoId/report', data: {
      'reason': reason.name.toUpperCase(),
      if (detail != null && detail.isNotEmpty) 'detail': detail,
    });
  }
}
