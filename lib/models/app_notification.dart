import 'dart:convert';

enum NotificationChannel { transactions, promotions, security }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationChannel channel;
  final DateTime receivedAt;
  final Map<String, dynamic> data;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.channel,
    required this.receivedAt,
    required this.data,
    this.isRead = false,
  });

  static NotificationChannel channelFromType(String? type) {
    switch (type) {
      case 'credit_transfer':
      case 'voucher_refill':
      case 'offer_purchase':
      case 'offer_gift':
      case 'low_balance':
        return NotificationChannel.transactions;
      case 'security':
      case 'otp':
        return NotificationChannel.security;
      default:
        return NotificationChannel.promotions;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'channel': channel.name,
        'receivedAt': receivedAt.toIso8601String(),
        'data': data,
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        channel: NotificationChannel.values.firstWhere(
          (c) => c.name == json['channel'],
          orElse: () => NotificationChannel.promotions,
        ),
        receivedAt: DateTime.parse(json['receivedAt'] as String),
        data: Map<String, dynamic>.from(json['data'] as Map),
        isRead: json['isRead'] as bool? ?? false,
      );

  static AppNotification fromJsonString(String s) =>
      AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());
}
