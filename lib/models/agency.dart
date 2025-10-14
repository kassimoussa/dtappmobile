class Agency {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String? email;
  final String? description;
  final Map<String, String> openingHours;
  final bool isActive;

  Agency({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.email,
    this.description,
    required this.openingHours,
    required this.isActive,
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String,
      email: json['email'] as String?,
      description: json['description'] as String?,
      openingHours: Map<String, String>.from(json['opening_hours'] as Map),
      isActive: json['is_active'] as bool,
    );
  }
}
