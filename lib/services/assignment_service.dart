import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/assignment_model.dart';


class AssignmentService {
  static const String _assignmentsKey = 'custom_assignments';
  static const String _resultsKey = 'custom_quiz_results';

  // Save a new assignment
  Future<void> saveAssignment(CustomAssignment assignment) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = await getAllAssignments();

    // Check if assignment already exists, update it
    final existingIndex = assignments.indexWhere((a) => a.id == assignment.id);
    if (existingIndex >= 0) {
      assignments[existingIndex] = assignment;
    } else {
      assignments.add(assignment);
    }

    final assignmentsJson = assignments.map((a) => a.toJson()).toList();
    await prefs.setString(_assignmentsKey, jsonEncode(assignmentsJson));
  }

  // Get all assignments
  Future<List<CustomAssignment>> getAllAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson = prefs.getString(_assignmentsKey);

    if (assignmentsJson == null) return [];

    final List assignments = jsonDecode(assignmentsJson);
    return assignments.map((json) => CustomAssignment.fromJson(json)).toList();
  }

  // Get assignments for a specific teacher
  Future<List<CustomAssignment>> getAssignmentsByTeacher(String teacherId) async {
    final assignments = await getAllAssignments();
    return assignments.where((a) => a.teacherId == teacherId).toList();
  }

  // Get active assignments for a specific student
  Future<List<CustomAssignment>> getActiveAssignmentsForStudent(String studentId) async {
    final assignments = await getAllAssignments();
    return assignments.where((a) => a.isActive && a.isAssignedToStudent(studentId)).toList();
  }

  // Get assignments assigned to a specific student
  Future<List<CustomAssignment>> getAssignmentsForStudent(String studentId) async {
    final assignments = await getAllAssignments();
    return assignments.where((a) => a.isAssignedToStudent(studentId)).toList();
  }

  // Save quiz result
  Future<void> saveQuizResult(CustomQuizResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final results = await getAllQuizResults();

    // Remove any existing result for the same assignment and student
    results.removeWhere((r) => r.assignmentId == result.assignmentId && r.studentId == result.studentId);

    results.add(result);

    final resultsJson = results.map((r) => r.toJson()).toList();
    await prefs.setString(_resultsKey, jsonEncode(resultsJson));
  }

  // Get all quiz results
  Future<List<CustomQuizResult>> getAllQuizResults() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getString(_resultsKey);

    if (resultsJson == null) return [];

    final List results = jsonDecode(resultsJson);
    return results.map((json) => CustomQuizResult.fromJson(json)).toList();
  }

  // Get results for a specific assignment
  Future<List<CustomQuizResult>> getResultsForAssignment(String assignmentId) async {
    final results = await getAllQuizResults();
    return results.where((r) => r.assignmentId == assignmentId).toList();
  }

  // Get results for a specific student
  Future<List<CustomQuizResult>> getResultsForStudent(String studentId) async {
    final results = await getAllQuizResults();
    return results.where((r) => r.studentId == studentId).toList();
  }

  // Get result for specific assignment and student
  Future<CustomQuizResult?> getResultForAssignmentAndStudent(String assignmentId, String studentId) async {
    final results = await getAllQuizResults();
    try {
      return results.firstWhere((r) => r.assignmentId == assignmentId && r.studentId == studentId);
    } catch (e) {
      return null;
    }
  }

  // Delete an assignment
  Future<void> deleteAssignment(String assignmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = await getAllAssignments();
    assignments.removeWhere((a) => a.id == assignmentId);

    final assignmentsJson = assignments.map((a) => a.toJson()).toList();
    await prefs.setString(_assignmentsKey, jsonEncode(assignmentsJson));

    // Also delete related results
    final results = await getAllQuizResults();
    results.removeWhere((r) => r.assignmentId == assignmentId);
    final resultsJson = results.map((r) => r.toJson()).toList();
    await prefs.setString(_resultsKey, jsonEncode(resultsJson));
  }

  // Update assignment status
  Future<void> updateAssignmentStatus(String assignmentId, bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = await getAllAssignments();
    final index = assignments.indexWhere((a) => a.id == assignmentId);

    if (index >= 0) {
      assignments[index] = CustomAssignment(
        id: assignments[index].id,
        teacherId: assignments[index].teacherId,
        teacherName: assignments[index].teacherName,
        assignedStudentIds: assignments[index].assignedStudentIds,
        assignedStudentNames: assignments[index].assignedStudentNames,
        questions: assignments[index].questions,
        title: assignments[index].title,
        description: assignments[index].description,
        createdAt: assignments[index].createdAt,
        dueDate: assignments[index].dueDate,
        isActive: isActive,
      );

      final assignmentsJson = assignments.map((a) => a.toJson()).toList();
      await prefs.setString(_assignmentsKey, jsonEncode(assignmentsJson));
    }
  }

  // Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
