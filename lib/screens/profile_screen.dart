import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/user_provider.dart';

import '../theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isLoggedIn) {
          return const Scaffold(
            body: Center(
              child: Text('Please login to view profile'),
            ),
          );
        }

        User user = userProvider.currentUser!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Profile'),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                          ? Colors.grey.shade800
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        userProvider.getUserAvatar(radius: 40),
                        const SizedBox(height: 16),

                        // Name and Role
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.role == UserRole.teacher
                                ? Colors.orange.shade100
                                : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role == UserRole.teacher ? 'Teacher' : 'Student',
                            style: TextStyle(
                              color: user.role == UserRole.teacher
                                  ? Colors.orange.shade700
                                  : Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Total Score',
                          user.totalScore.toString(),
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Quizzes',
                          user.totalQuizzesCompleted.toString(),
                          Icons.quiz,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Subject Scores
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                          ? Colors.grey.shade800
                          : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject Performance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (user.subjectScores.isEmpty)
                          Text(
                            'No quiz results yet. Start practicing!',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          )
                        else
                          ...user.subjectScores.entries.map((entry) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key.replaceAll('_', ' ').replaceAll('custom assignment', 'Assignment').toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${entry.value} pts',
                                    style: TextStyle(
                                      color: entry.value > 5 ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                          ? Colors.grey.shade800
                          : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(context, 'Member Since', _formatDate(user.createdAt)),
                        const SizedBox(height: 8),
                        _buildInfoRow(context, 'User ID', user.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.grey.shade800
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String labelKey, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            labelKey,
            style: TextStyle(
              color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                  ? Colors.white
                  : Colors.black,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
