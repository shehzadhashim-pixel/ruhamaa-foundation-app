import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final provider = Provider.of<AppStateProvider>(context, listen: false);
    try {
      final authResult = await provider.executeLogin(
        _emailController.text,
        _passwordController.text,
      );

      if (!authResult['success']) {
        setState(() {
          _errorMessage = authResult['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during authentication: $e';
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branding Logo Icon container
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xff6366f1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    size: 64,
                    color: Color(0xff6366f1),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'RUHAMAA FOUNDATION',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Color(0xff1e293b),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Employee Attendance & Field Audits',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xff64748b),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                
                CustomCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0f172a),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Official Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Security Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xfffef2f2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xfffca5a5)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xffb91c1c),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        PrimaryButton(
                          label: 'Authenticate',
                          onPressed: _submitting ? null : _submitLogin,
                          isLoading: _submitting,
                          backgroundColor: const Color(0xff4f46e5),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                const Text(
                  'Secured by Firebase Auth & Cloud Firestore',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff94a3b8),
                    fontFamily: 'monospace',
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

// Add executeLogin wrapper to provider
extension AppStateProviderAuthExtension on AppStateProvider {
  Future<Map<String, dynamic>> executeLogin(String email, String password) async {
    try {
      await signIn(email, password);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
