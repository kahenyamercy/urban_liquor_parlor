import 'package:flutter/material.dart';
import '../models/category.dart';
import 'product_list_screen.dart';

class SubCategoryScreen extends StatelessWidget {
  final CategoryItem parentCategory;
  final List<CategoryItem> subCategories;

  const SubCategoryScreen({
    super.key,
    required this.parentCategory,
    required this.subCategories,
  });

  final Map<String, IconData> _categoryIcons = const {
    'Vodka': Icons.local_bar,
    'Rum':   Icons.sports_bar,
    'Gin':   Icons.wine_bar,
  };

  final Map<String, Color> _categoryColors = const {
    'Vodka': Color(0xFF6366F1),
    'Rum':   Color(0xFFB45309),
    'Gin':   Color(0xFF059669),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Text(parentCategory.name),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: subCategories.length,
        itemBuilder: (context, index) {
          final cat = subCategories[index];
          final color = _categoryColors[cat.name] ?? const Color(0xFF1A1A2E);
          final icon  = _categoryIcons[cat.name]  ?? Icons.local_bar;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListScreen(category: cat.name),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text('View all',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}