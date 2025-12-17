import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  bool _isUploading = false;
  String _username = 'Loading...';
  String _email = '';
  String? _avatarUrl; // Biar bisa kosong
  int _healthXp = 0;
  int _socialXp = 0;
  int _litXp = 0;
  int _totalTasks = 0;

  @override
  void initState() {
    super.initState();
    _getProfileData();
  }

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
          _avatarUrl = data['avatar_url']; // Ambil URL dari DB
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

  // 1. USERNAME UPDATE LOGIC
  Future<void> _updateProfileName(String newName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('profiles').update({'username': newName}).eq('id', user.id);
      if (mounted) {
        setState(() => _username = newName);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Username updated!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    // 1. Ambil gambar
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );

    if (imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 2. Read bytes safely
      final fileBytes = await imageFile.readAsBytes();

      // 3. Determine clean file extension & content type
      String fileExt = 'jpg';
      String contentType = 'image/jpeg';
      
      if (imageFile.mimeType != null) {
          contentType = imageFile.mimeType!;
          fileExt = contentType.split('/').last;
      } else if (imageFile.name.contains('.')) {
          // parsing nama
          fileExt = imageFile.name.split('.').last;
          contentType = 'image/$fileExt';
      }

      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 4. Upload ke Supabase
      await _supabase.storage.from('avatars').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true
        ),
      );

      // 5. Ambil public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // 6. Update Profile
      await _supabase.from('profiles').update({
        'avatar_url': imageUrl,
      }).eq('id', user.id);

      if (mounted) {
        setState(() {
          _avatarUrl = imageUrl;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Avatar updated!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Upload Error: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final TextEditingController _nameController = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Username'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateProfileName(_nameController.text.trim());
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  int _calculateLevel(int xp) => (xp / 100).floor() + 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 10),
                
                //UI dengan 'Working' update button
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[100],
                      backgroundImage: _avatarUrl != null 
                          ? NetworkImage(_avatarUrl!) 
                          : null,
                      child: _avatarUrl == null
                          ? Text(
                              _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                              style: TextStyle(fontSize: 40, color: Colors.blue),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _uploadAvatar,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: _isUploading 
                              ? Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(Icons.camera_alt, size: 20, color: Colors.grey[800]),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // --- USERNAME WITH EDIT ICON ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _username,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 18, color: Colors.grey),
                      onPressed: _showEditProfileDialog,
                      splashRadius: 20,
                    )
                  ],
                ),
                
                Text(_email, style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 12),
                Chip(
                  label: Text("Total Tasks Completed: $_totalTasks"),
                  backgroundColor: Colors.blue[50],
                  labelStyle: TextStyle(color: Colors.blue[900]),
                ),
                
                SizedBox(height: 32),
                Align(alignment: Alignment.centerLeft, child: Text("Mastery Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                SizedBox(height: 12),
                _buildMasteryCard("Health", _healthXp, Colors.green, Icons.favorite),
                _buildMasteryCard("Social", _socialXp, Colors.blue, Icons.people),
                _buildMasteryCard("Literature", _litXp, Colors.orange, Icons.book),
                SizedBox(height: 24),
                _buildMenuButton('Help Center', Icons.help, () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Contact admin")))),
                SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async => await _supabase.auth.signOut(),
                    child: Text('LOG OUT'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red, padding: EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMasteryCard(String category, int xp, Color color, IconData icon) {
      int level = _calculateLevel(xp);
      double progress = (xp % 100) / 100;
      return Card(
        child: Padding(padding: EdgeInsets.all(12), child: Column(children: [Row(children: [Icon(icon, color: color), SizedBox(width: 8), Text("$category: Level $level")]), LinearProgressIndicator(value: progress, color: color)])),
      );
  }

  Widget _buildMenuButton(String title, IconData icon, VoidCallback onTap) {
      return Card(child: ListTile(leading: Icon(icon), title: Text(title), onTap: onTap));
  }
}