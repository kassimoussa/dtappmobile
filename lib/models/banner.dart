class PromoBanner {
  static const String _serverBase = 'http://10.39.230.106';

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
    final rawUrl = json['image_url'] as String;
    return PromoBanner(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: _resolveUrl(rawUrl),
      link: json['link'] as String?,
      order: json['order'] as int,
    );
  }

  static String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$_serverBase${url.startsWith('/') ? '' : '/'}$url';
  }
}
