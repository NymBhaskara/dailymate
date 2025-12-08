import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _completedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedTasks();
  }

  Future<void> _fetchCompletedTasks() async {
    try {
      final response = await _supabase
          .from('user_tasks') // GANTI DARI 'tasks' KE 'user_tasks'
          .select('*')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_completed', true) // Ambil yang sudah selesai
          .order('completed_at', ascending: false);

      setState(() {
        _completedTasks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching completed tasks: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History Page'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Group tasks by date
                  ..._buildTaskGroups(),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildTaskGroups() {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    
    final todayTasks = _completedTasks.where((task) {
      final completedAt = DateTime.parse(task['completed_at']);
      return completedAt.year == now.year &&
             completedAt.month == now.month &&
             completedAt.day == now.day;
    }).toList();
    
    final yesterdayTasks = _completedTasks.where((task) {
      final completedAt = DateTime.parse(task['completed_at']);
      return completedAt.year == yesterday.year &&
             completedAt.month == yesterday.month &&
             completedAt.day == yesterday.day;
    }).toList();

    return [
      if (todayTasks.isNotEmpty) ...[
        _buildDateSection('Today', todayTasks),
        SizedBox(height: 24),
      ],
      if (yesterdayTasks.isNotEmpty) ...[
        _buildDateSection('Yesterday', yesterdayTasks),
      ],
    ];
  }

  Widget _buildDateSection(String title, List<Map<String, dynamic>> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        SizedBox(height: 12),
        ...tasks.map((task) => _buildHistoryItem(task)).toList(),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> task) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.check_circle, color: Colors.green),
        title: Text(task['title'] ?? 'No Title'),
        subtitle: Text(task['category'] ?? 'No Category'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}