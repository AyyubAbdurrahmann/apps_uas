class Expense {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? description;
  final String? imagePath;
  final String currency;
  final bool isRecurring;
  final String? recurringType; // daily, weekly, monthly, yearly
  final DateTime? nextRecurringDate;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
    this.imagePath,
    this.currency = 'IDR',
    this.isRecurring = false,
    this.recurringType,
    this.nextRecurringDate,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
      'imagePath': imagePath,
      'currency': currency,
      'isRecurring': isRecurring ? 1 : 0,
      'recurringType': recurringType,
      'nextRecurringDate': nextRecurringDate?.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id']?.toString(),
      title: map['title'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      imagePath: map['imagePath'] as String?,
      currency: map['currency'] as String? ?? 'IDR',
      isRecurring: (map['isRecurring'] as int?) == 1,
      recurringType: map['recurringType'] as String?,
      nextRecurringDate: map['nextRecurringDate'] != null
          ? DateTime.parse(map['nextRecurringDate'] as String)
          : null,
    );
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    String? imagePath,
    String? currency,
    bool? isRecurring,
    String? recurringType,
    DateTime? nextRecurringDate,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      currency: currency ?? this.currency,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      nextRecurringDate: nextRecurringDate ?? this.nextRecurringDate,
    );
  }
}
