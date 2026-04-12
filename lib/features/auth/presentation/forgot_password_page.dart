import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:carsharing/features/auth/data/services/auth_api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Step 1: send email. Step 2: enter token + new password.
  int _step = 1;

  late final TextEditingController _emailController;
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'At least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'At least one uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'At least one number';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'At least one special character';
    }
    return null;
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (!EmailValidator.validate(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthApiService().resetPassword(email);
      if (!mounted) return;
      setState(() { _loading = false; _step = 2; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset code sent! Check your email.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Failed to send reset email. Please try again.');
    }
  }

  Future<void> _confirmReset() async {
    final token = _tokenController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (token.isEmpty) { _showError('Please enter the reset code.'); return; }
    final passwordError = _validatePassword(newPassword);
    if (passwordError != null) { _showError(passwordError); return; }
    if (newPassword != confirm) { _showError('Passwords do not match.'); return; }

    setState(() => _loading = true);
    try {
      await AuthApiService().confirmResetPassword(token: token, newPassword: newPassword);
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please log in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Invalid or expired reset code. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _step == 1 ? _buildStep1() : _buildStep2(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.lock_reset, size: 72, color: Colors.blue),
        const SizedBox(height: 24),
        const Text('Reset your password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text(
          'Enter your email address and we will send you a reset code.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _sendResetEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Send Reset Code', style: TextStyle(fontSize: 16)),
              ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.mark_email_read_outlined, size: 72, color: Colors.green),
        const SizedBox(height: 24),
        const Text('Enter reset code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'We sent a code to ${_emailController.text.trim()}. Enter it below along with your new password.',
          style: const TextStyle(color: Colors.grey, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _tokenController,
          decoration: const InputDecoration(
            labelText: 'Reset Code',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            helperText: 'Min 8 chars, 1 uppercase, 1 number, 1 special character',
            helperMaxLines: 2,
          ),
          obscureText: _obscureNew,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          obscureText: _obscureConfirm,
        ),
        const SizedBox(height: 24),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _confirmReset,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Reset Password', style: TextStyle(fontSize: 16)),
              ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Resend Code'),
        ),
      ],
    );
  }
}
