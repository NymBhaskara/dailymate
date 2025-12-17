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
          .from('user_tasks')
          .select('*')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_completed', true) // Ambil yang sudah selesai
          .order('completed_at', ascending: false);

      if (mounted) {
        setState(() {
          _completedTasks = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching completed tasks: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold TANPA AppBar (karena sudah ada di HomePage wrapper)
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  _completedTasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: Text("No completed tasks yet.", style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    : Column(children: _buildTaskGroups()),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildTaskGroups() {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    
    // Helper untuk membandingkan tanggal
    bool isSameDay(DateTime d1, DateTime d2) {
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    }

    final todayTasks = _completedTasks.where((task) {
      if (task['completed_at'] == null) return false;
      return isSameDay(DateTime.parse(task['completed_at']).toLocal(), now);
    }).toList();
    
    final yesterdayTasks = _completedTasks.where((task) {
      if (task['completed_at'] == null) return false;
      return isSameDay(DateTime.parse(task['completed_at']).toLocal(), yesterday);
    }).toList();

    // Tugas lama (lebih dari kemarin)
    final olderTasks = _completedTasks.where((task) {
       if (task['completed_at'] == null) return false;
       final date = DateTime.parse(task['completed_at']).toLocal();
       return !isSameDay(date, now) && !isSameDay(date, yesterday);
    }).toList();

    return [
      if (todayTasks.isNotEmpty) ...[
        _buildDateSection('Today', todayTasks),
        SizedBox(height: 24),
      ],
      if (yesterdayTasks.isNotEmpty) ...[
        _buildDateSection('Yesterday', yesterdayTasks),
        SizedBox(height: 24),
      ],
      if (olderTasks.isNotEmpty) ...[
         _buildDateSection('Older', olderTasks),
      ]
    ];
  }

  Widget _buildDateSection(String title, List<Map<String, dynamic>> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
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
        subtitle: Text("${task['category']} • +${task['xp_reward'] ?? 0} XP"),
        // trailing: Icon(Icons.arrow_forward_ios, size: 16), // Opsional
      ),
    );
  }
}