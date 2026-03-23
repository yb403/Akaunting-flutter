class Item {
  final int id;
  final String name;
  final String description;
  final double salePrice;
  final double purchasePrice;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.salePrice,
    required this.purchasePrice,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? 'No description',
      salePrice: (json['sale_price'] ?? 0).toDouble(),
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
    );
  }
}
