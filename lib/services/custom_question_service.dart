import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';

class CustomQuestionService {
  static const String _key = 'custom_questions';

  Future<List<Question>> getCustomQuestions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList(_key) ?? [];
    return data.map((e) => Question.fromJson(jsonDecode(e))).toList();
  }

  Future<void> saveCustomQuestion(Question question) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList(_key) ?? [];
    data.add(jsonEncode(question.toJson()));
    await prefs.setStringList(_key, data);
  }

  Future<void> deleteCustomQuestion(Question question) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList(_key) ?? [];
    data.removeWhere((e) {
      Question q = Question.fromJson(jsonDecode(e));
      return q.id == question.id;
    });
    await prefs.setStringList(_key, data);
  }

  Future<void> clearAllQuestions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
