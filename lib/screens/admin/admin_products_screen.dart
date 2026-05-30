// ignore_for_file: unnecessary_underscores

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

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('products').delete().eq('id', product.id);
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
              child: _products.isEmpty
                  ? const Center(
                      child: Text('No products yet. Tap + to add.',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _products.length,
                      itemBuilder: (context, index) =>
                          _buildProductRow(_products[index]),
                    ),
            ),
    );
  }

  Widget _buildProductRow(Product product) {
    final isLowStock   = product.stock > 0 && product.stock <= 5;
    final isOutOfStock = product.stock == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildProductImage(product.imageUrl, size: 52),
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

          // Price + action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('KES ${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _iconBtn(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF6366F1),
                    onTap: () => _openProductForm(product: product),
                  ),
                  const SizedBox(width: 6),
                  _iconBtn(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onTap: () => _deleteProduct(product),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? url, {required double size}) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size, height: size,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size, height: size,
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(size),
      );
    }
    return _placeholder(size);
  }

  Widget _placeholder(double size) {
    return Container(
      width: size, height: size,
      color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
      child: const Icon(Icons.liquor, color: Colors.grey, size: 24),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product form — URL-based image input
// ─────────────────────────────────────────────────────────────────────────────
class ProductFormSheet extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaved;

  const ProductFormSheet({super.key, this.product, required this.onSaved});

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _nameController     = TextEditingController();
  final _priceController    = TextEditingController();
  final _stockController    = TextEditingController();
  final _imageUrlController = TextEditingController();


  List<String> _categories = [];
    bool _loadingCategories = true;
    String _category = '';

    bool _saving = false;
    bool _previewingImage = false;
    String? _previewUrl;

    Future<void> _loadCategories() async {
  try {
    final response = await supabase
        .from('categories')
        .select('name')
        .order('name');

    final List<String> names = (response as List)
        .map((row) => row['name'] as String)
        .toList();

    setState(() {
      _categories = names;
      if (_category.isEmpty || !_categories.contains(_category)) {
          _category = _categories.isNotEmpty ? _categories.first : '';
        }
      _loadingCategories = false;
    });
  } catch (e) {
    print('❌ Error loading categories: $e');
    // Fallback to hardcoded if fetch fails
    setState(() {
      _categories = [
        'Beer', 'Cider', 'Gin', 'Rum', 'Soda', 
        'Spirits', 'Vodka', 'Water', 'Whiskey', 'Wine'
        ];
        if (_category.isEmpty || !_categories.contains(_category)) {
            _category = _categories.first;
          }
      _loadingCategories = false;
    });
  }
}


  @override
  void initState() {
    super.initState();
    
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text     = p.name;
      _priceController.text    = p.price.toStringAsFixed(0);
      _stockController.text    = p.stock.toString();
      _imageUrlController.text = p.imageUrl ?? '';
      _category = p.category;

      if (p.imageUrl != null && p.imageUrl!.isNotEmpty) {
        _previewUrl = p.imageUrl;
        _previewingImage = true;
      }
    }

    // Live preview as admin types the URL
   _loadCategories();
    _imageUrlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    final url = _imageUrlController.text.trim();
    final isValidUrl = url.startsWith('http://') || url.startsWith('https://');
    setState(() {
      _previewUrl = isValidUrl ? url : null;
      _previewingImage = isValidUrl;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name  = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());
    final imageUrl = _imageUrlController.text.trim();

    if (name.isEmpty || price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in name, price and stock')),
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
        // Save null if URL is empty — never save empty string
        'image_url': imageUrl.isNotEmpty ? imageUrl : null,
      };

      if (widget.product == null) {
        await supabase.from('products').insert(data);
        print('✅ Product added: $name');
      } else {
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
      child: SingleChildScrollView(
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

            // ── Image preview ────────────────────────────────────────────
            if (_previewingImage && _previewUrl != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _previewUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Could not load image',
                                style: TextStyle(
                                    color: Colors.red, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Image URL field ──────────────────────────────────────────
            TextField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Image URL (paste from Google Images)',
                hintText: 'https://example.com/image.jpg',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.image_outlined, size: 20),
                suffixIcon: _imageUrlController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _imageUrlController.clear();
                          setState(() {
                            _previewUrl = null;
                            _previewingImage = false;
                          });
                        },
                      )
                    : null,
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),

            // Hint text for finding images
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4, bottom: 16),
              child: Text(
                'Tip: Google the product → Images → right-click → Copy image address',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ),

            _field(_nameController, 'Product name', TextInputType.text),
            const SizedBox(height: 12),

            _loadingCategories
                ? Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ):

            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value:  _categories.contains(_category)
                        ? _category
                        : _categories.first,
              decoration: _inputDecoration('Category'),
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _saving ? null : (v) => 
              setState(() => _category = v!),
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
                    : Text(
                        isEdit ? 'Save changes' : 'Add product',
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
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