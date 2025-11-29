import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Text(
              'User Name',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'user@example.com',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 32),
            
            // Menu Items
            _buildProfileMenuItem('Mastery', Icons.workspace_premium),
            _buildProfileMenuItem('Edit Profile', Icons.edit),
            _buildProfileMenuItem('Task History', Icons.history),
            _buildProfileMenuItem('Help Center', Icons.help),
            
            SizedBox(height: 32),
            
            // Generate Task Buttons
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text('GENERATE TASK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text('GENERATE TASK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text('GENERATE TASK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Logout Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: Text('LOG OUT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(String title, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}