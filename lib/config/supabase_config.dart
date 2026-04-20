import 'package:supabase_flutter/supabase_flutter.dart';

// Global Supabase client — import this file anywhere you need database access
final supabase = Supabase.instance.client;

const supabaseUrl = 'https://svknqvvmcgklwbqzcfah.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN2a25xdnZtY2drbHdicXpjZmFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzNDYzMzAsImV4cCI6MjA5MTkyMjMzMH0.pXEihrJTahkBDUcR7XdJgATWMHnjoqUxa27zVUwiFvc';