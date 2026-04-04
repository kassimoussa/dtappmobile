class PromoPopup {
  static const String _serverBase = 'http://10.39.230.106';

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
    final rawUrl = json['image_url'] as String;
    return PromoPopup(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: _resolveUrl(rawUrl),
      link: json['link'] as String?,
    );
  }

  static String _resolveUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$_serverBase${url.startsWith('/') ? '' : '/'}$url';
  }
}
