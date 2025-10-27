import 'dart:math';
import '../models/question_model.dart';

class QuizService {
  final Random _random = Random();
  final List<Question> _customQuestions = [];

  void setCustomQuestions(List<Question> questions) {
    _customQuestions.clear();
    _customQuestions.addAll(questions);
  }

  Question generateQuestion() {
    // If there are custom questions, use them
    if (_customQuestions.isNotEmpty) {
      return _customQuestions[_random.nextInt(_customQuestions.length)];
    }

    // Otherwise, generate traditional multiplication questions
    int a = _random.nextInt(12) + 1;
    int b = _random.nextInt(12) + 1;
    return Question.multiplication(a, b);
  }

  Question generateQuestionFromTable(int table) {
    // If there are custom questions, use them
    if (_customQuestions.isNotEmpty) {
      return _customQuestions[_random.nextInt(_customQuestions.length)];
    }

    // Otherwise, generate multiplication questions from the specified table
    int a = table;
    int b = _random.nextInt(12) + 1;
    return Question.multiplication(a, b);
  }

  bool checkAnswer(Question question, int userAnswer) {
    return question.isCorrect(userAnswer);
  }
}
