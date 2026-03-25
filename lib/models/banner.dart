class PromoBanner {
  final int id;
  final String title;
  final String imageUrl;
  final String? link;
  final int order;

  PromoBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.link,
    required this.order,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      link: json['link'] as String?,
      order: json['order'] as int,
    );
  }
}
