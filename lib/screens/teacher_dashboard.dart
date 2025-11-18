import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_data_model.dart' show StudentData;
import '../models/user_model.dart';
import '../services/student_service.dart';
import '../services/assignment_service.dart';
import '../utils/arabic_numbers.dart';
import '../services/user_provider.dart';
import '../models/assignment_model.dart'
    show CustomAssignment, CustomQuizResult;
import '../widgets/custom_app_bar.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<StudentData> _studentsData = [];
  List<User> _studentsUsers = [];
  List<CustomAssignment> _teacherAssignments = [];
  bool _isLoading = true;
  Map<String, bool> _studentCompleted = {};

  final Map<String, List<CustomQuizResult>> _latestResultsByAssignment = {};
  final List<StreamSubscription<List<CustomQuizResult>>> _resultsSubs = [];
  StreamSubscription<List<StudentData>>? _studentsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final service = StudentService();
    final studentsData = await service.getStudents();

    _studentsSub ??= service.streamStudents().listen((updatedList) {
      if (!mounted) return;
      setState(() => _studentsData = updatedList);
    }, onError: (_) {});

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<User> users = [];
    try {
      users = await userProvider.getAllStudents();
    } catch (_) {
      users = [];
    }

    List<CustomAssignment> teacherAssignments = [];
    try {
      teacherAssignments = await userProvider.getTeacherAssignments();
    } catch (_) {
      teacherAssignments = [];
    }

    for (final s in _resultsSubs) {
      try {
        s.cancel();
      } catch (_) {}
    }
    _resultsSubs.clear();
    _latestResultsByAssignment.clear();
    _studentCompleted.clear();

    for (final assignment in teacherAssignments) {
      try {
        final sub = userProvider.streamAssignmentResults(assignment.id).listen((
          results,
        ) {
          _latestResultsByAssignment[assignment.id] = results;
          final Map<String, bool> completed = {};
          for (final lst in _latestResultsByAssignment.values) {
            for (final r in lst) {
              completed[r.studentId] = true;
            }
          }
          if (!mounted) return;
          setState(() => _studentCompleted = completed);
        }, onError: (_) {});
        _resultsSubs.add(sub);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _studentsData = studentsData;
      _studentsUsers = users;
      _teacherAssignments = teacherAssignments;
      _isLoading = false;
    });
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
        } catch (_) {}
      }
    }

    String initials = 'طالب';
    if (user.name.isNotEmpty) {
      final parts = user.name.split(' ');
      if (parts.length >= 2)
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      else
        initials = user.name
            .substring(0, math.min(2, user.name.length))
            .toUpperCase();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primary,
      child: Text(
        initials,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Arabic-digit and formatting helpers
  String _toArabicDigits(String input) {
    const western = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final buf = StringBuffer();
    for (final ch in input.split('')) {
      final i = western.indexOf(ch);
      buf.write(i >= 0 ? arabic[i] : ch);
    }
    return buf.toString();
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final ss = local.second.toString().padLeft(2, '0');
    // Simplified format without English timezone text in parentheses.
    final formatted = '$y-$m-$d $hh:$mm:$ss';
    return _toArabicDigits(formatted);
  }

  String _formatDurationHuman(Duration dur) {
    if (dur.inSeconds <= 0) return _toArabicDigits('0 ثانية');
    final parts = <String>[];
    final h = dur.inHours;
    final min = dur.inMinutes % 60;
    final s = dur.inSeconds % 60;
    if (h > 0) parts.add('${_toArabicDigits(h.toString())} ساعة');
    if (min > 0) parts.add('${_toArabicDigits(min.toString())} دقيقة');
    if (s > 0) parts.add('${_toArabicDigits(s.toString())} ثانية');
    return parts.join(' ');
  }

  String _formatNumber(dynamic v) {
    if (v == null) return '';
    if (v is num) {
      if (v % 1 == 0) return _toArabicDigits(v.toInt().toString());
      return _toArabicDigits(v.toStringAsFixed(2));
    }
    return _toArabicDigits(v.toString());
  }

  void _showResultLogDialog(CustomQuizResult r) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سجل الطالب'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.startedAt != null) ...[
                Text(
                  'بداية (UTC ISO): ${toArabicDigits(r.startedAt!.toUtc().toIso8601String())}',
                ),
                const SizedBox(height: 6),
                Text('بداية (محلي): ${_formatDateTime(r.startedAt!)}'),
                const SizedBox(height: 8),
              ],
              if (r.completedAt != null) ...[
                Text(
                  'انتهاء (UTC ISO): ${toArabicDigits(r.completedAt!.toUtc().toIso8601String())}',
                ),
                const SizedBox(height: 6),
                Text('انتهاء (محلي): ${_formatDateTime(r.completedAt!)}'),
                const SizedBox(height: 8),
              ],
              Text(
                'الدرجة: ${_formatNumber(r.score)}/${_formatNumber(r.totalQuestions)} (${_toArabicDigits(r.percentage.toStringAsFixed(0))}%)',
              ),
              const SizedBox(height: 8),
              const Text('Raw JSON:'),
              const SizedBox(height: 6),
              Text(jsonEncode(r.toJson())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showAssignmentResultsDialog(CustomAssignment assignment) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final results = await userProvider.getAssignmentResults(assignment.id);
      // If some results are missing startedAt, try to recover it from
      // assignments/{assignmentId}/submissions/{studentId} where
      // markAssignmentStarted writes the timestamp.
      final assignmentService = AssignmentService();
      for (int i = 0; i < results.length; i++) {
        final r = results[i];
        if (r.startedAt == null) {
          try {
            final started = await assignmentService.getSubmissionStarted(
              assignment.id,
              r.studentId,
            );
            if (started != null) {
              // replace with a copy that includes startedAt
              results[i] = CustomQuizResult(
                assignmentId: r.assignmentId,
                studentId: r.studentId,
                studentName: r.studentName,
                questionResults: r.questionResults,
                completedAt: r.completedAt,
                startedAt: started,
                score: r.score,
                totalQuestions: r.totalQuestions,
              );
            }
          } catch (_) {}
        }
      }
      final Map<String, CustomQuizResult> resMap = {
        for (var r in results) r.studentId: r,
      };

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            Future<void> _exportCsv() async {
              try {
                final questions = assignment.questions;
                final sb = StringBuffer();
                // header
                sb.write(
                  'StudentId,StudentName,Score,Total,Percentage,StartedAt,CompletedAt,DurationSeconds',
                );
                for (int i = 0; i < questions.length; i++)
                  sb.write(
                    ',Q${i + 1}Text,Q${i + 1}Correct,Q${i + 1}Answer,Q${i + 1}IsCorrect',
                  );
                sb.writeln();

                for (var sid in assignment.assignedStudentIds) {
                  final sidx = assignment.assignedStudentIds.indexOf(sid);
                  final sname = assignment.assignedStudentNames.length > sidx
                      ? assignment.assignedStudentNames[sidx]
                      : sid;
                  final r = resMap[sid];
                  final score = r?.score ?? 0;
                  final total = r?.totalQuestions ?? questions.length;
                  final pct = r?.percentage ?? 0.0;
                  final startedAtStr = (r != null && r.startedAt != null)
                      ? r.startedAt!.toLocal().toIso8601String()
                      : '';
                  final completedAtStr = (r != null && r.completedAt != null)
                      ? r.completedAt!.toLocal().toIso8601String()
                      : '';
                  final durationSeconds =
                      (r != null &&
                          r.startedAt != null &&
                          r.completedAt != null)
                      ? r.completedAt!.difference(r.startedAt!).inSeconds
                      : null;
                  sb.write(
                    '"$sid","$sname",$score,$total,${pct.toStringAsFixed(1)},"$startedAtStr","$completedAtStr",${durationSeconds ?? ''}',
                  );

                  if (r != null && r.questionResults.isNotEmpty) {
                    for (var qr in r.questionResults) {
                      final textEsc = qr.questionText.replaceAll('"', '""');
                      sb.write(
                        ',"$textEsc",${qr.correctAnswer},${qr.userAnswer},${qr.isCorrect}',
                      );
                    }
                  } else {
                    for (int i = 0; i < questions.length; i++)
                      sb.write(',"",,,');
                  }

                  sb.writeln();
                }

                String fileName =
                    'assignment_${assignment.id}_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
                String? downloads;
                try {
                  if (Platform.isWindows) {
                    final up = Platform.environment['USERPROFILE'];
                    if (up != null) downloads = '$up\\Downloads';
                  } else {
                    final home = Platform.environment['HOME'];
                    if (home != null) downloads = '$home/Downloads';
                  }
                } catch (_) {}

                String path = (downloads != null)
                    ? '$downloads\\$fileName'
                    : fileName;
                final file = File(path);
                await file.writeAsString(sb.toString());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('CSV exported to $path')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
              }
            }

            return AlertDialog(
              title: Text('نتائج: ${assignment.title}'),
              content: SizedBox(
                width: double.maxFinite,
                child: assignment.assignedStudentIds.isEmpty
                    ? const Text('لا طلاب محددين لهذا الواجب')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // CSV export removed as requested
                          Expanded(
                            child: ListView.builder(
                              itemCount: assignment.assignedStudentIds.length,
                              itemBuilder: (context, index) {
                                final sid =
                                    assignment.assignedStudentIds[index];
                                final sname =
                                    assignment.assignedStudentNames.length >
                                        index
                                    ? assignment.assignedStudentNames[index]
                                    : sid;
                                final r = resMap[sid];
                                return Card(
                                  child: ExpansionTile(
                                    title: Text(sname),
                                    subtitle: r == null
                                        ? const Text('لم يُنهي بعد')
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${_formatNumber(r.score)}/${_formatNumber(r.totalQuestions)}  (${_toArabicDigits(r.percentage.toStringAsFixed(0))}%)',
                                              ),
                                              if (r.completedAt != null)
                                                Text(
                                                  'أنهى: ${_formatDateTime(r.completedAt!)}',
                                                ),
                                              if (r.startedAt != null &&
                                                  r.completedAt != null)
                                                Text(
                                                  'المدة: ${_formatDurationHuman(r.completedAt!.difference(r.startedAt!))}',
                                                )
                                              else if (r.completedAt != null &&
                                                  r.startedAt == null)
                                                Text(
                                                  'المدة: غير متاحة (لم يبدأ الطالب رسمياً)',
                                                ),
                                            ],
                                          ),
                                    children: r == null
                                        ? []
                                        : r.questionResults.asMap().entries.map((
                                            entry,
                                          ) {
                                            final idx = entry.key;
                                            final qr = entry.value;
                                            // Try to show choice text when available
                                            String userText;
                                            String correctText;
                                            if (assignment.questions.length >
                                                    idx &&
                                                assignment
                                                        .questions[idx]
                                                        .choices !=
                                                    null) {
                                              final q =
                                                  assignment.questions[idx];
                                              final userIdx = qr.userAnswer
                                                  .toInt();
                                              final correctIdx =
                                                  q.correctChoiceIndex ??
                                                  qr.correctAnswer.toInt();
                                              userText =
                                                  (userIdx >= 0 &&
                                                      q.choices!.length >
                                                          userIdx)
                                                  ? q.choices![userIdx]
                                                  : _formatNumber(
                                                      qr.userAnswer,
                                                    );
                                              correctText =
                                                  (correctIdx >= 0 &&
                                                      q.choices!.length >
                                                          correctIdx)
                                                  ? q.choices![correctIdx]
                                                  : _formatNumber(
                                                      qr.correctAnswer,
                                                    );
                                            } else {
                                              userText = _formatNumber(
                                                qr.userAnswer,
                                              );
                                              correctText = _formatNumber(
                                                qr.correctAnswer,
                                              );
                                            }

                                            return ListTile(
                                              title: Text(qr.questionText),
                                              subtitle: Text(
                                                'الإجابة: $userText  —  الصحيح: $correctText',
                                              ),
                                              trailing: Icon(
                                                qr.isCorrect
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: qr.isCorrect
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            );
                                          }).toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إغلاق'),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ عند جلب النتائج: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'نتائج الطلاب',
        color: Theme.of(context).colorScheme.primary,
        actions: [
          // Show a small loading indicator while loading, otherwise a refresh button
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
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
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            // Results view (replaces the old Students list) — professional assignment-results launcher
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _teacherAssignments.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد واجبات لعرض النتائج لها',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _teacherAssignments.length,
                            itemBuilder: (context, index) {
                              final asg = _teacherAssignments[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: ListTile(
                                  title: Text(asg.title),
                                  subtitle: Text(
                                    'الطلاب: ${asg.assignedStudentNames.length} • الأسئلة: ${asg.questions.length}',
                                  ),
                                  trailing: ElevatedButton(
                                    child: const Text('عرض النتائج'),
                                    onPressed: () =>
                                        _showAssignmentResultsDialog(asg),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
