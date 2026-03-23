class Account {
  final int id;
  final String name;
  final String currencyCode;
  final double balance;
  final String? bankName;

  Account({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.balance,
    this.bankName,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as int,
      name: json['name'] as String,
      currencyCode: json['currency_code'] as String? ?? 'USD',
      balance: (json['balance'] ?? 0).toDouble(),
      bankName: json['bank_name'] as String?,
    );
  }
}
