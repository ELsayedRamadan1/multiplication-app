import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../theme_provider.dart';
import '../services/user_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/excel_export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _isDisposed = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  Future<void> _handleLogout() async {
    if (!mounted) return;
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('تسجيل خروج', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );

    if (shouldLogout == true) {
      try {
        // Clear user session
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userToken');
        
        // Navigate to login screen and remove all previous routes
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج')),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool get _mounted => !_isDisposed;

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          bool success = await userProvider.updateUserAvatar(image.path);
          
          if (success) {
            setState(() {
              _pickedImage = image;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث الصورة بنجاح')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('حدث خطأ أثناء تحديث الصورة')),
              );
            }
          }
        } catch (e) {
          print('Error updating avatar: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ غير متوقع')),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء اختيار الصورة: $e')),
      );
    }
  }

  Future<void> _exportStudents() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.isTeacher) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الميزة متاحة فقط للمعلمين')),
      );
      return;
    }

    setState(() => _isLoading = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // جلب الطلاب حسب إعدادات المعلم (افتراضيًا جميع الطلاب)
      List<User> students = await userProvider.getAllStudents(
        grade: userProvider.teacherDefaultGrade,
        classNumber: userProvider.teacherDefaultClassNumber,
      );

      if (students.isEmpty) {
        Navigator.of(context).pop();
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد طلاب لتصديرهم')),
        );
        return;
      }

      ExcelExportService excelService = ExcelExportService();
      String? filePath = await excelService.exportStudentsToExcel(students);

      Navigator.of(context).pop();

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ الملف بنجاح: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التصدير: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (currentUser == null) {
      return const Center(child: Text('الرجاء تسجيل الدخول'));
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'الإعدادات '),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: themeProvider.themeMode == ThemeMode.dark
                      ? [Colors.grey.shade900, Colors.black]
                      : [Colors.purple.shade50, Colors.white],
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User Profile Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.purple.shade100,
                                backgroundImage: _pickedImage != null
                                    ? FileImage(File(_pickedImage!.path))
                                    : (currentUser.avatarPath != null && 
                                       currentUser.avatarPath!.isNotEmpty
                                        ? FileImage(File(currentUser.avatarPath!))
                                        : null),
                                child: _pickedImage == null && 
                                      (currentUser.avatarPath == null || 
                                       currentUser.avatarPath!.isEmpty)
                                    ? Text(
                                        currentUser.name.isNotEmpty
                                            ? currentUser.name[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          color: Colors.blue,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: themeProvider.themeMode == ThemeMode.dark 
                                          ? Colors.grey.shade800 
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                    onPressed: _pickImage,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentUser.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: currentUser.role == UserRole.teacher 
                                      ? Colors.blue.shade100 
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentUser.role == UserRole.teacher ? 'معلم' : 'طالب',
                                  style: TextStyle(
                                    color: currentUser.role == UserRole.teacher 
                                        ? Colors.blue.shade800 
                                        : Colors.green.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentUser.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (currentUser.school.isNotEmpty) ...[
                            _buildInfoRow('المدرسة', currentUser.school),
                            const SizedBox(height: 4),
                          ],
                          if (currentUser.grade > 0) ...[
                            _buildInfoRow('الصف', 'الصف ${currentUser.grade}'),
                            const SizedBox(height: 4),
                          ],
                          if (currentUser.classNumber > 0) ...[
                            _buildInfoRow('الفصل', 'الفصل ${currentUser.classNumber}'),
                            const SizedBox(height: 4),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Theme Toggle Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        themeProvider.themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.amber
                            : Colors.blue,
                      ),
                      title: Text(
                        'الوضع الليلي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      trailing: Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (bool value) {
                          themeProvider.toggleTheme();
                        },
                        activeColor: Colors.blue,
                        activeTrackColor: Colors.blue.shade200,
                      ),
                    ),
                  ),
                  
                  // Logout Button

                  // Export students for teachers
                  if (currentUser.role == UserRole.teacher) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.file_upload),
                        label: const Text('تصدير بيانات الطلاب (Excel)'),
                        onPressed: _exportStudents,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 137),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),


                ],
              ),
            ),
    );
  }
}
