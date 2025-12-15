class User {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String birthDate;
  final String contact;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.birthDate,
    required this.contact,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      middleName: json['middle_name'],
      birthDate: json['birth_date'],
      contact: json['contact'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'birth_date': birthDate,
      'contact': contact,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$lastName $firstName $middleName';
    }
    return '$lastName $firstName';
  }
}
