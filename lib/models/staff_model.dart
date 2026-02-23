class Staff {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;

  Staff({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role = 'staff',
  });

  String get fullName => '$firstName $lastName';

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'].toString(),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'staff',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role,
    };
  }
}
