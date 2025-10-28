import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  _StudentManagementScreenState createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<User> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList('users') ?? [];
    List<User> allUsers = data.map((e) => User.fromJson(jsonDecode(e))).toList();

    // Filter only students
    setState(() {
      _students = allUsers.where((user) => user.role == UserRole.student).toList();
      _isLoading = false;
    });
  }

  Future<void> _addStudent(String name, String email) async {
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرجاء ملء جميع الحقول')),
      );
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> data = prefs.getStringList('users') ?? [];
      List<User> allUsers = data.map((e) => User.fromJson(jsonDecode(e))).toList();

      // Check if student already exists
      bool exists = allUsers.any((user) => user.email == email);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('البريد الإلكتروني مستخدم مسبقًا')),
        );
        return;
      }

      // Create new student
      User newStudent = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        role: UserRole.student,
      );

      allUsers.add(newStudent);
      List<String> updatedData = allUsers.map((user) => jsonEncode(user.toJson())).toList();
      await prefs.setStringList('users', updatedData);

      await _loadStudents();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة الطالب بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إضافة الطالب' + ': $e')),
      );
    }
  }

  void _showAddStudentDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة طالب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'اسم الطالب',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _addStudent(nameController.text.trim(), emailController.text.trim());
              Navigator.of(context).pop();
            },
            child: Text('إضافة طالب'),
          ),
        ],
      ),
    );
  }

  void _showBulkAddDialog() {
    TextEditingController studentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة طلاب'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('أدخل معلومات الطلاب (الاسم، البريد الإلكتروني) سطرًا لكل طالب:'),
              Text('مثال:'),
              Text('أحمد محمد, ahmed@example.com', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: studentsController,
                decoration: InputDecoration(
                  labelText: 'قائمة الطلاب',
                  border: const OutlineInputBorder(),
                  hintText: 'أحمد محمد, ahmed@example.com\nسارة علي, sara@example.com',
                ),
                maxLines: 8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _bulkAddStudents(studentsController.text);
              Navigator.of(context).pop();
            },
            child: Text('إضافة الطلاب'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkAddStudents(String studentsText) async {
    List<String> lines = studentsText.trim().split('\n');
    int addedCount = 0;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      List<String> parts = line.split(',').map((e) => e.trim()).toList();
      if (parts.length >= 2) {
        String name = parts[0];
        String email = parts[1];

        await _addStudent(name, email);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      await _loadStudents();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إضافة $addedCount طالب بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلاب'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.green.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStudentDialog,
            tooltip: 'إضافة طالب',
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: _showBulkAddDialog,
            tooltip: 'إضافة طلاب متعددين',
          ),
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
                : [Colors.green.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _students.isEmpty
                ? Center(
                    child: Text(
                      'لا يوجد طلاب مسجلين.\nقم بإضافة طلاب للبدء!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      User student = _students[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade600,
                            child: Text(
                              student.name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.email),
                              Text(
                                'الرقم التعريفي: ${student.id.substring(0, 8)}...',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteStudent(student);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف الطالب'),
                              ),
                            ],
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تفاصيل الطالب: ${student.name} - ${student.email}')),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _deleteStudent(User student) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف الطالب'),
        content: Text('هل أنت متأكد من حذف الطالب ${student.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> data = prefs.getStringList('users') ?? [];
        List<User> allUsers = data.map((e) => User.fromJson(jsonDecode(e))).toList();

        allUsers.removeWhere((user) => user.id == student.id);
        List<String> updatedData = allUsers.map((user) => jsonEncode(user.toJson())).toList();
        await prefs.setStringList('users', updatedData);

        await _loadStudents();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting student' + ': $e')),
        );
      }
    }
  }
}
