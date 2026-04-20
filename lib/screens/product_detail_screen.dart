import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stock == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Text(product.name),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Product image
          Container(
            height: 280,
            width: double.infinity,
            color: const Color(0xFF1A1A2E).withOpacity(0.05),
            child: product.imageUrl != null
                ? Image.network(product.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.liquor, size: 80, color: Colors.grey),
                    ))
                : const Center(
                    child: Icon(Icons.liquor, size: 80, color: Colors.grey)),
          ),

          // Product info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      Text(
                        'KES ${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF1A1A2E)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    outOfStock
                        ? 'Currently out of stock'
                        : '${product.stock} units available',
                    style: TextStyle(
                      color: outOfStock ? Colors.red : Colors.green,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),

                  // Add to cart button — we'll wire this up in the cart step
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: outOfStock ? null : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cart coming in next step!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: Text(
                        outOfStock ? 'Out of stock' : 'Add to cart',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}