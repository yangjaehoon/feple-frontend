import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart' show DioException;
import 'package:feple/auth/token_store.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/user_service.dart';

/// 콜드스타트에 "이 사람이 누구인가"를 확정한다.
///
/// 스플래시가 기다려야 하는 건 여기까지다. 토큰이 있으면
/// [UserProvider.ready](보안 스토리지 캐시 로드) 시점에 이미 유저가 들어와
/// 있고, 네트워크 갱신은 그 프로필을 최신화할 뿐이라 붙잡아둘 이유가 없다.
class SessionBootstrapper {
  SessionBootstrapper(this._userProvider);

  final UserProvider _userProvider;

  /// 스플래시를 걷어도 되는 시점까지만 기다린다.
  ///
  /// 절대 던지지 않는다 — 시작 경로에서 예외가 올라가면 스플래시가 남는다.
  Future<void> resolveIdentity() async {
    // 생성자의 캐시 로드가 먼저 끝나도록 기다린 뒤 네트워크로 갱신 —
    // 두 경로가 _user를 번갈아 쓰며 화면이 깜빡이는 경합 제거.
    // 캐시 로드가 실패해도(보안 스토리지 손상 등) 여기서 던지면 안 된다 —
    // unawaited로 불리는 경로라 그대로 올라가면 앱은 멀쩡히 떴는데
    // Crashlytics에 치명적 크래시로 기록된다. 토큰으로 다시 시도한다.
    try {
      await _userProvider.ready;
    } catch (e) {
      log('Cached user load failed: $e');
    }
    final String? token;
    try {
      token = await TokenStore.readAccessToken();
    } catch (e) {
      log('Auto login skipped (token read failed): $e');
      return;
    }
    // 토큰이 없으면 게스트 — 갱신할 것도 기다릴 것도 없다.
    if (token == null) return;

    // 토큰은 있는데 캐시가 비었다면(캐시 JSON 파싱 실패 등) 아직 이 사람이
    // 누구인지 모른다. 그대로 진입시키면 게스트 화면을 보여줬다가 뒤늦게
    // 나이확인·온보딩으로 갈아치우게 되므로 이때만 예전처럼 기다린다.
    // 스플래시가 떠 있는 동안이라 죽은 토큰을 정리해도 사용자가 겪는 변화가 없다.
    if (_userProvider.user == null) {
      await _refresh(token, mayClearSession: true);
      return;
    }
    // 캐시로 신원이 확정됐으면 갱신은 백그라운드로 넘기고 바로 반환한다.
    unawaited(_refresh(token, mayClearSession: false));
  }

  /// 프로필 갱신과 홈 데이터 프리페치. 늦게 온 결과가 그 사이의 인증 변화를
  /// 덮어쓰지 않도록 [UserProvider]의 인증 세대가 걸러준다.
  ///
  /// [mayClearSession]은 "실패했을 때 세션을 끊어도 되는가"다. 스플래시가 떠
  /// 있는 동안(기다리는 분기)에만 true다 — 사용자가 이미 앱을 쓰고 있는데
  /// 배경 갱신이 아무 안내 없이 게스트로 떨어뜨리면 안 되고, 죽은 토큰은
  /// 어차피 다음 요청에서 `DioClient`가 401로 처리한다.
  Future<void> _refresh(String token, {required bool mayClearSession}) async {
    // connect(5s) + receive(12s) + 갱신 재시도(20s) + 여유 = 40s 상한
    // _plainDio 타임아웃 없음으로 인한 무한 대기 방지
    final generation = _userProvider.authGeneration;
    try {
      await _userProvider
          .fetchUserFromToken(token, clearDeadToken: mayClearSession)
          .timeout(const Duration(seconds: 40));
      // 로그인 성공 시 홈 데이터를 미리 캐싱 (최대 2초 대기)
      // → HomeFragment 진입 시 스켈레톤 없이 즉시 표시
      final userId = _userProvider.currentUserId;
      if (userId != null) {
        await _prefetchHomeData(userId)
            .timeout(const Duration(seconds: 2), onTimeout: () {});
      }
    } on TimeoutException {
      log('Auto login timed out');
    } on DioException catch (e) {
      if (e.response == null) {
        // 오프라인 — 서버 미도달, 토큰 유효성 확인 불가 → 캐시 user 유지
        log('Auto login failed (offline): ${e.type}');
      } else {
        // 서버 도달했으나 오류(5xx 등) — 401/403/404는 fetchUserFromToken이 이미 정리
        // 5xx는 서버 오류이므로 토큰 유지, 이후 API 호출 시 DioClient가 401 처리
        log('Auto login failed (server ${e.response?.statusCode})');
      }
    } catch (e) {
      // 응답 파싱 실패 등 예상치 못한 오류 — 죽은 토큰 정리
      log('Auto login failed (unexpected): $e');
      if (!mayClearSession) return;
      // 그 사이 사용자가 직접 로그인·로그아웃했다면 건드리면 안 된다.
      if (_userProvider.authGeneration != generation) return;
      try {
        await _userProvider.logout().timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
  }

  /// 스플래시 중 홈 데이터를 FestivalCacheService에 저장 —
  /// HomeStateNotifier가 캐시 우선 표시 전략으로 즉시 렌더링할 수 있게 한다.
  Future<void> _prefetchHomeData(int userId) async {
    try {
      final (artists, festivals) = await (
        sl<UserService>().fetchFollowingArtists(userId),
        sl<UserService>().fetchLikedFestivals(userId),
      ).wait;
      await Future.wait([
        sl<FestivalCacheService>().saveHomeArtists(userId, artists),
        sl<FestivalCacheService>().saveHomeFestivals(userId, festivals),
      ]);
      log('Home pre-fetch: ${artists.length} artists, ${festivals.length} festivals');
    } catch (e) {
      log('Home pre-fetch failed (ignored): $e');
    }
  }
}
