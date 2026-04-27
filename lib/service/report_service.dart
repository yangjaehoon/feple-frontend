import 'package:feple/network/dio_client.dart';

enum ReportReason { SPAM, ABUSE, OBSCENE, MISINFORMATION, OTHER }

class ReportService {
  Future<void> submitReport(int postId, ReportReason reason, {String? detail}) async {
    await DioClient.dio.post('/posts/$postId/report', data: {
      'reason': reason.name,
      if (detail != null && detail.isNotEmpty) 'detail': detail,
    });
  }
}
