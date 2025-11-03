import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/assignment_model.dart';
import '../models/notification_model.dart';
import '../models/question_model.dart';
import '../services/assignment_service.dart';
import '../services/notification_service.dart';
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

  final AssignmentService _assignmentService = AssignmentService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      
      if (currentUser != null) {
        final assignments = await _assignmentService.getActiveAssignmentsForStudent(currentUser.id);
        final notifications = await _notificationService.getNotificationsForUser(currentUser.id);
        
        if (mounted) {
          setState(() {
            _assignments = assignments;
            _notifications = notifications;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في تحميل البيانات: $e')),
        );
      }
    }
  }

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
      appBar: AppBar(
        title: const Text('الواجبات المطلوبة'),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.black : Colors.blue.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignments.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد واجبات حالياً',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _assignments.length,
                    itemBuilder: (context, index) {
                      final assignment = _assignments[index];
                      final hasNewNotification = _notifications.any(
                        (n) => n.assignmentId == assignment.id && !n.isRead,
                      );
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        elevation: 2,
                        child: ListTile(
                          title: Row(
                            children: [
                              if (hasNewNotification)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  assignment.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (assignment.description != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                                  child: Text(
                                    assignment.description!,
                                    style: TextStyle(
                                      color: isDarkMode 
                                          ? Colors.grey[400] 
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ),
                              if (assignment.dueDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'تاريخ التسليم: ${assignment.dueDate!.toLocal().toString().split(' ')[0]}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'المعلم: ${assignment.teacherName}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _handleStartAssignment(assignment),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode 
                                  ? Colors.blue[700] 
                                  : Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('بدء الحل'),
                          ),
                          onTap: () => _handleStartAssignment(assignment),
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
              Text('الوصف: ${assignment.description!}'),
            Text('الاسئلة: ${assignment.questions.length}'),
            Text('المعلم: ${assignment.teacherName}'),
            Text('تاريخ الاسنحقاق : ${assignment.dueDate ?? 'No due date'}'),
            const SizedBox(height: 16),
            Text('معاينة السؤال', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Text('... و ${assignment.questions.length - 3} اسئلة اكثر'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('اغلق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startAssignment(assignment);
            },
            child: Text('ابدا الواجب'),
          ),
        ],
      ),
    );
  }

  void _startAssignment(CustomAssignment assignment) {
    _handleStartAssignment(assignment);
  }
}
