class ChatModel {
  final String id;
  final String type;
  final String name;
  final String image;
  final String? lastMessage;
  final String? contentType;
  final String? media;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.type,
    required this.name,
    required this.image,
    this.lastMessage,
    this.contentType,
    this.media,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json["_id"],
      type: json["type"],
      name: json["name"] ?? "Unknown",
      image: json["image"] ?? "",
      lastMessage: json["lastMessage"]?["message"],
      contentType: json["lastMessage"]?["contentType"],
      media: json["lastMessage"]?["media"],
      updatedAt: DateTime.parse(json["updatedAt"]),
    );
  }
}
