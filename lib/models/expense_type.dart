class ExpenseType {
  final int id;
  final String name;

  const ExpenseType({required this.id, required this.name});

  factory ExpenseType.fromMap(Map<String, Object?> map) {
    return ExpenseType(id: map['id'] as int, name: map['name'] as String);
  }
}
