import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static final _dateFormat = DateFormat('MMM d, yyyy');

  // Dates currently selected in the pickers.
  late DateTime _from;
  late DateTime _to;

  // Range the expense list is filtered by; updated when Apply is pressed.
  late DateTime _appliedFrom;
  late DateTime _appliedTo;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _to = DateTime(now.year, now.month, now.day);
    _from = DateTime(_to.year, _to.month, _to.day - 30);
    _appliedFrom = _from;
    _appliedTo = _to;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: isFrom ? DateTime(2000) : _from,
      lastDate: isFrom ? _to : DateTime(today.year, today.month, today.day),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  void _applyFilter() {
    setState(() {
      _appliedFrom = _from;
      _appliedTo = _to;
    });
  }

  /// Every expense created between the start of [_appliedFrom] and the end
  /// of [_appliedTo] (inclusive).
  List<Expense> _filteredExpenses(ExpenseProvider provider) {
    final start = _appliedFrom;
    final end = DateTime(_appliedTo.year, _appliedTo.month, _appliedTo.day + 1);
    final expenses = [
      for (final period in provider.allPeriods)
        for (final expense in period.expenses)
          if (!expense.createdAt.isBefore(start) &&
              expense.createdAt.isBefore(end))
            expense,
    ];
    return expenses;
  }

  Future<void> _showClearHistoryDialog(
    BuildContext context,
    int previousCount,
  ) async {
    final provider = context.read<ExpenseProvider>();
    final controller = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Clear History'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How many of the oldest previous periods should be '
                    'deleted? ($previousCount available)',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. 3',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final n = int.tryParse(controller.text.trim());
                    if (n == null || n <= 0) {
                      setState(() => errorText = 'Enter a positive number');
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    provider.clearOldestPrevious(n);
                  },
                  child: const Text('Clear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('History')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final previous = provider.previousPeriods;
        final expenses = _filteredExpenses(provider);
        final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
        final typeTotals = <String, double>{};
        for (final expense in expenses) {
          typeTotals.update(
            expense.type,
            (sum) => sum + expense.amount,
            ifAbsent: () => expense.amount,
          );
        }
        final sortedTypes = typeTotals.keys.toList()..sort();

        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear History',
                onPressed: previous.isEmpty
                    ? null
                    : () => _showClearHistoryDialog(context, previous.length),
              ),
            ],
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'From',
                        value: _dateFormat.format(_from),
                        onTap: () => _pickDate(isFrom: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'To',
                        value: _dateFormat.format(_to),
                        onTap: () => _pickDate(isFrom: false),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: _applyFilter,
                  child: const Text('Apply'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '${_dateFormat.format(_appliedFrom)} - '
                  '${_dateFormat.format(_appliedTo)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('No expenses in this date range'),
                )
              else ...[
                for (final type in sortedTypes)
                  ListTile(
                    dense: true,
                    title: Text(type),
                    trailing: Text(
                      formatBdt(typeTotals[type]!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                const Divider(),
                ListTile(
                  title: Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Text(
                    formatBdt(total),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(value),
      ),
    );
  }
}
