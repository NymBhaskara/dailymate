import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 APP STARTING...');
  
  try {
    // ⚠️ GANTI DENGAN CREDENTIALS ANDA!
    const supabaseUrl = 'https://akeymbccmvylyzsutswc.supabase.co/';
    const supabaseAnonKey = 'sb_publishable_H_KAEWSGzeIP5-h_twFZNg_Rkc-pQjP'; // full key
    
    // if (supabaseUrl.contains('akeymbccmvylyzsutswc') || 
    //     supabaseAnonKey.contains('sb_publishable_H_KAEWSGzeIP5-h_twFZNg_Rkc-pQjP')) {
    //   throw Exception('Please replace with your actual Supabase credentials!');
    // }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    print('✅ Supabase initialized');
    runApp(MyApp());
  } catch (e) {
    print('❌ Error: $e');
    runApp(ErrorApp(error: 'Setup error: $e\n\nPlease check main.dart for hardcoded credentials.'));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tambahkan ini
      title: 'Task App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
      routes: {
        '/home': (context) => HomePage(),
        '/history': (context) => HistoryPage(),
        '/profile': (context) => ProfilePage(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        print('🔄 Auth stream state: ${snapshot.connectionState}');
        print('📊 Auth has data: ${snapshot.hasData}');
        print('❌ Auth has error: ${snapshot.hasError}');
        
        if (snapshot.hasError) {
          print('🔥 Auth error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text('Auth Error: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => LoginPage())
                    ),
                    child: Text('Go to Login'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Jika masih loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking authentication...'),
                ],
              ),
            ),
          );
        }
        
        // Cek session
        final session = Supabase.instance.client.auth.currentSession;
        final user = Supabase.instance.client.auth.currentUser;
        
        print('🔐 Session: $session');
        print('👤 User: $user');
        
        if (session != null) {
          print('✅ User is authenticated, going to HomePage');
          return HomePage();
        } else {
          print('🔓 User not authenticated, going to LoginPage');
          return LoginPage();
        }
      },
    );
  }
}

// Fallback error app
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'App Failed to Start',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart
                    runApp(MyApp());
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}