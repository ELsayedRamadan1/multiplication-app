import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question_model.dart';
import '../models/student_data_model.dart';
import '../services/quiz_service.dart';
import '../services/student_service.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';

class QuizScreen extends StatefulWidget {
  final String studentName;

  const QuizScreen({super.key, required this.studentName});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  late Question _currentQuestion;
  late TextEditingController _controller;
  bool? _isCorrect;
  int _score = 0;
  int _totalQuestions = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<StudentAnswer> _answers = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _currentQuestion = _quizService.generateQuestion();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
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

  void _checkAnswer() {
    int? answer = int.tryParse(_controller.text);
    if (answer != null) {
      bool isCorrect = _quizService.checkAnswer(_currentQuestion, answer);
      _answers.add(StudentAnswer(
        question: '${_currentQuestion.a} x ${_currentQuestion.b}',
        answer: answer.toString(),
        isCorrect: isCorrect,
      ));
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
    // Save quiz results using UserProvider
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isLoggedIn) {
      await userProvider.updateUserScore(_score, subject: 'multiplication_quiz');
    }

    // Also save to student service for backward compatibility
    StudentService service = StudentService();
    StudentData student = StudentData(
      name: widget.studentName,
      score: _score,
      totalQuestions: _totalQuestions,
      answers: _answers,
    );
    await service.saveStudent(student);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quiz completed! Final Score: $_score/$_totalQuestions')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
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
                    'Score: $_score / $_totalQuestions',
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
                    'What is ${_currentQuestion.a} x ${_currentQuestion.b}?',
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
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Your Answer',
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
                      'Check',
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
                              ? 'Correct! +1 point'
                              : 'Correct: ${_currentQuestion.correctAnswer}',
                          style: TextStyle(
                            color: _isCorrect! ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isCorrect!)
                          ScaleTransition(
                            scale: _fadeAnimation,
                            child: Text('🎊 Great Job!',
                                style: const TextStyle(fontSize: 18)),
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
                      'Next Question',
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
                  child: Text('Finish Quiz', style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
