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
import '../../../../shared/appearance/app_palette.dart';
import '../../../../shared/layout/breakpoints.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_danger_button.dart';
import '../../../../shared/widgets/appearance_picker.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_draft.dart';
import '../category_routes.dart';
import '../controllers/category_form_state.dart';
import '../widgets/category_name_field.dart';
import '../widgets/limit_stepper.dart';

/// "Adicionar Categoria". Pops with the created `Category`, so callers (the
/// transaction form) can select it right away.
class CategoryQuickFormPage extends ConsumerStatefulWidget {
  const CategoryQuickFormPage({super.key});

  @override
  ConsumerState<CategoryQuickFormPage> createState() =>
      _CategoryQuickFormPageState();
}

class _CategoryQuickFormPageState extends ConsumerState<CategoryQuickFormPage> {
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

/// "Adicionar Categoria" and "Editar" share this screen.
///
/// Edit is opened with the [Category] already in hand (`extra`) when coming
/// from the list; when only the [categoryId] is known (a deep link, or a
/// browser refresh on web) it is fetched first.
// GAP: icon and color are required by the API but the design shows them only
// as the two small controls inside the name field. Untouched, they save as the
// "local_offer" icon in the brand green.
class CategoryFormPage extends ConsumerStatefulWidget {
  const CategoryFormPage.create({super.key})
    : categoryId = null,
      initial = null;

  const CategoryFormPage.edit({
    super.key,
    required int this.categoryId,
    this.initial,
  });

  final int? categoryId;
  final Category? initial;

  bool get isEdit => categoryId != null;

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  int _limitCents = 0;
  String? _icon;
  String? _color;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _fill(initial);
    } else if (widget.isEdit) {
      Future.microtask(
        () => ref
            .read(categoryFormControllerProvider.notifier)
            .loadForEdit(widget.categoryId!),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _fill(Category category) {
    _filled = true;
    _name.text = category.name;
    _limitCents = category.limitCents ?? 0;
    _icon = category.icon;
    _color = category.color;
  }

  Future<void> _pickColor() async {
    final hex = await showColorPickerSheet(context, selected: _color);
    if (mounted && hex != null) setState(() => _color = hex);
  }

  Future<void> _pickIcon() async {
    final name = await showIconPickerSheet(
      context,
      selected: _icon,
      tint: _color,
    );
    if (mounted && name != null) setState(() => _icon = name);
  }

  CategoryDraft _draft() => CategoryDraft(
    name: _name.text.trim(),
    icon: _icon ?? AppIcons.defaultCategory,
    color: _color ?? AppPalette.defaultHex,
    // Zero means "no limit": the API takes null, never 0.00.
    limitCents: _limitCents > 0 ? _limitCents : null,
  );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(categoryFormControllerProvider.notifier);
    if (widget.isEdit) {
      controller.update(widget.categoryId!, _draft());
    } else {
      controller.create(_draft());
    }
  }

  Future<void> _confirmRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover categoria?'),
        content: const Text(
          'A categoria deixa de aparecer na lista. Esta ação não pode ser '
          'desfeita.',
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
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(categoryFormControllerProvider.notifier)
          .remove(widget.categoryId!);
    }
  }

  void _leave(CategoryOutcome outcome) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (outcome) {
          CategoryOutcome.created => 'Categoria criada.',
          CategoryOutcome.updated => 'Categoria atualizada.',
          CategoryOutcome.removed => 'Categoria removida.',
        }),
      ),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(CategoryRoutes.list);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(categoryFormControllerProvider.select((s) => s.outcome), (
      _,
      outcome,
    ) {
      if (outcome != null) _leave(outcome);
    });

    final state = ref.watch(categoryFormControllerProvider);

    // Fetched by id: fill the form once, when the category arrives.
    final fetched = state.initial;
    if (!_filled && fetched != null) _fill(fetched);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar' : 'Adicionar Categoria'),
        leadingWidth: 64,
        leading: const AppBackButton(fallbackRoute: CategoryRoutes.list),
      ),
      body: SafeArea(child: _body(context, state)),
    );
  }

  Widget _body(BuildContext context, CategoryFormState state) {
    final theme = Theme.of(context);

    if (widget.isEdit && !_filled) {
      if (state.loadError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.loadError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 240,
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(categoryFormControllerProvider.notifier)
                        .loadForEdit(widget.categoryId!),
                    child: const Text('Tentar novamente'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ResponsiveCenter(
              maxWidth: Breakpoints.formMax,
              verticalPadding: 24,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    LimitStepper(
                      cents: _limitCents,
                      caption: widget.isEdit
                          ? 'Editar Limite'
                          : 'Adicionar Limite',
                      captionBelow: widget.isEdit,
                      errorText: state.fieldErrors['limit_amount'],
                      enabled: !state.busy,
                      onChanged: (cents) => setState(() => _limitCents = cents),
                    ),
                    const SizedBox(height: 40),
                    CategoryNameField(
                      label: widget.isEdit
                          ? 'Editar Categoria'
                          : 'Nome da Categoria',
                      hint: 'Ex: Alimentação',
                      controller: _name,
                      color: _color,
                      icon: _icon,
                      errorText:
                          state.fieldErrors['name'] ??
                          state.fieldErrors['color'] ??
                          state.fieldErrors['icon'],
                      enabled: !state.busy,
                      onPickColor: _pickColor,
                      onPickIcon: _pickIcon,
                      onSubmitted: (_) => _save(),
                      validator: (v) => Validators.requiredField(
                        v,
                        message: 'Informe o nome da categoria.',
                      ),
                    ),
                    if (widget.isEdit) ...[
                      const SizedBox(height: 16),
                      AppDangerButton(
                        label: 'Remover',
                        loading: state.removing,
                        onPressed: state.busy ? null : _confirmRemove,
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
          ),
        ),
        // Pinned under the scroll area, as in the design: "Salvar" never
        // moves, and stays reachable with the keyboard open.
        ResponsiveCenter(
          maxWidth: Breakpoints.formMax,
          verticalPadding: 16,
          child: AppButton(
            label: 'Salvar',
            icon: Icons.check_circle,
            loading: state.saving,
            onPressed: state.busy ? null : _save,
          ),
        ),
      ],
    );
  }
}
