import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Dio HTTP 요청을 Firebase Performance HttpMetric으로 자동 추적.
/// DioClient의 SWR 캐시 인터셉터 이후에 등록되어 실제 네트워크 요청만 측정함.
class PerformanceInterceptor extends Interceptor {
  static const _kMetricKey = '_perf_metric';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final method = _toHttpMethod(options.method);
      if (method != null) {
        final cleanUrl = _stripQueryParams(options.uri);
        final metric = FirebasePerformance.instance.newHttpMetric(cleanUrl, method);
        await metric.start();
        options.extra[_kMetricKey] = metric;
      }
    } catch (e) {
      debugPrint('[Perf] metric start error');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    await _stopMetric(
      response.requestOptions,
      statusCode: response.statusCode,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    await _stopMetric(
      err.requestOptions,
      statusCode: err.response?.statusCode,
    );
    handler.next(err);
  }

  Future<void> _stopMetric(RequestOptions options, {int? statusCode}) async {
    final metric = options.extra[_kMetricKey] as HttpMetric?;
    if (metric == null) return;
    try {
      if (statusCode != null) metric.httpResponseCode = statusCode;
      await metric.stop();
    } catch (e) {
      debugPrint('[Perf] metric stop error');
    }
  }

  String _stripQueryParams(Uri uri) =>
      Uri(scheme: uri.scheme, host: uri.host, port: uri.port, path: uri.path)
          .toString();

  HttpMethod? _toHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.Get;
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'DELETE':
        return HttpMethod.Delete;
      default:
        return null;
    }
  }
}
