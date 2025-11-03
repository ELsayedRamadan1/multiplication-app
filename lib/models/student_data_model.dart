class StudentAnswer {
  final String question;
  final String answer;
  final bool isCorrect;

  StudentAnswer({
    required this.question,
    required this.answer,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'isCorrect': isCorrect,
    };
  }

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    return StudentAnswer(
      question: json['question'],
      answer: json['answer'],
      isCorrect: json['isCorrect'],
    );
  }

  @override
  String toString() {
    return '$question = $answer';
  }
}

class StudentData {
  final String id;
  final String name;
  final int score;
  final int totalQuestions;
  final List<StudentAnswer> answers;

  StudentData({
    String? id,
    required this.name,
    this.score = 0,
    this.totalQuestions = 0,
    List<StudentAnswer>? answers,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       answers = answers ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'totalQuestions': totalQuestions,
      'answers': answers.map((answer) => answer.toJson()).toList(),
    };
  }

  factory StudentData.fromJson(Map<String, dynamic> json) {
    return StudentData(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unknown',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => StudentAnswer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Backward compatibility constructor for old format
  factory StudentData.fromOldFormat({
    required String name,
    required int score,
    required int totalQuestions,
    required List<String> answers,
  }) {
    return StudentData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      score: score,
      totalQuestions: totalQuestions,
      answers: answers
          .map((answer) => StudentAnswer(
                question: '',
                answer: answer,
                isCorrect: false,
              ))
          .toList(),
    );
  }
}
