import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assignment_model.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';

class TeacherAssignmentDashboard extends StatefulWidget {
  const TeacherAssignmentDashboard({super.key});

  @override
  _TeacherAssignmentDashboardState createState() => _TeacherAssignmentDashboardState();
}

class _TeacherAssignmentDashboardState extends State<TeacherAssignmentDashboard> {
  @override
  void initState() {
    super.initState();
    // no manual load; UI will use streams
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقدّم الطلاب'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.orange.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // refresh by calling setState which will rebuild StreamBuilders
              setState(() {});
            },
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
                : [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: StreamBuilder<List<CustomAssignment>>(
          stream: userProvider.streamTeacherAssignments(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final assignments = snapshot.data ?? [];

            if (assignments.isEmpty) {
              return const Center(
                child: Text(
                  'لم يتم إنشاء أي واجبات بعد.\nأنشئ واجبًا لترى تقدّم الطلاب!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      assignment.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${assignment.questions.length} سؤال',
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (assignment.description != null && assignment.description!.isNotEmpty)
                              Text(
                                'الوصف: ${assignment.description!}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'الحالة: ${assignment.isActive ? 'نشط' : 'غير نشط'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: assignment.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'نتائج الطلاب:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            // Show assigned students with a real-time check for completion, plus detailed results below
                            StreamBuilder<List<CustomQuizResult>>(
                              stream: userProvider.streamAssignmentResults(assignment.id),
                              builder: (context, resSnapshot) {
                                final assignmentResults = resSnapshot.data ?? [];

                                // create a set of studentIds who completed this assignment
                                final completedIds = assignmentResults.map((r) => r.studentId).toSet();

                                // Assigned students list (ids + names if available in assignment)
                                final assignedIds = assignment.assignedStudentIds;
                                final assignedNames = assignment.assignedStudentNames;

                                Widget assignedList;
                                if (assignedIds.isEmpty) {
                                  assignedList = Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('لم يتم تعيين طلاب لهذا الواجب بعد.', style: TextStyle(color: Colors.grey)),
                                  );
                                } else {
                                  assignedList = Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: assignedIds.asMap().entries.map((entry) {
                                      final i = entry.key;
                                      final id = entry.value;
                                      final name = i < assignedNames.length ? assignedNames[i] : 'طالب';
                                      final completed = completedIds.contains(id);
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(name),
                                        trailing: completed
                                            ? const Icon(Icons.check_circle, color: Colors.green)
                                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                                      );
                                    }).toList(),
                                  );
                                }

                                // Detailed results (students who completed)
                                Widget resultsWidget;
                                if (assignmentResults.isEmpty) {
                                  resultsWidget = Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'لم يكمل أي طالب هذا الواجب بعد.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  );
                                } else {
                                  resultsWidget = Column(
                                    children: assignmentResults.map((result) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: result.percentage >= 70
                                            ? Colors.green.shade50
                                            : result.percentage >= 50
                                                ? Colors.yellow.shade50
                                                : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: result.percentage >= 70
                                              ? Colors.green.shade200
                                              : result.percentage >= 50
                                                  ? Colors.yellow.shade200
                                                  : Colors.red.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                result.studentName,
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                '${result.score}/${result.totalQuestions} (${result.percentage.toStringAsFixed(1)}%)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: result.percentage >= 70
                                                      ? Colors.green.shade700
                                                      : result.percentage >= 50
                                                          ? Colors.orange.shade700
                                                          : Colors.red.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'أُكمل في: ${result.completedAt.toString().substring(0, 16)}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    )).toList(),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('الطلاب المعينون:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    assignedList,
                                    const SizedBox(height: 12),
                                    const Text('تفاصيل النتائج:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    resultsWidget,
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _showDetailedResults(assignment, []),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('عرض التفاصيل'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _toggleAssignmentStatus(assignment),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(
                                        color: assignment.isActive ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    child: Text(
                                      assignment.isActive ? 'إلغاء التفعيل' : 'تفعيل',
                                      style: TextStyle(
                                        color: assignment.isActive ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showDetailedResults(CustomAssignment assignment, List<CustomQuizResult> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('النتائج الخاصة بـ: ${assignment.title}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('الأسئلة:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...assignment.questions.map((question) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${assignment.questions.indexOf(question) + 1}. ${question.question} (الإجابة: ${question.correctAnswer})',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
              const SizedBox(height: 16),
              const Text('أداء الطلاب:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...results.map((result) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...result.questionResults.map((qResult) => Text(
                      'س${result.questionResults.indexOf(qResult) + 1}: ${qResult.userAnswer} (${qResult.isCorrect ? '✓' : '✗'})',
                      style: TextStyle(
                        fontSize: 12,
                        color: qResult.isCorrect ? Colors.green : Colors.red,
                      ),
                    )),
                  ],
                ),
              )),
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

  void _toggleAssignmentStatus(CustomAssignment assignment) async {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.updateAssignmentStatus(assignment.id, !assignment.isActive);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم ${!assignment.isActive ? 'تفعيل' : 'إلغاء تفعيل'} الواجب بنجاح!',
        ),
      ),
    );
  }
}
