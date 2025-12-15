import 'user.dart';

enum UserRole {
  owner,
  admin,
  member;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => UserRole.member,
    );
  }
}

class RoomMember {
  final int id;
  final User user;
  final UserRole role;
  final bool isBanned;
  final DateTime joinedAt;

  RoomMember({
    required this.id,
    required this.user,
    required this.role,
    required this.isBanned,
    required this.joinedAt,
  });

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      id: json['id'],
      user: User.fromJson(json['user']),
      role: UserRole.fromString(json['role']),
      isBanned: json['is_banned'],
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  bool get isOwner => role == UserRole.owner;
  bool get isAdmin => role == UserRole.admin || role == UserRole.owner;
}
