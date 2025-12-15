class CleaningSchedule {
  final int id;
  final int userId;
  final int dayOfWeek;
  final String area;
  final DateTime createdAt;
  final DateTime updatedAt;

  CleaningSchedule({
    required this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.area,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CleaningSchedule.fromJson(Map<String, dynamic> json) {
    return CleaningSchedule(
      id: json['id'],
      userId: json['user_id'],
      dayOfWeek: json['day_of_week'],
      area: json['area'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
