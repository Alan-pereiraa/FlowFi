import 'package:dio/dio.dart';

import '../network/api_exception.dart';

/// The only error type above the data layer.
sealed class Failure implements Exception {
  const Failure();

  factory Failure.fromApiException(ApiException e) => switch (e.statusCode) {
    null => const NetworkFailure(),
    401 => const UnauthorizedFailure(),
    404 => const NotFoundFailure(),
    422 => ValidationFailure(message: e.message, fieldErrors: e.fieldErrors),
    429 => RateLimitedFailure(retryAfter: e.retryAfter),
    _ => const UnexpectedFailure(),
  };
}

/// Session is over. The interceptor already cleared the token.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// Laravel's 422. Messages are the raw backend (English) text; map them with
/// `error_messages.dart` before showing.
final class ValidationFailure extends Failure {
  const ValidationFailure({this.message, this.fieldErrors = const {}});

  final String? message;
  final Map<String, List<String>> fieldErrors;

  String? firstErrorFor(String field) => fieldErrors[field]?.firstOrNull;
}

final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({this.retryAfter});

  /// Null on web, where the `Retry-After` header is not exposed.
  final Duration? retryAfter;
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure();
}

/// Runs a datasource call and rethrows any API error as a [Failure].
Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on ApiException catch (e) {
    throw Failure.fromApiException(e);
  } on DioException catch (e) {
    throw Failure.fromApiException(ApiException.fromDio(e));
  }
}
