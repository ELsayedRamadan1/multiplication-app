enum UserRole {
  student,
  teacher,
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarPath; // Optional profile picture
  final DateTime createdAt;
  final int totalScore;
  final int totalQuizzesCompleted;
  final Map<String, int> subjectScores; // Track scores by subject/table

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarPath,
    DateTime? createdAt,
    this.totalScore = 0,
    this.totalQuizzesCompleted = 0,
    Map<String, int>? subjectScores,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    subjectScores = subjectScores ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.index,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
      'totalScore': totalScore,
      'totalQuizzesCompleted': totalQuizzesCompleted,
      'subjectScores': subjectScores,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values[json['role']],
      avatarPath: json['avatarPath'],
      createdAt: DateTime.parse(json['createdAt']),
      totalScore: json['totalScore'] ?? 0,
      totalQuizzesCompleted: json['totalQuizzesCompleted'] ?? 0,
      subjectScores: Map<String, int>.from(json['subjectScores'] ?? {}),
    );
  }

  User copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? avatarPath,
    int? totalScore,
    int? totalQuizzesCompleted,
    Map<String, int>? subjectScores,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
      totalScore: totalScore ?? this.totalScore,
      totalQuizzesCompleted: totalQuizzesCompleted ?? this.totalQuizzesCompleted,
      subjectScores: subjectScores ?? this.subjectScores,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }
}
