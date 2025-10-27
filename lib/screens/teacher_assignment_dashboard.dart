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
  List<CustomAssignment> _assignments = [];
  List<CustomQuizResult> _allResults = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    List<CustomAssignment> assignments = await userProvider.getTeacherAssignments();
    List<CustomQuizResult> allResults = [];

    for (var assignment in assignments) {
      List<CustomQuizResult> results = await userProvider.getAssignmentResults(assignment.id);
      allResults.addAll(results);
    }

    setState(() {
      _assignments = assignments;
      _allResults = allResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Progress'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.orange.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                : [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: _assignments.isEmpty
            ? const Center(
                child: Text(
                  'No assignments created yet.\nCreate an assignment to see student progress!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: _assignments.length,
                itemBuilder: (context, index) {
                  CustomAssignment assignment = _assignments[index];
                  List<CustomQuizResult> assignmentResults = _allResults
                      .where((result) => result.assignmentId == assignment.id)
                      .toList();

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ExpansionTile(
                      title: Text(
                        assignment.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${assignment.questions.length} questions • ${assignmentResults.length} completed',
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (assignment.description != null && assignment.description!.isNotEmpty)
                                Text(
                                  'Description: ${assignment.description!}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Status: ${assignment.isActive ? 'Active' : 'Inactive'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: assignment.isActive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Student Results:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              if (assignmentResults.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'No students have completed this assignment yet.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                ...assignmentResults.map((result) => Container(
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
                                        'Completed: ${result.completedAt.toString().substring(0, 16)}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                )),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _showDetailedResults(assignment, assignmentResults),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text('View Details'),
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
                                        assignment.isActive ? 'Deactivate' : 'Activate',
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
              ),
      ),
    );
  }

  void _showDetailedResults(CustomAssignment assignment, List<CustomQuizResult> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Results for: ${assignment.title}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...assignment.questions.map((question) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${assignment.questions.indexOf(question) + 1}. ${question.question} (Answer: ${question.correctAnswer})',
                  style: const TextStyle(fontSize: 12),
                ),
              )),
              const SizedBox(height: 16),
              const Text('Student Performance:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      'Q${result.questionResults.indexOf(qResult) + 1}: ${qResult.userAnswer} (${qResult.isCorrect ? '✓' : '✗'})',
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleAssignmentStatus(CustomAssignment assignment) async {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.updateAssignmentStatus(assignment.id, !assignment.isActive);
    await _loadData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Assignment ${!assignment.isActive ? 'activated' : 'deactivated'} successfully!',
        ),
      ),
    );
  }
}
