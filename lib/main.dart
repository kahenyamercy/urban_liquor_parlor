import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://svknqvvmcgklwbqzcfah.supabase.co',        // paste your URL here
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN2a25xdnZtY2drbHdicXpjZmFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzNDYzMzAsImV4cCI6MjA5MTkyMjMzMH0.pXEihrJTahkBDUcR7XdJgATWMHnjoqUxa27zVUwiFvc', // paste your key here
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Liquor Parlor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Urban Liquor Parlor',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}