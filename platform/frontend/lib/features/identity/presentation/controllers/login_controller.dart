import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/utils/validators.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'login_state.dart';
import 'session_controller.dart';

final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
      LoginController.new,
    );

/// Email + OTP login on a single screen.
class LoginController extends Notifier<LoginState> {
  /// Fallback cooldown after each send. The backend allows 3 requests/min per
  /// email; the 202 carries no `Retry-After` and web can't read the header.
  static const resendCooldown = Duration(seconds: 60);

  Timer? _timer;

  @override
  LoginState build() {
    ref.onDispose(() => _timer?.cancel());
    return const LoginState();
  }

  Future<void> sendCode(String rawEmail) async {
    if (!state.canSend) return;
    final email = _normalize(rawEmail);
    final emailError = Validators.email(email);
    if (emailError != null) {
      state = state.copyWith(
        emailError: () => emailError,
        formError: () => null,
      );
      return;
    }

    state = state.copyWith(
      sending: true,
      emailError: () => null,
      codeError: () => null,
      formError: () => null,
    );

    try {
      await ref.read(authRepositoryProvider).requestOtp(email);
      if (!ref.mounted) return;
      state = state.copyWith(sending: false, codeSent: true);
      _startCooldown(resendCooldown);
    } on RateLimitedFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        sending: false,
        formError: () => ErrorMessages.general(failure),
      );
      _startCooldown(failure.retryAfter ?? resendCooldown);
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        sending: false,
        emailError: () => ErrorMessages.forField(failure, 'email'),
        formError: () => failure.fieldErrors.containsKey('email')
            ? null
            : ErrorMessages.general(failure),
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        sending: false,
        formError: () => ErrorMessages.general(failure),
      );
    }
  }

  Future<void> verify(String rawEmail, String rawCode) async {
    if (state.verifying) return;
    final email = _normalize(rawEmail);
    final code = rawCode.trim();
    final emailError = Validators.email(email);
    final codeError = Validators.otpCode(code);
    if (emailError != null || codeError != null) {
      state = state.copyWith(
        emailError: () => emailError,
        codeError: () => codeError,
        formError: () => null,
      );
      return;
    }

    state = state.copyWith(
      verifying: true,
      emailError: () => null,
      codeError: () => null,
      formError: () => null,
    );

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .verifyOtp(email: email, code: code);
      if (!ref.mounted) return;
      state = state.copyWith(verifying: false);
      // The router redirects off the login screen from the new session state.
      ref.read(sessionControllerProvider.notifier).signedIn(user);
    } on ValidationFailure catch (failure) {
      if (!ref.mounted) return;
      final tooManyAttempts = ErrorMessages.isTooManyAttempts(failure);
      if (tooManyAttempts) _stopCooldown();
      state = state.copyWith(
        verifying: false,
        emailError: () => ErrorMessages.forField(failure, 'email'),
        codeError: () => ErrorMessages.forField(failure, 'code'),
        codeResetCount: tooManyAttempts
            ? state.codeResetCount + 1
            : state.codeResetCount,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        verifying: false,
        formError: () => ErrorMessages.general(failure),
      );
    }
  }

  String _normalize(String email) => email.trim().toLowerCase();

  void _startCooldown(Duration duration) {
    _timer?.cancel();
    state = state.copyWith(cooldownSeconds: duration.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.cooldownSeconds - 1;
      if (left <= 0) {
        timer.cancel();
        state = state.copyWith(cooldownSeconds: 0);
      } else {
        state = state.copyWith(cooldownSeconds: left);
      }
    });
  }

  void _stopCooldown() {
    _timer?.cancel();
    state = state.copyWith(cooldownSeconds: 0);
  }
}
