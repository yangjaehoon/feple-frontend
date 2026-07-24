import 'package:dio/dio.dart';
import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _makeException({
  DioExceptionType type = DioExceptionType.unknown,
  int? statusCode,
  dynamic data,
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/test'),
    type: type,
    response: statusCode != null
        ? Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: statusCode,
            data: data,
          )
        : null,
  );
}

void main() {
  group('isOffline', () {
    test('connectionError이면 true', () {
      expect(isOffline(_makeException(type: DioExceptionType.connectionError)), true);
    });

    test('connectionTimeout이면 true', () {
      expect(isOffline(_makeException(type: DioExceptionType.connectionTimeout)), true);
    });

    test('receiveTimeout이면 true', () {
      expect(isOffline(_makeException(type: DioExceptionType.receiveTimeout)), true);
    });

    test('unknown이면 true', () {
      expect(isOffline(_makeException(type: DioExceptionType.unknown)), true);
    });

    test('400 서버 응답(badResponse)이면 false — 서버에는 도달한 것', () {
      expect(isOffline(_makeException(type: DioExceptionType.badResponse, statusCode: 400)), false);
    });

    test('500 서버 응답이면 false', () {
      expect(isOffline(_makeException(type: DioExceptionType.badResponse, statusCode: 500)), false);
    });

    test('DioException이 아닌 일반 예외이면 false', () {
      expect(isOffline(Exception('random error')), false);
    });
  });

  group('isDioConflict', () {
    test('409 상태코드이면 true', () {
      expect(isDioConflict(_makeException(type: DioExceptionType.badResponse, statusCode: 409)), true);
    });

    test('400 상태코드이면 false', () {
      expect(isDioConflict(_makeException(type: DioExceptionType.badResponse, statusCode: 400)), false);
    });

    test('DioException이 아니면 false', () {
      expect(isDioConflict(Exception('err')), false);
    });
  });

  group('throwIfBannedWord', () {
    test('400 + code BAD_WORD이면 BannedWordException throw', () {
      final e = _makeException(
        type: DioExceptionType.badResponse,
        statusCode: 400,
        data: {'code': 'BAD_WORD', 'field': 'title'},
      );
      expect(() => throwIfBannedWord(e), throwsA(isA<BannedWordException>()));
    });

    test('BannedWordException의 field가 응답 field와 일치', () {
      final e = _makeException(
        type: DioExceptionType.badResponse,
        statusCode: 400,
        data: {'code': 'BAD_WORD', 'field': 'content'},
      );
      try {
        throwIfBannedWord(e);
        fail('예외가 발생해야 함');
      } on BannedWordException catch (ex) {
        expect(ex.field, 'content');
      }
    });

    test('field가 null이면 defaultField 사용', () {
      final e = _makeException(
        type: DioExceptionType.badResponse,
        statusCode: 400,
        data: {'code': 'BAD_WORD'},
      );
      try {
        throwIfBannedWord(e, defaultField: 'title');
        fail('예외가 발생해야 함');
      } on BannedWordException catch (ex) {
        expect(ex.field, 'title');
      }
    });

    test('400이지만 code가 BAD_WORD가 아니면 아무것도 안 함', () {
      final e = _makeException(
        type: DioExceptionType.badResponse,
        statusCode: 400,
        data: {'code': 'VALIDATION_ERROR'},
      );
      expect(() => throwIfBannedWord(e), returnsNormally);
    });

    test('500 응답이면 아무것도 안 함', () {
      final e = _makeException(
        type: DioExceptionType.badResponse,
        statusCode: 500,
        data: {'code': 'BAD_WORD'},
      );
      expect(() => throwIfBannedWord(e), returnsNormally);
    });

    test('data가 Map이 아니면 아무것도 안 함', () {
      final e = _makeException(
        type: DioExceptionType.badResponse,
        statusCode: 400,
        data: 'plain string',
      );
      expect(() => throwIfBannedWord(e), returnsNormally);
    });
  });

  group('networkAwareErrorKey', () {
    test('connectionTimeout이면 connection_error 반환', () {
      final e = _makeException(type: DioExceptionType.connectionTimeout);
      expect(networkAwareErrorKey(e, 'post_failed'), 'connection_error');
    });

    test('sendTimeout이면 connection_error 반환', () {
      final e = _makeException(type: DioExceptionType.sendTimeout);
      expect(networkAwareErrorKey(e, 'post_failed'), 'connection_error');
    });

    test('receiveTimeout이면 connection_error 반환', () {
      final e = _makeException(type: DioExceptionType.receiveTimeout);
      expect(networkAwareErrorKey(e, 'post_failed'), 'connection_error');
    });

    test('connectionError이면 connection_error 반환', () {
      final e = _makeException(type: DioExceptionType.connectionError);
      expect(networkAwareErrorKey(e, 'post_failed'), 'connection_error');
    });

    test('서버 500이면 operationErrorKey 반환', () {
      final e = _makeException(type: DioExceptionType.badResponse, statusCode: 500);
      expect(networkAwareErrorKey(e, 'post_failed'), 'post_failed');
    });

    test('일반 예외이면 operationErrorKey 반환', () {
      expect(networkAwareErrorKey(Exception('err'), 'post_failed'), 'post_failed');
    });
  });
}
