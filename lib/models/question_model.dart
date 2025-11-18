import '../utils/arabic_numbers.dart';

enum QuestionType {
  addition,
  subtraction,
  multiplication,
  division,
  customText,
  multipleChoice,
}

enum OperationType { addition, subtraction, multiplication, division }

class Question {
  final String id;
  final String question;
  final double correctAnswer;
  final int? a;
  final int? b;
  final OperationType operation;
  final QuestionType type;
  final String? explanation;
  final List<String>? choices;
  final int? correctChoiceIndex;

  Question({
    required this.id,
    required this.question,
    required this.correctAnswer,
    this.a,
    this.b,
    required this.operation,
    required this.type,
    this.explanation,
    this.choices,
    this.correctChoiceIndex,
  });

  // Factory constructor for arithmetic questions
  /// If [roundDecimals] is provided and the operation is division,
  /// the correct answer will be rounded to that many decimal places.
  factory Question.arithmetic(
    int a,
    int b,
    OperationType operation, {
    int? roundDecimals,
  }) {
    final qText =
        '${toArabicDigits(a.toString())} ${_getOperationSymbol(operation)} ${toArabicDigits(b.toString())} = ؟';
    final answer = _calculateAnswer(a, b, operation, roundDecimals: roundDecimals);
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: qText,
      correctAnswer: answer,
      a: a,
      b: b,
      operation: operation,
      type: _toQuestionType(operation),
      choices: null,
      correctChoiceIndex: null,
    );
  }

  // For backward compatibility
  factory Question.multiplication(int a, int b) => Question.arithmetic(a, b, OperationType.multiplication);

  // Factory constructor for custom text questions
  factory Question.customText(
    String question,
    double answer, {
    String? explanation,
    List<String>? choices,
    int? correctChoiceIndex,
  }) {
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      correctAnswer: answer,
      operation: OperationType.addition, // Default operation
      type: QuestionType.customText,
      explanation: explanation,
      choices: choices,
      correctChoiceIndex: correctChoiceIndex,
    );
  }

  // Factory for multiple-choice questions
  factory Question.multipleChoice(
    String question,
    List<String> choices,
    int correctIndex, {
    String? explanation,
  }) {
    double parsedAnswer = 0;
    if (correctIndex >= 0 && correctIndex < choices.length) {
      final p = double.tryParse(choices[correctIndex].replaceAll(',', '.'));
      if (p != null) parsedAnswer = p;
    }
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      correctAnswer: parsedAnswer,
      operation: OperationType.addition,
      type: QuestionType.multipleChoice,
      explanation: explanation,
      choices: choices,
      correctChoiceIndex: correctIndex,
    );
  }

  // Convert to map for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'correctAnswer': correctAnswer,
      'a': a,
      'b': b,
      'operation': operation.index,
      'type': type.index,
      'explanation': explanation,
      'choices': choices,
      'correctChoiceIndex': correctChoiceIndex,
    };
  }

  // Create from map for JSON deserialization
  factory Question.fromJson(Map<String, dynamic> json) {
    List<String>? loadedChoices;
    if (json['choices'] != null) {
      try {
        loadedChoices = List<String>.from(json['choices']);
      } catch (_) {
        loadedChoices = null;
      }
    }
    return Question(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      question: json['question'] ?? '',
      correctAnswer: (json['correctAnswer'] as num?)?.toDouble() ?? 0.0,
      a: json['a'],
      b: json['b'],
      operation: OperationType.values[json['operation'] ?? OperationType.multiplication.index],
      type: QuestionType.values[json['type'] ?? QuestionType.multiplication.index],
      explanation: json['explanation'],
      choices: loadedChoices,
      correctChoiceIndex: json['correctChoiceIndex'],
    );
  }

  // Helper method to calculate answer
  static double _calculateAnswer(int a, int b, OperationType operation, {int? roundDecimals}) {
    switch (operation) {
      case OperationType.addition:
        return (a + b).toDouble();
      case OperationType.subtraction:
        return (a - b).toDouble();
      case OperationType.multiplication:
        return (a * b).toDouble();
      case OperationType.division:
        double val = b == 0 ? 0.0 : (a / b).toDouble();
        if (roundDecimals != null) return double.parse(val.toStringAsFixed(roundDecimals));
        return val;
    }
  }

  // Helper method to get operation symbol
  static String _getOperationSymbol(OperationType operation) {
    switch (operation) {
      case OperationType.addition:
        return '+';
      case OperationType.subtraction:
        return '-';
      case OperationType.multiplication:
        return '×';
      case OperationType.division:
        return '÷';
    }
  }

  // Helper method to convert OperationType to QuestionType
  static QuestionType _toQuestionType(OperationType operation) => QuestionType.values[operation.index];

  @override
  String toString() => 'Question{id: $id, question: $question, correctAnswer: $correctAnswer, type: $type, choices: $choices, correctIdx: $correctChoiceIndex}';
}
