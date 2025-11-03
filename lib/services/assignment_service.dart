import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/assignment_model.dart';
import 'notification_service.dart';


class AssignmentService {
  static const String _assignmentsKey = 'custom_assignments';
  static const String _resultsKey = 'custom_quiz_results';

  final NotificationService _notificationService = NotificationService();
  final _random = Random();

  // Generate a unique ID for assignments
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + _random.nextInt(1000).toString();
  }

  // Save a new assignment and notify students
  Future<void> saveAssignment(CustomAssignment assignment, {bool notifyStudents = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = await getAllAssignments();

    // Generate ID if new assignment
    if (assignment.id.isEmpty) {
      assignment = assignment.copyWith(id: _generateId());
    }

    // Check if assignment already exists, update it
    final existingIndex = assignments.indexWhere((a) => a.id == assignment.id);
    if (existingIndex >= 0) {
      assignments[existingIndex] = assignment;
    } else {
      assignments.add(assignment);
    }

    final assignmentsJson = assignments.map((a) => a.toJson()).toList();
    await prefs.setString(_assignmentsKey, jsonEncode(assignmentsJson));

    // Notify students about new assignment
    if (notifyStudents) {
      for (final studentId in assignment.assignedStudentIds) {
        await _notificationService.createNotification(
          title: 'واجب جديد',
          message: 'لديك واجب جديد: ${assignment.title}',
          type: 'assignment',
          assignmentId: assignment.id,
          studentId: studentId,
        );
      }
    }
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

  // Get students assigned to an assignment
  Future<List<String>> getAssignedStudents(String assignmentId) async {
    final assignments = await getAllAssignments();
    final assignment = assignments.firstWhere(
      (a) => a.id == assignmentId,
      orElse: () => CustomAssignment(
        id: '',
        teacherId: '',
        teacherName: '',
        assignedStudentIds: [],
        assignedStudentNames: [],
        questions: [],
        title: '',
      ),
    );
    return assignment.assignedStudentIds;
  }

  // Mark assignment as completed by student
  Future<void> completeAssignment(String assignmentId, String studentId, int score) async {
    final assignments = await getAllAssignments();
    final assignmentIndex = assignments.indexWhere((a) => a.id == assignmentId);
    
    if (assignmentIndex != -1) {
      // In a real app, you would save the student's answers and score here
      // For now, we'll just mark it as completed and notify the teacher
      await _notificationService.createNotification(
        title: 'تم حل الواجب',
        message: 'قام الطالب بحل الواجب بنجاح',
        type: 'assignment_completed',
        assignmentId: assignmentId,
        studentId: studentId,
      );
    }
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

}
