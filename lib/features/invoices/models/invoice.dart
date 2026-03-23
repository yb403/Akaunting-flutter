class Invoice {
  final int id;
  final String documentNumber;
  final String status;
  final double amount;
  final String currencyCode;
  final String contactName;
  final String issuedAt;

  Invoice({
    required this.id,
    required this.documentNumber,
    required this.status,
    required this.amount,
    required this.currencyCode,
    required this.contactName,
    required this.issuedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int,
      documentNumber: json['document_number'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'draft',
      amount: (json['amount'] ?? 0).toDouble(),
      currencyCode: json['currency_code'] as String? ?? 'USD',
      contactName: json['contact_name'] as String? ?? 'No Contact',
      issuedAt: json['issued_at'] as String? ?? '',
    );
  }
}
