import 'dart:async';

/// 사용자가 명시적으로 최신화를 요청한 흐름(당겨서 새로고침, 재시도 버튼 등)을
/// [withForcedRefresh]로 감싸면, 그 흐름에서 발생하는 모든 GET 요청이 SWR
/// 메모리 캐시를 건너뛰고 실제 네트워크로 나간다.
///
/// Zone 값으로 전파되므로 중간 서비스/모델 계층에 `forceRefresh` 파라미터를
/// 추가할 필요가 없다 — `withForcedRefresh(() => someService.fetch())` 처럼
/// 최상위 호출부만 감싸면 그 안의 await 체인 전체가 강제 새로고침으로 동작한다.
///
/// 오프라인일 때는 `_ResponseCacheInterceptor`가 여전히 캐시로 폴백하므로,
/// 강제 새로고침이 곧 "실패 시 빈 화면"을 의미하지는 않는다.
const forcedRefreshZoneKey = #fepleForcedRefresh;

Future<T> withForcedRefresh<T>(Future<T> Function() body) =>
    runZoned(body, zoneValues: const {forcedRefreshZoneKey: true});

/// 현재 실행 Zone이 강제 새로고침 컨텍스트인지 여부 (DioClient 인터셉터용).
bool get isForcedRefreshZone => Zone.current[forcedRefreshZoneKey] == true;
