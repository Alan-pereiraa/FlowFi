import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/routes.dart';
import '../../../../core/clock.dart';
import '../../../../shared/money/money.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/dates.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/money_amount_field.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_input.dart';
import '../../domain/entities/transaction_schedule.dart';
import '../../domain/entities/transaction_type.dart';
import '../controllers/transaction_form_controller.dart';
import '../controllers/transaction_form_state.dart';
import '../widgets/category_chips.dart';
import '../widgets/recurrence_card.dart';
import '../widgets/transaction_type_toggle.dart';

/// "Nova Transação" ([transactionId] null) and "Editar Transação".
/// Pops with `true` after a save or delete so the statement reloads.
class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.transactionId});

  final int? transactionId;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  static const _maxListedDuration = 24;

  final _description = TextEditingController();
  final _dateText = TextEditingController();
  TransactionType _type = TransactionType.expense;
  Money _amount = Money.zero;
  late DateTime _date;
  int? _categoryId;
  int _installments = 1;

  /// Client-side "empty field" checks; the API's 422 is the real validation.
  String? _amountMissing;
  String? _categoryMissing;

  bool get _isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _setDate(Dates.dateOnly(ref.read(clockProvider)()));
  }

  @override
  void dispose() {
    _description.dispose();
    _dateText.dispose();
    super.dispose();
  }

  void _setDate(DateTime date) {
    _date = date;
    _dateText.text = Dates.input(date);
  }

  void _fillFrom(Transaction original) {
    setState(() {
      _type = original.type;
      _amount = original.totalAmount;
      _description.text = original.description ?? '';
      _setDate(original.date);
      _categoryId = original.categoryId;
      _installments = original.installmentsCount;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _setDate(picked));
  }

  Future<void> _createCategory() async {
    final created = await context.push<Category>(Routes.newCategory);
    if (created == null || !mounted) return;
    ref
        .read(transactionFormControllerProvider(widget.transactionId).notifier)
        .categoryCreated(created);
    setState(() {
      _categoryId = created.id;
      _categoryMissing = null;
    });
  }

  void _submit() {
    setState(() {
      _amountMissing = _amount.isZero ? 'Informe um valor.' : null;
      _categoryMissing = _categoryId == null ? 'Escolha uma categoria.' : null;
    });
    if (_amountMissing != null || _categoryMissing != null) return;

    final description = _description.text.trim();
    ref
        .read(transactionFormControllerProvider(widget.transactionId).notifier)
        .save(
          TransactionInput(
            type: _type,
            categoryId: _categoryId!,
            date: _date,
            description: description.isEmpty ? null : description,
            schedule: TransactionSchedule(
              totalAmount: _amount,
              installmentsCount: _installments,
            ),
          ),
        );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir transação?'),
        content: const Text(
          'A transação e todas as suas parcelas serão removidas.',
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
      await ref
          .read(
            transactionFormControllerProvider(widget.transactionId).notifier,
          )
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = transactionFormControllerProvider(widget.transactionId);
    ref.listen(provider.select((s) => s.original), (previous, original) {
      if (previous == null && original != null) _fillFrom(original);
    });
    ref.listen(provider.select((s) => s.saved || s.deleted), (_, done) {
      if (done) context.pop(true);
    });
    final state = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar Transação' : 'Nova Transação'),
        actions: [
          if (_isEdit && state.original != null)
            IconButton(
              tooltip: 'Excluir transação',
              onPressed: state.busy ? null : _confirmDelete,
              icon: state.deleting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(child: _body(context, state)),
    );
  }

  Widget _body(BuildContext context, TransactionFormState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadError != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyState(
            icon: Icons.cloud_off,
            title: 'Não foi possível carregar',
            message: state.loadError,
          ),
          TextButton(
            onPressed: ref
                .read(
                  transactionFormControllerProvider(widget.transactionId)
                      .notifier,
                )
                .load,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locked = state.scheduleLocked;
    final amountColor = _type == TransactionType.expense
        ? scheme.error
        : theme.extension<AppColors>()!.success;
    final durationOptions = {
      for (var n = 1; n <= _maxListedDuration; n++) n,
      _installments,
    }.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TransactionTypeToggle(
                value: _type,
                // Immutable on the backend: changing it means delete + create.
                onChanged: _isEdit
                    ? null
                    : (type) => setState(() => _type = type),
              ),
              const SizedBox(height: 32),
              MoneyAmountField(
                label: _isEdit ? 'NOVO VALOR' : 'VALOR',
                value: _amount,
                color: amountColor,
                enabled: !locked,
                errorText: _amountMissing ?? state.fieldErrors['total_amount'],
                onChanged: (value) => setState(() {
                  _amount = value;
                  _amountMissing = null;
                }),
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Descrição',
                hint: 'Ex: Mercado',
                controller: _description,
                icon: Icons.edit_note,
                errorText: state.fieldErrors['description'],
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Data',
                controller: _dateText,
                icon: Icons.calendar_today_outlined,
                errorText: state.fieldErrors['date'],
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              Text(
                'Categoria',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              CategoryChips(
                categories: state.categories,
                selectedId: _categoryId,
                onCreate: _createCategory,
                onSelected: (id) => setState(() {
                  _categoryId = id;
                  _categoryMissing = null;
                }),
              ),
              if ((_categoryMissing ?? state.fieldErrors['category_id'])
                  case final error?) ...[
                const SizedBox(height: 4),
                Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              RecurrenceCard(
                value: _installments > 1,
                onChanged: locked
                    ? null
                    : (on) => setState(() => _installments = on ? 2 : 1),
              ),
              const SizedBox(height: 16),
              Text(
                'Selecione a duração da transação',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _installments,
                key: ValueKey(_installments),
                items: [
                  for (final n in durationOptions)
                    if (n > 1 || _installments == 1)
                      DropdownMenuItem(value: n, child: Text('${n}x')),
                ],
                onChanged: locked || _installments == 1
                    ? null
                    : (n) => setState(() => _installments = n!),
                decoration: InputDecoration(
                  errorText:
                      state.fieldErrors['installments_count'] ??
                      state.fieldErrors['period_unit'],
                  helperText: _installments > 1
                      ? 'O valor total é dividido entre as parcelas mensais.'
                      : null,
                ),
              ),
              if (locked) ...[
                const SizedBox(height: 16),
                Text(
                  'Esta transação já tem parcelas pagas, então valor, '
                  'recorrência e duração não podem mais ser alterados.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (state.formError != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.formError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'Salvar Transação',
                icon: Icons.check_circle,
                loading: state.saving,
                onPressed: state.busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
