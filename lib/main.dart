import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'screens/journal_screen.dart';
import 'screens/auth_screen.dart';
import 'theme.dart'; // 👈 import your modular theme setup

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JournalApp());
}

class JournalApp extends StatelessWidget {
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journal',
      themeMode: ThemeMode.system, // 👈 respond to system theme
      theme: lightTheme,
      darkTheme: darkTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: SizedBox.shrink(), // Replaced CircularProgressIndicator
            );
          }
          return snapshot.hasData ? const JournalScreen() : const AuthScreen();
        },
      ),
    );
  }
}
