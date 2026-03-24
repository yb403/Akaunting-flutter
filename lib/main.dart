import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String email = prefs.getString('email') ?? '';
  String password = prefs.getString('password') ?? '';
  bool isLoggedIn = email.isNotEmpty && password.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: isLoggedIn 
          ? const MainScreen()
          : const LoginPage(),
    );
  }
}

