import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as paint;
import 'package:provider/provider.dart';
import '../services/user_provider.dart';
import 'create_question_screen.dart';
import 'quiz_setup_screen.dart';
import 'student_assignments_screen.dart';
import 'teacher_dashboard.dart';
import 'settings_screen.dart';
import '../widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTable = 1;
  int _bottomIndex = 0;
  late final PageController _pageController;
  // Persistent filter state so UI doesn't reset on rebuilds
  int? _filterGrade;
  int? _filterClassNumber;

  // Convert western digits to Arabic-Indic digits for nicer UI
  String _toArabicNumber(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String s = number.toString();
    for (int i = 0; i < english.length; i++) {
      s = s.replaceAll(english[i], arabic[i]);
    }
    return s;
  }

  void _onBottomNavTap(int index, UserProvider userProvider) {
    // Animate to the selected page for both teachers and students
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildFilterPage(UserProvider userProvider) {
    // Use persistent state variables so the user's selection survives rebuilds
    int? grade = _filterGrade;
    int? classNumber = _filterClassNumber;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تصفية الطلاب (الصف - الفصل)',
                    style: TextStyle(fontWeight: paint.FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: grade,
                          decoration: const InputDecoration(labelText: 'الصف'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('الكل'),
                            ),
                            ...List.generate(
                              6,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text('الصف ${i + 1}'),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _filterGrade = v;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          initialValue: classNumber,
                          decoration: const InputDecoration(labelText: 'الفصل'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('الكل'),
                            ),
                            ...List.generate(
                              10,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text('الفصل ${i + 1}'),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _filterClassNumber = v;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          setState(() {
                            _filterGrade = null;
                            _filterClassNumber = null;
                          });
                          // Persist cleared defaults as well
                          await userProvider.setTeacherDefaults(grade: null, classNumber: null);
                        },
                        child: const Text('مسح'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Persist teacher defaults from the maintained state
                          await userProvider.setTeacherDefaults(
                            grade: _filterGrade,
                            classNumber: _filterClassNumber,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حفظ إعدادات التصفية'),
                            ),
                          );
                        },
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(UserProvider userProvider, Color primaryColor) {
    // prepare pages according to role
    final pages = userProvider.isTeacher
        ? <Widget>[
            // teacher pages: each page provides its own AppBar inside the Scaffold
            Scaffold(
              appBar: CustomAppBar(title: 'تصفية الطلاب', color: primaryColor),
              body: _buildFilterPage(userProvider),
            ),
            const CreateQuestionScreen(),
            const TeacherDashboard(),
            const SettingsScreen(),
          ]
        : <Widget>[
            // student pages: wrap table view with Scaffold app bar, others already have their own Scaffold
            Scaffold(
              appBar: CustomAppBar(title: 'جدول الضرب', color: primaryColor),
              body: _buildTableView(),
            ),
            // Show QuizSetup as a full page (it already contains a Scaffold)
            QuizSetupScreen(
              studentName: userProvider.currentUser?.name ?? 'طالب',
            ),
            const StudentAssignmentsScreen(),
            const SettingsScreen(),
          ];

    return SafeArea(
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _bottomIndex = index);
          // auto-open behavior removed — pages are full screens now and user interacts directly
        },
        children: pages,
      ),
    );
  }

  Widget _buildTableView() {
    final double width = MediaQuery.of(context).size.width;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ تحديد عدد الأعمدة تلقائيًا حسب حجم الشاشة
    int cols;
    if (width >= 1000) {
      cols = 5; // شاشات كبيرة (ويب أو لابتوب)
    } else if (width >= 700) {
      cols = 4; // تابلت
    } else if (width >= 500) {
      cols = 3; // موبايلات كبيرة
    } else {
      cols = 2; // موبايلات صغيرة
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 كارت اختيار الجدول
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade600,
                              Colors.blue.shade300,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade100.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.grid_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'اختيار الجدول',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: paint.FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'معاينة جدول الضرب كاملة',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.blue.shade100,
                      ),
                    ),
                    child: DropdownButton<int>(
                      value: selectedTable,
                      underline: const SizedBox.shrink(),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem<int>(
                          value: i + 1,
                          child: Text(
                            _toArabicNumber(i + 1),
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade200
                                  : Colors.black,
                              fontSize: 20,
                              fontWeight: paint.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      onChanged: (v) => setState(() => selectedTable = v ?? 1),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 كارت الجدول الكامل
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'جدول ${_toArabicNumber(selectedTable)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: paint.FontWeight.bold,
                            color: isDark ? Colors.grey.shade50 : Colors.black,
                          ),
                        ),
                        Text(
                          '×',
                          style: TextStyle(
                            fontSize: 20,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ✅ جدول Responsive بدون Overflow
                    GridView.builder(
                      itemCount: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: width < 400 ? 1.4 : 1.8,
                      ),
                      itemBuilder: (context, i) {
                        final mult = i + 1;
                        final res = selectedTable * mult;
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.blue.shade100,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  // Show full expression with equals sign and Arabic numerals
                                  '${_toArabicNumber(selectedTable)} × ${_toArabicNumber(mult)} = ${_toArabicNumber(res)}',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _bottomIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize filter state from provider once (if not already set)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (_filterGrade == null && _filterClassNumber == null) {
      // If the stored teacher defaults are identical to the teacher's own grade/class
      // (likely assigned at registration), treat them as "not set" so UI shows "الكل".
      final tdg = userProvider.teacherDefaultGrade;
      final tdc = userProvider.teacherDefaultClassNumber;
      final ug = userProvider.currentUser?.grade;
      final uc = userProvider.currentUser?.classNumber;
      if (tdg != null && tdc != null && ug != null && uc != null && tdg == ug && tdc == uc) {
        _filterGrade = null;
        _filterClassNumber = null;
      } else {
        _filterGrade = tdg;
        _filterClassNumber = tdc;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Determine primary color and app bar title based on role and selected tab
        Color primaryColor = userProvider.isTeacher
            ? Colors.orange.shade800
            : Colors.blue.shade800;
        if (userProvider.isTeacher) {
          switch (_bottomIndex) {
            case 0:
              break;
            case 1:
              break;
            case 2:
              break;
            default:
              break;
          }
        } else {
          switch (_bottomIndex) {
            case 0:
              break;
            case 1:
              break;
            case 2:
              break;
            default:
              break;
          }
        }

        // Each page provides its own AppBar/Scaffold inside the PageView, so we render the PageView body here.
        return Scaffold(
          body: _buildBody(userProvider, primaryColor),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _bottomIndex,
            onTap: (i) => _onBottomNavTap(i, userProvider),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade600,
            items: userProvider.isTeacher
                ? const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.filter_list),
                      label: 'تصفية',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.add_circle_outline),
                      label: 'أسئلة',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.school_rounded),
                      label: 'النتائج',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      label: 'الإعدادات',
                    ),
                  ]
                : const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.grid_on),
                      label: 'الجدول',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.quiz),
                      label: 'اختبار',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.assignment),
                      label: 'الواجبات',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'الإعدادات',
                    ),
                  ],
          ),
        );
      },
    );
  }
}
