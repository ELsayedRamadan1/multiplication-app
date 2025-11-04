import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_data_model.dart' show StudentData;
import '../models/user_model.dart';
import '../services/student_service.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';
import '../models/assignment_model.dart' show CustomAssignment, CustomQuizResult;
import '../widgets/custom_app_bar.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<StudentData> _studentsData = [];
  List<User> _studentsUsers = [];
  bool _isLoading = true;
  // Map of studentId -> whether they completed any of the teacher's assignments
  Map<String, bool> _studentCompleted = {};

  // Cache latest results per assignment and active subscriptions
  final Map<String, List<CustomQuizResult>> _latestResultsByAssignment = {};
  final List<StreamSubscription<List<CustomQuizResult>>> _resultsSubs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    // load stored performance data
    StudentService service = StudentService();
    List<StudentData> studentsData = await service.getStudents();

    // load users from UserProvider (which in turn uses AuthService)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<User> users = [];
    try {
      users = await userProvider.getAllStudents();
    } catch (_) {
      users = [];
    }

    // Load this teacher's assignments and subscribe to their result streams so UI updates in real-time
    List<CustomAssignment> teacherAssignments = [];
    try {
      teacherAssignments = await userProvider.getTeacherAssignments();
    } catch (_) {
      teacherAssignments = [];
    }

    // Cancel previous subscriptions
    for (final s in _resultsSubs) {
      try {
        s.cancel();
      } catch (_) {}
    }
    _resultsSubs.clear();
    _latestResultsByAssignment.clear();
    _studentCompleted.clear();

    // Subscribe to result streams for each assignment
    for (final assignment in teacherAssignments) {
      try {
        final sub = userProvider.streamAssignmentResults(assignment.id).listen((results) {
          _latestResultsByAssignment[assignment.id] = results;

          // recompute which students have completed any assignment
          final Map<String, bool> completed = {};
          for (final lst in _latestResultsByAssignment.values) {
            for (final r in lst) {
              completed[r.studentId] = true;
            }
          }

          if (mounted) {
            setState(() {
              _studentCompleted = completed;
            });
          }
        }, onError: (_) {
          // ignore stream errors
        });

        _resultsSubs.add(sub);
      } catch (_) {
        // ignore subscription errors
      }
    }

    setState(() {
      _studentsData = studentsData;
      _studentsUsers = users;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (final s in _resultsSubs) {
      try { s.cancel(); } catch (_) {}
    }
    _resultsSubs.clear();
    super.dispose();
  }

  Widget _buildAvatar(User user, double radius) {
    if (user.avatarPath != null && user.avatarPath!.isNotEmpty) {
      if (user.avatarPath!.startsWith('http')) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: NetworkImage(user.avatarPath!),
        );
      } else {
        try {
          return CircleAvatar(
            radius: radius,
            backgroundImage: FileImage(File(user.avatarPath!)),
          );
        } catch (_) {
          // fallthrough to initials
        }
      }
    }

    // initials
    String initials = 'طالب';
    if (user.name.isNotEmpty) {
      final parts = user.name.split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = user.name.substring(0, math.min(2, user.name.length)).toUpperCase();
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade700,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'لوحة تحكم المعلم',
        color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark ? Colors.black : Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [

            // Students List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _studentsUsers.isEmpty
                      ? const Center(child: Text('لا توجد بيانات طلاب بعد'))
                      : ListView.builder(
                          itemCount: _studentsUsers.length,
                          itemBuilder: (context, index) {
                            final user = _studentsUsers[index];
                            // try to find performance data by matching name or email
                            final perf = _studentsData.firstWhere(
                                (s) => s.name == user.name,
                                orElse: () => StudentData(name: user.name));

                            return Card(
                              margin: const EdgeInsets.all(10),
                              child: ListTile(
                                leading: _buildAvatar(user, 28),
                                title: Text(user.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (user.school.isNotEmpty) Text('المدرسة: ${user.school}'),
                                    Text('الصف: ${user.grade}  •  الفصل: ${user.classNumber}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'النتيجة: ${perf.score}/${perf.totalQuestions}', 
                                      style: TextStyle(
                                        color: perf.totalQuestions > 0 
                                          ? (perf.score / perf.totalQuestions >= 0.7 
                                              ? Colors.green 
                                              : Colors.orange
                                            ) 
                                          : Colors.grey
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_studentCompleted[user.id] == true) ...[
                                      const Icon(Icons.check_circle, color: Colors.green),
                                      const SizedBox(width: 8),
                                    ],
                                    IconButton(
                                      icon: const Icon(Icons.more_horiz),
                                      onPressed: () {
                                        _showStudentDetails(user, perf);
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () => _showStudentDetails(user, perf),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
                  ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadStudents,
        tooltip: 'تحديث',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showStudentDetails(User user, StudentData perf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(user, 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.school.isNotEmpty) Text('المدرسة: ${user.school}'),
                        Text('الصف: ${user.grade}'),
                        Text('الفصل: ${user.classNumber}'),
                        const SizedBox(height: 6),
                        Text('البريد: ${user.email}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('أداء الطالب:'),
              const SizedBox(height: 8),
              Text('النتيجة: ${perf.score}/${perf.totalQuestions}'),
              const SizedBox(height: 8),
              if (perf.answers.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: perf.answers.length,
                    itemBuilder: (context, index) {
                      final ans = perf.answers[index];
                      return ListTile(
                        title: Text(ans.question),
                        subtitle: Text('إجابتك: ${ans.answer}'),
                        trailing: Icon(ans.isCorrect ? Icons.check : Icons.close, color: ans.isCorrect?Colors.green:Colors.red),
                      );
                    },
                  ),
                )
              else
                const Text('لا توجد إجابات ��حفوظة لهذا الطالب'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق')),
        ],
      ),
    );
  }
}
