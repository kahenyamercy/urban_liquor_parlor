// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:urban_liquor_parlor/services/supabase_auth.dart';
import '../config/supabase_config.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'rider/rider_screen.dart';

class AgeGateScreen extends StatefulWidget {
  const AgeGateScreen({super.key});

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUpMode = false; // Starts in Log In mode by default
  DateTime? _selectedDob;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2008),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password.');
      return;
    }

    if (_isSignUpMode && name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }

    if (_isSignUpMode && _selectedDob == null) {
      setState(() => _errorMessage = 'Please select your date of birth.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUpMode) {
        await _authService.signUp(
          email: email,
          password: password,
          dateOfBirth: _selectedDob!,
          fullName: name,
        );

        if (!mounted) return;

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'Verify Your Email',
              style: TextStyle(
                color: Color(0xFF3F51B5),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'We have sent a verification link to:\n$email\n\nPlease check your inbox to activate your account before logging in.',
              style: const TextStyle(color: Color(0xFF3F51B5), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'LOG IN',
                  style: TextStyle(
                    color: Color(0xFF3F51B5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (!mounted) return;

        setState(() {
          _isSignUpMode = false;
          _errorMessage = null;
        });

        return;
      }

      await _authService.signIn(email: email, password: password);

      if (!mounted) return;

      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', currentUser.id)
            .maybeSingle();

        final role = profile?['role'] as String? ?? 'customer';

        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else if (role == 'rider') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RiderScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'URBAN LIQUOR',
                style: TextStyle(
                  color: Color(0xFF009688),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'WHISKEY · BEER · WINES · SPIRITS',
                style: TextStyle(
                  color: Color.fromARGB(255, 12, 228, 210),
                  fontSize: 11,
                  letterSpacing: 3,
                ),
              ),
              
              const SizedBox(height: 32),
              Text(
                _isSignUpMode ? "Create Account" : "Welcome Back",
                style: const TextStyle(color: Color(0xFFE6E6FA), fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUpMode
                    ? 'You must be 18 or older to register.'
                    : 'Log in to access your profile.',
                style: const TextStyle(color: Color(0xFFE6E6FA), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Only display Name field if signing up
              if (_isSignUpMode) ...[
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                  decoration: _inputDecoration('Full Name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: _emailController,
                style: const TextStyle(color: Color(0xFFFFFFFF)),
                decoration: _inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Color(0xFFFFFFFF)),
                decoration: _inputDecoration('Password'),
                obscureText: true,
                textInputAction: _isSignUpMode
                    ? TextInputAction.next
                    : TextInputAction.done,
                onSubmitted: (_) => _isSignUpMode ? null : _submit(),
              ),
              const SizedBox(height: 12),

              // Only display Date of Birth Picker if signing up
              if (_isSignUpMode) ...[
                GestureDetector(
                  onTap: _pickDob,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF3F51B5).withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDob == null
                              ? 'Select date of birth'
                              : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                          style: TextStyle(
                            color: _selectedDob == null
                                ? const Color(0xFFCAF0EC)
                                : const Color(0xFFCAF0EC),
                            fontSize: 14,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_month,
                          color: Color(0xFFFFFFFF),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFE6E6FA),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4169E1)),
                    foregroundColor: const Color(0xFFE6E6FA),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFFFFFF),
                          ),
                        )
                      : Text(
                          _isSignUpMode ? 'REGISTER' : 'LOG IN',
                          style: const TextStyle(letterSpacing: 2),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Mode Toggler Text Link
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUpMode = !_isSignUpMode;
                    _errorMessage =
                        null; // Clear old errors when flipping modes
                  });
                },
                child: Text(
                  _isSignUpMode
                      ? "Already have an account? Log In"
                      : " Create an Account",
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFFFFFFF)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: const Color(0xFF4169E1).withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF4169E1)),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
