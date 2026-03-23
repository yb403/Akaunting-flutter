class Transaction {
  final int id;
  final String date;
  final double amount;
  final String currencyCode;
  final String type; // income, expense

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.currencyCode,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      date: json['paid_at'] as String? ?? 'Unknown Date',
      amount: (json['amount'] ?? 0).toDouble(),
      currencyCode: json['currency_code'] as String? ?? 'USD',
      type: json['type'] as String? ?? 'income',
    );
  }
}
