import 'package:flutter/material.dart';
import 'package:multiplication_table_app/screens/profile_screen.dart';
import 'package:multiplication_table_app/screens/student_assignments_screen.dart';
import 'package:provider/provider.dart';
import '../models/multiplication_table_model.dart';
import '../models/notification_model.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';
import 'create_question_screen.dart';
import 'custom_quiz_screen.dart';
import 'login_screen.dart';
import 'quiz_screen.dart';
import 'table_screen.dart';
import 'teacher_dashboard.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTable = 1;
  String studentName = '';
  bool isTeacher = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Welcome'),
            backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                ? Colors.black
                : (userProvider.isTeacher ? Colors.orange.shade800 : Colors.blue.shade800),
            elevation: 0,
            leading: userProvider.getUserAvatar(radius: 20),
            actions: [
              IconButton(
                icon: Icon(
                  Provider.of<ThemeProvider>(context).themeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                onPressed: () {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                tooltip: 'Settings',
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                tooltip: 'Profile',
              ),
              if (!userProvider.isTeacher) // Show notifications only for students
                Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    return FutureBuilder<List<NotificationModel>>(
                      future: provider.getUserNotifications(),
                      builder: (context, snapshot) {
                        int unreadCount = 0;
                        if (snapshot.hasData) {
                          unreadCount = snapshot.data!.where((n) => !n.isRead).length;
                        }

                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                                );
                              },
                              tooltip: 'Notifications',
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  // Show confirmation dialog
                  bool? confirmLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Logout'),
                      content: Text('Are you sure you want to delete?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirmLogout == true) {
                    await userProvider.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                tooltip: 'Logout',
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                    ? [Colors.grey.shade900, Colors.black]
                    : [userProvider.isTeacher ? Colors.orange.shade50 : Colors.blue.shade50, Colors.white],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // User Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: userProvider.isTeacher ? Colors.orange.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: userProvider.isTeacher ? Colors.orange.shade300 : Colors.blue.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              userProvider.isTeacher ? Icons.school : Icons.person,
                              size: 20,
                              color: userProvider.isTeacher ? Colors.orange.shade700 : Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userProvider.isTeacher ? 'Teacher Mode' : 'Student Mode',
                              style: TextStyle(
                                color: userProvider.isTeacher ? Colors.orange.shade700 : Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (userProvider.isTeacher) ...[
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TeacherDashboard()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('View Student Data', style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateQuestionScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Create Custom Questions', style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CustomQuizScreen(studentName: userProvider.currentUser?.name ?? '')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Use Custom Questions', style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Enhanced App Logo
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (userProvider.isTeacher ? Colors.orange : Colors.blue).withOpacity(0.2),
                              (userProvider.isTeacher ? Colors.orange : Colors.blue).withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (userProvider.isTeacher ? Colors.orange : Colors.blue).withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (userProvider.isTeacher ? Colors.orange : Colors.blue).withOpacity(0.1),
                              spreadRadius: 6,
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                (userProvider.isTeacher ? Colors.orange : Colors.blue).shade50,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calculate,
                            size: 50,
                            color: userProvider.isTeacher ? Colors.orange.shade700 : Colors.blue,
                          ),
                        ),
                      ),
                      Text(
                        userProvider.isTeacher ? 'Teacher Dashboard' : 'Multiplication Master',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: userProvider.isTeacher ? Colors.orange.shade700 : Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        userProvider.isTeacher ? 'Manage Students and Create Questions' : 'Learn • Practice • Excel',
                        style: TextStyle(
                          fontSize: 14,
                          color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      if (!userProvider.isTeacher) ...[
                        Text('Multiplication Table', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                                ? Colors.grey.shade800
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: DropdownButton<int>(
                            value: selectedTable,
                            onChanged: (int? newValue) {
                              setState(() {
                                selectedTable = newValue!;
                              });
                            },
                            items: List.generate(12, (index) => index + 1).map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text('$value', style: const TextStyle(fontSize: 16)),
                                ),
                              );
                            }).toList(),
                            underline: const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    TableScreen(table: MultiplicationTable(selectedTable)),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.list, size: 18),
                          label: Text('View Multiplication Table'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    QuizScreen(studentName: userProvider.currentUser?.name ?? 'Student'),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.quiz, size: 18),
                          label: Text('Practice Quiz'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StudentAssignmentsScreen()),
                            );
                          },
                          icon: const Icon(Icons.assignment, size: 18),
                          label: Text('My Assignments'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                ]]),
            ),
            ),
          )));
      },
    );
  }
}
