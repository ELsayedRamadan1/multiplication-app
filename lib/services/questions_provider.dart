import 'package:flutter/foundation.dart';

import 'custom_question_service.dart';
import '../models/question_model.dart';

class QuestionsProvider extends ChangeNotifier {
  final CustomQuestionService _service = CustomQuestionService();
  List<Question> _questions = [];
  bool _isLoading = false;

  List<Question> get questions => List.unmodifiable(_questions);
  bool get isLoading => _isLoading;

  QuestionsProvider() {
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _questions = await _service.getCustomQuestions();
    } catch (_) {
      _questions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuestion(Question q) async {
    await _service.saveCustomQuestion(q);
    _questions.add(q);
    notifyListeners();
  }

  Future<void> deleteQuestion(Question q) async {
    await _service.deleteCustomQuestion(q);
    _questions.removeWhere((e) => e.id == q.id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _service.clearAllQuestions();
    _questions.clear();
    notifyListeners();
  }
}

