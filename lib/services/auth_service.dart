import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  // Get all registered users
  Future<List<User>> getAllUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList(_usersKey) ?? [];
    return data.map((e) => User.fromJson(jsonDecode(e))).toList();
  }

  // Register a new user
  Future<User> registerUser({
    required String name,
    required String email,
    required UserRole role,
    String? avatarPath,
  }) async {
    // Check if user already exists
    List<User> existingUsers = await getAllUsers();
    bool userExists = existingUsers.any((user) => user.email == email);

    if (userExists) {
      throw Exception('User with this email already exists');
    }

    // Create new user
    User newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
      avatarPath: avatarPath,
    );

    // Save user
    await _saveUser(newUser);
    return newUser;
  }

  // Login user
  Future<User?> loginUser(String email) async {
    List<User> users = await getAllUsers();
    User? user = users.firstWhere((user) => user.email == email);

    // Set as current user
    await _setCurrentUser(user);
    return user;
  }

  // Logout current user
  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Get current logged in user
  Future<User?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString(_currentUserKey);

    if (userData != null) {
      Map<String, dynamic> userJson = jsonDecode(userData);
      return User.fromJson(userJson);
    }

    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    User? currentUser = await getCurrentUser();
    return currentUser != null;
  }

  // Update user data
  Future<void> updateUser(User updatedUser) async {
    List<User> users = await getAllUsers();
    int userIndex = users.indexWhere((user) => user.id == updatedUser.id);

    if (userIndex != -1) {
      users[userIndex] = updatedUser;
      await _saveAllUsers(users);

      // Always update current user if it exists and matches the updated user
      await _setCurrentUser(updatedUser);
    }
  }

  // Delete user account
  Future<void> deleteUser(String userId) async {
    List<User> users = await getAllUsers();
    users.removeWhere((user) => user.id == userId);
    await _saveAllUsers(users);

    // Logout if current user is deleted
    User? currentUser = await getCurrentUser();
    if (currentUser?.id == userId) {
      await logoutUser();
    }
  }

  // Private helper methods
  Future<void> _saveUser(User user) async {
    List<User> users = await getAllUsers();
    users.add(user);
    await _saveAllUsers(users);
  }

  Future<void> _saveAllUsers(List<User> users) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList(_usersKey, data);
  }

  Future<void> _setCurrentUser(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
  }

  // Update user's avatar
  Future<void> updateUserAvatar(String userId, String avatarPath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<User> users = await getAllUsers();
    
    // Find and update the user
    int userIndex = users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      User updatedUser = users[userIndex];
      users[userIndex] = User(
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        role: updatedUser.role,
        avatarPath: avatarPath,
        createdAt: updatedUser.createdAt,
        totalScore: updatedUser.totalScore,
        totalQuizzesCompleted: updatedUser.totalQuizzesCompleted,
        subjectScores: updatedUser.subjectScores,
      );
      
      // Save updated users list
      await _saveAllUsers(users);
      
      // Update current user if it's the same user
      String? currentUserJson = prefs.getString(_currentUserKey);
      if (currentUserJson != null) {
        Map<String, dynamic> currentUserData = jsonDecode(currentUserJson);
        if (currentUserData['id'] == userId) {
          currentUserData['avatarPath'] = avatarPath;
          await prefs.setString(_currentUserKey, jsonEncode(currentUserData));
        }
      }
    }
  }
}
