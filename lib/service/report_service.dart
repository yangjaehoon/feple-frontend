import 'package:feple/model/report_reason.dart';
import 'package:feple/network/dio_client.dart';

export 'package:feple/model/report_reason.dart';

class ReportService {
  Future<void> submitReport(int postId, ReportReason reason, {String? detail}) =>
      _submit('/posts/$postId/report', reason, detail: detail);

  Future<void> submitCommentReport(int commentId, ReportReason reason, {String? detail}) =>
      _submit('/comments/$commentId/report', reason, detail: detail);

  Future<void> submitPhotoReport(int artistId, int photoId, ReportReason reason, {String? detail}) =>
      _submit('/artists/$artistId/photos/$photoId/report', reason, detail: detail);

  Future<void> _submit(String endpoint, ReportReason reason, {String? detail}) =>
      DioClient.dio.post(endpoint, data: {
        'reason': reason.name.toUpperCase(),
        if (detail != null && detail.isNotEmpty) 'detail': detail,
      });
}
