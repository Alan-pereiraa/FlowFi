import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/routes.dart';
import '../../../../shared/appearance/app_icons.dart';
import '../../../../shared/appearance/app_palette.dart';
import '../../../../shared/utils/currency_input_formatter.dart';
import '../../../../shared/utils/date_labels.dart';
import '../../../../shared/utils/money.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_danger_button.dart';
import '../../../../shared/widgets/app_date_field.dart';
import '../../../../shared/widgets/app_icon_tile.dart';
import '../../../../shared/widgets/app_money_field.dart';
import '../../../../shared/widgets/app_progress_bar.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/appearance_picker.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_update.dart';
import '../controllers/goal_detail_controller.dart';
import '../controllers/goal_detail_state.dart';

/// One goal: where it stands, add money to it, edit it, delete it. Lives
/// inside the app shell, so it has no `Scaffold`.
///
/// Opened with the [Goal] already in hand (`extra`) when coming from the list;
/// with only the [goalId] (a deep link, or a browser refresh on web) it is
/// fetched first.
// GAP: no design exists for this screen; it is built from the design system's
// own pieces (cards, fields, buttons) and mirrors the "Nova Meta" form.
class GoalDetailPage extends ConsumerStatefulWidget {
  const GoalDetailPage({super.key, required this.goalId, this.initial});

  final int goalId;
  final Goal? initial;

