import '../models/expense.dart';
import '../models/expense_period.dart';
import '../models/imported_row.dart';
import 'database_helper.dart';

class ExpenseRepository {
  final DatabaseHelper _dbHelper;

  ExpenseRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<Expense>> _expensesForPeriod(int periodId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'expenses',
      where: 'period_id = ?',
      whereArgs: [periodId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<ExpensePeriod> getCurrentPeriod() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'periods',
      where: 'closed_at IS NULL',
      limit: 1,
    );
    final period = ExpensePeriod.fromMap(rows.first);
    final expenses = await _expensesForPeriod(period.id);
    return period.copyWith(expenses: expenses);
  }

  Future<List<ExpensePeriod>> getPreviousPeriods() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'periods',
      where: 'closed_at IS NOT NULL',
      orderBy: 'closed_at DESC',
    );
    final periods = <ExpensePeriod>[];
    for (final row in rows) {
      final period = ExpensePeriod.fromMap(row);
      final expenses = await _expensesForPeriod(period.id);
      periods.add(period.copyWith(expenses: expenses));
    }
    return periods;
  }

  Future<void> addExpense(String type, double amount) async {
    final db = await _dbHelper.database;
    final current = await getCurrentPeriod();
    await db.insert('expenses', {
      'period_id': current.id,
      'type': type,
      'amount': amount,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> closeCurrentPeriod() async {
    final db = await _dbHelper.database;
    final current = await getCurrentPeriod();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'periods',
      {'closed_at': now},
      where: 'id = ?',
      whereArgs: [current.id],
    );
    await db.insert('periods', {'started_at': now, 'closed_at': null});
  }

  /// Deletes the [count] oldest previous (closed) periods, along with
  /// their expenses. If fewer than [count] previous periods exist, all
  /// of them are deleted.
  Future<void> clearOldestPreviousPeriods(int count) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'periods',
      columns: ['id'],
      where: 'closed_at IS NOT NULL',
      orderBy: 'closed_at ASC',
      limit: count,
    );
    if (rows.isEmpty) return;

    final ids = rows.map((row) => row['id'] as int).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.transaction((txn) async {
      await txn.delete(
        'expenses',
        where: 'period_id IN ($placeholders)',
        whereArgs: ids,
      );
      await txn.delete(
        'periods',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
    });
  }

  /// Replaces all periods and expenses with the contents of [rows] (as
  /// produced by [parseCsvToRows]). Throws a [FormatException] and leaves
  /// existing data untouched if [rows] doesn't contain exactly one open
  /// (current) period.
  Future<void> replaceAllData(List<ImportedExpenseRow> rows) async {
    final db = await _dbHelper.database;

    final periodMeta = <String, ({DateTime startedAt, DateTime? closedAt})>{};
    for (final row in rows) {
      periodMeta.putIfAbsent(
        row.periodKey,
        () => (startedAt: row.periodStartedAt, closedAt: row.periodClosedAt),
      );
    }

    final openCount = periodMeta.values
        .where((p) => p.closedAt == null)
        .length;
    if (openCount != 1) {
      throw const FormatException(
        'CSV must contain exactly one open (current) period',
      );
    }

    await db.transaction((txn) async {
      await txn.delete('expenses');
      await txn.delete('periods');

      final periodIds = <String, int>{};
      final sortedKeys = periodMeta.keys.toList()
        ..sort(
          (a, b) =>
              periodMeta[a]!.startedAt.compareTo(periodMeta[b]!.startedAt),
        );
      for (final key in sortedKeys) {
        final meta = periodMeta[key]!;
        final id = await txn.insert('periods', {
          'started_at': meta.startedAt.millisecondsSinceEpoch,
          'closed_at': meta.closedAt?.millisecondsSinceEpoch,
        });
        periodIds[key] = id;
      }

      for (final row in rows) {
        if (row.type == null) continue;
        await txn.insert('expenses', {
          'period_id': periodIds[row.periodKey],
          'type': row.type,
          'amount': row.amount,
          'created_at': row.expenseCreatedAt!.millisecondsSinceEpoch,
        });
      }
    });
  }
}
