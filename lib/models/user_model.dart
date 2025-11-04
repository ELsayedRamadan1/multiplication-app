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
  final String school;
  final int grade; // 1-6 for grades 1 through 6
  final int classNumber; // 1-10 for class numbers
  // Optional defaults used by teachers to target students when creating assignments
  final int? teacherDefaultGrade;
  final int? teacherDefaultClassNumber;

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
    required this.school,
    required this.grade,
    required this.classNumber,
    this.teacherDefaultGrade,
    this.teacherDefaultClassNumber,
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
      'school': school,
      'grade': grade,
      'classNumber': classNumber,
      'teacherDefaultGrade': teacherDefaultGrade,
      'teacherDefaultClassNumber': teacherDefaultClassNumber,
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
      subjectScores: json['subjectScores'] != null ? Map<String, int>.from(json['subjectScores']) : null,
      school: json['school'] ?? '',
      grade: json['grade'] ?? 1,
      classNumber: json['classNumber'] ?? 1,
      teacherDefaultGrade: json['teacherDefaultGrade'],
      teacherDefaultClassNumber: json['teacherDefaultClassNumber'],
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
    String? school,
    int? grade,
    int? classNumber,
    int? teacherDefaultGrade,
    int? teacherDefaultClassNumber,
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
      school: school ?? this.school,
      grade: grade ?? this.grade,
      classNumber: classNumber ?? this.classNumber,
      teacherDefaultGrade: teacherDefaultGrade ?? this.teacherDefaultGrade,
      teacherDefaultClassNumber: teacherDefaultClassNumber ?? this.teacherDefaultClassNumber,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }
}
