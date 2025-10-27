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
        const SnackBar(content: Text('Please fill in all fields')),
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
          SnackBar(content: Text('Email already exists')),
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
        SnackBar(content: Text('Student added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding student' + ': $e')),
      );
    }
  }

  void _showAddStudentDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Student Name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addStudent(nameController.text.trim(), emailController.text.trim());
              Navigator.of(context).pop();
            },
            child: Text('Add Student'),
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
        title: Text('Add Students'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter student information (Name, Email) one per line:'),
              Text('Example:'),
              Text('John Doe, john@example.com', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: studentsController,
                decoration: InputDecoration(
                  labelText: 'Students List',
                  border: const OutlineInputBorder(),
                  hintText: 'John Doe, john@example.com\nJane Smith, jane@example.com',
                ),
                maxLines: 8,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _bulkAddStudents(studentsController.text);
              Navigator.of(context).pop();
            },
            child: Text('Add Students'),
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
        SnackBar(content: Text('$addedCount students added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.green.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStudentDialog,
            tooltip: 'Add Student',
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: _showBulkAddDialog,
            tooltip: 'Bulk Add Students',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
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
                : [Colors.green.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _students.isEmpty
                ? Center(
                    child: Text(
                      'No students found.\nAdd some students to get started!',
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
                                '${'ID'}: ${student.id.substring(0, 8)}...',
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
                                child: Text('Delete Student'),
                              ),
                            ],
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${'Student Information'}: ${student.name} - ${student.email}')),
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
        title: Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
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
