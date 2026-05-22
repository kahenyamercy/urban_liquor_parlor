import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urban_liquor_parlor/services/supabase_auth.dart';

import '../config/supabase_config.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'rider/rider_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  DateTime? _selectedDob;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year - 18), 
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Color(0xFF1A1A2E),
              surface: Color(0xFF22223B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
      );
    if (picked != null) setState(() => _selectedDob = picked);
  }
  bool _isOldEnough(DateTime dob) {
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill out email and password.');
      return;
      }

    if (!_isLogin) {
      if (name.isEmpty) {
        setState(() => _error = 'Please enter your full name.');
        return;
      }
      if (_selectedDob == null) {
        setState(() => _error = 'Please select your date of birth.');
        return;
      }
      if (!_isOldEnough(_selectedDob!)) {
        setState(() => _error = 'Access Denied. You must be 18 or older to register.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await _authService.signIn(
          email: email,
          password: password,
        );
      } else {
        // AFTER
await _authService.signUp(
  email: email,
  password: password,
  fullName: name,
  dateOfBirth: _selectedDob!,
);

final signedInUser = supabase.auth.currentUser;

if (signedInUser == null) {
  // No active session yet — email verification required
  if (!mounted) return;
  _showVerificationDialog(email);
  return;
}

await supabase.from('profiles').upsert({
  'id': signedInUser.id,
  'full_name': name,
  'role': 'customer',
});
      }
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        _showVerificationDialog(email);
        setState(() => _error = 'Could not find authenticated user session.');
        return;
      }
      final userId = currentUser.id;
      print('🔍 Looking up profile for: $userId');
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final role = profile?['role'] as String? ?? 'customer';
      print('✅ Logged in. Role: $role');          

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
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      setState(() => _error = e.message);
    } catch (e) {
      print('❌ Unexpected error: $e');
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Verify Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'An activation link has been sent to:\n$email\n\nPlease check your inbox to confirm your account details.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLogin = true;
                _error = null;
              });
            },
            child: const Text('OK, SIGN IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.liquor, color: Colors.white, size: 36),
                const SizedBox(height: 24),

                Text(
                  _isLogin ? 'Welcome back' : 'Create account',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Sign in to continue'
                      : 'Sign up to start ordering',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 36),

                // Name field — register only
                if (!_isLogin) ...[
                  _buildField(
                    _nameController,
                    'Full name',
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _pickDob,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDob == null
                                    ? 'Date of birth'
                                    : '${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}',
                                style: TextStyle(
                                  color: _selectedDob == null 
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : Colors.white,
                                      fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.white54),
                          ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                _buildField(
                  _emailController,
                  'Email',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _buildField(
                  _passwordController,
                  'Password',
                  Icons.lock_outline,
                  obscure: true,
                ),

                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A1A2E),
                            ),
                          )
                        : Text(
                            _isLogin ? 'Sign in' : 'Create account',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Toggle login / register
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                    }),
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Register"
                          : 'Already have an account? Sign in',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
