import 'package:dio/dio.dart';
import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _error(
  int status, {
  Object? data,
  Map<String, List<String>>? headers,
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(headers ?? {}),
    ),
  );
}

void main() {
  test('parses Laravel 422 field errors', () {
    final e = ApiException.fromDio(
      _error(
        422,
        data: {
          'message': 'O código é inválido ou expirou.',
          'errors': {
            'code': ['O código é inválido ou expirou.'],
          },
        },
      ),
    );

    final failure = Failure.fromApiException(e);
    expect(failure, isA<ValidationFailure>());
    expect(
      (failure as ValidationFailure).firstErrorFor('code'),
      'O código é inválido ou expirou.',
    );
  });

  test('reads Retry-After on 429 when available', () {
    final e = ApiException.fromDio(
      _error(
        429,
        headers: {
          'retry-after': ['42'],
        },
      ),
    );

    final failure = Failure.fromApiException(e) as RateLimitedFailure;
    expect(failure.retryAfter, const Duration(seconds: 42));
  });

  test('maps status codes to failures', () {
    expect(
      Failure.fromApiException(const ApiException()),
      isA<NetworkFailure>(),
    );
    expect(
      Failure.fromApiException(const ApiException(statusCode: 401)),
      isA<UnauthorizedFailure>(),
    );
    expect(
      Failure.fromApiException(const ApiException(statusCode: 404)),
      isA<NotFoundFailure>(),
    );
    expect(
      Failure.fromApiException(const ApiException(statusCode: 500)),
      isA<UnexpectedFailure>(),
    );
  });
}
