import 'user.dart';

class Message {
  final int id;
  final int senderId;
  final User sender;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.sender,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      sender: User.fromJson(json['sender']),
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
