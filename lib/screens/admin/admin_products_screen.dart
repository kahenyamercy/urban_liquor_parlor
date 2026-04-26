import 'package:flutter/material.dart';

import '../../config/supabase_config.dart';
import '../../models/product.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await supabase
          .from('products')
          .select()
          .order('category')
          .order('name');

      setState(() {
        _products = (response as List)
            .map((row) => Product.fromMap(row))
            .toList();
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading products: $e');
      setState(() => _loading = false);
    }
  }

  void _openProductForm({Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFormSheet(
        product: product,
        onSaved: () {
          Navigator.pop(context);
          _loadProducts();
        },
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text(
            'Are you sure you want to delete this product?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('products').delete().eq('id', id);
        _loadProducts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Manage products'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(),
        backgroundColor: const Color(0xFF1A1A2E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _products.length,
                itemBuilder: (context, index) =>
                    _buildProductRow(_products[index]),
              ),
            ),
    );
  }

  Widget _buildProductRow(Product product) {
    final isLowStock = product.stock <= 5;
    final isOutOfStock = product.stock == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOutOfStock
              ? Colors.red.shade200
              : isLowStock
                  ? Colors.orange.shade200
                  : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Category dot
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.liquor,
                color: Colors.grey, size: 22),
          ),
          const SizedBox(width: 12),

          // Name, category, stock
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(product.category,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isOutOfStock
                          ? Icons.error_outline
                          : isLowStock
                              ? Icons.warning_amber
                              : Icons.check_circle_outline,
                      size: 13,
                      color: isOutOfStock
                          ? Colors.red
                          : isLowStock
                              ? Colors.orange
                              : Colors.green,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isOutOfStock
                          ? 'Out of stock'
                          : '${product.stock} in stock'
                              '${isLowStock ? ' — low' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOutOfStock
                            ? Colors.red
                            : isLowStock
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('KES ${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _openProductForm(product: product),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          size: 16, color: Color(0xFF6366F1)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _deleteProduct(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_outline,
                          size: 16, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product add/edit form sheet
// ─────────────────────────────────────────────────────────────────────────────
class ProductFormSheet extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaved;

  const ProductFormSheet({super.key, this.product, required this.onSaved});

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _nameController    = TextEditingController();
  final _priceController   = TextEditingController();
  final _stockController   = TextEditingController();
  final _imageController   = TextEditingController();
  String _category = 'Beer';
  bool _saving = false;

  final List<String> _categories = [
    'Beer', 'Whiskey', 'Wine', 'Spirits', 'Cider', 'Water', 'Soda'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text  = p.name;
      _priceController.text = p.price.toStringAsFixed(0);
      _stockController.text = p.stock.toString();
      _imageController.text = p.imageUrl ?? '';
      _category = p.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name  = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (name.isEmpty || price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name, price and stock')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final data = {
        'name':      name,
        'category':  _category,
        'price':     price,
        'stock':     stock,
        'image_url': _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
      };

      if (widget.product == null) {
        // Insert new product
        await supabase.from('products').insert(data);
        print('✅ Product added: $name');
      } else {
        // Update existing product
        await supabase
            .from('products')
            .update(data)
            .eq('id', widget.product!.id);
        print('✅ Product updated: $name');
      }

      widget.onSaved();
    } catch (e) {
      print('❌ Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isEdit ? 'Edit product' : 'Add product',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          _field(_nameController,  'Product name', TextInputType.text),
          const SizedBox(height: 12),

          // Category dropdown
          DropdownButtonFormField<String>(
            value: _category,
            decoration: _inputDecoration('Category'),
            items: _categories.map((c) =>
                DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _field(_priceController, 'Price (KES)',
                    TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(_stockController, 'Stock qty',
                    TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _field(_imageController, 'Image URL (optional)',
              TextInputType.url),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Save changes' : 'Add product',
                      style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}