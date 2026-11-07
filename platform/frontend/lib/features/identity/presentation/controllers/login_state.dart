import 'package:flutter/foundation.dart';

@immutable
class LoginState {
  const LoginState({
    this.sending = false,
    this.verifying = false,
    this.codeSent = false,
    this.cooldownSeconds = 0,
    this.codeResetCount = 0,
    this.emailError,
    this.codeError,
    this.formError,
  });

  final bool sending;
  final bool verifying;
  final bool codeSent;

  final int cooldownSeconds;

  final int codeResetCount;

  final String? emailError;
  final String? codeError;
  final String? formError;

  bool get canSend => !sending && cooldownSeconds == 0;

  LoginState copyWith({
    bool? sending,
    bool? verifying,
    bool? codeSent,
    int? cooldownSeconds,
    int? codeResetCount,
    String? Function()? emailError,
    String? Function()? codeError,
    String? Function()? formError,
  }) {
    return LoginState(
      sending: sending ?? this.sending,
      verifying: verifying ?? this.verifying,
      codeSent: codeSent ?? this.codeSent,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      codeResetCount: codeResetCount ?? this.codeResetCount,
      emailError: emailError == null ? this.emailError : emailError(),
      codeError: codeError == null ? this.codeError : codeError(),
      formError: formError == null ? this.formError : formError(),
    );
  }
}
