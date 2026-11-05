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
import '../../domain/entities/installment.dart';
import '../../domain/entities/recurring_input.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_draft.dart';
import '../../domain/entities/transaction_input.dart';
import '../../domain/entities/transaction_schedule.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/entities/recurrence.dart';
import '../controllers/transaction_form_controller.dart';
import '../controllers/transaction_form_state.dart';
import '../controllers/voice_draft_controller.dart';
import '../widgets/category_chips.dart';
import '../widgets/choice_row.dart';
import '../widgets/first_installment_notice.dart';
import '../widgets/goal_picker.dart';
import '../widgets/installments_section.dart';
import '../widgets/recurrence_card.dart';
import '../widgets/transaction_type_toggle.dart';
import '../widgets/voice_fill_card.dart';

/// "Nova Transação" ([transactionId] null) and "Editar Transação".
class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.transactionId});

  final int? transactionId;

  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  static const _maxListedCount = 24;

  final _description = TextEditingController();
  final _dateText = TextEditingController();
  TransactionType _type = TransactionType.expense;
  Money _amount = Money.zero;
  late DateTime _date;
  int? _categoryId;
  int? _goalId;

  int _installments = 1;

  bool _recurring = false;
  RecurrenceEnd _recurrenceEnd = RecurrenceEnd.occurrences;
  int _occurrences = 2;
  DateTime? _endDate;
  String _periodUnit = 'month';
  int _periodInterval = 1;

  /// Client-side "empty field" checks; the API's 422 is the real validation.
  String? _amountMissing;
  String? _categoryMissing;
  String? _goalMissing;
  String? _endDateMissing;

  bool get _isEdit => widget.transactionId != null;
  bool get _isTransfer => _type == TransactionType.transfer;
  bool get _isWithdrawal => _type == TransactionType.withdrawal;
  bool get _movesGoal => _type.movesGoal;
  String get _goalMissingMessage => _isWithdrawal
      ? 'Escolha a meta de origem.'
      : 'Escolha a meta de destino.';
  bool get _canSplit => _type == TransactionType.expense;
  bool get _isSplit => _canSplit && _installments > 1;

  TransactionFormController get _controller => ref.read(
    transactionFormControllerProvider(widget.transactionId).notifier,
  );

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
      _goalId = original.goalId;
      _installments = original.installmentsCount;
    });
  }

  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      if (type != TransactionType.expense) _installments = 1;
    });
    if (type.movesGoal &&
        ref
            .read(transactionFormControllerProvider(widget.transactionId))
            .goals
            .isEmpty) {
      _controller.loadGoals();
    }
  }

  Future<DateTime?> _askDate(DateTime initial, {DateTime? first}) =>
      showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: first ?? DateTime(2000),
        lastDate: DateTime(2100),
      );

  Future<void> _pickDate() async {
    final picked = await _askDate(_date);
    if (picked == null) return;
    setState(() {
      _setDate(picked);
      if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await _askDate(
      _endDate ?? DateTime(_date.year, _date.month + 3, _date.day),
      first: _date,
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      _recurrenceEnd = RecurrenceEnd.date;
      _endDateMissing = null;
    });
  }

  Future<void> _createCategory() async {
    final created = await context.push<Category>(Routes.newCategory);
    if (created == null || !mounted) return;
    _controller.categoryCreated(created);
    setState(() {
      _categoryId = created.id;
      _categoryMissing = null;
    });
  }

  void _submit() {
    final creatingRecurrence = !_isEdit && _recurring && !_isSplit;
    setState(() {
      _amountMissing = _amount.isZero ? 'Informe um valor.' : null;
      _categoryMissing = !_movesGoal && _categoryId == null
          ? 'Escolha uma categoria.'
          : null;
      _goalMissing = _movesGoal && _goalId == null ? _goalMissingMessage : null;
      _endDateMissing =
          creatingRecurrence &&
              _recurrenceEnd == RecurrenceEnd.date &&
              _endDate == null
          ? 'Escolha até quando repetir.'
          : null;
    });
    if (_amountMissing != null ||
        _categoryMissing != null ||
        _goalMissing != null ||
        _endDateMissing != null) {
      return;
    }

    final text = _description.text.trim();
    final description = text.isEmpty ? null : text;

    if (creatingRecurrence) {
      _controller.saveRecurring(
        RecurringInput(
          type: _type,
          categoryId: _movesGoal ? null : _categoryId,
          goalId: _movesGoal ? _goalId : null,
          amount: _amount,
          startDate: _date,
          description: description,
          occurrences: _recurrenceEnd == RecurrenceEnd.occurrences
              ? _occurrences
              : null,
          endDate: _recurrenceEnd == RecurrenceEnd.date ? _endDate : null,
          periodUnit: _periodUnit,
          periodInterval: _periodInterval,
        ),
      );
      return;
    }

    _controller.save(
      TransactionInput(
        type: _type,
        categoryId: _movesGoal ? null : _categoryId,
        goalId: _movesGoal ? _goalId : null,
        date: _date,
        description: description,
        schedule: TransactionSchedule(
          totalAmount: _amount,
          installmentsCount: _canSplit ? _installments : 1,
        ),
      ),
    );
  }

  void _applyDraft(TransactionDraft draft) {
    final today = Dates.dateOnly(ref.read(clockProvider)());
    setState(() {
      _type = draft.type;
      _amount = draft.amount ?? Money.zero;
      _description.text = draft.description ?? '';
      _setDate(draft.date ?? today);
      _categoryId = draft.movesGoal ? null : draft.categoryId;
      _goalId = draft.movesGoal ? draft.goalId : null;
      _installments =
          !draft.recurring &&
              draft.type == TransactionType.expense &&
              (draft.installmentsCount ?? 1) > 1
          ? draft.installmentsCount!
          : 1;
      _recurring = draft.recurring;
      _periodUnit = draft.periodUnit ?? 'month';
      _periodInterval = draft.periodInterval ?? 1;
      _endDate = draft.endDate;
      if (draft.occurrences != null) {
        _occurrences = draft.occurrences!.clamp(2, 120);
        _recurrenceEnd = RecurrenceEnd.occurrences;
      } else if (draft.endDate != null) {
        _recurrenceEnd = RecurrenceEnd.date;
      } else {
        _recurrenceEnd = draft.recurring
            ? RecurrenceEnd.never
            : RecurrenceEnd.occurrences;
      }
      _amountMissing = draft.missingAmount ? 'Informe um valor.' : null;
      _categoryMissing = draft.missingCategory
          ? 'Escolha uma categoria.'
          : null;
      _goalMissing = draft.missingGoal ? 'Escolha a meta de destino.' : null;
      _endDateMissing = null;
    });
    if (draft.movesGoal &&
        ref
            .read(transactionFormControllerProvider(widget.transactionId))
            .goals
            .isEmpty) {
      _controller.loadGoals();
    }
  }

  String _firstInstallmentMessage(Transaction? original) {
    final installments = original?.installments ?? const <Installment>[];
    final first = original?.date == _date && installments.isNotEmpty
        ? installments.first.date
        : _date;
    final month = Dates.monthYear(first);
    final today = Dates.dateOnly(ref.read(clockProvider)());
    return !_isEdit && !first.isAfter(today)
        ? 'A primeira parcela conta em $month e já entra como paga.'
        : 'A primeira parcela conta em $month.';
  }

  String get _recurrenceSubtitle {
    if (_periodUnit == 'month' && _periodInterval == 1) {
      return _isTransfer ? 'Repetir mensalmente' : 'Repetir mais vezes';
    }
    final unit = switch ((_periodUnit, _periodInterval == 1)) {
      ('day', true) => 'dia',
      ('day', false) => 'dias',
      ('week', true) => 'semana',
      ('week', false) => 'semanas',
      ('year', true) => 'ano',
      ('year', false) => 'anos',
      (_, true) => 'mês',
      (_, false) => 'meses',
    };
    return _periodInterval == 1
        ? 'Repetir a cada $unit'
        : 'Repetir a cada $_periodInterval $unit';
  }

  static String _every(String unit, int interval) {
    if (interval == 1) {
      return switch (unit) {
        'day' => 'todo dia',
        'week' => 'toda semana',
        'year' => 'todo ano',
        _ => 'todo mês',
      };
    }
    final units = switch (unit) {
      'day' => 'dias',
      'week' => 'semanas',
      'year' => 'anos',
      _ => 'meses',
    };
    return 'a cada $interval $units';
  }

  String _savedRecurrenceSubtitle(Recurrence recurrence) {
    final every = _every(recurrence.periodUnit, recurrence.periodInterval);
    if (!recurrence.active) return 'Encerrada. Repetia $every.';
    final end = recurrence.occurrences != null
        ? '${recurrence.generatedCount} de ${recurrence.occurrences} vezes'
        : recurrence.endDate != null
        ? 'até ${Dates.input(recurrence.endDate!)}'
        : 'sem data para terminar';
    return 'Repete $every, $end.\n'
        'Próxima: ${Dates.input(recurrence.nextOccurrenceOn!)}';
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmDelete() async {
    final confirmed = await _confirm(
      title: 'Excluir transação?',
      message: 'A transação e todas as suas parcelas serão removidas.',
      action: 'Excluir',
    );
    if (confirmed) await _controller.delete();
  }

  Future<void> _confirmEndRecurrence() async {
    final confirmed = await _confirm(
      title: 'Cancelar transação recorrente?',
      message:
          'Ela deixa de se repetir. Esta e as transações anteriores '
          'continuam no extrato.',
      action: 'Cancelar recorrência',
    );
    if (confirmed) await _controller.endRecurrence();
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
    ref.listen(provider.select((s) => s.recurrenceEnded), (_, ended) {
      if (!ended) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recorrência cancelada.')));
      context.pop(true);
    });
    ref.listen(voiceDraftControllerProvider.select((s) => s.draftVersion), (
      _,
      _,
    ) {
      final draft = ref.read(voiceDraftControllerProvider).draft;
      if (draft != null) _applyDraft(draft);
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
    final voice = ref.watch(voiceDraftControllerProvider);
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
            onPressed: _controller.load,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final amountColor = switch (_type) {
      TransactionType.expense => scheme.error,
      TransactionType.income => theme.extension<AppColors>()!.success,
      TransactionType.transfer => scheme.primary,
      TransactionType.withdrawal => scheme.tertiary,
    };
    final original = state.original;
    final recurrenceOn = _isEdit ? state.recurrenceActive : _recurring;
    final splitBlocked = recurrenceOn || (original?.isRecurring ?? false);

    Widget error(String message) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEdit) ...[
                VoiceFillCard(
                  state: voice,
                  onStart: ref
                      .read(voiceDraftControllerProvider.notifier)
                      .start,
                  onStop: ref.read(voiceDraftControllerProvider.notifier).stop,
                  onCancel: ref
                      .read(voiceDraftControllerProvider.notifier)
                      .cancel,
                ),
                const SizedBox(height: 16),
              ],
              TransactionTypeToggle(
                value: _type,
                // Immutable on the backend: changing it means delete + create.
                onChanged: _isEdit ? null : _setType,
              ),
              const SizedBox(height: 32),
              MoneyAmountField(
                label: _isEdit ? 'NOVO VALOR' : 'VALOR',
                value: _amount,
                color: amountColor,
                errorText:
                    _amountMissing ??
                    state.fieldErrors['total_amount'] ??
                    state.fieldErrors['amount'],
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
                errorText:
                    state.fieldErrors['date'] ??
                    state.fieldErrors['start_date'],
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              if (_movesGoal) ...[
                if (state.goalsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.goalsError != null)
                  Row(
                    children: [
                      Expanded(child: error(state.goalsError!)),
                      TextButton(
                        onPressed: _controller.loadGoals,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  )
                else
                  GoalPicker(
                    goals: state.goals,
                    selectedId: _goalId,
                    label: _isWithdrawal ? 'Meta de origem' : 'Meta de destino',
                    errorText: _goalMissing ?? state.fieldErrors['goal_id'],
                    onSelected: (id) => setState(() {
                      _goalId = id;
                      _goalMissing = null;
                    }),
                  ),
              ] else ...[
                if (_canSplit) ...[
                  ChoiceRow(
                    title: 'Transação Parcelada',
                    selected: _installments > 1,
                    onTap: splitBlocked && _installments <= 1
                        ? null
                        : () => setState(() {
                            _installments = _installments > 1 ? 1 : 2;
                          }),
                    trailing: _installments > 1
                        ? _CountMenu(
                            value: _installments,
                            tooltip: 'Número de parcelas',
                            onSelected: (n) =>
                                setState(() => _installments = n),
                            max: _maxListedCount,
                          )
                        : null,
                  ),
                  if (_installments > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'O valor total é dividido em $_installments parcelas '
                        'mensais.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (_installments > 1) ...[
                    const SizedBox(height: 12),
                    FirstInstallmentNotice(
                      message: _firstInstallmentMessage(original),
                    ),
                  ],
                  if (state.fieldErrors['installments_count'] ??
                          state.fieldErrors['period_unit']
                      case final message?)
                    error(message),
                  const SizedBox(height: 16),
                ],
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
                    case final message?)
                  error(message),
              ],
              if (!_isWithdrawal) ...[
                const SizedBox(height: 16),
                RecurrenceCard(
                  value: recurrenceOn,
                  subtitle: _isEdit && state.recurrence != null
                      ? _savedRecurrenceSubtitle(state.recurrence!)
                      : _recurrenceSubtitle,
                  onChanged: _isSplit
                      ? null
                      : _isEdit
                      ? (recurrenceOn && !state.busy
                            ? (on) {
                                if (!on) _confirmEndRecurrence();
                              }
                            : null)
                      : (on) => setState(() {
                          _recurring = on;
                          if (!on) {
                            _periodUnit = 'month';
                            _periodInterval = 1;
                          }
                        }),
                ),
              ],
              if (!_isEdit && _recurring && !_isSplit) ...[
                const SizedBox(height: 16),
                ChoiceRow(
                  title: 'Repetir',
                  subtitle: 'Selecione as parcelas',
                  selected: _recurrenceEnd == RecurrenceEnd.occurrences,
                  onTap: () => setState(
                    () => _recurrenceEnd = RecurrenceEnd.occurrences,
                  ),
                  trailing: _CountMenu(
                    value: _occurrences,
                    min: 2,
                    max: _maxListedCount,
                    tooltip: 'Quantas vezes repetir',
                    onSelected: (n) => setState(() {
                      _occurrences = n;
                      _recurrenceEnd = RecurrenceEnd.occurrences;
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                ChoiceRow(
                  title: 'Repetir durante',
                  subtitle: _endDate == null
                      ? 'Data específica'
                      : 'Até ${Dates.input(_endDate!)}',
                  selected: _recurrenceEnd == RecurrenceEnd.date,
                  onTap: () {
                    if (_endDate == null) {
                      _pickEndDate();
                    } else {
                      setState(() => _recurrenceEnd = RecurrenceEnd.date);
                    }
                  },
                  trailing: ChoicePill(
                    icon: Icons.calendar_today_outlined,
                    tooltip: 'Escolher data final',
                    onPressed: _pickEndDate,
                  ),
                ),
                const SizedBox(height: 12),
                ChoiceRow(
                  title: 'Repetir',
                  subtitle: 'Até ser cancelado',
                  selected: _recurrenceEnd == RecurrenceEnd.never,
                  onTap: () =>
                      setState(() => _recurrenceEnd = RecurrenceEnd.never),
                ),
                if (_endDateMissing ??
                        state.fieldErrors['end_date'] ??
                        state.fieldErrors['occurrences']
                    case final message?)
                  error(message),
              ],
              if (original != null && original.installments.isNotEmpty) ...[
                const SizedBox(height: 16),
                InstallmentsSection(
                  installments: original.installments,
                  busy: state.busy,
                  updatingId: state.updatingInstallmentId,
                  today: ref.read(clockProvider)(),
                  onToggle: _controller.toggleInstallment,
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
                onPressed: state.busy || voice.busy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountMenu extends StatelessWidget {
  const _CountMenu({
    required this.value,
    required this.onSelected,
    required this.tooltip,
    this.min = 2,
    this.max = 24,
  });

  final int value;
  final int min;
  final int max;
  final String tooltip;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = {for (var n = min; n <= max; n++) n, value}.toList()
      ..sort();
    return PopupMenuButton<int>(
      tooltip: tooltip,
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final n in options) PopupMenuItem(value: n, child: Text('${n}x')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: scheme.outline)),
        ),
        child: Text(
          '${value}x',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: scheme.onSurface),
        ),
      ),
    );
  }
}
