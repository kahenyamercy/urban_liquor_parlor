class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  // Convert Supabase row (a Map) into a Product object
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id:       map['id'].toString(),
      name:     map['name'] as String,
      category: map['category'] as String,
      price:    (map['price'] as num).toDouble(),
      stock:    map['stock'] as int,
      imageUrl: map['image_url'] as String?,
    );
  }
}