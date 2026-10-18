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
    'The name has already been taken.':
        'Você já tem uma categoria com esse nome.',
    'This transaction already has paid installments; its payment plan can '
            'no longer be changed.':
        'Esta transação já tem parcelas pagas; valor, recorrência e duração '
        'não podem mais ser alterados.',
  };

  /// Backend messages with a variable part.
  static final _patterns = <RegExp, String Function(Match)>{
    RegExp(
      r'^This transaction exceeds the category limit for (\d{4})-(\d{2})\.$',
    ): (m) =>
        'Esta transação ultrapassa o limite da categoria em '
        '${m[2]}/${m[1]}.',
  };

  static const _fieldFallback = <String, String>{
    'email': 'E-mail inválido.',
    'code': 'Código inválido.',
    'first_name': 'Nome inválido.',
    'last_name': 'Sobrenome inválido.',
    'phone_number': 'Telefone inválido.',
    'name': 'Nome inválido.',
    'icon': 'Escolha um ícone.',
    'color': 'Escolha uma cor.',
    'limit_amount': 'Limite inválido.',
    'total_amount': 'Valor inválido.',
    'description': 'Descrição inválida.',
    'date': 'Data inválida.',
    'category_id': 'Escolha uma categoria.',
    'installments_count': 'Duração inválida.',
    'period_unit': 'Duração inválida.',
    'installments': 'Parcelas inválidas.',
  };

  static const tooManyAttempts = 'Muitas tentativas. Solicite um novo código.';

  static String? _translate(String? raw) {
    if (raw == null) return null;
    final known = _known[raw];
    if (known != null) return known;
    for (final MapEntry(key: pattern, value: build) in _patterns.entries) {
      final match = pattern.firstMatch(raw);
      if (match != null) return build(match);
    }
    return null;
  }

  /// Message for a 422 on [field], or null when the field has no error.
  static String? forField(ValidationFailure failure, String field) {
    final raw = failure.firstErrorFor(field);
    if (raw == null) return null;
    return _translate(raw) ?? _fieldFallback[field] ?? 'Valor inválido.';
  }

  /// Whether [failure] carries the backend's "too many attempts" OTP error.
  static bool isTooManyAttempts(ValidationFailure failure) =>
      _known[failure.firstErrorFor('code')] == tooManyAttempts;

  /// Generic message for a failure shown outside a form field.
  static String general(Failure failure) => switch (failure) {
    UnauthorizedFailure() => 'Sua sessão expirou. Entre novamente.',
    NotFoundFailure() => 'Não encontrado.',
    ValidationFailure(:final message) =>
      _translate(message) ?? 'Verifique os dados informados.',
    RateLimitedFailure() => 'Muitas tentativas. Aguarde um momento.',
    NetworkFailure() =>
      'Sem conexão. Verifique sua internet e tente novamente.',
    UnexpectedFailure() => 'Algo deu errado. Tente novamente.',
  };
}
