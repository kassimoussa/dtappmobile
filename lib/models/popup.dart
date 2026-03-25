class PromoPopup {
  final int id;
  final String title;
  final String imageUrl;
  final String? link;

  PromoPopup({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.link,
  });

  factory PromoPopup.fromJson(Map<String, dynamic> json) {
    return PromoPopup(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      link: json['link'] as String?,
    );
  }
}
