import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false);

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching tasks: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateTask() async {
    try {
      final response = await _supabase
          .from('tasks')
          .insert({
            'user_id': _supabase.auth.currentUser!.id,
            'title': 'New Task',
            'category': 'Health',
            'description': 'Auto-generated task',
            'is_completed': false,
          })
          .select();

      if (response.isNotEmpty) {
        _fetchTasks(); // Refresh task list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task generated successfully!')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating task: $error')),
      );
    }
  }

  Future<void> _completeTask(String taskId) async {
    try {
      await _supabase
          .from('tasks')
          .update({'is_completed': true, 'completed_at': DateTime.now().toIso8601String()})
          .eq('id', taskId);

      _fetchTasks(); // Refresh task list
    } catch (error) {
      print('Error completing task: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Homepage'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section dengan Generate Task Button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you ready to do some task?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Generate some from the button below!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _generateTask,
                          child: Text('GENERATE TASK'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Task List
                  Text(
                    'Your Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  ..._tasks.map((task) => _buildTaskItem(task)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(task['category']),
            shape: BoxShape.circle,
          ),
          child: Icon(_getCategoryIcon(task['category']), color: Colors.white, size: 20),
        ),
        title: Text(task['category'] ?? 'No Category'),
        subtitle: Text(task['title'] ?? 'No Title'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!(task['is_completed'] ?? false))
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () => _completeTask(task['id']),
              ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Health':
        return Colors.green;
      case 'Social':
        return Colors.blue;
      case 'Literature':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Health':
        return Icons.favorite;
      case 'Social':
        return Icons.people;
      case 'Literature':
        return Icons.book;
      default:
        return Icons.task;
    }
  }
}