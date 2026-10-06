import 'failure.dart';

/// Backend messages are English; UI copy is pt-BR. This is the single place
/// where they are translated. Never show raw backend text.
abstract final class ErrorMessages {
  static const _known = <String, String>{
    'The code is invalid or has expired.': 'Código inválido ou expirado.',
    'Too many attempts. Request a new code.':
        'Muitas tentativas. Solicite um novo código.',
    'This account has been deactivated.': 'Esta conta foi desativada.',
    'The email has already been taken.': 'Este e-mail já está em uso.',
  };

  static const _fieldFallback = <String, String>{
    'email': 'E-mail inválido.',
    'code': 'Código inválido.',
    'first_name': 'Nome inválido.',
    'last_name': 'Sobrenome inválido.',
    'phone_number': 'Telefone inválido.',
  };

  static const tooManyAttempts = 'Muitas tentativas. Solicite um novo código.';

  /// Message for a 422 on [field], or null when the field has no error.
  static String? forField(ValidationFailure failure, String field) {
    final raw = failure.firstErrorFor(field);
    if (raw == null) return null;
    return _known[raw] ?? _fieldFallback[field] ?? 'Valor inválido.';
  }

  /// Whether [failure] carries the backend's "too many attempts" OTP error.
  static bool isTooManyAttempts(ValidationFailure failure) =>
      _known[failure.firstErrorFor('code')] == tooManyAttempts;

  /// Generic message for a failure shown outside a form field.
  static String general(Failure failure) => switch (failure) {
    UnauthorizedFailure() => 'Sua sessão expirou. Entre novamente.',
    NotFoundFailure() => 'Não encontrado.',
    ValidationFailure(:final message) =>
      _known[message] ?? 'Verifique os dados informados.',
    RateLimitedFailure() => 'Muitas tentativas. Aguarde um momento.',
    NetworkFailure() =>
      'Sem conexão. Verifique sua internet e tente novamente.',
    UnexpectedFailure() => 'Algo deu errado. Tente novamente.',
  };
}
