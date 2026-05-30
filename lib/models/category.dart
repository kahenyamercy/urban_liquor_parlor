class CategoryItem {
  final int id;
  final String name;
  final String imageUrl;
  final int? parentId;

  CategoryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.parentId
  });
}