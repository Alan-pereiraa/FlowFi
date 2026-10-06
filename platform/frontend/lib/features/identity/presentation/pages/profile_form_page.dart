import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/routes.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/entities/user.dart';
import '../controllers/profile_form_controller.dart';
import '../controllers/session_controller.dart';
import '../widgets/phone_input_formatter.dart';

enum ProfileFormMode { complete, edit }

/// Same form for the first login (`complete`) and for editing (`edit`).
/// Only the fields the API has: first_name, last_name, phone_number, email.
// GAP: the design's birth date, CPF and avatar fields don't exist on `users`.
class ProfileFormPage extends ConsumerStatefulWidget {
  const ProfileFormPage({super.key, required this.mode});

  final ProfileFormMode mode;

  @override
  ConsumerState<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends ConsumerState<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  bool get _isEdit => widget.mode == ProfileFormMode.edit;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionControllerProvider).user;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _phone = TextEditingController(
      text: PhoneInputFormatter.format(user?.phoneNumber ?? ''),
    );
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _orNull(String text) => text.trim().isEmpty ? null : text.trim();

  void _submit(User? user) {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim().toLowerCase();
    ref
        .read(profileFormControllerProvider.notifier)
        .save(
          ProfileUpdate(
            firstName: _firstName.text.trim(),
            lastName: _orNull(_lastName.text),
            phoneNumber: _orNull(PhoneInputFormatter.digitsOf(_phone.text)),
            email: _isEdit && email != user?.email ? email : null,
          ),
        );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Seus dados deixarão de ficar acessíveis e este e-mail não poderá '
          'ser usado para entrar novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(profileFormControllerProvider.notifier).deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileFormControllerProvider.select((s) => s.saved), (
      _,
      saved,
    ) {
      // Complete mode: the router moves on from the new session state.
      if (saved && _isEdit) context.pushReplacement(Routes.profileSuccess);
    });
    final state = ref.watch(profileFormControllerProvider);
    final user = ref.watch(sessionControllerProvider).user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: _isEdit,
        title: Text(_isEdit ? 'Editar Perfil' : 'Complete seu Perfil'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.onSurfaceVariant,
                        foregroundColor: theme.colorScheme.surface,
                        child: const Icon(Icons.person, size: 44),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEdit ? 'Editar Perfil' : 'Como podemos te chamar?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'Nome',
                      hint: 'Ex: Alex',
                      controller: _firstName,
                      icon: Icons.badge_outlined,
                      errorText: state.fieldErrors['first_name'],
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                      validator: (v) => Validators.requiredField(
                        v,
                        message: 'Informe seu nome.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Sobrenome',
                      hint: 'Ex: Junior',
                      controller: _lastName,
                      icon: Icons.badge_outlined,
                      errorText: state.fieldErrors['last_name'],
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.familyName],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Telefone',
                      hint: '(00) 00000-0000',
                      controller: _phone,
                      icon: Icons.phone_outlined,
                      errorText: state.fieldErrors['phone_number'],
                      keyboardType: TextInputType.phone,
                      textInputAction: _isEdit
                          ? TextInputAction.next
                          : TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [PhoneInputFormatter()],
                      validator: Validators.optionalPhone,
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'E-mail',
                        controller: _email,
                        icon: Icons.mail_outline,
                        errorText: state.fieldErrors['email'],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                      ),
                    ],
                    if (state.formError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        state.formError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    AppButton(
                      label: _isEdit ? 'Atualizar Perfil' : 'Continuar',
                      loading: state.saving,
                      onPressed: state.busy ? null : () => _submit(user),
                    ),
                    // Logout and deletion have no screen in the design.
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => ref
                                .read(profileFormControllerProvider.notifier)
                                .logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da conta'),
                    ),
                    if (_isEdit)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: state.busy ? null : _confirmDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Excluir conta'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
