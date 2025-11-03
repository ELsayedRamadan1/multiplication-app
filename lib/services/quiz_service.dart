import 'dart:math';
import '../models/question_model.dart';
import '../models/quiz_settings_model.dart';

class QuizService {
  final Random _random = Random();
  final List<Question> _customQuestions = [];
  QuizSettings? _currentSettings;
  int _questionsRemaining = 0;
  int _currentQuestionCount = 0;
  late DifficultyLevel _difficultyLevel;
  late OperationType _operationType;

  void setCustomQuestions(List<Question> questions) {
    _customQuestions.clear();
    _customQuestions.addAll(questions);
  }

  void setQuizSettings(QuizSettings settings) {
    _currentSettings = settings;
    _operationType = settings.operationType;
    _difficultyLevel = settings.difficultyLevel;
    _currentQuestionCount = 0;
    _questionsRemaining = settings.maxQuestions;
  }

  int getTotalQuestionCount() {
    return _currentSettings?.maxQuestions ?? 10;
  }

  Question generateQuestion() {
    if (_currentSettings == null) {
      throw Exception('Quiz settings not initialized');
    }

    if (_customQuestions.isNotEmpty) {
      return _customQuestions[_random.nextInt(_customQuestions.length)];
    }

    int a, b;
    int maxNumber = 10; // Default value

    // Set max number based on difficulty and operation
    switch (_operationType) {
      case OperationType.addition:
      case OperationType.subtraction:
        maxNumber = _difficultyLevel == DifficultyLevel.easy
            ? 10
            : _difficultyLevel == DifficultyLevel.medium
            ? 50
            : 100;
        break;
      case OperationType.multiplication:
      case OperationType.division:
        maxNumber = _difficultyLevel == DifficultyLevel.easy
            ? 5
            : _difficultyLevel == DifficultyLevel.medium
            ? 10
            : 12;
        break;
    }

    if (!_currentSettings!.isRandomTable && _operationType == OperationType.multiplication) {
      // For specific multiplication tables
      a = _currentSettings!.tableNumber!;
      b = _random.nextInt(maxNumber) + 1;
    } else {
      // For other cases
      a = _random.nextInt(maxNumber) + 1;

      if (_operationType == OperationType.division) {
        b = _getRandomDivisor(a);
        a = a * b; // Ensure a is a multiple of b
      } else if (_operationType == OperationType.subtraction) {
        b = _random.nextInt(a) + 1; // Ensure a >= b
      } else {
        b = _random.nextInt(maxNumber) + 1;
      }
    }

    _currentQuestionCount++;
    _questionsRemaining--;

    return Question.arithmetic(a, b, _operationType);
  }

  int _getRandomDivisor(int number) {
    if (number == 0) return 1;
    final divisors = <int>[];
    for (int i = 1; i <= number; i++) {
      if (number % i == 0) {
        divisors.add(i);
      }
    }
    return divisors[_random.nextInt(divisors.length)];
  }

  bool hasMoreQuestions() {
    return _questionsRemaining > 0;
  }

  int getCurrentQuestionNumber() {
    return _currentQuestionCount;
  }

  int getRemainingQuestionCount() {
    return _questionsRemaining;
  }
}