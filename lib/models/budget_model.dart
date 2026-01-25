class Budget {
  final int? id;
  final String category;
  final double amount;
  final String period; // monthly, weekly, yearly
  final DateTime startDate;
  final DateTime endDate;
  final bool alertEnabled;
  final double alertThreshold; // percentage (e.g., 80 for 80%)

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.alertEnabled = true,
    this.alertThreshold = 80.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'alertEnabled': alertEnabled ? 1 : 0,
      'alertThreshold': alertThreshold,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: map['amount'] as double,
      period: map['period'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      alertEnabled: (map['alertEnabled'] as int?) == 1,
      alertThreshold: map['alertThreshold'] as double? ?? 80.0,
    );
  }
}
