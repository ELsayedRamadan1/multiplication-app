import 'package:flutter/foundation.dart';

enum QuestionType {
  multiplication, // Traditional multiplication questions
  customText,     // Custom text-based questions
  customImage,    // Custom questions with images
}

class Question {
  final String id;
  final QuestionType type;
  final String question;
  final String? imagePath; // For image questions
  final int correctAnswer;
  final String? explanation; // Optional explanation for the answer
  final DateTime createdAt;

  // For backward compatibility with traditional multiplication questions
  final int? a;
  final int? b;

  Question({
    required this.id,
    required this.type,
    required this.question,
    this.imagePath,
    required this.correctAnswer,
    this.explanation,
    DateTime? createdAt,
    this.a,
    this.b,
  }) : createdAt = createdAt ?? DateTime.now();

  // Factory constructor for traditional multiplication questions (with backward compatibility)
  factory Question.multiplication(int a, int b) {
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: QuestionType.multiplication,
      question: 'What is $a × $b?',
      correctAnswer: a * b,
      a: a,
      b: b,
    );
  }

  // Factory constructor for custom text questions
  factory Question.customText(String questionText, int answer, {String? explanation}) {
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: QuestionType.customText,
      question: questionText,
      correctAnswer: answer,
      explanation: explanation,
    );
  }

  // Factory constructor for custom image questions
  factory Question.customImage(String questionText, int answer, String imagePath, {String? explanation}) {
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: QuestionType.customImage,
      question: questionText,
      imagePath: imagePath,
      correctAnswer: answer,
      explanation: explanation,
    );
  }

  bool isCorrect(int userAnswer) {
    return userAnswer == correctAnswer;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'question': question,
      'imagePath': imagePath,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'createdAt': createdAt.toIso8601String(),
      'a': a,
      'b': b,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: QuestionType.values[json['type']],
      question: json['question'],
      imagePath: json['imagePath'],
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
      createdAt: DateTime.parse(json['createdAt']),
      a: json['a'],
      b: json['b'],
    );
  }

  @override
  String toString() {
    return 'Question(type: $type, question: $question, answer: $correctAnswer)';
  }
}
