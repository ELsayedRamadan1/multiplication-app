import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_data_model.dart' show StudentData, StudentAnswer;
import '../services/student_service.dart';
import '../theme_provider.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<StudentData> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    StudentService service = StudentService();
    List<StudentData> students = await service.getStudents();
    setState(() {
      _students = students;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المعلم'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.blue.shade800,
        elevation: 0,
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
        child: _students.isEmpty
            ? const Center(child: Text('لا توجد بيانات طلاب بعد'))
            : ListView.builder(
          itemCount: _students.length,
          itemBuilder: (context, index) {
            StudentData student = _students[index];
            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text('الاسم: ${student.name}'),
                subtitle: Text('النتيجة: ${student.score}/${student.totalQuestions}'),
                trailing: Text('${student.answers.length} إجابات'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('إجابات ${student.name}'),
                      content: Container(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: student.answers.length,
                          itemBuilder: (context, index) {
                            StudentAnswer answer = student.answers[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${answer.question} = ${answer.answer}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: answer.isCorrect
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(
                                    answer.isCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: answer.isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                    size: 24,
                                  ),
                                ],
                              ),
                            );
                          },
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
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
