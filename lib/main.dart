import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/secure_storage.dart';
import 'dashboard_page.dart';
import 'user_dashboard_page.dart';
import 'driver_dashboard_page.dart';
import 'ride_list_page.dart';
import 'core/pages/api_debug_screen.dart';
import 'rest_integration_tester.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/data/services/auth_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/verify-email': (context) => const EmailVerificationPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/user-dashboard': (context) => const UserDashboardPage(),
        '/driver-dashboard': (context) => const DriverDashboardPage(),
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
        // Create user with Firebase Auth
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _mailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = userCredential.user;
        if (user == null) throw Exception('Failed to create user');

        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': _mailController.text.trim(),
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'age': _ageController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
          if (_selectedRole == 'driver') ...{
            'car_model': _carModelController.text.trim(),
            'car_color': _carColorController.text.trim(),
            'car_year': _carYearController.text.trim(),
            'license_number': _licenseNumberController.text.trim(),
          },
        });
        
        print('✅ REGISTRATION: User created with role: $_selectedRole');

        // Get Firebase ID token for REST API authorization
        final idToken = await user.getIdToken();
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Failed to get authentication token');
        }
        
        // Store token and user info in secure storage for REST API calls
        await TokenStorage().saveTokens(
          accessToken: idToken,
          refreshToken: idToken,
          userId: user.uid,
          userRole: _selectedRole,
        );

        if (!mounted) return;
        
        setState(() => _isLoading = false);
        
        // Navigate to appropriate dashboard based on role
        if (_selectedRole == 'driver') {
          Navigator.pushReplacementNamed(context, '/driver-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/user-dashboard');
        }
      } catch (e) {
        if (!mounted) return;
        
        setState(() => _isLoading = false);
        String message = 'Registration failed';
        
        if (e.toString().contains('email-already-in-use')) {
          message = 'Email already in use';
        } else if (e.toString().contains('weak-password')) {
          message = 'Password is too weak';
        } else if (e.toString().contains('invalid-email')) {
          message = 'Invalid email address';
        } else if (e.toString().contains('network')) {
          message = 'Network error. Please check your connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
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
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('User'),
                                  subtitle: const Text('Book rides'),
                                  value: 'user',
                                  groupValue: _selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Driver'),
                                  subtitle: const Text('Offer rides'),
                                  value: 'driver',
                                  groupValue: _selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
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
    final email = _emailController.text.trim();
    
    try {
      // Login with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to get user after login');

      // Get Firebase ID token for REST API authorization
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Failed to get authentication token');
      }
      
      // Get user role from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final role = userData?['role'] as String? ?? 'user';
      
      print('🔍 LOGIN DEBUG: User ID: ${user.uid}');
      print('🔍 LOGIN DEBUG: User Data: $userData');
      print('🔍 LOGIN DEBUG: Role: $role');
      
      // Store token and user info in secure storage for REST API calls
      await TokenStorage().saveTokens(
        accessToken: idToken,
        refreshToken: idToken,
        userId: user.uid,
        userRole: role,
      );

      if (!mounted) return;
      
      setState(() => _isLoading = false);

      print('🚗 NAVIGATION DEBUG: Role = $role');
      if (role == 'driver') {
        print('🚗 NAVIGATION: Pushing to /driver-dashboard');
        Navigator.pushReplacementNamed(context, '/driver-dashboard');
      } else {
        print('👤 NAVIGATION: Pushing to /user-dashboard');
        Navigator.pushReplacementNamed(context, '/user-dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      String message = 'Login failed';
      
      if (e.toString().contains('user-not-found')) {
        message = 'No user found with this email';
      } else if (e.toString().contains('wrong-password')) {
        message = 'Invalid email or password';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Invalid email address';
      } else if (e.toString().contains('network')) {
        message = 'Network error. Please check your connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      String message = 'Failed to send reset email';
      if (e.toString().contains('user-not-found')) {
        message = 'No account found with this email address.';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Invalid email address.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isVerified = false;
  bool _isLoading = false;
  bool _isResending = false;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _timer;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _checkVerification();
    });
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;
    if (user?.emailVerified ?? false) {
    setState(() {
      _isVerified = true;
        _isLoading = false;
      });
      _timer?.cancel();
      // Navigate to dashboard
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;
    
    setState(() {
      _isResending = true;
      _canResend = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        
        // Start cooldown timer
        _resendCooldown = 60; // 60 seconds cooldown
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _resendCooldown--;
          });
          if (_resendCooldown <= 0) {
      setState(() {
        _canResend = true;
      });
            timer.cancel();
          }
    });

    ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('User not found');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send verification email';
      if (e.code == 'too-many-requests') {
        message = 'Too many requests. Please wait before trying again.';
      } else if (e.code == 'user-not-found') {
        message = 'User not found. Please sign up again.';
      } else {
        message = 'Error: ${e.message}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
      
      // Reset resend state on error
      setState(() {
        _canResend = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Reset resend state on error
      setState(() {
        _canResend = true;
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mail_outline, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'We\'ve sent a verification link to your email address.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _isLoading ? const CircularProgressIndicator() : const SizedBox.shrink(),
              if (_isVerified)
                const Padding(
                  padding: EdgeInsets.only(top: 24.0),
                  child: Text(
                    'Email verified! Logging you in...',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ),
              const SizedBox(height: 32),
              const Text(
                'Didn\'t receive the email?',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _isResending
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : ElevatedButton.icon(
                      onPressed: _canResend ? _resendVerificationEmail : null,
                      icon: const Icon(Icons.refresh),
                      label: Text(_canResend 
                          ? 'Resend Verification Email'
                          : 'Resend in $_resendCooldown seconds'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canResend ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                child: const Text(
                  'Back to Sign Up',
                  style: TextStyle(color: Colors.grey),
                ),
                ),
            ],
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
  final TextEditingController _carModelController = TextEditingController(); // Driver specific
  final TextEditingController _carColorController = TextEditingController(); // Driver specific
  final TextEditingController _carYearController = TextEditingController(); // Driver specific
  bool _isEditing = false;
  bool _isLoading = true;
  String _userRole = 'user'; // Default role

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _surnameController.text = data['surname'] ?? '';
      _ageController.text = data['age'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _userRole = data['role'] ?? 'user';
      if (_userRole == 'driver') {
        _carModelController.text = data['car_model'] ?? '';
        _carColorController.text = data['car_color'] ?? '';
        _carYearController.text = data['car_year'] ?? '';
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final updateData = {
            'name': _nameController.text.trim(),
            'surname': _surnameController.text.trim(),
            'age': _ageController.text.trim(),
            'phone': _phoneController.text.trim(),
          };

          if (_userRole == 'driver') {
            updateData['car_model'] = _carModelController.text.trim();
            updateData['car_color'] = _carColorController.text.trim();
            updateData['car_year'] = _carYearController.text.trim();
          }

          await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);
                        setState(() {
            _isEditing = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        } else {
          throw Exception('User not found');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = 'Failed to update profile: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        print('Error updating profile: $e');
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
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
                                      Text(user?.email ?? '', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
