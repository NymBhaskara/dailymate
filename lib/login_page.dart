import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('🔄 Attempting sign in...');
      
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      print('✅ Sign in successful: ${response.user?.email}');
      
      // JANGAN gunakan Navigator di sini!
      // AuthWrapper akan otomatis redirect ke HomePage
      // karena auth state sudah berubah
      
    } on AuthException catch (error) {
      print('❌ Sign in error: ${error.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('🔄 Attempting sign up...');
      
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      print('✅ Sign up successful: ${response.user?.email}');
      
      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful! Please sign in.')),
        );
      }
    } on AuthException catch (error) {
      print('❌ Sign up error: ${error.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Test method untuk bypass login
  Future<void> _testLogin() async {
  try {
    setState(() {
      _isLoading = true;
    });
    
    print('🧪 Testing with demo account...');
    
    // Coba langsung sign in dengan demo account
    final signInResponse = await _supabase.auth.signInWithPassword(
      email: 'demo@example.com',
      password: 'demopassword123',
    );
    
    // ✅ SEKARANG MENGGUNAKAN RESPONSE:
    print('✅ Test login successful!');
    print('   Email: ${signInResponse.user?.email}');
    print('   User ID: ${signInResponse.user?.id}');
    print('   Session valid: ${signInResponse.session != null}');
    
  } on AuthException catch (e) {
    print('❌ Auth error: ${e.message}');
    
    // Jika user tidak ditemukan, buat akun demo
    if (e.message.contains('Invalid login credentials')) {
      try {
        print('🔄 Creating demo account...');
        final signUpResponse = await _supabase.auth.signUp(
          email: 'demo@example.com',
          password: 'demopassword123',
        );
        
        if (signUpResponse.user != null) {
          print('✅ Demo account created. Please click "Quick Test" again.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Demo account created! Please click "Quick Test" again to login.')),
          );
        }
      } catch (signUpError) {
        print('❌ Failed to create demo account: $signUpError');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test login failed: ${e.message}')),
      );
    }
  } catch (e) {
    print('❌ Unexpected error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Test login failed: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'DailyMate',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your Daily Task Manager',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 24),
            if (_isLoading)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Signing in...'),
                ],
              )
            else
              Column(
                children: [
                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signIn,
                      child: Text('Sign In'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _signUp,
                      child: Text('Sign Up'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Test Login Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _testLogin,
                      child: Text('Quick Test (Demo Account)'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}