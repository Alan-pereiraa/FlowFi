import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/app_palette.dart';
import '../../../../shared/utils/currency_input_formatter.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_date_field.dart';
import '../../../../shared/widgets/app_money_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/appearance_picker.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../domain/entities/new_goal.dart';
import '../controllers/goal_form_controller.dart';
import '../goal_routes.dart';
import '../widgets/goal_tip_card.dart';

/// "Nova Meta". Lives inside the app shell, so it has no `Scaffold`.
// GAP: the design has no icon or color field for a goal, but the API requires
// both. They default to the savings icon in the brand green and can be changed
// from the button at the end of the name field.
class GoalFormPage extends ConsumerStatefulWidget {
  const GoalFormPage({super.key});

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _initial = TextEditingController();

  DateTime? _expiresAt;
  String _icon = AppIcons.defaultGoal;
  String _color = AppPalette.defaultHex;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _initial.dispose();
    super.dispose();
  }

  Future<void> _pickAppearance() async {
    final choice = await showAppearanceSheet(
      context,
      icon: _icon,
      color: _color,
    );
    if (!mounted || choice == null) return;
    setState(() {
      _icon = choice.icon ?? _icon;
      _color = choice.color ?? _color;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(goalFormControllerProvider.notifier)
        .create(
          NewGoal(
            name: _name.text.trim(),
            icon: _icon,
            color: _color,
            targetCents: CurrencyInputFormatter.centsOf(_target.text),
            expiresAt: _expiresAt,
            initialCents: CurrencyInputFormatter.centsOf(_initial.text),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(goalFormControllerProvider.select((s) => s.created), (
      _,
      created,
    ) {
      if (created != null) context.go(GoalRoutes.success, extra: created);
    });
    final state = ref.watch(goalFormControllerProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ResponsiveCenter(
        maxWidth: 560,
        verticalPadding: 24,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nova Meta',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Defina um novo objetivo financeiro e comece a planejar o '
                'seu futuro.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Nome da Meta',
                hint: 'Ex: Viagem de Férias',
                controller: _name,
                icon: Icons.edit_note,
                errorText: state.fieldErrors['name'],
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                enabled: !state.saving,
                validator: (v) => Validators.requiredField(
                  v,
                  message: 'Informe o nome da meta.',
                ),
                suffix: IconButton(
                  tooltip: 'Escolher ícone e cor',
                  onPressed: state.saving ? null : _pickAppearance,
                  icon: Icon(
                    AppIcons.resolve(_icon),
                    color: AppPalette.parse(_color),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppMoneyField(
                label: 'Valor da Meta',
                controller: _target,
                errorText: state.fieldErrors['target_amount'],
                textInputAction: TextInputAction.next,
                enabled: !state.saving,
                validator: (v) => CurrencyInputFormatter.centsOf(v ?? '') > 0
                    ? null
                    : 'Informe o valor da meta.',
              ),
              const SizedBox(height: 20),
              AppDateField(
                label: 'Data Alvo',
                value: _expiresAt,
                onChanged: (date) => setState(() => _expiresAt = date),
                helper: 'Opcional. Sem data, a meta fica contínua.',
                errorText: state.fieldErrors['expires_at'],
                enabled: !state.saving,
              ),
              const SizedBox(height: 20),
              AppMoneyField(
                label: 'Valor Inicial (opcional)',
                controller: _initial,
                helper: 'Quanto você já tem guardado para essa meta?',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                enabled: !state.saving,
              ),
              const SizedBox(height: 24),
              const GoalTipCard(),
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
                label: 'Criar Meta',
                loading: state.saving,
                onPressed: state.saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
