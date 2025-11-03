
enum QuestionType {
  addition,
  subtraction,
  multiplication,
  division,
  customText,
  customImage,
}

enum OperationType {
  addition,
  subtraction,
  multiplication,
  division,
}

class Question {
  final String id;
  final String question;
  final double correctAnswer;
  final int? a;
  final int? b;
  final OperationType operation;
  final QuestionType type;
  final String? explanation;
  final String? imagePath;

  Question({
    required this.id,
    required this.question,
    required this.correctAnswer,
    this.a,
    this.b,
    required this.operation,
    required this.type,
    this.explanation,
    this.imagePath,
  });

  // Factory constructor for arithmetic questions
  factory Question.arithmetic(int a, int b, OperationType operation) {
    final question = '${a} ${_getOperationSymbol(operation)} ${b} = ؟';
    final answer = _calculateAnswer(a, b, operation);
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      correctAnswer: answer,
      a: a,
      b: b,
      operation: operation,
      type: _toQuestionType(operation),
    );
  }

  // For backward compatibility
  factory Question.multiplication(int a, int b) {
    return Question.arithmetic(a, b, OperationType.multiplication);
  }

  // Factory constructor for custom text questions
  factory Question.customText(String question, double answer, {String? explanation}) {
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      correctAnswer: answer,
      operation: OperationType.addition, // Default operation
      type: QuestionType.customText,
      explanation: explanation,
    );
  }

  // Factory constructor for custom image questions
  factory Question.customImage(String question, double answer, String imagePath, {String? explanation}) {
    return Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: question,
      correctAnswer: answer,
      operation: OperationType.addition, // Default operation
      type: QuestionType.customImage,
      explanation: explanation,
      imagePath: imagePath,
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
      'imagePath': imagePath,
    };
  }

  // Create from map for JSON deserialization
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      question: json['question'],
      correctAnswer: (json['correctAnswer'] as num).toDouble(),
      a: json['a'],
      b: json['b'],
      operation: OperationType.values[json['operation'] ?? OperationType.multiplication.index],
      type: QuestionType.values[json['type'] ?? QuestionType.multiplication.index],
      explanation: json['explanation'],
      imagePath: json['imagePath'],
    );
  }

  // Helper method to calculate answer
  static double _calculateAnswer(int a, int b, OperationType operation) {
    switch (operation) {
      case OperationType.addition: return (a + b).toDouble();
      case OperationType.subtraction: return (a - b).toDouble();
      case OperationType.multiplication: return (a * b).toDouble();
      case OperationType.division: return (a / b).toDouble();
    }
  }

  // Helper method to get operation symbol
  static String _getOperationSymbol(OperationType operation) {
    switch (operation) {
      case OperationType.addition: return '+';
      case OperationType.subtraction: return '-';
      case OperationType.multiplication: return '×';
      case OperationType.division: return '÷';
    }
  }

  // Helper method to convert OperationType to QuestionType
  static QuestionType _toQuestionType(OperationType operation) {
    return QuestionType.values[operation.index];
  }

  @override
  String toString() {
    return 'Question{id: $id, question: $question, correctAnswer: $correctAnswer, type: $type}';
  }
}