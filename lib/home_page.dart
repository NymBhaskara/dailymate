import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; // Diperlukan untuk fitur Random

// Import halaman lain untuk navigasi
import 'history_page.dart';
import 'profile_page.dart';

// --- BAGIAN 1: KONTEN UTAMA HOME (Logika Task & XP) ---
// (Dulu namanya HomePage, sekarang kita ganti jadi HomeContent agar bisa dibungkus navigasi)
class HomeContent extends StatefulWidget {
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
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
          .from('user_tasks')
          .select('*')
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_completed', false) // Hanya ambil yang belum selesai
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _activeTasks = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching tasks: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logika Generate Random Task sesuai Kategori
  Future<void> _showCategorySelector() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _categoryButton('Health', Icons.favorite, Colors.green),
                  _categoryButton('Social', Icons.people, Colors.blue),
                  _categoryButton('Literature', Icons.book, Colors.orange),
                ],
              ),
              SizedBox(height: 10),
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
        throw Exception("There is no assignment data for this category in the database yet!");
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New task created successfully!')),
        );
      }

    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper untuk menentukan kolom database mana yang harus diupdate
  String _getXpColumn(String category) {
    switch (category) {
      case 'Health':
        return 'health_xp';
      case 'Social':
        return 'social_xp';
      case 'Literature':
        return 'lit_xp';
      default:
        return 'health_xp'; // Default fallback
    }
  }

  // Fungsi Complete Task dengan Logika XP
  Future<void> _completeTask(Map<String, dynamic> task) async {
    final int taskId = task['id'];
    final int xpReward = task['xp_reward'] ?? 0;
    final String category = task['category'];
    final String userId = _supabase.auth.currentUser!.id;

    setState(() => _isLoading = true);

    try {
      // 1. Update status tugas di tabel 'user_tasks' menjadi completed
      await _supabase
          .from('user_tasks')
          .update({
            'is_completed': true, 
            'completed_at': DateTime.now().toIso8601String()
          })
          .eq('id', taskId);

      // 2. Ambil data profil user saat ini
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      // Tentukan kolom mana yang mau ditambah
      final String targetColumn = _getXpColumn(category);
      
      // Hitung nilai baru
      final int currentXp = profileData[targetColumn] ?? 0;
      final int currentTotalTasks = profileData['total_tasks_completed'] ?? 0;
      
      // 3. Update tabel 'profiles' dengan XP baru
      await _supabase.from('profiles').update({
        targetColumn: currentXp + xpReward,
        'total_tasks_completed': currentTotalTasks + 1,
        'last_active_date': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // 4. Refresh tampilan list tugas
      await _fetchUserTasks(); 
      
      // 5. Tampilkan SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.yellow),
                SizedBox(width: 8),
                Text('Task completed! ${category} XP increased by $xpReward'),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (error) {
      print('Error completing task: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating XP: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold di sini TANPA AppBar, karena AppBar dikelola oleh HomePage Wrapper
    return Scaffold(
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
                        Text('Are you ready to do some task?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Generate some from the button below!', style: TextStyle(color: Colors.grey[600])),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showCategorySelector,
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
                  Text('Your Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _activeTasks.isEmpty 
                    ? Text("There are no active tasks yet", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
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
          onPressed: () => _completeTask(task),
          tooltip: "Mark as complete",
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

// --- BAGIAN 2: WRAPPER UTAMA (Navigasi Bawah) ---
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Daftar halaman untuk setiap tab navigasi
  final List<Widget> _pages = [
    HomeContent(), // Halaman Utama (Kode di atas)
    HistoryPage(), // Halaman History
    ProfilePage(), // Halaman Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dinamis sesuai tab yang aktif
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Hilangkan tombol back default
      ),
      
      // Menampilkan halaman sesuai tab yang dipilih
      body: _pages[_currentIndex],

      // Menu Navigasi Bawah
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'DailyMate';
      case 1: return 'History';
      case 2: return 'Profile';
      default: return 'DailyMate';
    }
  }
}