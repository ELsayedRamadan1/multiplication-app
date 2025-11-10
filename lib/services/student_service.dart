import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_data_model.dart' show StudentData;
import 'dart:async';

class StudentService {
  static const String _key = 'student_data';

  // Broadcast controller so multiple listeners can receive updates
  static final StreamController<List<StudentData>> _studentsController = StreamController<List<StudentData>>.broadcast();

  /// Returns a stream that emits current list of students and subsequent updates
  Stream<List<StudentData>> streamStudents() {
    // Emit current snapshot asynchronously when someone subscribes
    Future.microtask(() async {
      final current = await getStudents();
      if (!_studentsController.isClosed) _studentsController.add(current);
    });
    return _studentsController.stream;
  }

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

    // After saving, notify stream listeners with updated list
    try {
      final updated = await getStudents();
      if (!_studentsController.isClosed) _studentsController.add(updated);
    } catch (_) {
      // ignore
    }
  }

  Future<void> clearData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);

    // Emit empty list
    if (!_studentsController.isClosed) _studentsController.add([]);
  }

  // Alias for getStudents to maintain backward compatibility
  Future<List<StudentData>> getAllStudents() async {
    return await getStudents();
  }

  // Dispose controller when app closes (optional)
  static Future<void> disposeController() async {
    try {
      await _studentsController.close();
    } catch (_) {}
  }
}
