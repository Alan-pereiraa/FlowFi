import '../../core/errors/error_messages.dart';
import '../../core/errors/failure.dart';

/// pt-BR copy for the 422s of the categories and goals endpoints.
///
/// `ErrorMessages` (core) is the single translator for auth/profile errors and
/// is not extensible, so these two modules add their own field messages here
/// and delegate everything non-field to `ErrorMessages.general`.
abstract final class LedgerErrorMessages {
  static const _categoryFallbacks = <String, String>{
    'name': 'Nome inválido.',
    'icon': 'Ícone inválido.',
    'color': 'Cor inválida.',
    'limit_amount': 'Limite inválido.',
  };

  static const _goalFallbacks = <String, String>{
    'name': 'Nome inválido.',
    'icon': 'Ícone inválido.',
    'color': 'Cor inválida.',
    'target_amount': 'Valor da meta inválido.',
    'expires_at': 'Data inválida.',
  };

  /// Message for a 422 on a category [field], or null when it has no error.
  static String? categoryField(ValidationFailure failure, String field) =>
      _field(
        failure,
        field,
        fallbacks: _categoryFallbacks,
        duplicateName: 'Você já tem uma categoria com esse nome.',
      );

  /// Message for a 422 on a goal [field], or null when it has no error.
  static String? goalField(ValidationFailure failure, String field) => _field(
    failure,
    field,
    fallbacks: _goalFallbacks,
    duplicateName: 'Você já tem uma meta com esse nome.',
  );

  /// Failure of "adicionar valor" to a goal.
  static String goalDeposit(Failure failure) => switch (failure) {
    ValidationFailure() =>
      'Não foi possível adicionar esse valor. Confira o valor e tente '
          'novamente.',
    _ => general(failure),
  };

  /// Failure of deleting a goal. The API answers 422 under `goal` when the
  /// goal already has deposits.
  static String goalDelete(Failure failure) => switch (failure) {
    ValidationFailure(:final fieldErrors) when fieldErrors.containsKey('goal') =>
      'Não é possível excluir uma meta que já tem valores adicionados.',
    _ => general(failure),
  };

  /// Message for a failure shown outside a field.
  static String general(Failure failure) => ErrorMessages.general(failure);

  static String? _field(
    ValidationFailure failure,
    String field, {
    required Map<String, String> fallbacks,
    required String duplicateName,
  }) {
    final raw = failure.firstErrorFor(field);
    if (raw == null) return null;

    final lower = raw.toLowerCase();
    if (field == 'name' && lower.contains('already been taken')) {
      return duplicateName;
    }
    if (lower.contains('is required')) return 'Campo obrigatório.';
    if (lower.contains('greater than')) {
      return 'Valor acima do máximo permitido.';
    }
    if (lower.contains('at least')) return 'Informe um valor maior que zero.';
    return fallbacks[field] ?? 'Valor inválido.';
  }
}
