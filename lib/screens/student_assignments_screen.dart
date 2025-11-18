import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assignment_model.dart';
import '../utils/arabic_numbers.dart';
import 'package:intl/intl.dart';
import '../services/user_provider.dart';
import 'custom_quiz_screen.dart';
import '../widgets/custom_app_bar.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  _StudentAssignmentsScreenState createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  void _handleStartAssignment(CustomAssignment assignment) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomQuizScreen(
          assignment: assignment,
          studentName: currentUser.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'الواجبات المطلوبة',
        color: isDarkMode ? Colors.black : Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );

          return StreamBuilder<List<CustomAssignment>>(
            stream: userProvider.streamActiveStudentAssignments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final assignments = snapshot.data ?? [];

              if (assignments.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد واجبات حالياً',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        title: Text(
                          assignment.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (assignment.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 4),
                                child: Text(assignment.description!),
                              ),
                            Text('الأسئلة: ${assignment.questions.length}'),
                            Text('المعلم: ${assignment.teacherName}'),
                          ],
                        ),
                        trailing: FutureBuilder<CustomQuizResult?>(
                          future: userProvider.getAssignmentResultForStudent(
                            assignment.id,
                          ),
                          builder: (context, resultSnapshot) {
                            if (resultSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox(
                                width: 90,
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final existingResult = resultSnapshot.data;

                            // ✅ الطالب أنهى الواجب
                            if (existingResult != null) {
                              return SizedBox(
                                width: 90,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                          padding: EdgeInsets.zero,
                                          textStyle: const TextStyle(fontSize: 13),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6),
                                            child: Text('منتهي'),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '${existingResult.score}/${existingResult.totalQuestions}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // ✅ انتهت المهلة
                            final isExpired =
                                assignment.dueDate != null &&
                                    DateTime.now().isAfter(assignment.dueDate!);
                            if (isExpired) {
                              return SizedBox(
                                width: 90,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                          padding: EdgeInsets.zero,
                                          textStyle: const TextStyle(fontSize: 13),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        child: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6),
                                            child: Text('انتهت'),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          assignment.dueDate != null
                                              ? toArabicDigits(
                                            DateFormat('yyyy-MM-dd HH:mm')
                                                .format(assignment.dueDate!
                                                .toLocal()),
                                          )
                                              : '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // ✅ الواجب متاح - الزر "بدء الحل"
                            return SizedBox(
                              width: 90,
                              child: SizedBox(
                                height: 32,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _handleStartAssignment(assignment),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    padding: EdgeInsets.zero,
                                    textStyle: const TextStyle(fontSize: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding:
                                      EdgeInsets.symmetric(horizontal: 6),
                                      child: Text('بدء الحل'),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        onTap: () async {
                          final existing = await userProvider
                              .getAssignmentResultForStudent(assignment.id);
                          if (existing != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'لقد أنهيت هذا الواجب سابقًا (${existing.score}/${existing.totalQuestions})',
                                ),
                              ),
                            );
                            return;
                          }
                          if (assignment.dueDate != null &&
                              DateTime.now().isAfter(assignment.dueDate!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'انتهت مهلة هذا الواجب ولا يمكن الدخول إليه',
                                ),
                              ),
                            );
                            return;
                          }

                          _handleStartAssignment(assignment);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
