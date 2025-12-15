import 'user.dart';

class Task {
  final int id;
  final String title;
  final String? description;
  final int assigneeId;
  final User assignee;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.assigneeId,
    required this.assignee,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      assigneeId: json['assignee_id'],
      assignee: User.fromJson(json['assignee']),
      completed: json['completed'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
