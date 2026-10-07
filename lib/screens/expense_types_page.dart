import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/expense_type.dart';
import '../providers/expense_provider.dart';
import '../utils/lowercase_text_formatter.dart';

/// Only letters may be typed or pasted; they are converted to lowercase.
final _expenseTypeInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
  const LowerCaseTextFormatter(),
];

class ExpenseTypesPage extends StatefulWidget {
  const ExpenseTypesPage({super.key});

  @override
  State<ExpenseTypesPage> createState() => _ExpenseTypesPageState();
}

class _ExpenseTypesPageState extends State<ExpenseTypesPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    if (_controller.text.trim().isEmpty) return;
    final provider = context.read<ExpenseProvider>();
    try {
      await provider.addExpenseType(_controller.text);
      _controller.clear();
    } on FormatException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    }
  }

  Future<void> _showRenameDialog(ExpenseType type) async {
    final provider = context.read<ExpenseProvider>();
    final controller = TextEditingController(text: type.name);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> save() async {
              try {
                await provider.renameExpenseType(type.id, controller.text);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } on FormatException catch (e) {
                setState(() => errorText = e.message);
              }
            }

            return AlertDialog(
              title: const Text('Edit Expense Type'),
              content: TextField(
                controller: controller,
                autofocus: true,
                inputFormatters: _expenseTypeInputFormatters,
                decoration: InputDecoration(
                  labelText: 'Expense Type',
                  errorText: errorText,
                ),
                onSubmitted: (_) => save(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(onPressed: save, child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _confirmDelete(ExpenseType type) async {
    final provider = context.read<ExpenseProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense Type'),
        content: Text(
          'Delete "${type.name}"? Existing expenses of this type are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.deleteExpenseType(type.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Types')),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final types = provider.expenseTypes;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        inputFormatters: _expenseTypeInputFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Expense Type',
                          hintText: 'e.g. grocery',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add expense type',
                      onPressed: _add,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: types.isEmpty
                    ? const Center(child: Text('No expense types yet'))
                    : ListView.builder(
                        itemCount: types.length,
                        itemBuilder: (context, index) {
                          final type = types[index];
                          return ListTile(
                            title: Text(type.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit',
                                  onPressed: () => _showRenameDialog(type),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Delete',
                                  onPressed: () => _confirmDelete(type),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
