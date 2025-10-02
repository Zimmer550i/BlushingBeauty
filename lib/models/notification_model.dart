class NotificationModel {
  final String id;
  final String content;
  final String? senderName;
  final String? senderImage;
  final String receiverId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.content,
    required this.senderName,
    required this.senderImage,
    required this.receiverId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      senderName: json['senderId']?['name'],
      senderImage: json['senderId']?['image'],
      receiverId: json['receiverId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
