class CategoryItem {
  CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.iconUrl,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      imageUrl: json['image_url'] as String?,
      iconUrl: json['icon_url'] as String?,
    );
  }

  final int id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? iconUrl;
}
