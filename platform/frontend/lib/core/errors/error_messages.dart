import 'failure.dart';

abstract final class ErrorMessages {
  static const _tooManyAttempts = 'Muitas tentativas. Solicite um novo código.';

  static String? forField(ValidationFailure failure, String field) =>
      failure.firstErrorFor(field);

  static bool isTooManyAttempts(ValidationFailure failure) =>
      failure.firstErrorFor('code') == _tooManyAttempts;

  static String general(Failure failure) => switch (failure) {
    UnauthorizedFailure() => 'Sua sessão expirou. Entre novamente.',
    NotFoundFailure() => 'Não encontrado.',
    ValidationFailure(:final message) =>
      message ?? 'Verifique os dados informados.',
    RateLimitedFailure() => 'Muitas tentativas. Aguarde um momento.',
    NetworkFailure() =>
      'Sem conexão. Verifique sua internet e tente novamente.',
    UnexpectedFailure(:final message) =>
      message ?? 'Algo deu errado. Tente novamente.',
  };
}
