import 'package:dio/dio.dart';

/// Error thrown by datasources. Never crosses the data layer: repositories
/// convert it into a `Failure`.
class ApiException implements Exception {
  const ApiException({
    this.statusCode,
    this.message,
    this.fieldErrors = const {},
    this.retryAfter,
  });

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    if (response == null) return const ApiException();

    final data = response.data;
    String? message;
    var fieldErrors = const <String, List<String>>{};

    if (data is Map<String, dynamic>) {
      message = data['message'] as String?;
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        fieldErrors = errors.map(
          (field, messages) => MapEntry(
            field,
            (messages as List<dynamic>).map((m) => m.toString()).toList(),
          ),
        );
      }
    }

    // Unreadable on web: the API's CORS config exposes no headers.
    final retryAfterHeader = response.headers.value('retry-after');
    final retrySeconds = retryAfterHeader == null
        ? null
        : int.tryParse(retryAfterHeader);

    return ApiException(
      statusCode: response.statusCode,
      message: message,
      fieldErrors: fieldErrors,
      retryAfter: retrySeconds == null ? null : Duration(seconds: retrySeconds),
    );
  }

  /// Null when no response arrived (offline, timeout, server down).
  final int? statusCode;
  final String? message;
  final Map<String, List<String>> fieldErrors;
  final Duration? retryAfter;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
