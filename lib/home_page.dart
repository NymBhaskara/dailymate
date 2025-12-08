import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; // Diperlukan untuk fitur Random

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activeTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserTasks();
  }

  // Ambil tugas milik user dari tabel 'user_tasks'
  Future<void> _fetchUserTasks() async {
    try {
      final response = await _supabase
          .from('user_tasks') // TABEL BARU
          .select('*')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_completed', false) // Hanya ambil yang belum selesai
          .order('created_at', ascending: false);

      setState(() {
        _activeTasks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching tasks: $error');
      setState(() => _isLoading = false);
    }
  }

  // Logika Generate Random Task sesuai Kategori
  Future<void> _showCategorySelector() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pilih Kategori Fokus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _categoryButton('Health', Icons.favorite, Colors.green),
                  _categoryButton('Social', Icons.people, Colors.blue),
                  _categoryButton('Literature', Icons.book, Colors.orange),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryButton(String category, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Tutup modal
        _generateRandomTask(category); // Generate task
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 8),
          Text(category, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _generateRandomTask(String category) async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil Pool Task dari tabel 'tasks' berdasarkan kategori
      final List<dynamic> poolResponse = await _supabase
          .from('tasks') // Ambil dari Master Data
          .select()
          .eq('category', category);

      if (poolResponse.isEmpty) {
        throw Exception("Belum ada data tugas untuk kategori ini di database!");
      }

      // 2. Pilih 1 secara ACAK
      final randomTask = (poolResponse..shuffle()).first;

      // 3. Masukkan ke tabel 'user_tasks'
      await _supabase.from('user_tasks').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'task_reference_id': randomTask['id'],
        'title': randomTask['title'],
        'category': randomTask['category'],
        'xp_reward': randomTask['xp_reward'],
        'is_completed': false,
      });

      // 4. Refresh tampilan
      await _fetchUserTasks();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tugas baru berhasil dibuat! Semangat!')),
      );

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeTask(int id) async {
    try {
      await _supabase
          .from('user_tasks')
          .update({
            'is_completed': true, 
            'completed_at': DateTime.now().toIso8601String()
          })
          .eq('id', id);

      _fetchUserTasks(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tugas selesai! XP bertambah (logic next)')),
      );
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
          IconButton(icon: Icon(Icons.logout), onPressed: () async { await _supabase.auth.signOut(); }),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AREA GENERATE TASK
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
                        Text('Siap untuk berkembang hari ini?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Pilih kategori dan dapatkan tugas harianmu!', style: TextStyle(color: Colors.grey[600])),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showCategorySelector, // Munculkan pilihan kategori
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
                  
                  // LIST TUGAS AKTIF
                  Text('Tugas Aktif Kamu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _activeTasks.isEmpty 
                    ? Text("Belum ada tugas aktif. Generate sekarang!", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                    : Column(children: _activeTasks.map((task) => _buildTaskItem(task)).toList()),
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
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: _getCategoryColor(task['category']).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_getCategoryIcon(task['category']), color: _getCategoryColor(task['category']), size: 20),
        ),
        title: Text(task['title'] ?? 'No Title'),
        subtitle: Text("${task['category']} • +${task['xp_reward']} XP"),
        trailing: IconButton(
          icon: Icon(Icons.check_circle_outline, color: Colors.grey, size: 32),
          onPressed: () => _completeTask(task['id']),
          tooltip: "Tandai Selesai",
        ),
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Health': return Colors.green;
      case 'Social': return Colors.blue;
      case 'Literature': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Health': return Icons.favorite;
      case 'Social': return Icons.people;
      case 'Literature': return Icons.book;
      default: return Icons.task;
    }
  }
}