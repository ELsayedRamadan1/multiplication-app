import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_provider.dart';
import '../services/excel_export_service.dart';
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

  Future<void> _addStudent(String name, String email, String school, int grade, int classNumber) async {
    if (name.isEmpty || email.isEmpty || school.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء ملء جميع الحقول المطلوبة')),
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
        school: school,
        grade: grade,
        classNumber: classNumber,
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
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController schoolController = TextEditingController();
    int? selectedGrade;
    int? selectedClass;

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('إضافة طالب جديد'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name Field
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الثلاثي',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الاسم الثلاثي';
                        }
                        final parts = value.trim().split(' ');
                        if (parts.length < 3) {
                          return 'الرجاء إدخال الاسم الثلاثي كاملاً';
                        }
                        return null;
                      },
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'الرجاء إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 16),

                    // School Field
                    TextFormField(
                      controller: schoolController,
                      decoration: const InputDecoration(
                        labelText: 'اسم المدرسة',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال اسم المدرسة';
                        }
                        return null;
                      },
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),

                    // Grade Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedGrade,
                      decoration: const InputDecoration(
                        labelText: 'الصف الدراسي',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(6, (index) => index + 1).map((grade) {
                        return DropdownMenuItem<int>(
                          value: grade,
                          child: Text('الصف $grade', textDirection: TextDirection.rtl),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedGrade = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'الرجاء اختيار الصف الدراسي';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Class Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'الفصل',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(10, (index) => index + 1).map((classNum) {
                        return DropdownMenuItem<int>(
                          value: classNum,
                          child: Text('الفصل $classNum', textDirection: TextDirection.rtl),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedClass = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'الرجاء اختيار الفصل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && selectedGrade != null && selectedClass != null) {
                    _addStudent(
                      nameController.text,
                      emailController.text,
                      schoolController.text,
                      selectedGrade!,
                      selectedClass!,
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('الرجاء إكمال جميع الحقول المطلوبة'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        )
    );
  }

  void _showBulkAddDialog() {
    TextEditingController studentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة طلاب بشكل جماعي'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('أدخل بيانات الطلاب (اسم الطالب، البريد الإلكتروني، المدرسة، الصف، الفصل)'),
              const SizedBox(height: 8),
              TextField(
                controller: studentsController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'مثال:\nمحمد أحمد علي, mohamed@example.com, مدرسة النجاح, 3, 2\nسارة خالد, sara@example.com, مدرسة الأمل, 4, 1',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _bulkAddStudents(studentsController.text);
              Navigator.pop(context);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkAddStudents(String text) async {
    List<String> lines = text.split('\n');
    int added = 0;
    int failed = 0;

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      List<String> parts = line.split(',');
      if (parts.length < 5) {
        failed++;
        continue;
      }

      String name = parts[0].trim();
      String email = parts[1].trim();
      String school = parts[2].trim();
      int? grade = int.tryParse(parts[3].trim());
      int? classNum = int.tryParse(parts[4].trim());

      if (name.isEmpty || email.isEmpty || school.isEmpty || grade == null || classNum == null) {
        failed++;
        continue;
      }

      try {
        await _addStudent(name, email, school, grade, classNum);
        added++;
      } catch (e) {
        failed++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة $added طالب، فشل إضافة $failed'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _exportToExcel() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد طلاب لتصديرهم')),
      );
      return;
    }

    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      ExcelExportService excelService = ExcelExportService();
      String? filePath = await excelService.exportStudentsToExcel(_students);

      Navigator.of(context).pop(); // إخفاء مؤشر التحميل

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الملف بنجاح!\n$filePath'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'موافق',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // إخفاء مؤشر التحميل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء التصدير: $e')),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلاب'),
        backgroundColor: isDarkMode
            ? ThemeData.dark().scaffoldBackgroundColor
            : Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
            tooltip: 'تصدير كملف Excel',
          ),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        color: Theme.of(context).colorScheme.background,
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Header with Avatar and Basic Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          child: Text(
                            student.name.split(' ').map((e) => e[0]).take(2).join('').toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Student Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              student.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Email
                            Row(
                              children: [
                                Icon(
                                  Icons.email, 
                                  size: 16, 
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    student.email,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // School
                            _buildInfoRow(Icons.school, 'المدرسة', student.school),
                            const SizedBox(height: 8),
                            // Grade and Class
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(
                                    Icons.grade, 
                                    'الصف', 
                                    student.grade.toString()
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoRow(
                                    Icons.class_, 
                                    'الفصل', 
                                    student.classNumber.toString()
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Student ID
                            _buildInfoRow(
                              Icons.credit_card,
                              'الرقم التعريفي',
                              student.id.substring(0, 8) + '...',
                            ),
                          ],
                        ),
                      ),
                      // More Options Button
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteStudent(student);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                const Text('حذف الطالب', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert, 
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  // Details Section
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Grade and Class
                        Row(
                          children: [
                            _buildInfoRow(Icons.class_, 'الصف', '${student.grade}'),
                            const SizedBox(width: 16),
                            _buildInfoRow(Icons.meeting_room, 'الفصل', '${student.classNumber}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Student ID
                        Row(
                          children: [
                            _buildInfoRow(Icons.credit_card, 'الرقم التعريفي', student.id.length > 8 ? student.id.substring(0, 8) + '...' : student.id),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ));
          },
      ),
    ));
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
