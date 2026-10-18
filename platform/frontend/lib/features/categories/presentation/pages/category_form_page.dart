import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/appearance_picker.dart';
import '../../../../shared/appearance/hex_color.dart';
import '../../../../shared/money/money.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/money_amount_field.dart';
import '../../domain/entities/category_input.dart';
import '../controllers/category_form_controller.dart';

/// "Adicionar Categoria". Pops with the created `Category`, so callers (the
/// transaction form) can select it right away.
class CategoryFormPage extends ConsumerStatefulWidget {
  const CategoryFormPage({super.key});

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  static const _limitStep = Money(1000);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  Money _limit = Money.zero;
  String _color = HexColor.palette.first;
  String? _icon;
  bool _iconMissing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    final color = await AppearancePicker.pickColor(context, selected: _color);
    if (color != null) setState(() => _color = color);
  }

  Future<void> _pickIcon() async {
    final icon = await AppearancePicker.pickIcon(
      context,
      selected: _icon,
      color: HexColor.tryParse(_color),
    );
    if (icon != null) {
      setState(() {
        _icon = icon;
        _iconMissing = false;
      });
    }
  }

  void _submit() {
    final validName = _formKey.currentState!.validate();
    setState(() => _iconMissing = _icon == null);
    if (!validName || _icon == null) return;
    ref
        .read(categoryFormControllerProvider.notifier)
        .save(
          CategoryInput(
            name: _name.text.trim(),
            icon: _icon!,
            color: _color,
            // Zero means "Sem limite".
            limitAmount: _limit.isZero ? null : _limit,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(categoryFormControllerProvider.select((s) => s.created), (
      _,
      created,
    ) {
      if (created != null) context.pop(created);
    });
    final state = ref.watch(categoryFormControllerProvider);
    final theme = Theme.of(context);
    final accent = HexColor.parse(_color, fallback: theme.colorScheme.primary);

    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Categoria')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MoneyAmountField(
                        label: 'Adicionar Limite',
                        value: _limit,
                        step: _limitStep,
                        errorText: state.fieldErrors['limit_amount'],
                        onChanged: (value) => setState(() => _limit = value),
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        label: 'Nome da Categoria',
                        hint: 'Ex: Alimentação',
                        controller: _name,
                        errorText: state.fieldErrors['name'],
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        validator: (v) => Validators.requiredField(
                          v,
                          message: 'Informe o nome da categoria.',
                        ),
                        prefix: IconButton(
                          tooltip: 'Escolher cor',
                          onPressed: _pickColor,
                          icon: CircleAvatar(
                            radius: 12,
                            backgroundColor: accent,
                          ),
                        ),
                        suffix: IconButton(
                          tooltip: 'Escolher ícone',
                          onPressed: _pickIcon,
                          color: _icon == null ? null : accent,
                          icon: Icon(
                            _icon == null
                                ? Icons.sentiment_satisfied_outlined
                                : AppIcons.resolve(_icon),
                          ),
                        ),
                      ),
                      if (_iconMissing ||
                          state.fieldErrors['icon'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          state.fieldErrors['icon'] ?? 'Escolha um ícone.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: AppButton(
                  label: 'Salvar',
                  icon: Icons.check_circle,
                  loading: state.saving,
                  onPressed: state.saving ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
