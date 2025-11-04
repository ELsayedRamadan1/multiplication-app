import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream للاستماع لحالة تسجيل الدخول
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // المستخدم الحالي في Firebase
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  // ✅ تسجيل حساب جديد بالإيميل والباسورد
  Future<User> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? avatarPath,
    required String school,
    required int grade,
    required int classNumber,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      final newUser = User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        role: role,
        avatarPath: avatarPath,
        school: school,
        grade: grade,
        classNumber: classNumber,
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());

      return newUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('كلمة المرور ضعيفة جداً');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('البريد الإلكتروني مستخدم بالفعل');
      } else if (e.code == 'invalid-email') {
        throw Exception('البريد الإلكتروني غير صالح');
      } else {
        throw Exception('حدث خطأ: ${e.message}');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  // ✅ تسجيل الدخول بالإيميل والباسورد
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        throw Exception('بيانات المستخدم غير موجودة في Firestore');
      }

      return User.fromJson(doc.data() as Map<String, dynamic>);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('لا يوجد مستخدم بهذا البريد الإلكتروني');
      } else if (e.code == 'wrong-password') {
        throw Exception('كلمة المر��ر غير صحيحة');
      } else if (e.code == 'invalid-email') {
        throw Exception('البريد الإلكتروني غير صالح');
      } else if (e.code == 'user-disabled') {
        throw Exception('هذا الحساب معطل');
      } else {
        throw Exception('حدث خطأ: ${e.message}');
      }
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  // ✅ تسجيل الدخول بـ Google
  Future<User> signInWithGoogle({
    required UserRole role,
    required String school,
    required int grade,
    required int classNumber,
  }) async {
    try {
      // فصل أي جلسة Google مفتوحة مسبقًا
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
          await _googleSignIn.disconnect();
        }
      } catch (_) {
        // تجاهل أي خطأ ناتج عن disconnect
      }


      // تشغيل عملية تسجيل الدخول بـ Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('تم إلغاء تسجيل الدخول بواسطة المستخدم');
      }

      // الحصول على بيانات المصادقة
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // إنشاء بيانات اعتماد Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول إلى Firebase
      firebase_auth.UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // التحقق من وجود المستخدم في Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      User user;

      if (!doc.exists) {
        // إنشاء مستخدم جديد
        user = User(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'مستخدم',
          email: userCredential.user!.email!,
          role: role,
          avatarPath: userCredential.user!.photoURL,
          school: school,
          grade: grade,
          classNumber: classNumber,
        );

        await _firestore.collection('users').doc(user.id).set(user.toJson());
      } else {
        // جلب بيانات المستخدم الموجودة
        user = User.fromJson(doc.data() as Map<String, dynamic>);
      }

      return user;
    } catch (e) {
      throw Exception('حدث خطأ أثناء تسجيل الدخول بـ Google: $e');
    }
  }


  // ✅ الحصول على المستخدم الحالي
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final doc =
      await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!doc.exists) return null;

      return User.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // ✅ تحديث بيانات المستخدم
  Future<void> updateUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());

      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(user.name);
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث البيانات: $e');
    }
  }

  // ✅ تحديث الصورة الشخصية
  Future<void> updateUserAvatar(String userId, String avatarPath) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'avatarPath': avatarPath,
      });

      if (_auth.currentUser != null && _auth.currentUser!.uid == userId) {
        await _auth.currentUser!.updatePhotoURL(avatarPath);
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحديث الصورة: $e');
    }
  }

  // ✅ إرسال رابط إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('لا يوجد مست��دم بهذا البريد الإلكتروني');
      } else if (e.code == 'invalid-email') {
        throw Exception('البريد الإلكتروني غير صالح');
      } else {
        throw Exception('حدث خطأ: ${e.message}');
      }
    }
  }

  // ✅ تسجيل الخروج
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('حدث خطأ أثناء تسجيل الخروج: $e');
    }
  }

  // ✅ حذف الحساب
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء حذف الحساب: $e');
    }
  }

  // ✅ جلب جميع المستخدمين (للمعلمين فقط)
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => User.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب المستخدمين: $e');
    }
  }

  // Query users with optional filters. Server-side filtering is much faster for large collections.
  Future<List<User>> queryUsers({String? school, int? grade, int? classNumber, bool onlyStudents = true}) async {
    try {
      Query collectionQuery = _firestore.collection('users');

      if (onlyStudents) {
        // role stored as index in the document
        collectionQuery = collectionQuery.where('role', isEqualTo: UserRole.student.index);
      }

      if (school != null && school.trim().isNotEmpty) {
        // Use case-insensitive matching via where on exact value; if you need partial contains,
        // consider adding a normalized field or using a third-party search. Here we use exact match.
        collectionQuery = collectionQuery.where('school', isEqualTo: school.trim());
      }

      if (grade != null) {
        collectionQuery = collectionQuery.where('grade', isEqualTo: grade);
      }

      if (classNumber != null) {
        collectionQuery = collectionQuery.where('classNumber', isEqualTo: classNumber);
      }

      final snapshot = await collectionQuery.get();
      return snapshot.docs.map((d) => User.fromJson(d.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('حدث خطأ أثناء استعلام المستخدمين: $e');
    }
  }

  // ✅ التحقق من حالة تسجيل الدخول
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // تحديث تخزين إعدادات المعلم الافتراضية (الصف والفصل) في مستند المستخدم
  Future<void> updateTeacherDefaults(String userId, {int? grade, int? classNumber}) async {
    try {
      final data = <String, Object?>{};
      if (grade != null) data['teacherDefaultGrade'] = grade;
      if (classNumber != null) data['teacherDefaultClassNumber'] = classNumber;
      if (data.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(data);
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء حفظ إعدادات المعلم: $e');
    }
  }
}
