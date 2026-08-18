import 'package:feple/model/notice_model.dart';
import 'package:feple/model/notice_page.dart';
import 'package:feple/network/dio_client.dart';

class NoticeService {
  /// 공지사항 목록 조회 (고정 공지가 항상 상단)
  Future<NoticePage> getNotices({int page = 0}) async {
    final response = await DioClient.dio.get(
      '/notices',
      queryParameters: {'page': page},
    );
    return NoticePage.fromJson(response.data as Map<String, dynamic>);
  }

  /// 공지사항 상세 조회
  Future<NoticeModel> getNotice(int id) async {
    final response = await DioClient.dio.get('/notices/$id');
    return NoticeModel.fromJson(response.data as Map<String, dynamic>);
  }
}
