import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  static const String _assignmentsCollection = 'assignments';
  static const String _resultsCollection = 'quiz_results';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a new or existing assignment to Firestore
  Future<void> saveAssignment(CustomAssignment assignment, {bool notifyStudents = true}) async {
    try {
      final docRef = assignment.id.isEmpty
          ? _firestore.collection(_assignmentsCollection).doc()
          : _firestore.collection(_assignmentsCollection).doc(assignment.id);

      final id = docRef.id;
      final assignmentToSave = assignment.id.isEmpty ? assignment.copyWith(id: id) : assignment;

      await docRef.set(assignmentToSave.toJson());

      // Notifications have been removed by request; assignment is saved for teacher/student access via Firestore
    } catch (e) {
      throw Exception('حدث خطأ أثناء حفظ الواجب: $e');
    }
  }

  // Get all assignments (one-time)
  Future<List<CustomAssignment>> getAllAssignments() async {
    try {
      final snapshot = await _firestore.collection(_assignmentsCollection).get();
      return snapshot.docs.map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب الواجبات: $e');
    }
  }

  Future<List<CustomAssignment>> getAssignmentsByTeacher(String teacherId) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentsCollection)
          .where('teacherId', isEqualTo: teacherId)
          .get();
      return snapshot.docs.map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب واجبات المعلم: $e');
    }
  }

  Future<List<String>> getAssignedStudents(String assignmentId) async {
    try {
      final doc = await _firestore.collection(_assignmentsCollection).doc(assignmentId).get();
      if (!doc.exists) return [];
      final data = doc.data()!;
      final ids = (data['assignedStudentIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
      return ids;
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب طلاب الواجب: $e');
    }
  }

  // Marks completion and creates a lightweight result document
  Future<void> completeAssignment(String assignmentId, String studentId, int score) async {
    try {
      final docId = '${assignmentId}_$studentId';
      await _firestore.collection(_resultsCollection).doc(docId).set({
        'assignmentId': assignmentId,
        'studentId': studentId,
        'score': score,
        'completedAt': DateTime.now().toIso8601String(),
      });

      // Notifications removed: do not create notifications on completion
    } catch (e) {
      throw Exception('حدث خطأ أثناء إكمال الواجب: $e');
    }
  }

  Future<List<CustomAssignment>> getActiveAssignmentsForStudent(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentsCollection)
          .where('isActive', isEqualTo: true)
          .where('assignedStudentIds', arrayContains: studentId)
          .get();
      return snapshot.docs.map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب الواجبات النشطة: $e');
    }
  }

  Future<List<CustomAssignment>> getAssignmentsForStudent(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentsCollection)
          .where('assignedStudentIds', arrayContains: studentId)
          .get();
      return snapshot.docs.map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id})).toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب واجبات الطالب: $e');
    }
  }

  Future<void> saveQuizResult(CustomQuizResult result) async {
    try {
      final docId = '${result.assignmentId}_${result.studentId}';
      final docRef = _firestore.collection(_resultsCollection).doc(docId);

      // Prevent overwriting an existing result (disallow retakes)
      final existing = await docRef.get();
      if (existing.exists) {
        throw Exception('تم إنهاء هذا الواجب سابقًا');
      }

      await docRef.set(result.toJson());
    } catch (e) {
      throw Exception('حدث خطأ أثناء حفظ نتيجة الاختبار: $e');
    }
  }

  Future<List<CustomQuizResult>> getAllQuizResults() async {
    try {
      final snapshot = await _firestore.collection(_resultsCollection).get();
      return snapshot.docs.map((d) => CustomQuizResult.fromJson({...d.data()})).toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب نتائج الاختبارات: $e');
    }
  }

  Future<List<CustomQuizResult>> getResultsForAssignment(String assignmentId) async {
    try {
      final snapshot = await _firestore
          .collection(_resultsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .get();
      return snapshot.docs.map((d) => CustomQuizResult.fromJson({...d.data()})).toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب نتائج الواجب: $e');
    }
  }

  Future<List<CustomQuizResult>> getResultsForStudent(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection(_resultsCollection)
          .where('studentId', isEqualTo: studentId)
          .get();
      return snapshot.docs.map((d) => CustomQuizResult.fromJson({...d.data()})).toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب نتائج الطالب: $e');
    }
  }

  Future<CustomQuizResult?> getResultForAssignmentAndStudent(String assignmentId, String studentId) async {
    try {
      final docId = '${assignmentId}_$studentId';
      final doc = await _firestore.collection(_resultsCollection).doc(docId).get();
      if (!doc.exists) return null;
      return CustomQuizResult.fromJson({...doc.data()!});
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب نتيجة الاختبار: $e');
    }
  }

  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _firestore.collection(_assignmentsCollection).doc(assignmentId).delete();

      // delete results
      final results = await _firestore
          .collection(_resultsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final batch = _firestore.batch();
      for (final d in results.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('حدث خطأ أثناء حذف الواجب: $e');
    }
  }

  Future<void> updateAssignmentStatus(String assignmentId, bool isActive) async {
    try {
      await _firestore.collection(_assignmentsCollection).doc(assignmentId).update({'isActive': isActive});
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث حالة الواجب: $e');
    }
  }

  // ============ Real-time Streams ============

  Stream<List<CustomAssignment>> streamAssignmentsByTeacher(String teacherId) {
    try {
      return _firestore
          .collection(_assignmentsCollection)
          .where('teacherId', isEqualTo: teacherId)
          .snapshots()
          .map((s) => s.docs.map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id})).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  Stream<List<CustomAssignment>> streamActiveAssignmentsForStudent(String studentId) {
    try {
      return _firestore
          .collection(_assignmentsCollection)
          .where('isActive', isEqualTo: true)
          .where('assignedStudentIds', arrayContains: studentId)
          .snapshots()
          .map((s) => s.docs.map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id})).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  Stream<List<CustomAssignment>> streamAssignmentsForStudent(String studentId) {
    try {
      return _firestore
          .collection(_assignmentsCollection)
          .where('assignedStudentIds', arrayContains: studentId)
          .snapshots()
          .map((s) => s.docs.map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id})).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  Stream<List<CustomQuizResult>> streamResultsForAssignment(String assignmentId) {
    try {
      return _firestore
          .collection(_resultsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .snapshots()
          .map((s) => s.docs.map((d) => CustomQuizResult.fromJson({...d.data()})).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  Stream<List<CustomQuizResult>> streamResultsForStudent(String studentId) {
    try {
      return _firestore
          .collection(_resultsCollection)
          .where('studentId', isEqualTo: studentId)
          .snapshots()
          .map((s) => s.docs.map((d) => CustomQuizResult.fromJson({...d.data()})).toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

}
