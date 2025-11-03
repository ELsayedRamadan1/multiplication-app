import 'package:multiplication_table_app/models/question_model.dart';

enum DifficultyLevel {
  easy,    // Easy: 1-10 for addition/subtraction, 1-5 for multiplication/division
  medium,  // Medium: 1-50 for addition/subtraction, 1-10 for multiplication/division
  hard,    // Hard: 1-100 for addition/subtraction, 1-12 for multiplication/division
}

class QuizSettings {
  final int minQuestions;
  final int maxQuestions;
  final int? tableNumber;
  final bool isRandomTable;
  final OperationType operationType;
  final DifficultyLevel difficultyLevel;

  QuizSettings({
    required this.minQuestions,
    required this.maxQuestions,
    this.tableNumber,
    this.isRandomTable = true,
    required this.operationType,
    this.difficultyLevel = DifficultyLevel.medium,
  });

  // Create a copyWith method for easier updates
  QuizSettings copyWith({
    int? minQuestions,
    int? maxQuestions,
    int? tableNumber,
    bool? isRandomTable,
    OperationType? operationType,
    DifficultyLevel? difficultyLevel,
  }) {
    return QuizSettings(
      minQuestions: minQuestions ?? this.minQuestions,
      maxQuestions: maxQuestions ?? this.maxQuestions,
      tableNumber: tableNumber ?? this.tableNumber,
      isRandomTable: isRandomTable ?? this.isRandomTable,
      operationType: operationType ?? this.operationType,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'minQuestions': minQuestions,
      'maxQuestions': maxQuestions,
      'tableNumber': tableNumber,
      'isRandomTable': isRandomTable,
      'operation': operationType.index,
      'difficultyLevel': difficultyLevel.index,
    };
  }

  // Create from JSON
  factory QuizSettings.fromJson(Map<String, dynamic> json) {
    return QuizSettings(
      minQuestions: json['minQuestions'] ?? 5,
      maxQuestions: json['maxQuestions'] ?? 10,
      tableNumber: json['tableNumber'] ?? 1,
      isRandomTable: json['isRandomTable'] ?? true,
      operationType: OperationType.values[json['operation'] ?? OperationType.multiplication.index],
      difficultyLevel: DifficultyLevel.values[json['difficultyLevel'] ?? DifficultyLevel.medium.index],
    );
  }
}