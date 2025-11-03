import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question_model.dart';
import '../models/quiz_settings_model.dart';
import '../models/student_data_model.dart' show StudentAnswer, StudentData;
import '../services/quiz_service.dart';
import '../services/student_service.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';

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

class QuizScreen extends StatefulWidget {
  final String studentName;
  final int minQuestions;
  final int maxQuestions;
  final int? tableNumber;
  final bool isRandomTable;
  final OperationType operationType;
  final DifficultyLevel difficultyLevel;

  const QuizScreen({
    Key? key,
    required this.studentName,
    this.minQuestions = 5,
    this.maxQuestions = 10,
    this.tableNumber,
    this.isRandomTable = true,
    required this.operationType,
    required this.difficultyLevel,
  }) : assert(minQuestions <= maxQuestions, 'minQuestions must be less than or equal to maxQuestions');

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late final QuizService _quizService;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Question _currentQuestion;
  bool _isLoading = true;
  bool _showCorrectAnswer = false;
  int _score = 0;
  int _currentQuestionIndex = 0;
  int _totalQuestions = 0;
  bool? _isCorrect;
  final List<StudentAnswer> _answers = [];

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    _quizService.setQuizSettings(QuizSettings(
      minQuestions: widget.minQuestions,
      maxQuestions: widget.maxQuestions,
      tableNumber: widget.tableNumber,
      isRandomTable: widget.isRandomTable,
      operationType: widget.operationType,
      difficultyLevel: widget.difficultyLevel,
    ));

    _totalQuestions = _quizService.getTotalQuestionCount();
    _currentQuestion = _quizService.generateQuestion();
    setState(() => _isLoading = false);
    _animationController.forward();
  }

  void _generateNewQuestion() {
    setState(() {
      _currentQuestion = _quizService.generateQuestion();
      _controller.clear();
      _isCorrect = null;
      _animationController.reset();
      _animationController.forward();
    });
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

  // Helper method to get the operation symbol
  String _getOperationSymbol(OperationType operation) {
    switch (operation) {
      case OperationType.addition:
        return '+';
      case OperationType.subtraction:
        return '-';
      case OperationType.multiplication:
        return '×';
      case OperationType.division:
        return '÷';
    }
  }

  void _checkAnswer() {
    int answer = _parseArabicNumber(_controller.text);
    bool isCorrect = answer == _currentQuestion.correctAnswer;

    setState(() {
      _answers.add(StudentAnswer(
        question: '${_currentQuestion.a} ${_getOperationSymbol(_currentQuestion.operation)} ${_currentQuestion.b}',
        answer: answer.toString(),
        isCorrect: isCorrect,
      ));

      _isCorrect = isCorrect;
      _currentQuestionIndex++;
      if (isCorrect) {
        _score++;
      }

      // If we've reached max questions, finish the quiz
      if (_currentQuestionIndex >= _totalQuestions) {
        _finishQuiz();
        return;
      }

      // Show next question after a delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _currentQuestion = _quizService.generateQuestion();
            _controller.clear();
            _isCorrect = null;
            _animationController.reset();
            _animationController.forward();
          });
        }
      });
    });
  }

  void _finishQuiz() async {
    // Check if minimum questions are answered
    if (_totalQuestions < widget.minQuestions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يجب الإجابة على الأقل على ${_toArabicNumerals(widget.minQuestions.toString())} أسئلة'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Save quiz results using UserProvider
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isLoggedIn) {
      userProvider.updateUserScore(_score, subject: 'multiplication_quiz');
    }

    // Also save to student service for backward compatibility
    StudentService service = StudentService();
    StudentData student = StudentData(
      name: widget.studentName,
      score: _score,
      totalQuestions: _totalQuestions,
      answers: _answers,
    );
    service.saveStudent(student);

    if (mounted) {
      Navigator.pop(context, {
        'score': _score,
        'total': _totalQuestions,
        'answers': _answers.map((a) => a.toJson()).toList(),
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('اختبار جدول الضرب'),
            if (_totalQuestions > 0)
              Text(
                'السؤال ${_toArabicNumerals((_currentQuestionIndex + 1).toString())} من ${_toArabicNumerals(_totalQuestions.toString())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
        backgroundColor: Provider
            .of<ThemeProvider>(context)
            .themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.green.shade800,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Provider
                .of<ThemeProvider>(context)
                .themeMode == ThemeMode.dark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'السؤال ${_toArabicNumerals((_currentQuestionIndex + 1).toString())}',
                    key: ValueKey<int>(_score + _totalQuestions),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Provider
                          .of<ThemeProvider>(context)
                          .themeMode == ThemeMode.dark
                          ? Colors.greenAccent
                          : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'النتيجة: ${_toArabicNumerals(_score.toString())} من ${_toArabicNumerals(_totalQuestions.toString())}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Provider
                          .of<ThemeProvider>(context)
                          .themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    '${_toArabicNumerals(_currentQuestion.a.toString())} ${_getOperationSymbol(_currentQuestion.operation)} ${_toArabicNumerals(_currentQuestion.b.toString())} = ؟',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Provider
                          .of<ThemeProvider>(context)
                          .themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.blue.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    // Convert to Arabic numerals as user types
                    final selection = _controller.selection;
                    _controller.text = _toArabicNumerals(value);
                    _controller.selection = selection;
                  },
                  decoration: InputDecoration(
                    labelText: 'أدخل إجابتك',
                    labelStyle: TextStyle(
                      color: Provider
                          .of<ThemeProvider>(context)
                          .themeMode == ThemeMode.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Provider
                            .of<ThemeProvider>(context)
                            .themeMode == ThemeMode.dark
                            ? Colors.white70
                            : Colors.blue,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Provider
                            .of<ThemeProvider>(context)
                            .themeMode == ThemeMode.dark
                            ? Colors.white70
                            : Colors.blue,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Provider
                            .of<ThemeProvider>(context)
                            .themeMode == ThemeMode.dark
                            ? Colors.greenAccent
                            : Colors.green,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Provider
                        .of<ThemeProvider>(context)
                        .themeMode == ThemeMode.dark
                        ? Colors.grey.shade800
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(
                    color: Provider
                        .of<ThemeProvider>(context)
                        .themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _checkAnswer,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: Provider
                          .of<ThemeProvider>(context)
                          .themeMode == ThemeMode.dark
                          ? Colors.greenAccent
                          : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (Provider
                              .of<ThemeProvider>(context)
                              .themeMode == ThemeMode.dark
                              ? Colors.greenAccent
                              : Colors.green).withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      'تأكيد',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_isCorrect != null)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey<bool>(_isCorrect!),
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          _isCorrect!
                              ? 'إجابة صحيحة! +1 نقطة'
                              : 'إجابة خاطئة! الإجابة الصحيحة: ${_toArabicNumerals(_currentQuestion.correctAnswer.toString())}.',
                          style: TextStyle(
                            color: _isCorrect! ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isCorrect!)
                          ScaleTransition(
                            scale: _fadeAnimation,
                            child: Text('ممتاز!'),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _generateNewQuestion,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: Provider
                          .of<ThemeProvider>(context)
                          .themeMode == ThemeMode.dark
                          ? Colors.blueAccent
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (Provider
                              .of<ThemeProvider>(context)
                              .themeMode == ThemeMode.dark
                              ? Colors.blueAccent
                              : Colors.blue).withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      'السؤال التالي',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _finishQuiz,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('إنهاء الاختبار', style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
