import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/assignment_model.dart';
import '../services/assignment_service.dart';
import '../services/user_provider.dart';
import '../theme_provider.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');
  
  List<CustomAssignment> _allAssignments = [];
  List<CustomAssignment> _filteredAssignments = [];
  bool _isLoading = true;
  String? _selectedStatus;
  String? _selectedClass;
  String? _selectedStudent;
  
  final List<String> _statusOptions = ['الكل', 'نشط', 'منتهي'];
  final List<String> _classOptions = [];
  final List<String> _studentOptions = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _allAssignments = await _assignmentService.getAssignmentsByTeacher(userProvider.currentUser!.id);
      _filterAssignments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحميل الواجبات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterAssignments() {
    setState(() {
      _filteredAssignments = _allAssignments.where((assignment) {
        // Filter by status
        if (_selectedStatus == 'نشط' && !assignment.isActive) return false;
        if (_selectedStatus == 'منتهي' && assignment.isActive) return false;
        
        // Filter by class
        if (_selectedClass != null && _selectedClass!.isNotEmpty) {
          if (!assignment.assignedStudentNames.any((name) => name.contains(_selectedClass!))) {
            return false;
          }
        }
        
        // Filter by student
        if (_selectedStudent != null && _selectedStudent!.isNotEmpty) {
          if (!assignment.assignedStudentNames.contains(_selectedStudent)) {
            return false;
          }
        }
        
        // Filter by search text
        if (_searchController.text.isNotEmpty) {
          final searchTerm = _searchController.text.toLowerCase();
          return assignment.title.toLowerCase().contains(searchTerm) ||
                 assignment.description?.toLowerCase().contains(searchTerm) == true;
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الواجبات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignments,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن واجب...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (_) => _filterAssignments(),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'الكل',
                        selected: _selectedStatus == null,
                        onSelected: () {
                          setState(() => _selectedStatus = null);
                          _filterAssignments();
                        },
                      ),
                      ..._statusOptions.map((status) => _buildFilterChip(
                        label: status,
                        selected: _selectedStatus == status,
                        onSelected: () {
                          setState(() => _selectedStatus = status == 'الكل' ? null : status);
                          _filterAssignments();
                        },
                      )).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Assignment list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssignments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد واجبات متاحة',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_selectedStatus != null || _searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedStatus = null;
                                    _searchController.clear();
                                    _filterAssignments();
                                  });
                                },
                                child: const Text('مسح الفلاتر'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAssignments,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _filteredAssignments.length,
                          itemBuilder: (context, index) {
                            final assignment = _filteredAssignments[index];
                            return _buildAssignmentCard(assignment, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create assignment screen
          // Navigator.push(...);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.grey[300],
        selectedColor: Colors.blue[100],
        labelStyle: TextStyle(
          color: selected ? Colors.blue[900] : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(CustomAssignment assignment, bool isDark) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to assignment details
          // Navigator.push(...);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    assignment.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: assignment.isActive ? Colors.green[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      assignment.isActive ? 'نشط' : 'منتهي',
                      style: TextStyle(
                        color: assignment.isActive ? Colors.green[800] : Colors.grey[800],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (assignment.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  assignment.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people_outline,
                    label: '${assignment.assignedStudentIds.length} طالب',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.assignment_outlined,
                    label: '${assignment.questions.length} سؤال',
                  ),
                  const Spacer(),
                  Text(
                    _dateFormat.format(assignment.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
