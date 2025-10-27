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
  final String name;
  final int score;
  final int totalQuestions;
  final List<StudentAnswer> answers;

  StudentData({
    required this.name,
    required this.score,
    required this.totalQuestions,
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'totalQuestions': totalQuestions,
      'answers': answers.map((answer) => answer.toJson()).toList(),
    };
  }

  factory StudentData.fromJson(Map<String, dynamic> json) {
    return StudentData(
      name: json['name'],
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      answers: (json['answers'] as List<dynamic>?)
          ?.map((answerJson) => StudentAnswer.fromJson(answerJson))
          .toList() ?? [],
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
      name: name,
      score: score,
      totalQuestions: totalQuestions,
      answers: answers.map((answer) {
        // Parse old format: "2 x 3 = 6" and assume all are correct for backward compatibility
        return StudentAnswer(
          question: answer.split(' = ')[0],
          answer: answer.split(' = ')[1],
          isCorrect: true, // Assume correct for old data
        );
      }).toList(),
    );
  }}
