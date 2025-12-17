import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  String _username = 'Loading...';
  String _email = '';
  int _healthXp = 0;
  int _socialXp = 0;
  int _litXp = 0;
  int _totalTasks = 0;

  @override
  void initState() {
    super.initState();
    _getProfileData();
  }

  // Ambil data profil dari Supabase
  Future<void> _getProfileData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _username = data['username'] ?? 'User';
          _email = user.email ?? '-';
          _healthXp = data['health_xp'] ?? 0;
          _socialXp = data['social_xp'] ?? 0;
          _litXp = data['lit_xp'] ?? 0;
          _totalTasks = data['total_tasks_completed'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateLevel(int xp) {
    return (xp / 100).floor() + 1; // Level naik setiap 100 XP
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold TANPA AppBar
    return Scaffold(
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 10),
                // 1. Profile Header (Real Data)
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                    style: TextStyle(fontSize: 40, color: Colors.blue),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _username,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  _email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 12),
                Chip(
                  label: Text("Total Tasks Completed: $_totalTasks"),
                  backgroundColor: Colors.blue[50],
                  labelStyle: TextStyle(color: Colors.blue[900]),
                ),
                
                SizedBox(height: 32),
                
                // 2. Mastery / XP Section (Pengganti tombol Mastery yang tidak bisa diklik)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Mastery Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 12),
                _buildMasteryCard("Health", _healthXp, Colors.green, Icons.favorite),
                _buildMasteryCard("Social", _socialXp, Colors.blue, Icons.people),
                _buildMasteryCard("Literature", _litXp, Colors.orange, Icons.book),

                SizedBox(height: 24),
                
                // 3. Menu Lainnya (Placeholder)
                _buildMenuButton('Edit Profile', Icons.edit, () {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("The Edit Profile feature is not yet available")));
                }),
                _buildMenuButton('Help Center', Icons.help, () {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Contact admin@dailymate.com")));
                }),
                
                SizedBox(height: 32),
                
                // 4. Logout Button (Berfungsi)
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _supabase.auth.signOut();
                      // Redirect ditangani oleh AuthWrapper di main.dart
                    },
                    child: Text('LOG OUT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  // Widget Kartu Mastery (Progress Bar)
  Widget _buildMasteryCard(String category, int xp, Color color, IconData icon) {
    int level = _calculateLevel(xp);
    double progress = (xp % 100) / 100; // 0.0 sampai 1.0

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Level $level • $xp XP", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text("${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Tombol Menu Biasa
  Widget _buildMenuButton(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}