import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quiz_settings_model.dart';
import '../theme_provider.dart';
import 'quiz_screen.dart';
import '../models/question_model.dart';
import '../widgets/custom_app_bar.dart';

class QuizSetupScreen extends StatefulWidget {
  final String studentName;

  const QuizSetupScreen({super.key, required this.studentName});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  int? _selectedTable;
  bool _isRandomTable = true;
  OperationType _selectedOperation = OperationType.multiplication;
  DifficultyLevel _difficulty = DifficultyLevel.medium;

  @override
  void initState() {
    super.initState();
    // Initialize with Arabic numerals
    _minController.text = _toArabicNumerals('5');
    _maxController.text = _toArabicNumerals('10');
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  // Convert Arabic numerals to English before parsing
  int _parseArabicNumber(String value) {
    if (value.isEmpty) return 0;
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String englishNumber = '';

    for (int i = 0; i < value.length; i++) {
      final char = value[i];
      final index = ar.indexOf(char);
      englishNumber += index != -1 ? index.toString() : char;
    }

    return int.tryParse(englishNumber) ?? 0;
  }

  // Helper function to convert English numbers to Arabic numerals
  String _toArabicNumerals(String input) {
    if (input.isEmpty) return input;

    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String result = '';
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      final index = en.indexOf(char);
      result += index != -1 ? ar[index] : char;
    }

    return result;
  }

  void _startQuiz() {
    if (_formKey.currentState?.validate() ?? false) {
      final minQuestions = int.parse(_parseArabicNumber(_minController.text).toString());
      final maxQuestions = int.parse(_parseArabicNumber(_maxController.text).toString());

      // For multiplication, we need to ensure table number is set if not random
      if (_selectedOperation == OperationType.multiplication &&
          !_isRandomTable &&
          _selectedTable == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار جدول الضرب')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            studentName: widget.studentName,
            minQuestions: minQuestions,
            maxQuestions: maxQuestions,
            tableNumber: _isRandomTable ? null : _selectedTable,
            isRandomTable: _isRandomTable,
            operationType: _selectedOperation,
            difficultyLevel: _difficulty,
          ),
        ),
      );
    }
  }

  Widget _buildStudentNameCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('اسم الطالب'),
            Text(widget.studentName, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationTypeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('نوع الاختبار'),
            DropdownButtonFormField<OperationType>(
              value: _selectedOperation,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: [
                DropdownMenuItem(
                  value: OperationType.multiplication,
                  child: const Text('ضرب'),
                ),
                DropdownMenuItem(
                  value: OperationType.addition,
                  child: const Text('جمع'),
                ),
                DropdownMenuItem(
                  value: OperationType.subtraction,
                  child: const Text('طرح'),
                ),
                DropdownMenuItem(
                  value: OperationType.division,
                  child: const Text('قسمة'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedOperation = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('مستوى الصعوبة'),
            const SizedBox(height: 8),
            DropdownButtonFormField<DifficultyLevel>(
              value: _difficulty,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: [
                DropdownMenuItem(
                  value: DifficultyLevel.easy,
                  child: const Text('سهل'),
                ),
                DropdownMenuItem(
                  value: DifficultyLevel.medium,
                  child: const Text('متوسط'),
                ),
                DropdownMenuItem(
                  value: DifficultyLevel.hard,
                  child: const Text('صعب'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _difficulty = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('إعدادات جدول الضرب'),
            SwitchListTile(
              title: const Text('جدول عشوائي'),
              value: _isRandomTable,
              onChanged: (value) {
                setState(() {
                  _isRandomTable = value;
                  if (!value && _selectedTable == null) {
                    _selectedTable = 1; // Default to table 1 if not random
                  }
                });
              },
              activeColor: Colors.blue,
            ),
            if (!_isRandomTable) ...[
              const SizedBox(height: 16),
              const Text('اختر جدول الضرب'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedTable,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: List.generate(12, (index) => index + 1)
                    .map((table) => DropdownMenuItem(
                  value: table,
                  child: Text(
                    'جدول ضرب ${_toArabicNumerals(table.toString())}',
                    textAlign: TextAlign.right,
                  ),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTable = value;
                  });
                },
                validator: (value) {
                  if (!_isRandomTable && value == null) {
                    return 'الرجاء اختيار جدول الضرب';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsCountCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('عدد الأسئلة'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                // Update the text with Arabic numerals as user types
                final selection = _minController.selection;
                _minController.text = _toArabicNumerals(value);
                _minController.selection = selection;
              },
              decoration: InputDecoration(
                labelText: 'الحد الأدنى',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'مطلوب';
                }
                final num = _parseArabicNumber(value);
                if (num < 1) {
                  return 'يجب أن يكون العدد أكبر من ${_toArabicNumerals('0')}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                // Update the text with Arabic numerals as user types
                final selection = _maxController.selection;
                _maxController.text = _toArabicNumerals(value);
                _maxController.selection = selection;
              },
              decoration: InputDecoration(
                labelText: 'الحد الأقصى',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'مطلوب';
                }
                final num = _parseArabicNumber(value);
                if (num < 1) {
                  return 'يجب أن يكون العدد أكبر من ${_toArabicNumerals('0')}';
                }
                final min = _parseArabicNumber(_minController.text);
                if (num < min) {
                  return 'يجب أن يكون أكبر من أو يساوي الحد الأدنى';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(

      appBar: const CustomAppBar(title: 'إعداد الاختبار'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Student Name
                _buildStudentNameCard(),
                const SizedBox(height: 20),

                // Operation Type Selection
                _buildOperationTypeCard(),
                const SizedBox(height: 20),

                // Quiz Settings (conditionally show table selection for multiplication)
                if (_selectedOperation == OperationType.multiplication)
                  _buildSettingsCard(),

                // Questions Count
                _buildQuestionsCountCard(),

                // Start Quiz Button
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _startQuiz,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'بدء الاختبار',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}