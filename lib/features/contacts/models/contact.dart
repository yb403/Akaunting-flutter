class Contact {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String type;
  final String currencyCode;
  final double balance;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.type,
    required this.currencyCode,
    required this.balance,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? 'No Email',
      phone: json['phone'] as String? ?? 'No Phone',
      type: json['type'] as String? ?? 'customer',
      currencyCode: json['currency_code'] as String? ?? 'USD',
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }
}
