import 'dart:io';
import 'package:flutter/material.dart';

import '../models/question_model.dart';
import '../models/user_model.dart';
import '../models/assignment_model.dart';
import 'auth_service.dart';
import 'assignment_service.dart';

class UserProvider extends ChangeNotifier {
  final AuthService authService;
  final AssignmentService _assignmentService = AssignmentService();

  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isStudent => _currentUser?.role == UserRole.student;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;

  UserProvider({required this.authService}) {
    _initializeUser();
    _listenToAuthChanges();
  }

  // Teacher default filters (optional)
  int? _teacherDefaultGrade;
  int? _teacherDefaultClassNumber;

  int? get teacherDefaultGrade => _teacherDefaultGrade;
  int? get teacherDefaultClassNumber => _teacherDefaultClassNumber;

  Future<void> setTeacherDefaults({int? grade, int? classNumber}) async {
    if (!isTeacher || _currentUser == null) return;
    _teacherDefaultGrade = grade;
    _teacherDefaultClassNumber = classNumber;
    notifyListeners();

    // persist in Firestore via AuthService
    try {
      await authService.updateTeacherDefaults(_currentUser!.id, grade: grade, classNumber: classNumber);
    } catch (e) {
      // ignore persistence errors but log
      print('Failed to persist teacher defaults: $e');
    }
  }

  // الاستماع لتغييرات حالة المصادقة
  void _listenToAuthChanges() {
    authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _currentUser = await authService.getCurrentUser();
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await authService.getCurrentUser();
    } catch (e) {
      print('حدث خطأ أثناء تحميل المستخدم الحالي: $e');
      _currentUser = null;
    }

    // If the user document contains teacher defaults, populate provider state
    if (_currentUser != null) {
      _teacherDefaultGrade = _currentUser!.teacherDefaultGrade;
      _teacherDefaultClassNumber = _currentUser!.teacherDefaultClassNumber;
    }

