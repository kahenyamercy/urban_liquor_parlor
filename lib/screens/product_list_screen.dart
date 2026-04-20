import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String category;
  final String? searchQuery;

  const ProductListScreen({
    super.key,
    required this.category,
    this.searchQuery,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      print('📦 Fetching products for: ${widget.category}');

      var query = supabase.from('products').select();

      // If it's a search, filter by name; otherwise filter by category
      if (widget.searchQuery != null) {
        query = query.ilike('name', '%${widget.searchQuery}%');
      } else {
        query = query.eq('category', widget.category);
      }

      final response = await query.order('name');
      final products = (response as List)
          .map((row) => Product.fromMap(row))
          .toList();

      print('✅ Products loaded: ${products.length}');

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading products: $e');
      setState(() {
        _error = 'Failed to load products.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Text(
          widget.searchQuery != null
              ? 'Results for "${widget.searchQuery}"'
              : widget.category,
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1A2E)),
      );
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('No products found.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) => _buildProductCard(_products[index]),
    );
  }

  Widget _buildProductCard(Product product) {
    final outOfStock = product.stock == 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image / placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.liquor,
                                size: 48, color: Colors.grey),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.liquor, size: 48, color: Colors.grey),
                      ),
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KES ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    outOfStock ? 'Out of stock' : '${product.stock} in stock',
                    style: TextStyle(
                      fontSize: 11,
                      color: outOfStock ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}