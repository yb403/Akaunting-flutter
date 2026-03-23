class Bill {
  final int id;
  final String documentNumber;
  final String contactName;
  final String status;
  final double amount;
  final String currencyCode;
  final String issuedAt;

  Bill({
    required this.id,
    required this.documentNumber,
    required this.contactName,
    required this.status,
    required this.amount,
    required this.currencyCode,
    required this.issuedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as int,
      documentNumber: json['document_number'] as String? ?? 'N/A',
      contactName: json['contact_name'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      currencyCode: json['currency_code'] as String? ?? 'USD',
      issuedAt: json['issued_at'] as String? ?? 'Unknown Date',
    );
  }
}
