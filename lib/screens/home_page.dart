import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../services/csv_service.dart';
import '../utils/formatters.dart';
import '../widgets/expense_list_item.dart';
import 'history_page.dart';
import 'stats_page.dart';

const _csvExportChannel = MethodChannel('expense_tracker/csv_export');

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _controller.text;
    if (input.trim().isEmpty) return;
    final provider = context.read<ExpenseProvider>();
    try {
      await provider.submitCommand(input);
      _controller.clear();
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _close() async {
    await context.read<ExpenseProvider>().closeCurrent();
  }

  Future<void> _exportCsv() async {
    final provider = context.read<ExpenseProvider>();
    final csvContent = exportPeriodsToCsv(provider.allPeriods);
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );

    try {
      await _csvExportChannel.invokeMethod('saveCsvToDownloads', {
        'fileName': 'expense_tracker_export_$timestamp.csv',
        'content': csvContent,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Exported to Downloads')));
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: ${e.message}')));
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import CSV'),
        content: const Text(
          'This replaces all current and previous expenses with the '
          "file's contents. This can't be undone. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final provider = context.read<ExpenseProvider>();
    try {
      await provider.importCsv(utf8.decode(bytes));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Import complete')));
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Stats',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatsPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HistoryPage()));
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'export') _exportCsv();
              if (value == 'import') _importCsv();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export', child: Text('Export CSV')),
              PopupMenuItem(value: 'import', child: Text('Import CSV')),
            ],
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = provider.currentPeriod?.expenses ?? [];
          final total = provider.currentPeriod?.total ?? 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  formatBdt(total),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(child: Text('No expenses yet'))
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) =>
                            ExpenseListItem(expense: expenses[index]),
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          inputFormatters: [_LowerCaseTextFormatter()],
                          decoration: const InputDecoration(
                            hintText: 'e.g. fare 60',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        tooltip: 'Add expense',
                        onPressed: _submit,
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton(
                        onPressed: expenses.isEmpty ? null : _close,
                        child: const Text('close'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Converts any typed or pasted uppercase letters to lowercase.
class _LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
