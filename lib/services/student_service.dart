import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_data_model.dart' show StudentData;

class StudentService {
  static const String _key = 'student_data';

  Future<List<StudentData>> getStudents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList(_key) ?? [];
    return data.map((e) {
      try {
        Map<String, dynamic> jsonData = jsonDecode(e);
        // Check if it's the new format (has answers as list of objects)
        if (jsonData['answers'] is List && jsonData['answers'].isNotEmpty) {
          var firstAnswer = jsonData['answers'][0];
          if (firstAnswer is Map && firstAnswer.containsKey('isCorrect')) {
            // New format with StudentAnswer objects
            return StudentData.fromJson(jsonData);
          }
        }
        // Old format - convert to new format
        return StudentData.fromOldFormat(
          name: jsonData['name'],
          score: jsonData['score'],
          totalQuestions: jsonData['totalQuestions'],
          answers: List<String>.from(jsonData['answers']),
        );
      } catch (e) {
        // If parsing fails, try old format as fallback
        return StudentData.fromOldFormat(
          name: 'Unknown',
          score: 0,
          totalQuestions: 0,
          answers: [],
        );
      }
    }).toList();
  }

  Future<void> saveStudent(StudentData student) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList(_key) ?? [];
    data.add(jsonEncode(student.toJson()));
    await prefs.setStringList(_key, data);
  }

  Future<void> clearData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
