import 'package:flutter/foundation.dart';
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
      id: json['id'],
      teacherId: json['teacherId'],
      teacherName: json['teacherName'],
      assignedStudentIds: List<String>.from(json['assignedStudentIds']),
      assignedStudentNames: List<String>.from(json['assignedStudentNames']),
      questions: (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  bool isAssignedToStudent(String studentId) {
    return assignedStudentIds.contains(studentId);
  }

  @override
  String toString() {
    return 'CustomAssignment(id: $id, title: $title, students: ${assignedStudentNames.length})';
  }
}

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
      assignmentId: json['assignmentId'],
      studentId: json['studentId'],
      studentName: json['studentName'],
      questionResults: (json['questionResults'] as List).map((q) => QuestionResult.fromJson(q)).toList(),
      completedAt: DateTime.parse(json['completedAt']),
      score: json['score'],
      totalQuestions: json['totalQuestions'],
    );
  }

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

  @override
  String toString() {
    return 'CustomQuizResult(student: $studentName, score: $score/$totalQuestions)';
  }
}

class QuestionResult {
  final String questionText;
  final int correctAnswer;
  final int userAnswer;
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
    return QuestionResult(
      questionText: json['questionText'],
      correctAnswer: json['correctAnswer'],
      userAnswer: json['userAnswer'],
      isCorrect: json['isCorrect'],
    );
  }
}
