class ShoppingItem {
  final int id;
  final String name;
  final String? quantity;
  final bool purchased;
  final int createdBy;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity,
    required this.purchased,
    required this.createdBy,
    required this.createdAt,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      purchased: json['purchased'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
