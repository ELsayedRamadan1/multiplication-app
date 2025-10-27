import 'dart:io';
import 'package:flutter/material.dart';

import '../models/question_model.dart';
import '../models/user_model.dart';
import '../models/assignment_model.dart';
import '../models/notification_model.dart';
import 'auth_service.dart';
import 'assignment_service.dart';
import 'notification_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AssignmentService _assignmentService = AssignmentService();
  final NotificationService _notificationService = NotificationService();
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isStudent => _currentUser?.role == UserRole.student;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;

  UserProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      print('Error loading current user: $e');
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user = await _authService.loginUser(email);
      if (user != null) {
        // Reload current user data to ensure we have the latest data
        User? currentUser = await _authService.getCurrentUser();
        _currentUser = currentUser ?? user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required UserRole role,
    String? avatarPath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      User newUser = await _authService.registerUser(
        name: name,
        email: email,
        role: role,
        avatarPath: avatarPath,
      );

      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Registration error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logoutUser();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateUserScore(int score, {String? subject}) async {
    if (_currentUser == null) return;

    Map<String, int> updatedScores = Map.from(_currentUser!.subjectScores);

    if (subject != null) {
      updatedScores[subject] = (updatedScores[subject] ?? 0) + score;
    }

    User updatedUser = _currentUser!.copyWith(
      totalScore: _currentUser!.totalScore + score,
      totalQuizzesCompleted: _currentUser!.totalQuizzesCompleted + 1,
      subjectScores: updatedScores,
    );

    // Update current user immediately
    _currentUser = updatedUser;

    // Save to persistent storage immediately
    await _authService.updateUser(updatedUser);

    notifyListeners();
  }
  Future<List<CustomAssignment>> getTeacherAssignments() async {
    if (!isTeacher || _currentUser == null) return [];
    return await _assignmentService.getAssignmentsByTeacher(_currentUser!.id);
  }

  Future<List<CustomAssignment>> getStudentAssignments() async {
    if (!isStudent || _currentUser == null) return [];
    return await _assignmentService.getAssignmentsForStudent(_currentUser!.id);
  }

  Future<List<CustomAssignment>> getActiveStudentAssignments() async {
    if (!isStudent || _currentUser == null) return [];
    return await _assignmentService.getActiveAssignmentsForStudent(_currentUser!.id);
  }

  Future<CustomAssignment> createAssignment({
    required String title,
    required List<Question> questions,
    required List<String> assignedStudentIds,
    required List<String> assignedStudentNames,
    String? description,
    DateTime? dueDate,
  }) async {
    if (!isTeacher || _currentUser == null) {
      throw Exception('Only teachers can create assignments');
    }

    final assignment = CustomAssignment(
      id: generateAssignmentId(),
      teacherId: _currentUser!.id,
      teacherName: _currentUser!.name,
      assignedStudentIds: assignedStudentIds,
      assignedStudentNames: assignedStudentNames,
      questions: questions,
      title: title,
      description: description,
      dueDate: dueDate,
    );

    await _assignmentService.saveAssignment(assignment);

    // Send notifications to assigned students
    if (assignedStudentIds.isNotEmpty) {
      await sendNotificationToStudents(
        title: 'New Assignment: ${assignment.title}',
        message: 'You have been assigned a new quiz. Check your assignments!',
        studentIds: assignedStudentIds,
        assignmentId: assignment.id,
      );
    }

    notifyListeners();
    return assignment;
  }

  Future<void> saveCustomQuizResult({
    required String assignmentId,
    required List<QuestionResult> questionResults,
    required int score,
  }) async {
    if (!isStudent || _currentUser == null) return;

    final result = CustomQuizResult(
      assignmentId: assignmentId,
      studentId: _currentUser!.id,
      studentName: _currentUser!.name,
      questionResults: questionResults,
      score: score,
      totalQuestions: questionResults.length,
    );

    await _assignmentService.saveQuizResult(result);

    // Also update user score for backward compatibility
    await updateUserScore(score, subject: 'custom_assignment_$assignmentId');

    notifyListeners();
  }

  Future<List<CustomQuizResult>> getAssignmentResults(String assignmentId) async {
    return await _assignmentService.getResultsForAssignment(assignmentId);
  }

  Future<List<CustomQuizResult>> getStudentResults() async {
    if (!isStudent || _currentUser == null) return [];
    return await _assignmentService.getResultsForStudent(_currentUser!.id);
  }

  Future<CustomQuizResult?> getAssignmentResultForStudent(String assignmentId) async {
    if (_currentUser == null) return null;
    return await _assignmentService.getResultForAssignmentAndStudent(assignmentId, _currentUser!.id);
  }

  Future<void> updateAssignmentStatus(String assignmentId, bool isActive) async {
    if (!isTeacher) return;
    await _assignmentService.updateAssignmentStatus(assignmentId, isActive);
    notifyListeners();
  }

  Future<void> deleteAssignment(String assignmentId) async {
    if (!isTeacher) return;
    await _assignmentService.deleteAssignment(assignmentId);
    notifyListeners();
  }

  String generateAssignmentId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<List<User>> getAllStudents() async {
    return await _authService.getAllUsers().then((users) =>
        users.where((user) => user.role == UserRole.student).toList());
  }

  // Notification methods
  Future<List<NotificationModel>> getUserNotifications() async {
    if (_currentUser == null) return [];
    return await _notificationService.getNotificationsForUser(_currentUser!.id);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
    notifyListeners();
  }

  Future<void> markAllNotificationsAsRead() async {
    if (_currentUser == null) return;
    await _notificationService.markAllAsRead(_currentUser!.id);
    notifyListeners();
  }

  Future<void> sendNotificationToStudents({
    required String title,
    required String message,
    required List<String> studentIds,
    String? assignmentId,
  }) async {
    if (!isTeacher) return;

    for (String studentId in studentIds) {
      await _notificationService.createNotification(
        title: title,
        message: message,
        type: 'assignment',
        assignmentId: assignmentId,
        studentId: studentId,
      );
    }
  }

  String getUserDisplayName() {
    return _currentUser?.name ?? 'Guest User';
  }

  String getUserInitials() {
    if (_currentUser?.name == null) return 'GU';
    List<String> parts = _currentUser!.name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _currentUser!.name.substring(0, 2).toUpperCase();
  }

  Widget getUserAvatar({double radius = 20}) {
    if (_currentUser?.avatarPath != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(_currentUser!.avatarPath!)),
        backgroundColor: Colors.grey.shade300,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _currentUser?.role == UserRole.teacher
          ? Colors.blue.shade600
          : Colors.green.shade600,
      child: Text(
        getUserInitials(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.6,
        ),
      ),
    );
  }
}
