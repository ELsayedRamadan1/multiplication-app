import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assignment_model.dart';
import '../models/question_model.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';
import 'custom_quiz_screen.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  _StudentAssignmentsScreenState createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  List<CustomAssignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    List<CustomAssignment> assignments = await userProvider.getActiveStudentAssignments();
    setState(() {
      _assignments = assignments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Assignments'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.blue.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignments,
            tooltip: 'Refresh',
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
        child: _assignments.isEmpty
            ? Center(
                child: Text(
                  'No assignments available.\nCheck back later!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: _assignments.length,
                itemBuilder: (context, index) {
                  CustomAssignment assignment = _assignments[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        assignment.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${assignment.questions.length} questions'),
                          if (assignment.description != null && assignment.description!.isNotEmpty)
                            Text(
                              assignment.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          Text(
                            'From: ${assignment.teacherName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.green),
                        onPressed: () => _startAssignment(assignment),
                        tooltip: 'Start Assignment',
                      ),
                      onTap: () => _showAssignmentDetails(assignment),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showAssignmentDetails(CustomAssignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assignment.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assignment.description != null && assignment.description!.isNotEmpty)
              Text('Description: ${assignment.description!}'),
            Text('Questions: ${assignment.questions.length}'),
            Text('Teacher: ${assignment.teacherName}'),
            Text('Due Date: ${assignment.dueDate ?? 'No due date'}'),
            const SizedBox(height: 16),
            Text('Questions Preview', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: assignment.questions.length > 3 ? 3 : assignment.questions.length,
                itemBuilder: (context, index) {
                  Question question = assignment.questions[index];
                  return Text(
                    '${index + 1}. ${question.question.length > 50 ? '${question.question.substring(0, 50)}...' : question.question}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  );
                },
              ),
            ),
            if (assignment.questions.length > 3)
              Text('... and ${assignment.questions.length - 3} more questions'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startAssignment(assignment);
            },
            child: Text('Start Assignment'),
          ),
        ],
      ),
    );
  }

  void _startAssignment(CustomAssignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomQuizScreen(
          assignment: assignment,
          studentName: Provider.of<UserProvider>(context, listen: false).currentUser?.name ?? 'Student',
        ),
      ),
    );
  }
}
