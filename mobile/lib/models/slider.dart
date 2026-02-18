class SliderItem {
  SliderItem({
    required this.id,
    this.imageUrl,
    this.link,
  });

  factory SliderItem.fromJson(Map<String, dynamic> json) {
    return SliderItem(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String?,
      link: json['link'] as String?,
    );
  }

  final int id;
  final String? imageUrl;
  final String? link;
}
