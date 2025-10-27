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
      // Use assignment questions
      _assignmentQuestions = widget.assignment!.questions;
      _totalQuestions = _assignmentQuestions.length;
      _currentQuestion = _assignmentQuestions[0];
      _currentQuestionIndex = 0;
    } else {
      // Use general custom questions
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
      // Assignment mode - go to next question in sequence
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
      // General custom questions mode
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
        SnackBar(content: Text('No questions available')),
      );
      return;
    }

    // Save quiz results
    UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);

    if (widget.assignment != null) {
      // Save as custom assignment result
      List<QuestionResult> questionResults = [];

      // Create question results based on current progress
      for (int i = 0; i <= _currentQuestionIndex && i < _assignmentQuestions.length; i++) {
        // For simplicity, assume all questions were answered correctly up to current point
        // In a real implementation, you'd track each answer individually
        questionResults.add(QuestionResult(
          questionText: _assignmentQuestions[i].question,
          correctAnswer: _assignmentQuestions[i].correctAnswer,
          userAnswer: _assignmentQuestions[i].correctAnswer, // Placeholder
          isCorrect: i < _currentQuestionIndex ? true : false, // Placeholder logic
        ));
      }

      await userProvider.saveCustomQuizResult(
        assignmentId: widget.assignment!.id,
        questionResults: questionResults,
        score: _score,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment completed! Score: $_score/${_assignmentQuestions.length}')),
      );
    } else {
      // Save as regular custom quiz
      if (userProvider.isLoggedIn) {
        await userProvider.updateUserScore(_score, subject: 'custom_quiz');
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz completed! Score: $_score/$_totalQuestions')),
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
            : 'Custom Questions Quiz'),
        backgroundColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.purple.shade800,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: widget.assignment != null
            ? _buildAssignmentQuiz()
            : _customQuestions.isEmpty
                ? const Center(
                    child: Text(
                      'No custom questions available.\nAsk your teacher to create some!',
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
          'No assignment questions available',
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
              // Assignment info
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
                      '${'Assignment'}: ${widget.assignment!.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${'Question of'} ${_currentQuestionIndex + 1} of ${_assignmentQuestions.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (widget.assignment!.description != null)
                      Text(
                        widget.assignment!.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Score: $_score / ${_assignmentQuestions.length}',
                  key: ValueKey<int>(_score + _assignmentQuestions.length),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
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
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
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
                      if (_currentQuestion!.imagePath != null && _currentQuestion!.imagePath!.isNotEmpty) ...[
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
                                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
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
                          color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_currentQuestion!.explanation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Hint: ${_currentQuestion!.explanation!}',
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
                  labelText: 'Your Answer',
                  labelStyle: TextStyle(
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                          ? Colors.white70
                          : Colors.purple,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                          ? Colors.white70
                          : Colors.purple,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                          ? Colors.purpleAccent
                          : Colors.purple,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                      ? Colors.grey.shade800
                      : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                style: TextStyle(
                  color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
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
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                        ? Colors.purpleAccent
                        : Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                            ? Colors.purpleAccent
                            : Colors.purple).withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    'Check Answer',
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
                            : 'Wrong! Correct: ${_currentQuestion!.correctAnswer}',
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
                onTap: _currentQuestionIndex < _assignmentQuestions.length - 1 ? _generateNewQuestion : _finishQuiz,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                        ? Colors.blueAccent
                        : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                            ? Colors.blueAccent
                            : Colors.blue).withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    _currentQuestionIndex < _assignmentQuestions.length - 1 ? 'Next Question' : 'Finish Assignment',
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
                  'Score: $_score / $_totalQuestions',
                  key: ValueKey<int>(_score + _totalQuestions),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
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
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
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
                      if (_currentQuestion!.imagePath != null && _currentQuestion!.imagePath!.isNotEmpty) ...[
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
                                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
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
                          color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_currentQuestion!.explanation != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Hint: ${_currentQuestion!.explanation!}',
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
                  labelText: 'Your Answer',
                  labelStyle: TextStyle(
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                          ? Colors.white70
                          : Colors.purple,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                          ? Colors.white70
                          : Colors.purple,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                          ? Colors.purpleAccent
                          : Colors.purple,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                      ? Colors.grey.shade800
                      : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                style: TextStyle(
                  color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
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
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                        ? Colors.purpleAccent
                        : Colors.purple,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                            ? Colors.purpleAccent
                            : Colors.purple).withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    'Check Answer',
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
                            : 'Wrong! Correct: ${_currentQuestion!.correctAnswer}',
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
                    color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                        ? Colors.blueAccent
                        : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
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
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Finish Quiz', style: const TextStyle(fontSize: 14)),
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
