import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/assignment_model.dart';
import '../models/question_model.dart';
import '../models/user_model.dart';
import '../services/questions_provider.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';
import 'question_editor_screen.dart';

class CreateQuestionScreen extends StatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  _CreateQuestionScreenState createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _explanationController = TextEditingController();
  final TextEditingController _assignmentTitleController =
      TextEditingController();
  final TextEditingController _assignmentDescriptionController =
      TextEditingController();
  DateTime? _assignmentDueDate; // optional due date for assignments
  List<CustomAssignment> _assignments = [];
  final List<String> _selectedStudentIds = [];
  final List<String> _selectedStudentNames = [];
  final List<String> _selectedQuestionIds = [];
  bool _isCreatingAssignment = false;
  // Dialog/local student-selection state
  bool _isLoadingStudents = false;
  List<User> _allStudents = [];
  List<User> _visibleStudents = [];
  int? _filterGrade;
  int? _filterClass;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<CustomAssignment> assignments = await userProvider
        .getTeacherAssignments();
    if (!mounted) return;
    setState(() {
      _assignments = assignments;
    });
  }

  Future<void> _deleteQuestion(Question question) async {
    await Provider.of<QuestionsProvider>(
      context,
      listen: false,
    ).deleteQuestion(question);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question deleted successfully!')),
    );
  }

  void _showCreateAssignmentDialog() {
    _selectedStudentIds.clear();
    _selectedStudentNames.clear();
    _selectedQuestionIds.clear();
    _assignmentTitleController.clear();
    _assignmentDescriptionController.clear();
    DateTime? localDueDate = _assignmentDueDate;
    bool allowDecimalDivisionLocal = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          // Local filter state for this dialog
          int? filterGrade;
          int? filterClass;

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

                  // If any selected question is a division, offer the "allow decimal results" option
                  Builder(
                    builder: (context) {
                      final selectedQuestionsPreview =
                          Provider.of<QuestionsProvider>(context, listen: false)
                              .questions
                              .where((q) => _selectedQuestionIds.contains(q.id))
                              .toList();
                      final hasDivisionSelected = selectedQuestionsPreview.any(
                        (q) => q.operation == OperationType.division,
                      );

                      if (!hasDivisionSelected) return const SizedBox.shrink();

                      return Row(
                        children: [
                          Checkbox(
                            value: allowDecimalDivisionLocal,
                            onChanged: (v) => dialogSetState(
                              () => allowDecimalDivisionLocal = v ?? false,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text('السماح بنتائج عشرية في القسمة'),
                          ),
                        ],
                      );
                    },
                  ),

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
                    child: Builder(
                      builder: (context) {
                        final qp = Provider.of<QuestionsProvider>(context);
                        if (qp.isLoading)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        final questions = qp.questions;
                        if (questions.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد أسئلة متاحة',
                              textDirection: TextDirection.rtl,
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            Question question = questions[index];
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
                                dialogSetState(() {
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Due date & time picker
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            localDueDate == null
                                ? 'اختيار تاريخ ووقت الاستحقاق (اختياري)'
                                : 'استحقاق: ${localDueDate?.toLocal().toString().split('.')[0]}',
                          ),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 7),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (pickedDate != null) {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                final combined = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                dialogSetState(() => localDueDate = combined);
                              } else {
                                dialogSetState(() => localDueDate = pickedDate);
                              }
                            }
                          },
                        ),
                      ),
                      if (localDueDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              dialogSetState(() => localDueDate = null),
                        ),
                      ],
                    ],
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
                  dialogSetState(() => _isCreatingAssignment = true);

                  List<Question> selectedQuestions =
                      Provider.of<QuestionsProvider>(context, listen: false)
                          .questions
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
                      dueDate: localDueDate,
                      allowDecimalDivision: allowDecimalDivisionLocal,
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
                    if (mounted)
                      dialogSetState(() => _isCreatingAssignment = false);
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

  // Show dialog to create a random assignment (teacher chooses operation, range, and count)
  void _showCreateRandomAssignmentDialog() {
    _selectedStudentIds.clear();
    _selectedStudentNames.clear();
    _assignmentTitleController.clear();
    _assignmentDescriptionController.clear();

    OperationType op = OperationType.multiplication;
    // Fixed range for random questions (min..max)
    const int fixedMin = 1;
    const int fixedMax = 10;
    final TextEditingController countController = TextEditingController(
      text: '5',
    );
    bool allowDecimalDivision = false;
    DateTime? randomDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            title: const Text('إنشاء واجب عشوائي'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _assignmentTitleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الواجب',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<OperationType>(
                    initialValue: op,
                    decoration: const InputDecoration(
                      labelText: 'العملية',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: OperationType.addition,
                        child: Text('+ جمع'),
                      ),
                      DropdownMenuItem(
                        value: OperationType.subtraction,
                        child: Text('- طرح'),
                      ),
                      DropdownMenuItem(
                        value: OperationType.multiplication,
                        child: Text('× ضرب'),
                      ),
                      DropdownMenuItem(
                        value: OperationType.division,
                        child: Text('÷ قسمة'),
                      ),
                    ],
                    onChanged: (v) => dialogSetState(
                      () => op = v ?? OperationType.multiplication,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: countController,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأسئلة',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  // Button to open student selection (same as in the normal assignment dialog)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Reuse the same student selection dialog
                            _showStudentSelectionDialog(
                              grade: null,
                              classNumber: null,
                            );
                          },
                          icon: const Icon(Icons.people),
                          label: Text(
                            _selectedStudentNames.isEmpty
                                ? 'اختر الطلاب'
                                : 'تم اختيار: ${_selectedStudentNames.length}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (op == OperationType.division) ...[
                    Row(
                      children: [
                        Checkbox(
                          value: allowDecimalDivision,
                          onChanged: (v) => dialogSetState(
                            () => allowDecimalDivision = v ?? false,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text('السماح بنتائج عشرية في القسمة'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Due date & time picker (date + time)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            randomDueDate == null
                                ? 'اختيار تاريخ ووقت الاستحقاق (اختياري)'
                                : 'استحقاق: ${randomDueDate?.toLocal().toString().split('.')[0]}',
                          ),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 7),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (pickedDate != null) {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                final combined = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                                dialogSetState(() => randomDueDate = combined);
                              } else {
                                dialogSetState(
                                  () => randomDueDate = pickedDate,
                                );
                              }
                            }
                          },
                        ),
                      ),
                      if (randomDueDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              dialogSetState(() => randomDueDate = null),
                        ),
                      ],
                    ],
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
                      _selectedStudentIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('الرجاء إدخال العنوان واختيار الطلاب'),
                      ),
                    );
                    return;
                  }

                  // Use fixed min/max range for random questions
                  int min = fixedMin;
                  int max = fixedMax;
                  int count = int.tryParse(countController.text) ?? 5;
                  if (count <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('عدد الأسئلة يجب أن يكون أكبر من صفر'),
                      ),
                    );
                    return;
                  }

                  dialogSetState(() => _isCreatingAssignment = true);
                  try {
                    final rnd = Random();
                    List<Question> questions = [];
                    for (int i = 0; i < count; i++) {
                      int a, b;
                      if (op == OperationType.division) {
                        if (allowDecimalDivision) {
                          // allow decimal division: pick any a and b in range (b != 0)
                          a = min + rnd.nextInt(max - min + 1);
                          b = min + rnd.nextInt(max - min + 1);
                          if (b == 0) b = 1;
                        } else {
                          // pick divisor in range, then pick multiplier to make dividend (integer result)
                          b = min + rnd.nextInt(max - min + 1);
                          int multiplier = min + rnd.nextInt(max - min + 1);
                          a = b * multiplier;
                        }
                      } else if (op == OperationType.subtraction) {
                        a = min + rnd.nextInt(max - min + 1);
                        b = min + rnd.nextInt((a - min) + 1); // ensure b <= a
                      } else {
                        a = min + rnd.nextInt(max - min + 1);
                        b = min + rnd.nextInt(max - min + 1);
                      }

                      // If division and decimals are allowed, round to 1 decimal place.
                      int? roundDecimals =
                          (op == OperationType.division && allowDecimalDivision)
                          ? 1
                          : null;
                      questions.add(
                        Question.arithmetic(
                          a,
                          b,
                          op,
                          roundDecimals: roundDecimals,
                        ),
                      );
                    }

                    await Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).createAssignment(
                      title: _assignmentTitleController.text,
                      questions: questions,
                      assignedStudentIds: List.from(_selectedStudentIds),
                      assignedStudentNames: List.from(_selectedStudentNames),
                      description: _assignmentDescriptionController.text.isEmpty
                          ? null
                          : _assignmentDescriptionController.text,
                      dueDate: randomDueDate,
                      allowDecimalDivision: allowDecimalDivision,
                    );

                    await _loadAssignments();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إنشاء الواجب العشوائي بنجاح'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ أثناء إنشاء الواجب: $e')),
                    );
                  } finally {
                    if (mounted)
                      dialogSetState(() => _isCreatingAssignment = false);
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
                    : const Text('إنشاء'),
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
        builder: (context, dialogSetState) {
          // Initialize and load students when the dialog is first built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _filterGrade = grade;
            _filterClass = classNumber;
            _loadAllStudents(dialogSetState);
          });

          return AlertDialog(
            title: const Text('اختر الطلاب'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                                dialogSetState(() {
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
                              child: Text('لا توجد طلاب مطابقين للفلتر المحدد'),
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
                                    dialogSetState(() {
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 2,
          bottom: TabBar(
            isScrollable: true,
            // use theme colors for labels
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onPrimary.withOpacity(0.7),
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            tabs: [
              Tab(text: 'الأسئلة'),
              Tab(text: 'الواجبات'),
              Tab(text: 'الطلاب'),
            ],
          ),
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
                  colors:
                      Provider.of<ThemeProvider>(context).themeMode ==
                          ThemeMode.dark
                      ? [Colors.grey.shade900, Colors.black]
                      : [Colors.orange.shade50, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const QuestionEditorScreen(),
                          ),
                        );
                        await _loadAssignments();
                        if (!mounted) return;
                      },
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
                    child: Builder(
                      builder: (context) {
                        final qp = Provider.of<QuestionsProvider>(context);
                        if (qp.isLoading)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        final questions = qp.questions;
                        if (questions.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد أسئلة متاحة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            Question question = questions[index];
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
                                        (question.choices != null &&
                                            question.choices!.isNotEmpty)
                                        ? Colors.blue
                                        : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الإجابة: ${question.correctAnswer}'),
                                    if (question.explanation != null)
                                      Text(
                                        'الشرح: ${question.explanation!}',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    Text(
                                      'نوع السؤال: ${question.choices != null && question.choices!.isNotEmpty ? 'اختيارات' : (question.type == QuestionType.customText ? 'نصي' : (question.type == QuestionType.addition
                                                      ? '+ جمع'
                                                      : question.type == QuestionType.subtraction
                                                      ? '- طرح'
                                                      : question.type == QuestionType.multiplication
                                                      ? '× ضرب'
                                                      : '÷ قسمة'))}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
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
                  colors:
                      Provider.of<ThemeProvider>(context).themeMode ==
                          ThemeMode.dark
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: _showCreateRandomAssignmentDialog,
                      icon: const Icon(Icons.shuffle),
                      label: const Text('إنشاء واجب عشوائي'),
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
                        ? const Center(
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
                                          ? Colors.purple
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
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'حذف',
                                          style: TextStyle(color: Colors.red),
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
                  colors:
                      Provider.of<ThemeProvider>(context).themeMode ==
                          ThemeMode.dark
                      ? [Colors.grey.shade900, Colors.black]
                      : [Colors.green.shade50, Colors.white],
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
                      ? const Center(
                          child: Text(
                            'لا يوجد طلاب مسجلين',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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

            // Progress tab removed per user request
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
