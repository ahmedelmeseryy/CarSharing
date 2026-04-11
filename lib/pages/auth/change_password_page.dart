import 'package:flutter/material.dart';
import 'package:carsharing/features/auth/data/services/auth_api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // Step 1: verify current password. Step 2: enter new password.
  int _step = 1;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Stored after step 1 to use in the final API call
  String _verifiedCurrentPassword = '';

  @override
  void dispose() {
    _currentPasswordController.dispose();
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

  /// Step 1: attempt a change-password call with a placeholder new password
  /// to verify the current password is correct before showing step 2.
  Future<void> _verifyCurrentPassword() async {
    final current = _currentPasswordController.text;
    if (current.isEmpty) {
      _showError('Please enter your current password.');
      return;
    }
    setState(() => _loading = true);
    try {
      // We verify by attempting the change with a temporarily invalid new password.
      // The server returns 401 if current password is wrong, 400 for bad new password.
      // If we get 400, current password is correct — proceed to step 2.
      await AuthApiService().changePassword(
        currentPassword: current,
        newPassword: '__VERIFY__',
      );
      // Unlikely to succeed with a dummy password, but handle it just in case
      if (!mounted) return;
      setState(() { _loading = false; _step = 2; _verifiedCurrentPassword = current; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final message = e.toString().toLowerCase();
      if (message.contains('401') || message.contains('unauthorized') || message.contains('incorrect') || message.contains('invalid')) {
        _showError('Current password is incorrect. Please try again.');
      } else {
        // Any non-401 error (like 400 bad request for invalid new password)
        // means the current password was accepted — move to step 2
        setState(() { _step = 2; _verifiedCurrentPassword = current; });
      }
    }
  }

  Future<void> _submitNewPassword() async {
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    final passwordError = _validatePassword(newPassword);
    if (passwordError != null) { _showError(passwordError); return; }
    if (newPassword != confirm) { _showError('Passwords do not match.'); return; }
    if (newPassword == _verifiedCurrentPassword) {
      _showError('New password must be different from your current password.');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthApiService().changePassword(
        currentPassword: _verifiedCurrentPassword,
        newPassword: newPassword,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Failed to change password. Please try again.');
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
      appBar: AppBar(title: const Text('Change Password')),
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
        const Icon(Icons.lock_outline, size: 72, color: Colors.blue),
        const SizedBox(height: 24),
        const Text('Verify your identity',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text(
          'Enter your current password to continue.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _currentPasswordController,
          decoration: InputDecoration(
            labelText: 'Current Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
          obscureText: _obscureCurrent,
        ),
        const SizedBox(height: 24),
        _loading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _verifyCurrentPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.lock_reset, size: 72, color: Colors.green),
        const SizedBox(height: 24),
        const Text('Set new password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text(
          'Current password verified. Enter your new password below.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
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
                onPressed: _submitNewPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Change Password', style: TextStyle(fontSize: 16)),
              ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _step = 1;
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
          }),
          child: const Text('Back'),
        ),
      ],
    );
  }
}