    _isLoading = false;
    notifyListeners();
  }

  // تسجيل الدخول بالإيميل والباسورد
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      User user = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('خطأ أثناء تسجيل الدخول: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // تسجيل الدخول بـ Google
  Future<bool> signInWithGoogle({
    required UserRole role,
    String? school,
    int? grade,
    int? classNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      User user = await authService.signInWithGoogle(
        role: role,
        school: school ?? '',
        grade: grade ?? 1,
        classNumber: classNumber ?? 1,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('خطأ أثناء تسجيل الدخول بـ Google: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // التسجيل
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? avatarPath,
    String? school,
    int? grade,
    int? classNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      User newUser = await authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        role: role,
        avatarPath: avatarPath,
        school: school ?? '',
        grade: grade ?? 1,
        classNumber: classNumber ?? 1,
      );

      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('حدث خطأ أثناء التسجيل: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    await authService.resetPassword(email);
  }

  // تحديث نقاط المستخدم
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

    _currentUser = updatedUser;
    await authService.updateUser(updatedUser);

    notifyListeners();
  }

  // الحصول على واجبات المعلم
  Future<List<CustomAssignment>> getTeacherAssignments() async {
    if (!isTeacher || _currentUser == null) return [];
    return await _assignmentService.getAssignmentsByTeacher(_currentUser!.id);
  }

  // Stream واجبات المعلم (real-time)
  Stream<List<CustomAssignment>> streamTeacherAssignments() {
    if (!isTeacher || _currentUser == null) return Stream.value([]);
    return _assignmentService.streamAssignmentsByTeacher(_currentUser!.id);
  }

  // الحصول على واجبات الطالب
  Future<List<CustomAssignment>> getStudentAssignments() async {
    if (!isStudent || _currentUser == null) return [];
    return await _assignmentService.getAssignmentsForStudent(_currentUser!.id);
  }

  // Stream واجبات الطالب (real-time)
  Stream<List<CustomAssignment>> streamStudentAssignments() {
    if (!isStudent || _currentUser == null) return Stream.value([]);
    return _assignmentService.streamAssignmentsForStudent(_currentUser!.id);
  }

  // الحصول على الواجبات النشطة للطالب
  Future<List<CustomAssignment>> getActiveStudentAssignments() async {
    if (!isStudent || _currentUser == null) return [];
    return await _assignmentService.getActiveAssignmentsForStudent(_currentUser!.id);
  }

  // Stream للواجبات النشطة للطالب
  Stream<List<CustomAssignment>> streamActiveStudentAssignments() {
    if (!isStudent || _currentUser == null) return Stream.value([]);
    return _assignmentService.streamActiveAssignmentsForStudent(_currentUser!.id);
  }

  // إنشاء واجب
  Future<CustomAssignment> createAssignment({
    required String title,
    required List<Question> questions,
    required List<String> assignedStudentIds,
    required List<String> assignedStudentNames,
    String? description,
    DateTime? dueDate,
  }) async {
    if (!isTeacher || _currentUser == null) {
      throw Exception('فقط المعلمون يمكنهم إنشاء المهام');
    }

    // Double-check the current user's Firestore record and role
    final userInFirestore = await authService.getCurrentUser();
    if (userInFirestore == null) {
      throw Exception('بيانات المعلم غير متاحة في الخادم. الرجاء تسجيل الخروج وتسجيل الدخول مرة أخرى.');
    }
    if (userInFirestore.role != UserRole.teacher) {
      throw Exception('يجب أن يكون لديك حساب معلم لإنشاء واجبات');
    }

    final assignment = CustomAssignment(
      id: '', // let Firestore generate id
      teacherId: _currentUser!.id,
      teacherName: _currentUser!.name,
      assignedStudentIds: assignedStudentIds,
      assignedStudentNames: assignedStudentNames,
      questions: questions,
      title: title,
      description: description,
      dueDate: dueDate,
    );

    try {
      await _assignmentService.saveAssignment(assignment);
    } catch (e) {
      // Re-throw with clearer message for UI
      throw Exception('فشل في إنشاء الواجب: ${e.toString()}');
    }

    notifyListeners();
    return assignment;
  }

  // حفظ نتيجة اختبار مخصص
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
    await updateUserScore(score, subject: 'custom_assignment_$assignmentId');
    notifyListeners();
  }

  // نتائج الواجب
  Future<List<CustomQuizResult>> getAssignmentResults(String assignmentId) async {
    return await _assignmentService.getResultsForAssignment(assignmentId);
  }

  // Stream نتائج الواجب
  Stream<List<CustomQuizResult>> streamAssignmentResults(String assignmentId) {
    return _assignmentService.streamResultsForAssignment(assignmentId);
  }

  // نتائج الطالب
  Future<List<CustomQuizResult>> getStudentResults() async {
    if (!isStudent || _currentUser == null) return [];
    return await _assignmentService.getResultsForStudent(_currentUser!.id);
  }

  // Stream نتائج الطالب
  Stream<List<CustomQuizResult>> streamStudentResults() {
    if (!isStudent || _currentUser == null) return Stream.value([]);
    return _assignmentService.streamResultsForStudent(_currentUser!.id);
  }

  // الحصول على نتيجة واجب محدد للطالب
  Future<CustomQuizResult?> getAssignmentResultForStudent(String assignmentId) async {
    if (_currentUser == null) return null;
    return await _assignmentService.getResultForAssignmentAndStudent(
        assignmentId,
        _currentUser!.id
    );
  }

  // تحديث حالة الواجب
  Future<void> updateAssignmentStatus(String assignmentId, bool isActive) async {
    if (!isTeacher) return;
    await _assignmentService.updateAssignmentStatus(assignmentId, isActive);
    notifyListeners();
  }

  // حذف واجب
  Future<void> deleteAssignment(String assignmentId) async {
    if (!isTeacher) return;
    await _assignmentService.deleteAssignment(assignmentId);
    notifyListeners();
  }

  String generateAssignmentId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // الحصول على جميع الطلاب أو حسب فلاتر (school, grade, classNumber)
  Future<List<User>> getAllStudents({String? school, int? grade, int? classNumber}) async {
    // If any filter is provided, use server-side query
    if ((school != null && school.trim().isNotEmpty) || grade != null || classNumber != null) {
      return await authService.queryUsers(
        school: school,
        grade: grade,
        classNumber: classNumber,
        onlyStudents: true,
      );
    }

    // Fallback: fetch all and filter client-side (legacy behavior)
    return await authService.getAllUsers().then((users) =>
        users.where((user) => user.role == UserRole.student).toList());
  }


  String getUserDisplayName() {
    return _currentUser?.name ?? 'مستخدم زائر';
  }

  String getUserInitials() {
    if (_currentUser?.name == null) return 'ZZ';
    List<String> parts = _currentUser!.name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _currentUser!.name.substring(0, 2).toUpperCase();
  }

  // تحديث صورة المستخدم
  Future<bool> updateUserAvatar(String avatarPath) async {
    if (_currentUser == null) return false;

    try {
      await authService.updateUserAvatar(_currentUser!.id, avatarPath);

      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        role: _currentUser!.role,
        avatarPath: avatarPath,
        createdAt: _currentUser!.createdAt,
        totalScore: _currentUser!.totalScore,
        totalQuizzesCompleted: _currentUser!.totalQuizzesCompleted,
        subjectScores: _currentUser!.subjectScores,
        school: _currentUser!.school,
        grade: _currentUser!.grade,
        classNumber: _currentUser!.classNumber,
      );

      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user avatar: $e');
      return false;
    }
  }

  Widget getUserAvatar({double radius = 20}) {
    if (_currentUser?.avatarPath != null) {
      // تحقق إذا كانت الصورة من Google أو محلية
      if (_currentUser!.avatarPath!.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(_currentUser!.avatarPath!),
          backgroundColor: Colors.grey.shade300,
        );
      } else {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(File(_currentUser!.avatarPath!)),
          backgroundColor: Colors.grey.shade300,
        );
      }
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