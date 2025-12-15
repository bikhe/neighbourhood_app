class Room {
  final int id;
  final String name;
  final String code;
  final int createdBy;
  final DateTime createdAt;
  final int memberCount;

  Room({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    required this.createdAt,
    required this.memberCount,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      memberCount: json['member_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'member_count': memberCount,
    };
  }
}
