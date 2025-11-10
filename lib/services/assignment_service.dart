import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  static const String _assignmentsCollection = 'assignments';
  static const String _resultsCollection = 'quiz_results';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a new or existing assignment to Firestore
  Future<void> saveAssignment(
    CustomAssignment assignment, {
    bool notifyStudents = true,
  }) async {
    try {
      final docRef = assignment.id.isEmpty
          ? _firestore.collection(_assignmentsCollection).doc()
          : _firestore.collection(_assignmentsCollection).doc(assignment.id);

      final id = docRef.id;
      final assignmentToSave = assignment.id.isEmpty
          ? assignment.copyWith(id: id)
          : assignment;

      await docRef.set(assignmentToSave.toJson());

      // Notifications have been removed by request; assignment is saved for teacher/student access via Firestore
    } catch (e) {
      throw Exception('حدث خطأ أثناء حفظ الواجب: $e');
    }
  }

  // Get all assignments (one-time)
  Future<List<CustomAssignment>> getAllAssignments() async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentsCollection)
          .get();
      return snapshot.docs
          .map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب الواجبات: $e');
    }
  }

  Future<List<CustomAssignment>> getAssignmentsByTeacher(
    String teacherId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentsCollection)
          .where('teacherId', isEqualTo: teacherId)
          .get();
      return snapshot.docs
          .map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب واجبات المعلم: $e');
    }
  }

  Future<List<String>> getAssignedStudents(String assignmentId) async {
    try {
      final doc = await _firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .get();
      if (!doc.exists) return [];
      final data = doc.data()!;
      final ids =
          (data['assignedStudentIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      return ids;
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب طلاب الواجب: $e');
    }
  }

  // Marks completion and creates a lightweight result document
  Future<void> completeAssignment(
    String assignmentId,
    String studentId,
    int score,
  ) async {
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

  Future<List<CustomAssignment>> getActiveAssignmentsForStudent(
    String studentId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentsCollection)
          .where('isActive', isEqualTo: true)
          .where('assignedStudentIds', arrayContains: studentId)
          .get();
      return snapshot.docs
          .map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب الواجبات النشطة: $e');
    }
  }

  Future<List<CustomAssignment>> getAssignmentsForStudent(
    String studentId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_assignmentsCollection)
          .where('assignedStudentIds', arrayContains: studentId)
          .get();
      return snapshot.docs
          .map((d) => CustomAssignment.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب واجبات الطالب: $e');
    }
  }

  Future<void> saveQuizResult(CustomQuizResult result) async {
    try {
      final docId = '${result.assignmentId}_${result.studentId}';
      final docRef = _firestore.collection(_resultsCollection).doc(docId);

      // If there's an existing doc it may be a "started" placeholder
      final existing = await docRef.get();
      if (existing.exists) {
        final data = existing.data();
        // If an existing completed score is present, disallow overwrite
        if (data != null &&
            (data['score'] != null || data['completedAt'] != null)) {
          throw Exception('تم إنهاء هذا الواجب سابقًا');
        }

        // Otherwise merge the full result with the existing started document
        await docRef.set(result.toJson(), SetOptions(merge: true));
      } else {
        await docRef.set(result.toJson());
      }
    } on FirebaseException catch (e) {
      // Re-throw with code so caller can detect permission issues
      throw Exception('Firestore error (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء حفظ نتيجة الاختبار: $e');
    }
  }

  /// Marks that a student started an assignment by creating a lightweight
  /// result document containing `startedAt`. If the document already exists
  /// and contains `startedAt`, the existing timestamp is returned.
  Future<DateTime> markAssignmentStarted(
    String assignmentId,
    String studentId,
    DateTime startedAt,
  ) async {
    try {
      final docId = '${assignmentId}_$studentId';
      final docRef = _firestore.collection(_resultsCollection).doc(docId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'assignmentId': assignmentId,
          'studentId': studentId,
          'startedAt': startedAt.toIso8601String(),
        });
        // Also create a submission record under assignments/{assignmentId}/submissions/{studentId}
        try {
          final subRef = _firestore
              .collection(_assignmentsCollection)
              .doc(assignmentId)
              .collection('submissions')
              .doc(studentId);
          await subRef.set({
            'studentId': studentId,
            'startedAt': startedAt.toIso8601String(),
          }, SetOptions(merge: true));
        } catch (_) {
          // ignore secondary write errors to avoid blocking the primary startedAt record
        }
        return startedAt;
      } else {
        final data = doc.data();
        if (data != null && data['startedAt'] != null) {
          final existing = DateTime.tryParse(data['startedAt']);
          return existing ?? startedAt;
        }

        // Merge startedAt into existing doc
        await docRef.set({
          'startedAt': startedAt.toIso8601String(),
        }, SetOptions(merge: true));

        // Also merge into assignments/.../submissions/{studentId}
        try {
          final subRef = _firestore
              .collection(_assignmentsCollection)
              .doc(assignmentId)
              .collection('submissions')
              .doc(studentId);
          await subRef.set({
            'startedAt': startedAt.toIso8601String(),
          }, SetOptions(merge: true));
        } catch (_) {}
        return startedAt;
      }
    } on FirebaseException catch (e) {
      throw Exception('Firestore error (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تسجيل بداية الواجب: $e');
    }
  }

  Future<List<CustomQuizResult>> getAllQuizResults() async {
    try {
      final snapshot = await _firestore.collection(_resultsCollection).get();
      return snapshot.docs
          .map((d) => CustomQuizResult.fromJson({...d.data()}))
          .toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب نتائج الاختبارات: $e');
    }
  }

  Future<List<CustomQuizResult>> getResultsForAssignment(
    String assignmentId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_resultsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .get();
      return snapshot.docs
          .map((d) => CustomQuizResult.fromJson({...d.data()}))
          .toList();
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
      return snapshot.docs
          .map((d) => CustomQuizResult.fromJson({...d.data()}))
          .toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب نتائج الطالب: $e');
    }
  }

  Future<CustomQuizResult?> getResultForAssignmentAndStudent(
    String assignmentId,
    String studentId,
  ) async {
    try {
      final docId = '${assignmentId}_$studentId';
      final doc = await _firestore
          .collection(_resultsCollection)
          .doc(docId)
          .get();
      if (!doc.exists) return null;
      return CustomQuizResult.fromJson({...doc.data()!});
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب نتيجة الاختبار: $e');
    }
  }

  Future<void> deleteAssignment(String assignmentId) async {
    try {
      // Delete submissions subcollection (if any)
      try {
        final subsSnap = await _firestore
            .collection(_assignmentsCollection)
            .doc(assignmentId)
            .collection('submissions')
            .get();
        final batchSubs = _firestore.batch();
        for (final d in subsSnap.docs) {
          batchSubs.delete(d.reference);
        }
        if (subsSnap.docs.isNotEmpty) await batchSubs.commit();
      } catch (_) {
        // ignore secondary errors
      }

      // delete results (quiz_results)
      final results = await _firestore
          .collection(_resultsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final batch = _firestore.batch();
      for (final d in results.docs) {
        batch.delete(d.reference);
      }
      if (results.docs.isNotEmpty) await batch.commit();

      // delete the assignment document itself
      await _firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .delete();
    } catch (e) {
      throw Exception('حدث خطأ أثناء حذف الواجب: $e');
    }
  }

  Future<void> updateAssignmentStatus(
    String assignmentId,
    bool isActive,
  ) async {
    try {
      await _firestore
          .collection(_assignmentsCollection)
          .doc(assignmentId)
          .update({'isActive': isActive});
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
          .map(
            (s) => s.docs
                .map(
                  (d) => CustomAssignment.fromJson({...d.data(), 'id': d.id}),
                )
                .toList(),
          );
    } catch (e) {
      return Stream.value([]);
    }
  }

  Stream<List<CustomAssignment>> streamActiveAssignmentsForStudent(
    String studentId,
  ) {
    try {
      return _firestore
          .collection(_assignmentsCollection)
          .where('isActive', isEqualTo: true)
          .where('assignedStudentIds', arrayContains: studentId)
          .snapshots()
          .map(
            (s) => s.docs
                .map(
                  (d) => CustomAssignment.fromJson({...d.data(), 'id': d.id}),
                )
                .toList(),
          );
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
          .map(
            (s) => s.docs
                .map(
                  (d) => CustomAssignment.fromJson({...d.data(), 'id': d.id}),
                )
                .toList(),
          );
    } catch (e) {
      return Stream.value([]);
    }
  }

  Stream<List<CustomQuizResult>> streamResultsForAssignment(
    String assignmentId,
  ) {
    try {
      return _firestore
          .collection(_resultsCollection)
          .where('assignmentId', isEqualTo: assignmentId)
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => CustomQuizResult.fromJson({...d.data()}))
                .toList(),
          );
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
          .map(
            (s) => s.docs
                .map((d) => CustomQuizResult.fromJson({...d.data()}))
                .toList(),
          );
    } catch (e) {
      return Stream.value([]);
    }
  }
}