  @override
  ConsumerState<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends ConsumerState<GoalDetailPage> {
  final _editKey = GlobalKey<FormState>();
  final _depositKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _deposit = TextEditingController();

  DateTime? _expiresAt;
  String _icon = AppIcons.defaultGoal;
  String _color = AppPalette.defaultHex;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _fill(initial);
    } else {
      Future.microtask(
        () => ref.read(goalDetailControllerProvider.notifier).load(widget.goalId),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _deposit.dispose();
    super.dispose();
  }

  /// Fills the edit form once, from the goal as first known.
  void _fill(Goal goal) {
    _filled = true;
    _name.text = goal.name;
    _target.text = CurrencyInputFormatter.textOf(goal.targetCents);
    _expiresAt = goal.expiresAt;
    _icon = goal.icon;
    _color = goal.color;
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

  void _saveEdits() {
    if (!_editKey.currentState!.validate()) return;
    ref
        .read(goalDetailControllerProvider.notifier)
        .save(
          widget.goalId,
          GoalUpdate(
            name: _name.text.trim(),
            icon: _icon,
            color: _color,
            targetCents: CurrencyInputFormatter.centsOf(_target.text),
            expiresAt: _expiresAt,
          ),
        );
  }

  void _addMoney(Goal goal) {
    if (!_depositKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(goalDetailControllerProvider.notifier)
        .deposit(goal, CurrencyInputFormatter.centsOf(_deposit.text));
  }

  Future<void> _confirmRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir meta?'),
        content: const Text(
          'A meta deixa de aparecer na lista. Esta ação não pode ser '
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
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(goalDetailControllerProvider.notifier)
          .remove(widget.goalId);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.goals);
    }
  }

  void _leave(GoalOutcome outcome) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (outcome) {
          GoalOutcome.updated => 'Meta atualizada.',
          GoalOutcome.removed => 'Meta excluída.',
        }),
      ),
    );
    _back();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(goalDetailControllerProvider.select((s) => s.outcome), (
      _,
      outcome,
    ) {
      if (outcome != null) _leave(outcome);
    });
    ref.listen(goalDetailControllerProvider.select((s) => s.depositCount), (
      previous,
      count,
    ) {
      if (count == previous) return;
      _deposit.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Valor adicionado.')));
    });

    final state = ref.watch(goalDetailControllerProvider);
    final goal = state.goal ?? widget.initial;

    // Fetched by id: fill the form once, when the goal arrives.
    if (!_filled && state.goal != null) _fill(state.goal!);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ResponsiveCenter(
        verticalPadding: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Minhas metas'),
              ),
            ),
            const SizedBox(height: 8),
            if (goal == null)
              _Loading(
                error: state.loadError,
                onRetry: () => ref
                    .read(goalDetailControllerProvider.notifier)
                    .load(widget.goalId),
              )
            else
              _content(context, state, goal),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, GoalDetailState state, Goal goal) {
    final summary = _SummaryCard(goal: goal);
    final deposit = _depositCard(context, state, goal);
    final edit = _editCard(context, state);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Phone: one column. Wide: where it stands and add-money on the left,
        // the edit form on the right.
        if (constraints.maxWidth < 860) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summary,
              const SizedBox(height: 16),
              deposit,
              const SizedBox(height: 16),
              edit,
              const SizedBox(height: 16),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [summary, const SizedBox(height: 16), deposit],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(child: edit),
          ],
        );
      },
    );
  }

  Widget _depositCard(BuildContext context, GoalDetailState state, Goal goal) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _depositKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Adicionar valor', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Quanto você guardou para essa meta agora?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              AppMoneyField(
                label: 'Valor',
                controller: _deposit,
                errorText: state.depositError,
                enabled: !state.busy,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addMoney(goal),
                validator: (v) => CurrencyInputFormatter.centsOf(v ?? '') > 0
                    ? null
                    : 'Informe o valor.',
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Adicionar valor',
                icon: Icons.add,
                loading: state.depositing,
                onPressed: state.busy ? null : () => _addMoney(goal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editCard(BuildContext context, GoalDetailState state) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _editKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editar meta', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nome da Meta',
                hint: 'Ex: Viagem de Férias',
                controller: _name,
                icon: Icons.edit_note,
                errorText: state.fieldErrors['name'],
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                enabled: !state.busy,
                validator: (v) => Validators.requiredField(
                  v,
                  message: 'Informe o nome da meta.',
                ),
                suffix: IconButton(
                  tooltip: 'Escolher ícone e cor',
                  onPressed: state.busy ? null : _pickAppearance,
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
                enabled: !state.busy,
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
                enabled: !state.busy,
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
                label: 'Salvar alterações',
                icon: Icons.check_circle,
                loading: state.saving,
                onPressed: state.busy ? null : _saveEdits,
              ),
              const SizedBox(height: 12),
              AppDangerButton(
                label: 'Excluir meta',
                loading: state.removing,
                onPressed: state.busy ? null : _confirmRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spinner while the goal is fetched, or the error with a retry.
class _Loading extends StatelessWidget {
  const _Loading({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (error == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Text(
            error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 240,
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the goal stands: identity, deadline, saved vs. target, what is left.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = AppPalette.parse(goal.color);

    final saved = Money.format(goal.currentCents, dropZeroCents: true);
    final target = Money.format(goal.targetCents, dropZeroCents: true);
    final monthly = goal.monthlyContributionCents(DateTime.now());
    final remaining = goal.targetCents - goal.currentCents;

    return Semantics(
      container: true,
      label: '${goal.name}. $saved de $target. ${goal.percent}% concluído.',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIconTile(icon: AppIcons.resolve(goal.icon), color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: saved,
                      style: theme.textTheme.headlineSmall,
                    ),
                    TextSpan(
                      text: ' / $target',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${goal.percent}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AppProgressBar(value: goal.progress),
              const SizedBox(height: 16),
              _Line(
                label: 'Data alvo',
                value: goal.expiresAt == null
                    ? 'Contínua'
                    : DateLabels.monthYear(goal.expiresAt!),
              ),
              _Line(
                label: goal.reached ? 'Situação' : 'Falta guardar',
                value: goal.reached
                    ? 'Meta alcançada'
                    : Money.format(remaining, dropZeroCents: true),
              ),
              if (monthly != null)
                _Line(
                  label: 'Guardar por mês',
                  value: Money.format(monthly),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
