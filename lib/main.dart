import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/secure_storage.dart';
import 'dashboard_page.dart';
import 'user_dashboard_page.dart';
import 'driver_dashboard_page.dart';
import 'ride_list_page.dart';
import 'core/pages/api_debug_screen.dart';
import 'rest_integration_tester.dart';
import 'features/auth/data/services/auth_api_service.dart';
import 'admin_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kamili Drive',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.grey[800]),
          titleTextStyle: TextStyle(
            color: Colors.grey[800],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/user-dashboard': (context) => const UserDashboardPage(),
        '/driver-dashboard': (context) => const DriverDashboardPage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/rides': (context) => const RideListPage(),
        '/profile': (context) => const ProfilePage(),
        '/api-debug': (context) => const ApiDebugScreen(),
        '/rest-integration': (context) => const RestIntegrationTester(),
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              const Icon(Icons.directions_car, size: 120, color: Colors.white),
              const SizedBox(height: 24),
            const Text(
                'Welcome to Kamili Drive!',
              textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Find your perfect ride.',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                  ),
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                child: const Text(
                  'Already have an account? Log In',
                  style: TextStyle(color: Colors.white),
                ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  final TextEditingController _carYearController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'user'; // 'user' or 'driver'

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? _validateRepeatPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please repeat your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await AuthApiService().register(
          email: _mailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          age: _ageController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole,
          carModel: _selectedRole == 'driver' ? _carModelController.text.trim() : null,
          carColor: _selectedRole == 'driver' ? _carColorController.text.trim() : null,
          carYear: _selectedRole == 'driver' ? _carYearController.text.trim() : null,
          licenseNumber: _selectedRole == 'driver' ? _licenseNumberController.text.trim() : null,
        );

        await TokenStorage().saveUserProfile(
          email: _mailController.text.trim(),
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          age: _ageController.text.trim(),
          phone: _phoneController.text.trim(),
          carModel: _selectedRole == 'driver' ? _carModelController.text.trim() : null,
          carColor: _selectedRole == 'driver' ? _carColorController.text.trim() : null,
          carYear: _selectedRole == 'driver' ? _carYearController.text.trim() : null,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (_selectedRole == 'driver') {
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
        } else if (_selectedRole == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Let's get started!",
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Create an account to continue.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Role Selection
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                          const Text(
                            'Account Type',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          RadioGroup<String>(
                            groupValue: _selectedRole,
                            onChanged: (value) {
                              if (value != null) setState(() => _selectedRole = value);
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('User'),
                                    subtitle: const Text('Book rides'),
                                    value: 'user',
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Driver'),
                                    subtitle: const Text('Offer rides'),
                                    value: 'driver',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Name*'),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Name is required'
                        : null,
              ),
              const SizedBox(height: 16),
                  TextFormField(
                    controller: _surnameController,
                    decoration:
                        const InputDecoration(labelText: 'Surname*'),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Surname is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration:
                        const InputDecoration(labelText: 'Age*'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Age is required';
                      final age = int.tryParse(value!);
                      if (age == null || age < 18) {
                        return 'Must be at least 18 years old';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mailController,
                    decoration: const InputDecoration(
                        labelText: 'Email*'),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration:
                        const InputDecoration(labelText: 'Password*'),
                    obscureText: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _repeatPasswordController,
                    decoration: const InputDecoration(
                        labelText: 'Repeat Password*'),
                    obscureText: true,
                    validator: _validateRepeatPassword,
                  ),
                  
                  // Driver-specific fields
                  if (_selectedRole == 'driver') ...[
              const SizedBox(height: 24),
                    const Text(
                      'Driver Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _carModelController,
                      decoration: const InputDecoration(
                          labelText: 'Car Model*'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Car model is required for drivers'
                          : null,
              ),
              const SizedBox(height: 16),
                    TextFormField(
                      controller: _carColorController,
                      decoration: const InputDecoration(
                          labelText: 'Car Color*'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Car color is required for drivers'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _carYearController,
                      decoration: const InputDecoration(
                          labelText: 'Car Year*'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Car year is required';
                        final year = int.tryParse(value!);
                        if (year == null || year < 1900 || year > DateTime.now().year) {
                          return 'Please enter a valid car year';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseNumberController,
                      decoration: const InputDecoration(
                          labelText: 'Driver License Number*'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'License number is required for drivers'
                          : null,
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _signUp,
                          child: const Text('Sign Up'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await AuthApiService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final storage = TokenStorage();
      final role = await storage.getUserRole() ?? 'user';

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (role == 'driver') {
        Navigator.pushReplacementNamed(context, '/driver-dashboard');
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/user-dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!EmailValidator.validate(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    // the reset password feature is not codded in API yet

    // try {
    //   await AuthApiService().resetPassword(email);
    //   if (!mounted) return;
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Password reset email sent! Check your inbox.'),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    // } catch (e) {
    //   if (!mounted) return;
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Failed to send reset email.')),
    //   );
    // }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                const Text(
                  "Welcome Back!",
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Log in to your account to continue.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
            TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Log In'),
                      ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Forgot Password?'),
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


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  final TextEditingController _carYearController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = true;
  String _userRole = 'user';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final storage = TokenStorage();
    _nameController.text = await storage.getUserName() ?? '';
    _surnameController.text = await storage.getUserSurname() ?? '';
    _ageController.text = await storage.getUserAge() ?? '';
    _phoneController.text = await storage.getUserPhone() ?? '';
    _userRole = await storage.getUserRole() ?? 'user';
    _email = await storage.getUserEmail() ?? '';
    if (_userRole == 'driver') {
      _carModelController.text = await storage.getUserCarModel() ?? '';
      _carColorController.text = await storage.getUserCarColor() ?? '';
      _carYearController.text = await storage.getUserCarYear() ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await TokenStorage().saveUserProfile(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          age: _ageController.text.trim(),
          phone: _phoneController.text.trim(),
          carModel: _userRole == 'driver' ? _carModelController.text.trim() : null,
          carColor: _userRole == 'driver' ? _carColorController.text.trim() : null,
          carYear: _userRole == 'driver' ? _carYearController.text.trim() : null,
        );
        if (!mounted) return;
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _logout(BuildContext context) async {
    await AuthApiService().logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.blue),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(Icons.person, size: 38, color: Colors.blue),
                        ),
                        const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                      Text(
                                        '${_nameController.text} ${_surnameController.text}',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                            const SizedBox(height: 4),
                                      Text(_email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.blue),
                                  onPressed: _isEditing ? _save : _toggleEdit,
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Name'),
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _surnameController,
                              decoration: const InputDecoration(labelText: 'Surname'),
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(labelText: 'Age'),
                            keyboardType: TextInputType.number,
                              enabled: _isEditing,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Phone'),
                              keyboardType: TextInputType.phone,
                              enabled: _isEditing,
                            ),
                            if (_userRole == 'driver') ...[
                              const Divider(height: 32),
                              const Text(
                                'Driver Information',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _carModelController,
                                decoration: const InputDecoration(labelText: 'Car Model'),
                                enabled: _isEditing,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _carColorController,
                                decoration: const InputDecoration(labelText: 'Car Color'),
                                enabled: _isEditing,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _carYearController,
                                decoration: const InputDecoration(labelText: 'Car Year'),
                                keyboardType: TextInputType.number,
                                enabled: _isEditing,
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Feature not yet implemented.')),
                                    );
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload Driver License'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.blue,
        backgroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                ),
              ),
            ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}
