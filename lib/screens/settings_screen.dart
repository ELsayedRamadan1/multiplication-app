import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../services/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'ar'; // Default to Arabic
  bool _isLoading = false;
  bool _isDisposed = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool get _mounted => !_isDisposed;

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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (currentUser == null) {
      return const Center(child: Text('الرجاء تسجيل الدخول'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: themeProvider.themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.purple.shade800,
        elevation: 0,
      ),
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
                                radius: 100,
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
                                          color: Colors.purple,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
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
                          Text(
                            currentUser.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            currentUser.email,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
