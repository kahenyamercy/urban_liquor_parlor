import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../models/product.dart';
import 'login_screen.dart';
import 'product_list_screen.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _categories = [];
  bool _loading = true;
  String? _error;

  // Category icons — add more as needed
  final Map<String, IconData> _categoryIcons = {
    'Beer':     Icons.sports_bar,
    'Whiskey':  Icons.local_bar,
    'Wine':     Icons.wine_bar,
    'Spirits':  Icons.liquor,
    'Cider':    Icons.emoji_food_beverage,
    'Water':    Icons.water_drop,
    'Soda':     Icons.bubble_chart,
  };

  // Category colors
  final Map<String, Color> _categoryColors = {
    'Beer':     const Color(0xFFF59E0B),
    'Whiskey':  const Color(0xFF92400E),
    'Wine':     const Color(0xFF7C3AED),
    'Spirits':  const Color(0xFF0F766E),
    'Cider':    const Color(0xFF65A30D),
    'Water':    const Color(0xFF0284C7),
    'Soda':     const Color(0xFFDB2777),
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      print('📦 Fetching categories from Supabase...');

      // Fetch distinct categories from the products table
      final response = await supabase
          .from('products')
          .select('category')
          .order('category');

      // Extract unique categories from the response
      final categories = response
          .map<String>((row) => row['category'] as String)
          .toSet()   // removes duplicates
          .toList();

      print('✅ Categories loaded: $categories');

      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading categories: $e');
      setState(() {
        _error = 'Failed to load categories. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user?.email ?? ''),
            _buildSearchBar(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Shop by category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

Widget _buildHeader(String email) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
    color: const Color(0xFF1A1A2E),
    child: Row(
      children: [
        const Icon(Icons.liquor, color: Colors.white, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Urban Liquor Parlor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Cart icon with badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ).then((_) => setState(() {})),
            ),
            if (CartService().totalItems > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${CartService().totalItems}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white, size: 20),
          onPressed: _signOut,
          tooltip: 'Sign out',
        ),
      ],
    ),
  );
}
  Widget _buildSearchBar() {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon:
              Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        // We'll wire up search fully in the product list screen
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListScreen(
                  category: 'Search',
                  searchQuery: value.trim(),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1A2E)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _loadCategories();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text(
          'No products yet.\nAdd some in your Supabase dashboard.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(String category) {
    final color = _categoryColors[category] ?? const Color(0xFF1A1A2E);
    final icon  = _categoryIcons[category]  ?? Icons.local_bar;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'View all',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}