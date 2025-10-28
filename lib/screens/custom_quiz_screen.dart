import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class _CustomQuizScreenState extends State<CustomQuizScreen> with TickerProviderStateMixin {
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<StudentAnswer> _answers = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    if (widget.assignment != null) {
      _assignmentQuestions = widget.assignment!.questions;
      _totalQuestions = _assignmentQuestions.length;
      _currentQuestion = _assignmentQuestions[0];
      _currentQuestionIndex = 0;
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

    int? answer = int.tryParse(_controller.text);
    if (answer != null) {
      bool isCorrect = _currentQuestion!.isCorrect(answer);

      setState(() {
        _isCorrect = isCorrect;
        _totalQuestions++;
        if (isCorrect) {
          _score++;
        }
      });
    }
  }

  void _finishQuiz() async {
    if (_currentQuestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أسئلة متاحة')),
      );
      return;
    }

    UserProvider userProvider = Provider.of<UserProvider>(
        context, listen: false);

    if (widget.assignment != null) {
      List<QuestionResult> questionResults = [];

      for (int i = 0; i <= _currentQuestionIndex &&
          i < _assignmentQuestions.length; i++) {
        questionResults.add(QuestionResult(
          questionText: _assignmentQuestions[i].question,
          correctAnswer: _assignmentQuestions[i].correctAnswer,
          userAnswer: _assignmentQuestions[i].correctAnswer,
          isCorrect: i < _currentQuestionIndex ? true : false,
        ));
      }

      await userProvider.saveCustomQuizResult(
        assignmentId: widget.assignment!.id,
        questionResults: questionResults,
        score: _score,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            'تم إنهاء الواجب! نتيجتك: $_score/${_assignmentQuestions.length}')),
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
        SnackBar(content: Text(
            'تم إنهاء الاختبار! نتيجتك: $_score/$_totalQuestions')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment != null
            ? widget.assignment!.title
            : 'اختبار الأسئلة المخصصة'),
        backgroundColor: Provider
            .of<ThemeProvider>(context)
            .themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.purple.shade800,
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
                : [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: widget.assignment != null
            ? _buildAssignmentQuiz()
            : _customQuestions.isEmpty
            ? const Center(
          child: Text(
            'لا توجد أسئلة مخصصة متاحة.\nاطلب من معلمك إنشاء بعضها!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        )
            : _buildGeneralQuiz(),
      ),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'الواجب: ${widget.assignment!.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'السؤال رقم ${_currentQuestionIndex +
                          1} من ${_assignmentQuestions.length}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (widget.assignment!.description != null)
                      Text(
                        widget.assignment!.description!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'النتيجة: $_score / ${_assignmentQuestions.length}',
                  key: ValueKey<int>(_score + _assignmentQuestions.length),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Provider
                        .of<ThemeProvider>(context)
                        .themeMode == ThemeMode.dark
                        ? Colors.purpleAccent
                        : Colors.purple,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Provider
                        .of<ThemeProvider>(context)
                        .themeMode == ThemeMode.dark
                        ? Colors.grey.shade800
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_currentQuestion!.imagePath != null &&
                          _currentQuestion!.imagePath!.isNotEmpty) ...[
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              File(_currentQuestion!.imagePath!),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 40,
                                        color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                      Text(
                        _currentQuestion!.question,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Provider
                              .of<ThemeProvider>(context)
                              .themeMode == ThemeMode.dark
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
                            color: Colors.grey.shade600,
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
                          : Colors.purple,
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
                        ? Colors.purpleAccent
                        : Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'تحقق من الإجابة',
                    style: TextStyle(color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
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
                        color: _isCorrect! ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isCorrect!)
                      Text(
                          '🎉 أداء رائع!', style: const TextStyle(fontSize: 18)),
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
                      horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Provider
                        .of<ThemeProvider>(context)
                        .themeMode == ThemeMode.dark
                        ? Colors.blueAccent
                        : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentQuestionIndex < _assignmentQuestions.length - 1
                        ? 'السؤال التالي'
                        : 'إنهاء الواجب',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
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
                  'النتيجة: $_score / $_totalQuestions',
                  key: ValueKey<int>(_score + _totalQuestions),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Provider
                        .of<ThemeProvider>(context)
                        .themeMode == ThemeMode.dark
                        ? Colors.purpleAccent
                        : Colors.purple,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Provider
                        .of<ThemeProvider>(context)
                        .themeMode == ThemeMode.dark
                        ? Colors.grey.shade800
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      if (_currentQuestion!.imagePath != null &&
                          _currentQuestion!.imagePath!.isNotEmpty)
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Image.file(
                            File(_currentQuestion!.imagePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 15),
                      Text(
                        _currentQuestion!.question,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Provider
                              .of<ThemeProvider>(context)
                              .themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_currentQuestion!.explanation != null)
                        Text(
                          'ملاحظة: ${_currentQuestion!.explanation!}',
                          style: TextStyle(fontSize: 12, color: Colors.grey
                              .shade600, fontStyle: FontStyle.italic),
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _checkAnswer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'تحقق من الإجابة',
                    style: TextStyle(color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
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
                        color: _isCorrect! ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isCorrect!)
                      Text(
                          '🎉 أداء رائع!', style: const TextStyle(fontSize: 18)),
                  ],
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _generateNewQuestion,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'السؤال التالي',
                    style: TextStyle(color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _finishQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                    'إنهاء الاختبار', style: TextStyle(fontSize: 14)),
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
