import 'package:dio/dio.dart';
import 'package:feple/common/util/response_parsing.dart';
import 'package:feple/model/app_config_model.dart';
import 'package:feple/network/dio_client.dart';

/// 앱 전역 설정(`GET /app/config`) 조회. 로그인 없이 콜드스타트에서 호출된다.
class AppConfigService {
  Future<AppConfigModel> fetch() async {
    // 점검·강제 업데이트 판단은 항상 서버의 현재 상태를 봐야 한다 — SWR 캐시가
    // 낡은 maintenance:true / 높은 minSupportedVersion을 돌려주면 서버가 이미
    // 해제했는데도 사용자가 앱에 못 들어가게 된다.
    final response = await DioClient.dio.get(
      '/app/config',
      options: Options(extra: const {'refresh': true}),
    );
    return AppConfigModel.fromJson(extractJsonMap(response.data));
  }
}
