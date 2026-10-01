class AdditionalExpense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;

  AdditionalExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
  });

  AdditionalExpense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
  }) {
    return AdditionalExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  factory AdditionalExpense.fromJson(Map<String, dynamic> json) => AdditionalExpense(
    id: json['id'] as String,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
  );
}
