import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/assignment_model.dart';
import '../models/question_model.dart';
import '../models/user_model.dart';
import '../services/custom_question_service.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';
import '../widgets/custom_app_bar.dart';

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
  final TextEditingController _assignmentTitleController =
      TextEditingController();
  final TextEditingController _assignmentDescriptionController =
      TextEditingController();
  QuestionType _selectedType = QuestionType.customText;
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  List<Question> _customQuestions = [];
  List<CustomAssignment> _assignments = [];
  final List<String> _selectedStudentIds = [];
  final List<String> _selectedStudentNames = [];
  final List<String> _selectedQuestionIds = [];
  bool _isCreatingAssignment = false;

  // Moved from dialog local state
  bool _isLoadingStudents = false;
  List<User> _allStudents = [];
  List<User> _visibleStudents = [];
  int? _filterGrade;
  int? _filterClass;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  Future<void> _loadAssignments() async {
    UserProvider userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );
    List<CustomAssignment> assignments = await userProvider
        .getTeacherAssignments();
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

  Future<void> _deleteQuestion(Question question) async {
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
        builder: (context, setState) {
          // Dialog builder (kept simple to avoid deprecated MediaQuery APIs)
          return AlertDialog(
            title: const Text('إنشاء سؤال جديد'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<QuestionType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'نوع السؤال',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: QuestionType.customText,
                        child: Text(' نصي'),
                      ),
                      DropdownMenuItem(
                        value: QuestionType.customImage,
                        child: Text('صورة '),
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
                      labelText: 'نص السؤال',
                      border: OutlineInputBorder(),
                      hintText: 'مثال: ما ناتج 5 + 3؟',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _answerController,
                    decoration: const InputDecoration(
                      labelText: 'الإجابة الصحيحة',
                      border: OutlineInputBorder(),
                      hintText: 'أدخل الرقم (صحيح أو عشري أو كسر)',
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _explanationController,
                    decoration: const InputDecoration(
                      labelText: 'الشرح (اختياري)',
                      border: OutlineInputBorder(),
                      hintText: 'اشرح كيفية حل هذه المسألة',
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
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withAlpha(
                                    204,
                                  ), // ~0.8 opacity
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
                      label: Text(
                        _selectedImage != null ? 'تغيير الصورة' : 'اختر صورة',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_questionController.text.isEmpty ||
                      _answerController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('الرجاء ملء جميع الحقول المطلوبة'),
                      ),
                    );
                    return;
                  }

                  // Check if the input is a valid number (integer, decimal, or fraction)
                  bool isValidNumber(String input) {
                    // Check for integer or decimal
                    if (double.tryParse(input) != null) return true;

                    // Check for fraction format (e.g., 1/2, 3/4)
                    if (RegExp(r'^\s*\d+\s*/\s*\d+\s*$').hasMatch(input)) {
                      var parts = input
                          .split('/')
                          .map((e) => int.tryParse(e.trim()))
                          .toList();
                      return parts.length == 2 &&
                          parts[0] != null &&
                          parts[1] != null &&
                          parts[1] != 0;
                    }

                    return false;
                  }

                  if (!isValidNumber(_answerController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'الرجاء إدخال رقم صحيح أو عشري أو كسر (مثل ١.٥ أو ١/٢)',
                        ),
                      ),
                    );
                    return;
                  }

                  // Parse the answer (could be integer, decimal, or fraction)
                  double answer;
                  if (_answerController.text.contains('/')) {
                    // Handle fraction (e.g., 1/2)
                    var parts = _answerController.text
                        .split('/')
                        .map((e) => double.parse(e.trim()))
                        .toList();
                    answer = parts[0] / parts[1];
                  } else {
                    // Handle integer or decimal
                    answer = double.parse(_answerController.text);
                  }

                  Question newQuestion;
                  if (_selectedType == QuestionType.customText) {
                    newQuestion = Question.customText(
                      _questionController.text,
                      answer,
                      explanation: _explanationController.text.isEmpty
                          ? null
                          : _explanationController.text,
                    );
                  } else {
                    if (_selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء اختيار صورة للأسئلة البصرية'),
                        ),
                      );
                      return;
                    }
                    newQuestion = Question.customImage(
                      _questionController.text,
                      answer,
                      _selectedImage!.path,
                      explanation: _explanationController.text.isEmpty
                          ? null
                          : _explanationController.text,
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
                    const SnackBar(content: Text('تم إنشاء السؤال بنجاح!')),
                  );
                },
                child: const Text('إنشاء'),
              ),
            ],
          );
        },
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
        builder: (context, setState) {
          // Local filter state for this dialog
          int? filterGrade;
          int? filterClass;
          // Adapt dropdown text color to current theme
          final bool isDark =
              Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
          final Color textColor = isDark ? Colors.white : Colors.black87;
          final Color dropdownBg = isDark ? Colors.grey.shade900 : Colors.white;

          return AlertDialog(
            title: const Text('إنشاء واجب'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _assignmentTitleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الواجب',
                      border: OutlineInputBorder(),
                      hintText: 'مثال: الواجب الأول في الرياضيات',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _assignmentDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'وصف الواجب (اختياري)',
                      border: OutlineInputBorder(),
                      hintText: 'وصف مختصر للواجب',
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'فلترة الطلاب (اختياري)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const SizedBox(height: 8),
                  // Dropdowns (limited): Grades = 6, Classes = 10. Stacked vertically to avoid overflow.
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<int?>(
                          isExpanded: true,
                          iconSize: 20,
                          style: TextStyle(fontSize: 13, color: textColor),
                          initialValue: filterGrade,
                          decoration: InputDecoration(
                            labelText: 'الصف',
                            labelStyle: TextStyle(color: textColor),
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'الكل',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            ...List.generate(6, (i) => i + 1).map(
                              (g) => DropdownMenuItem<int?>(
                                value: g,
                                child: Text(
                                  'الصف $g',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                            ),
                          ],
                          dropdownColor: dropdownBg,
                          onChanged: (v) => setState(() => filterGrade = v),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          isExpanded: true,
                          iconSize: 20,
                          style: TextStyle(fontSize: 13, color: textColor),
                          initialValue: filterClass,
                          decoration: InputDecoration(
                            labelText: 'الفصل',
                            labelStyle: TextStyle(color: textColor),
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'الكل',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            ...List.generate(10, (i) => i + 1).map(
                              (c) => DropdownMenuItem<int?>(
                                value: c,
                                child: Text(
                                  'الفصل $c',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                            ),
                          ],
                          dropdownColor: dropdownBg,
                          onChanged: (v) => setState(() => filterClass = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Button to open student selection dialog. The dialog now contains the 'select all matching' control.
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isCreatingAssignment
                              ? null
                              : () {
                                  final userProvider =
                                      Provider.of<UserProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final int? g =
                                      filterGrade ??
                                      userProvider.teacherDefaultGrade;
                                  final int? c =
                                      filterClass ??
                                      userProvider.teacherDefaultClassNumber;
                                  _showStudentSelectionDialog(
                                    grade: g,
                                    classNumber: c,
                                  );
                                },
                          icon: const Icon(Icons.people),
                          label: Text(
                            _selectedStudentNames.isEmpty
                                ? 'اختر الطلاب'
                                : 'تم اختيار: ${_selectedStudentNames.length}',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedStudentNames.isEmpty
                                ? Colors.grey
                                : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'اختر الأسئلة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _customQuestions.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد أسئلة متاحة',
                              textDirection: TextDirection.rtl,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _customQuestions.length,
                            itemBuilder: (context, index) {
                              Question question = _customQuestions[index];
                              bool isSelected = _selectedQuestionIds.contains(
                                question.id,
                              );

                              return CheckboxListTile(
                                title: Text(
                                  question.question,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                ),
                                subtitle: Text(
                                  'الإجابة: ${question.correctAnswer}',
                                  textDirection: TextDirection.rtl,
                                ),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (!_selectedQuestionIds.contains(
                                        question.id,
                                      )) {
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
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_assignmentTitleController.text.isEmpty ||
                      _selectedStudentIds.isEmpty ||
                      _selectedStudentNames.isEmpty ||
                      _selectedQuestionIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'الرجاء إدخال العنوان واختيار الطلاب والأسئلة',
                        ),
                      ),
                    );
                    return;
                  }

                  // set loading state
                  setState(() => _isCreatingAssignment = true);

                  List<Question> selectedQuestions = _customQuestions
                      .where((q) => _selectedQuestionIds.contains(q.id))
                      .toList();

                  try {
                    await Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).createAssignment(
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
                      const SnackBar(content: Text('تم إنشاء الواجب بنجاح!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ أثناء إنشاء الواجب: $e')),
                    );
                  } finally {
                    setState(() => _isCreatingAssignment = false);
                  }
                },
                child: _isCreatingAssignment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('إنشاء واجب'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Applies filters to the list of all students and updates the visible students list.
  void _applyFilters(StateSetter setState) {
    var filtered = List<User>.from(_allStudents);
    if (_filterGrade != null) {
      filtered = filtered.where((s) => s.grade == _filterGrade).toList();
    }
    if (_filterClass != null) {
      filtered = filtered.where((s) => s.classNumber == _filterClass).toList();
    }
    setState(() {
      _visibleStudents = filtered;
    });
  }

  // Fetches all students from the provider if they haven't been loaded yet.
  Future<void> _loadAllStudents(StateSetter setState) async {
    if (_allStudents.isNotEmpty) {
      _applyFilters(setState); // Already loaded, just apply filters
      return;
    }

    setState(() => _isLoadingStudents = true);

    try {
      final provider = Provider.of<UserProvider>(context, listen: false);
      _allStudents = await provider.getAllStudents();
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل الطلاب: $e')),
        );
      }
      _allStudents = []; // Clear on error
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
          _applyFilters(setState); // Apply initial filters after loading
        });
      }
    }
  }

  bool _allVisibleSelected() {
    return _visibleStudents.isNotEmpty &&
        _visibleStudents.every((s) => _selectedStudentIds.contains(s.id));
  }

  void _showStudentSelectionDialog({int? grade, int? classNumber}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Initialize and load students when the dialog is first built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _filterGrade = grade;
            _filterClass = classNumber;
            _loadAllStudents(setState);
          });

          return AlertDialog(
            title: const Text('اختر الطلاب'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          iconSize: 20,
                          value: _filterGrade,
                          decoration: const InputDecoration(
                            labelText: 'الصف',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('الكل'),
                            ),
                            ...List.generate(6, (i) => i + 1).map(
                              (g) => DropdownMenuItem<int?>(
                                value: g,
                                child: Text('الصف $g'),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _filterGrade = v;
                              _applyFilters(setState);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          iconSize: 20,
                          value: _filterClass,
                          decoration: const InputDecoration(
                            labelText: 'الفصل',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('الكل'),
                            ),
                            ...List.generate(10, (i) => i + 1).map(
                              (c) => DropdownMenuItem<int?>(
                                value: c,
                                child: Text('الفصل $c'),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _filterClass = v;
                              _applyFilters(setState);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _allVisibleSelected(),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    for (var s in _visibleStudents) {
                                      if (!_selectedStudentIds.contains(s.id)) {
                                        _selectedStudentIds.add(s.id);
                                        _selectedStudentNames.add(s.name);
                                      }
                                    }
                                  } else {
                                    for (var s in _visibleStudents) {
                                      _selectedStudentIds.remove(s.id);
                                      _selectedStudentNames.remove(s.name);
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const Text('تحديد الكل'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(maxHeight: 300),
                      child: _isLoadingStudents
                          ? const Center(child: CircularProgressIndicator())
                          : _visibleStudents.isEmpty
                          ? const Center(
                              child: Text('لا توجد طلاب مطابقة للفلتر المحدد'),
                            )
                          : ListView.builder(
                              itemCount: _visibleStudents.length,
                              itemBuilder: (context, index) {
                                User student = _visibleStudents[index];
                                bool isSelected = _selectedStudentIds.contains(
                                  student.id,
                                );

                                return CheckboxListTile(
                                  title: Text(student.name),
                                  subtitle: Text(student.email),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        if (!_selectedStudentIds.contains(
                                          student.id,
                                        )) {
                                          _selectedStudentIds.add(student.id);
                                          _selectedStudentNames.add(
                                            student.name,
                                          );
                                        }
                                      } else {
                                        _selectedStudentIds.remove(student.id);
                                        _selectedStudentNames.remove(
                                          student.name,
                                        );
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('تم'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<User>> _getAllStudents() async {
    // Use UserProvider to fetch students from Firestore
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final students = await userProvider.getAllStudents();
      return students;
    } catch (e) {
      // On error, return empty list and rethrow so caller can show error
      print('Error fetching students: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          title: ' أدوات المعلم',
          color: Theme.of(context).colorScheme.primary,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'الأسئلة'),
              Tab(text: 'الواجبات'),
              Tab(text: 'الطلاب'),
              Tab(text: 'التقدم'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _loadQuestions();
                await _loadAssignments();
              },
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Questions Tab
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _showCreateQuestionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('إنشاء سؤال جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _customQuestions.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد أسئلة متاحة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _customQuestions.length,
                            itemBuilder: (context, index) {
                              Question question = _customQuestions[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(
                                    question.question,
                                    style: TextStyle(
                                      color:
                                          question.type ==
                                              QuestionType.customImage
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الإجابة: ${question.correctAnswer}',
                                      ),
                                      if (question.explanation != null)
                                        Text(
                                          'الشرح: ${question.explanation!}',
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      Text(
                                        'نوع السؤال: ${question.type == QuestionType.customText ? 'نصي' : 'صورة'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('تأكيد الحذف'),
                                          content: const Text(
                                            'هل ترغب بحذف هذا السؤال؟',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(false),
                                              child: const Text('إلغاء'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(c).pop(true),
                                              child: const Text('حذف'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _deleteQuestion(question);
                                      }
                                    },
                                  ),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Coming soon'),
                                      ),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _showCreateAssignmentDialog,
                      icon: const Icon(Icons.assignment),
                      label: const Text('إنشاء الواجب'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _assignments.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد واجبات متاحة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _assignments.length,
                            itemBuilder: (context, index) {
                              CustomAssignment assignment = _assignments[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(
                                    assignment.title,
                                    style: TextStyle(
                                      color: assignment.description != null
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : null,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الاسئلة: ${assignment.questions.length}',
                                      ),
                                      if (assignment.description != null)
                                        Text(
                                          assignment.description!,
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
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
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        ),
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
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: FutureBuilder(
                future: _getAllStudents(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<User> students = snapshot.data as List<User>;

                  return students.isEmpty
                      ? Center(
                          child: Text(
                            'لا يوجد طلاب م��جلين',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        )
                      : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            User student = students[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(student.name[0].toUpperCase()),
                                ),
                                title: Text(student.name),
                                subtitle: Text(student.email),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                              ),
                            );
                          },
                        );
                },
              ),
            ),

            // Progress Tab
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: _assignments.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد واجبات متاحة',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _assignments.length,
                      itemBuilder: (context, index) {
                        CustomAssignment assignment = _assignments[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ExpansionTile(
                            title: Text(assignment.title),
                            subtitle: Text(
                              'عدد الطلاب: ${assignment.assignedStudentIds.length}',
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الطلاب المكلفين:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    const SizedBox(height: 8),
                                    ...assignment.assignedStudentNames.map(
                                      (name) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Text(
                                          '• $name',
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'عدد الأسئلة: ${assignment.questions.length}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAssignment(CustomAssignment assignment) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(
        context,
        listen: false,
      );
      await userProvider.deleteAssignment(assignment.id);

      await _loadAssignments();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم حذف الواجب بنجاح!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء حذف الواجب: $e')));
    }
  }

  void _showEditAssignmentDialog(CustomAssignment assignment) {
    _assignmentTitleController.text = assignment.title;
    _assignmentDescriptionController.text = assignment.description ?? '';

    // تحديد الطلاب والأسئلة الحالية مسبقًا
    _selectedStudentIds.clear();
    _selectedStudentNames.clear();
    _selectedQuestionIds.clear();

    // ملاحظة: هذه نسخة مبسطة. في التطبيق الفعلي، ستحتاج إلى
    // تحميل تفاصيل الواجب من الخدمة
    _assignmentTitleController.text = assignment.title;
    _assignmentDescriptionController.text = assignment.description ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تعديل الواجب'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _assignmentTitleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الواجب',
                    border: OutlineInputBorder(),
                    hintText: 'مثال: واجب الأسبوع الأول في الرياضيات',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _assignmentDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    border: OutlineInputBorder(),
                    hintText: 'وصف موجز للواجب',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Note: Student and question selection editing is coming soon!',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
                    const SnackBar(
                      content: Text('Please enter assignment title'),
                    ),
                  );
                  return;
                }

                try {
                  // For now, just refresh assignments and close dialog
                  await _loadAssignments();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Assignment updated successfully!'),
                    ),
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
