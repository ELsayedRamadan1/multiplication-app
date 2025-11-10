import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/assignment_model.dart';
import '../models/question_model.dart';
import '../models/student_data_model.dart';
import '../services/custom_question_service.dart';
import '../services/quiz_service.dart';
import '../services/student_service.dart';
import '../services/user_provider.dart';

import '../theme_provider.dart';

class CustomQuizScreen extends StatefulWidget {
  final String studentName;
  final CustomAssignment? assignment;

  const CustomQuizScreen({
    super.key,
    required this.studentName,
    this.assignment,
  });

  @override
  _CustomQuizScreenState createState() => _CustomQuizScreenState();
}

class _CustomQuizScreenState extends State<CustomQuizScreen>
    with TickerProviderStateMixin {
  final CustomQuestionService _questionService = CustomQuestionService();
  final QuizService _quizService = QuizService();
  late TextEditingController _controller = TextEditingController();

  List<Question> _customQuestions = [];
  List<Question> _assignmentQuestions = [];
  Question? _currentQuestion;
  bool? _isCorrect;
  int _score = 0;
  int _totalQuestions = 0;
  int _currentQuestionIndex = 0;
  DateTime? _startedAt;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<StudentAnswer> _answers = [];
  // For assignment / custom quiz detailed results
  final List<QuestionResult> _questionResults = [];
  static const double _epsilon = 0.0001; // tolerance for floating comparison

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    if (widget.assignment != null) {
      _assignmentQuestions = widget.assignment!.questions;
      _totalQuestions = _assignmentQuestions.length;
      _currentQuestion = _assignmentQuestions[0];
      _currentQuestionIndex = 0;
      // Prevent reopening a completed assignment: check server if current student already has a result
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          final res = await userProvider.getAssignmentResultForStudent(
            widget.assignment!.id,
          );
          if (res != null) {
            // Already completed: inform and close
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'لقد أنهيت هذا الواجب سابقًا (${res.score}/${res.totalQuestions})',
                  ),
                ),
              );
              Navigator.of(context).pop();
            }
          } else {
            // mark start time when student first opens the assignment
            try {
              final started = await userProvider.markAssignmentStarted(
                widget.assignment!.id,
              );
              _startedAt = started ?? DateTime.now();
            } catch (_) {
              _startedAt = DateTime.now();
            }
          }
        } catch (_) {
          // ignore errors here — allow opening the quiz and let save handle duplicates
        }
      });
    } else {
      _loadCustomQuestions();
    }
    _animationController.forward();
  }

  Future<void> _loadCustomQuestions() async {
    List<Question> questions = await _questionService.getCustomQuestions();
    setState(() {
      _customQuestions = questions;
      _quizService.setCustomQuestions(questions);
      if (questions.isNotEmpty) {
        _currentQuestion = _quizService.generateQuestion();
        _animationController.forward();
      }
    });
  }

  void _generateNewQuestion() {
    if (widget.assignment != null) {
      if (_currentQuestionIndex < _assignmentQuestions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _currentQuestion = _assignmentQuestions[_currentQuestionIndex];
          _controller.clear();
          _isCorrect = null;
          _animationController.reset();
          _animationController.forward();
        });
      }
    } else {
      if (_customQuestions.isEmpty) return;

      setState(() {
        _currentQuestion = _quizService.generateQuestion();
        _controller.clear();
        _isCorrect = null;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  void _checkAnswer() {
    if (_currentQuestion == null) return;

    // Handle both integer and decimal inputs
    String input = _controller.text.trim();
    double? answer;

    // Check for fraction format (e.g., 1/2)
    if (input.contains('/')) {
      var parts = input
          .split('/')
          .map((e) => double.tryParse(e.trim()))
          .toList();
      if (parts.length == 2 &&
          parts[0] != null &&
          parts[1] != null &&
          parts[1] != 0) {
        answer = parts[0]! / parts[1]!;
      }
    } else {
      // Handle regular number
      answer = double.tryParse(input);
    }

    if (answer != null) {
      final correct = _currentQuestion!.correctAnswer;
      final isCorrect = (answer - correct).abs() <= _epsilon;

      // Record question result
      _questionResults.add(
        QuestionResult(
          questionText: _currentQuestion!.question,
          correctAnswer: correct.toDouble(),
          userAnswer: answer,
          isCorrect: isCorrect,
        ),
      );

      setState(() {
        _isCorrect = isCorrect;
        _totalQuestions = _questionResults.length; // track answered count
        if (isCorrect) _score++;
      });
      // After showing feedback, automatically move to next question (or finish)
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        // If this is an assignment, advance through assignment questions
        if (widget.assignment != null) {
          if (_currentQuestionIndex < _assignmentQuestions.length - 1) {
            _generateNewQuestion();
          } else {
            _finishQuiz();
          }
        } else {
          // For general quiz, just generate a new random question
          _generateNewQuestion();
        }
      });
    }
  }

  void _finishQuiz() async {
    if (_currentQuestion == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد أسئلة متاحة')));
      return;
    }

    UserProvider userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );

    // show loading dialog while saving
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (widget.assignment != null) {
        // Use the recorded _questionResults; if user didn't answer all questions, fill missing with blanks
        final List<QuestionResult> resultsToSave = [];
        for (int i = 0; i < _assignmentQuestions.length; i++) {
          if (i < _questionResults.length) {
            resultsToSave.add(_questionResults[i]);
          } else {
            final q = _assignmentQuestions[i];
            resultsToSave.add(
              QuestionResult(
                questionText: q.question,
                correctAnswer: q.correctAnswer.toDouble(),
                userAnswer: 0.0,
                isCorrect: false,
              ),
            );
          }
        }

        await userProvider.saveCustomQuizResult(
          assignmentId: widget.assignment!.id,
          questionResults: resultsToSave,
          score: _score,
          startTime: _startedAt,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إنهاء الواجب! نتيجتك: $_score/${_assignmentQuestions.length}',
            ),
          ),
        );
      } else {
        if (userProvider.isLoggedIn) {
          await userProvider.updateUserScore(_score, subject: 'custom_quiz');
        }

        StudentService service = StudentService();
        StudentData student = StudentData(
          name: widget.studentName,
          score: _score,
          totalQuestions: _totalQuestions,
          answers: _answers,
        );
        await service.saveStudent(student);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إنهاء الاختبار! نتيجتك: $_score/$_totalQuestions',
            ),
          ),
        );
      }

      Navigator.of(context).pop(); // close loading
      Navigator.of(context).pop(); // close quiz screen
    } catch (e) {
      Navigator.of(context).pop(); // close loading
      final msg = e.toString();
      if (msg.contains('permission-denied') || msg.contains('صلاحيات')) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('فشل حفظ النتيجة'),
            content: const Text(
              'لا تمتلك صلاحيات كافية لحفظ النتيجة في قاعدة البيانات. الرجاء إعادة تسجيل الدخول كطالب أو التواصل مع مدير النظام.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(c).pop();
                  // Try retry
                  _finishQuiz();
                },
                child: const Text('إعادة المحاولة'),
              ),
              TextButton(
                onPressed: () async {
                  // Close dialog
                  Navigator.of(c).pop();
                  // Sign out the current user and redirect to splash/login flow
                  try {
                    await Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).logout();
                  } catch (_) {}
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/splash', (route) => false);
                },
                child: const Text('تسجيل الخروج وإعادة تسجيل الدخول'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء حفظ النتيجة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.assignment != null
              ? widget.assignment!.title
              : 'اختبار الأسئلة المخصصة',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: Container(
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
        child: widget.assignment != null
            ? _buildAssignmentQuiz()
            : _customQuestions.isEmpty
            ? Center(
                child: Text(
                  'لا توجد أسئلة مخصصة متاحة.\nاطلب من معلمك إنشاء بعضها!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              )
            : _buildGeneralQuiz(),
      ),
    );
  }

  Widget _buildImageWidget(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const SizedBox.shrink();
    }

    final imageFile = File(imagePath);
    final fileExists = imageFile.existsSync();

    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: fileExists
                ? Image.file(
                    imageFile,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildAssignmentQuiz() {
    if (_currentQuestion == null) {
      return const Center(
        child: Text(
          'لا توجد أسئلة في هذا الواجب',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'الواجب: ${widget.assignment!.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'السؤال رقم ${_currentQuestionIndex + 1} من ${_assignmentQuestions.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (widget.assignment!.description != null)
                      Text(
                        widget.assignment!.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'النتيجة: ${NumberFormat.decimalPattern('ar').format(_score)} / ${NumberFormat.decimalPattern('ar').format(_assignmentQuestions.length)}',
                  key: ValueKey<int>(_score + _assignmentQuestions.length),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Provider.of<ThemeProvider>(context).themeMode ==
                            ThemeMode.dark
                        ? Colors.grey.shade800
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(128, 0, 128, 0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildImageWidget(_currentQuestion!.imagePath),
                      Text(
                        _currentQuestion!.question,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              Provider.of<ThemeProvider>(context).themeMode ==
                                  ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_currentQuestion!.explanation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'تلميح: ${_currentQuestion!.explanation!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'إجابتك',
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _checkAnswer,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'تحقق من الإجابة',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_isCorrect != null)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      _isCorrect!
                          ? 'صحيح! +1 نقطة'
                          : 'إجابة خاطئة: ${_currentQuestion!.correctAnswer}',
                      style: TextStyle(
                        color: _isCorrect!
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.error,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isCorrect!)
                      Text(
                        '🎉 أداء رائع!',
                        style: const TextStyle(fontSize: 18),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _currentQuestionIndex < _assignmentQuestions.length - 1
                    ? _generateNewQuestion
                    : _finishQuiz,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentQuestionIndex < _assignmentQuestions.length - 1
                        ? 'السؤال التالي'
                        : 'إنهاء الواجب',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralQuiz() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'النتيجة: ${NumberFormat.decimalPattern('ar').format(_score)} / ${NumberFormat.decimalPattern('ar').format(_totalQuestions)}',
                  key: ValueKey<int>(_score + _totalQuestions),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildImageWidget(_currentQuestion!.imagePath),
                      const SizedBox(height: 15),
                      Text(
                        _currentQuestion!.question,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_currentQuestion!.explanation != null)
                        Text(
                          'ملاحظة: ${_currentQuestion!.explanation!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'إجابتك',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _checkAnswer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'تحقق من الإجابة',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (_isCorrect != null)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      _isCorrect!
                          ? 'صحيح! +1 نقطة'
                          : 'إجابة خاطئة: ${_currentQuestion!.correctAnswer}',
                      style: TextStyle(
                        color: _isCorrect!
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.error,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isCorrect!)
                      Text(
                        '🎉 أداء رائع!',
                        style: const TextStyle(fontSize: 18),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _generateNewQuestion,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'السؤال التالي',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _finishQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'إنهاء الاختبار',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
