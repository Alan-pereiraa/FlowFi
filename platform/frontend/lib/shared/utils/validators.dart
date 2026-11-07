abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? requiredField(
    String? value, {
    String message = 'Campo obrigatório.',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Informe seu e-mail.';
    if (!_email.hasMatch(trimmed)) return 'E-mail inválido.';
    return null;
  }

  static String? otpCode(String? value, {int length = 6}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Informe o código.';
    if (trimmed.length != length || int.tryParse(trimmed) == null) {
      return 'O código tem $length dígitos.';
    }
    return null;
  }

  static String? optionalPhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length < 10 || digits.length > 11) return 'Telefone inválido.';
    return null;
  }
}
