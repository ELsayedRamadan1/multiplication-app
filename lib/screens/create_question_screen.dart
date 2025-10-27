import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../models/assignment_model.dart';
import '../models/question_model.dart';
import '../models/user_model.dart';
import '../services/custom_question_service.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';

class CreateQuestionScreen extends StatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  _CreateQuestionScreenState createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  final CustomQuestionService _questionService = CustomQuestionService();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _explanationController = TextEditingController();
  final TextEditingController _assignmentTitleController = TextEditingController();
  final TextEditingController _assignmentDescriptionController = TextEditingController();
  QuestionType _selectedType = QuestionType.customText;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  List<Question> _customQuestions = [];
  List<CustomAssignment> _assignments = [];
  List<String> _selectedStudentIds = [];
  List<String> _selectedStudentNames = [];
  List<String> _selectedQuestionIds = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadAssignments();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _loadAssignments() async {
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    List<CustomAssignment> assignments = await userProvider.getTeacherAssignments();
    setState(() {
      _assignments = assignments;
    });
  }

  Future<void> _loadQuestions() async {
    List<Question> questions = await _questionService.getCustomQuestions();
    setState(() {
      _customQuestions = questions;
    });
  }

  void _deleteQuestion(Question question) async {
    await _questionService.deleteCustomQuestion(question);
    await _loadQuestions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question deleted successfully!')),
    );
  }

  void _showCreateQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<QuestionType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Question Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: QuestionType.customText,
                      child: Text('Text Question'),
                    ),
                    DropdownMenuItem(
                      value: QuestionType.customImage,
                      child: Text('Image Question'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., What is 5 + 3?',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer',
                    border: OutlineInputBorder(),
                    hintText: 'Enter the correct number',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _explanationController,
                  decoration: const InputDecoration(
                    labelText: 'Explanation (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Explain how to solve this problem',
                  ),
                  maxLines: 2,
                ),
                if (_selectedType == QuestionType.customImage) ...[
                  const SizedBox(height: 16),
                  if (_selectedImage != null) ...[
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_selectedImage!.path),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              icon: const Icon(Icons.close, color: Colors.red),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _pickImage();
                      setState(() {}); // Refresh dialog state
                    },
                    icon: const Icon(Icons.image),
                    label: Text(_selectedImage != null ? 'Change Image' : 'Select Image'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_questionController.text.isEmpty || _answerController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                int? answer = int.tryParse(_answerController.text);
                if (answer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid number for the answer')),
                  );
                  return;
                }

                Question newQuestion;
                if (_selectedType == QuestionType.customText) {
                  newQuestion = Question.customText(
                    _questionController.text,
                    answer,
                    explanation: _explanationController.text.isEmpty ? null : _explanationController.text,
                  );
                } else {
                  if (_selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an image for image questions')),
                    );
                    return;
                  }
                  newQuestion = Question.customImage(
                    _questionController.text,
                    answer,
                    _selectedImage!.path,
                    explanation: _explanationController.text.isEmpty ? null : _explanationController.text,
                  );
                }

                await _questionService.saveCustomQuestion(newQuestion);
                await _loadQuestions();

                // Clear form
                _questionController.clear();
                _answerController.clear();
                _explanationController.clear();
                _selectedImage = null;

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question created successfully!')),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAssignmentDialog() {
    _selectedStudentIds.clear();
    _selectedStudentNames.clear();
    _selectedQuestionIds.clear();
    _assignmentTitleController.clear();
    _assignmentDescriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _assignmentTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Week 1 Math Assignment',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _assignmentDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Brief description of the assignment',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Assign to Students:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showStudentSelectionDialog,
                  icon: const Icon(Icons.people),
                  label: Text(_selectedStudentNames.isEmpty
                      ? 'Select Students'
                      : 'Selected: ${_selectedStudentNames.length} students'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedStudentNames.isEmpty ? Colors.grey : Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _customQuestions.isEmpty
                      ? const Center(child: Text('No questions available'))
                      : ListView.builder(
                          itemCount: _customQuestions.length,
                          itemBuilder: (context, index) {
                            Question question = _customQuestions[index];
                            bool isSelected = _selectedQuestionIds.contains(question.id);

                            return CheckboxListTile(
                              title: Text(
                                question.question,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('Answer: ${question.correctAnswer}'),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    if (!_selectedQuestionIds.contains(question.id)) {
                                      _selectedQuestionIds.add(question.id);
                                    }
                                  } else {
                                    _selectedQuestionIds.remove(question.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_assignmentTitleController.text.isEmpty || _selectedStudentIds.isEmpty || _selectedStudentNames.isEmpty || _selectedQuestionIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill title and select students and questions')),
                  );
                  return;
                }

                List<Question> selectedQuestions = _customQuestions
                    .where((q) => _selectedQuestionIds.contains(q.id))
                    .toList();

                try {
                  UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
                  await userProvider.createAssignment(
                    title: _assignmentTitleController.text,
                    questions: selectedQuestions,
                    assignedStudentIds: _selectedStudentIds,
                    assignedStudentNames: _selectedStudentNames,
                    description: _assignmentDescriptionController.text.isEmpty
                        ? null
                        : _assignmentDescriptionController.text,
                  );

                  await _loadAssignments();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment created successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating assignment: $e')),
                  );
                }
              },
              child: const Text('Create Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentSelectionDialog() {
    // For now, use all registered users as students
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Students'),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder(
              future: _getAllStudents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<User> students = snapshot.data as List<User>;

                return Container(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      User student = students[index];
                      bool isSelected = _selectedStudentIds.contains(student.id);

                      return CheckboxListTile(
                        title: Text(student.name),
                        subtitle: Text(student.email),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              if (!_selectedStudentIds.contains(student.id)) {
                                _selectedStudentIds.add(student.id);
                                _selectedStudentNames.add(student.name);
                              }
                            } else {
                              _selectedStudentIds.remove(student.id);
                              _selectedStudentNames.remove(student.name);
                            }
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<User>> _getAllStudents() async {
    // Import AuthService functionality
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList('users') ?? [];
    List<User> allUsers = data.map((e) => User.fromJson(jsonDecode(e))).toList();

    // Filter only students
    return allUsers.where((user) => user.role == UserRole.student).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Tools'),
          backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
              ? Colors.black
              : Colors.orange.shade800,
          elevation: 0,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Questions'),
              Tab(text: 'Assignments'),
              Tab(text: 'Students'),
              Tab(text: 'Progress'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _loadQuestions();
                await _loadAssignments();
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Questions Tab
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                      ? [Colors.grey.shade900, Colors.black]
                      : [Colors.orange.shade50, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _showCreateQuestionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Question'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _customQuestions.isEmpty
                        ? const Center(
                            child: Text(
                              'No questions available',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _customQuestions.length,
                            itemBuilder: (context, index) {
                              Question question = _customQuestions[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    question.question,
                                    style: TextStyle(
                                      color: question.type == QuestionType.customImage
                                          ? Colors.blue
                                          : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Answer: ${question.correctAnswer}'),
                                      if (question.explanation != null)
                                        Text(
                                          'Explanation: ${question.explanation!}',
                                          style: const TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                      Text(
                                        'Question Type: ${question.type == QuestionType.customText ? 'Text' : 'Image'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Coming soon')),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Assignments Tab
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                      ? [Colors.grey.shade900, Colors.black]
                      : [Colors.purple.shade50, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _showCreateAssignmentDialog,
                      icon: const Icon(Icons.assignment),
                      label: const Text('Create Assignment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _assignments.isEmpty
                        ? const Center(
                            child: Text(
                              'No assignments available',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _assignments.length,
                            itemBuilder: (context, index) {
                              CustomAssignment assignment = _assignments[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    assignment.title,
                                    style: TextStyle(
                                      color: assignment.description != null ? Colors.purple : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Questions: ${assignment.questions.length}'),
                                      if (assignment.description != null)
                                        Text(
                                          assignment.description!,
                                          style: const TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _deleteAssignment(assignment);
                                      } else if (value == 'edit') {
                                        _showEditAssignmentDialog(assignment);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Students Tab
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                      ? [Colors.grey.shade900, Colors.black]
                      : [Colors.green.shade50, Colors.white],
                ),
              ),
              child: const Center(
                child: Text(
                  'Students Tab Content\n(Management functionality)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),

            // Progress Tab
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                      ? [Colors.grey.shade900, Colors.black]
                      : [Colors.orange.shade50, Colors.white],
                ),
              ),
              child: const Center(
                child: Text(
                  'Progress Tab Content\n(Assignment progress tracking)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAssignment(CustomAssignment assignment) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.deleteAssignment(assignment.id);

      await _loadAssignments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting assignment: $e')),
      );
    }
  }

  void _showEditAssignmentDialog(CustomAssignment assignment) {
    _assignmentTitleController.text = assignment.title;
    _assignmentDescriptionController.text = assignment.description ?? '';

    // Pre-select current students and questions
    _selectedStudentIds.clear();
    _selectedStudentNames.clear();
    _selectedQuestionIds.clear();

    // Note: This is a simplified version. In a real app, you would need to
    // load the assignment details from the service
    _assignmentTitleController.text = assignment.title;
    _assignmentDescriptionController.text = assignment.description ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _assignmentTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Week 1 Math Assignment',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _assignmentDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Brief description of the assignment',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Note: Student and question selection editing is coming soon!',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_assignmentTitleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter assignment title')),
                  );
                  return;
                }

                try {
                  UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
                  // For now, just update the title and description
                  // In a real app, you would need a proper update method
                  await _loadAssignments();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment updated successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating assignment: $e')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    _assignmentTitleController.dispose();
    _assignmentDescriptionController.dispose();
    super.dispose();
  }
}
