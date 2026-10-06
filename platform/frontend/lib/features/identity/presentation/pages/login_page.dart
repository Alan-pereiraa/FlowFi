import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/login_controller.dart';
import '../controllers/login_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  LoginController get _controller => ref.read(loginControllerProvider.notifier);

  void _sendCode() => _controller.sendCode(_email.text);

  void _verify() {
    TextInput.finishAutofillContext();
    _controller.verify(_email.text, _code.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider.select((s) => s.codeResetCount), (_, _) {
      _code.clear();
    });
    final state = ref.watch(loginControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogo(size: 32)),
                        const SizedBox(height: 24),
                        Text(
                          'Bem-Vindo!',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Faça Log-in para continuar sua jornada financeira!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: 'Email',
                          controller: _email,
                          icon: Icons.mail_outline,
                          errorText: state.emailError,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.send,
                          autofillHints: const [AutofillHints.email],
                          onSubmitted: (_) => _sendCode(),
                          suffix: _SendCodeButton(
                            state: state,
                            onPressed: _sendCode,
                          ),
                        ),
                        if (state.codeSent) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Enviamos um código para o seu e-mail.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        AppTextField(
                          hint: 'Insira seu código temporário',
                          controller: _code,
                          errorText: state.codeError,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onSubmitted: (_) => _verify(),
                        ),
                        if (state.formError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            state.formError!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Entrar',
                          loading: state.verifying,
                          onPressed: _verify,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendCodeButton extends StatelessWidget {
  const _SendCodeButton({required this.state, required this.onPressed});

  final LoginState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      LoginState(sending: true) => 'Enviando…',
      LoginState(:final cooldownSeconds) when cooldownSeconds > 0 =>
        'Reenviar em ${cooldownSeconds}s',
      LoginState(codeSent: true) => 'Reenviar',
      _ => 'Enviar Código',
    };
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton(
        onPressed: state.canSend ? onPressed : null,
        child: Text(label),
      ),
    );
  }
}
