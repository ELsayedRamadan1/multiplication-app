import 'question_model.dart';

class CustomAssignment {
  final String id;
  final String teacherId;
  final String teacherName;
  final List<String> assignedStudentIds;
  final List<String> assignedStudentNames;
  final List<Question> questions;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool isActive;

  CustomAssignment({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.assignedStudentIds,
    required this.assignedStudentNames,
    required this.questions,
    required this.title,
    this.description,
    DateTime? createdAt,
    this.dueDate,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'assignedStudentIds': assignedStudentIds,
      'assignedStudentNames': assignedStudentNames,
      'questions': questions.map((q) => q.toJson()).toList(),
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory CustomAssignment.fromJson(Map<String, dynamic> json) {
    return CustomAssignment(
      id: json['id'] ?? '',
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      assignedStudentIds: (json['assignedStudentIds'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      assignedStudentNames: (json['assignedStudentNames'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      questions: (json['questions'] as List?)
          ?.map((q) => Question.fromJson(Map<String, dynamic>.from(q)))
          .toList() ??
          [],
      title: json['title'] ?? '',
      description: json['description'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  bool isAssignedToStudent(String studentId) {
    return assignedStudentIds.contains(studentId);
  }

  CustomAssignment copyWith({
    String? id,
    String? teacherId,
    String? teacherName,
    List<String>? assignedStudentIds,
    List<String>? assignedStudentNames,
    List<Question>? questions,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isActive,
  }) {
    return CustomAssignment(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      assignedStudentIds: assignedStudentIds ?? List.from(this.assignedStudentIds),
      assignedStudentNames: assignedStudentNames ?? List.from(this.assignedStudentNames),
      questions: questions ?? List.from(this.questions),
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'CustomAssignment(id: $id, title: $title, students: ${assignedStudentNames.length})';
  }
}

// ===================================================================

class CustomQuizResult {
  final String assignmentId;
  final String studentId;
  final String studentName;
  final List<QuestionResult> questionResults;
  final DateTime completedAt;
  final int score;
  final int totalQuestions;

  CustomQuizResult({
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.questionResults,
    DateTime? completedAt,
    required this.score,
    required this.totalQuestions,
  }) : completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'questionResults': questionResults.map((q) => q.toJson()).toList(),
      'completedAt': completedAt.toIso8601String(),
      'score': score,
      'totalQuestions': totalQuestions,
    };
  }

  factory CustomQuizResult.fromJson(Map<String, dynamic> json) {
    return CustomQuizResult(
      assignmentId: json['assignmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      questionResults: (json['questionResults'] as List?)
          ?.map((q) =>
          QuestionResult.fromJson(Map<String, dynamic>.from(q)))
          .toList() ??
          [],
      completedAt: DateTime.tryParse(json['completedAt'] ?? '') ??
          DateTime.now(),
      score: (json['score'] is int)
          ? json['score']
          : int.tryParse(json['score'].toString()) ?? 0,
      totalQuestions: (json['totalQuestions'] is int)
          ? json['totalQuestions']
          : int.tryParse(json['totalQuestions'].toString()) ?? 0,
    );
  }

  double get percentage =>
      totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

  @override
  String toString() {
    return 'CustomQuizResult(student: $studentName, score: $score/$totalQuestions)';
  }
}

// ===================================================================

class QuestionResult {
  final String questionText;
  final double correctAnswer;
  final double userAnswer;
  final bool isCorrect;

  QuestionResult({
    required this.questionText,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
    };
  }

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    double parseNumber(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return QuestionResult(
      questionText: json['questionText'] ?? '',
      correctAnswer: parseNumber(json['correctAnswer']),
      userAnswer: parseNumber(json['userAnswer']),
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}
