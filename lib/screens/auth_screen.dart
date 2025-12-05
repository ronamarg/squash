import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../widgets/animated_shapes.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false; // Toggle between sign in and sign up
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final userCredential = await _firebaseService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        // Navigation will be handled by the auth state listener in main.dart
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailPasswordAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      if (_isSignUp) {
        await _firebaseService.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _usernameController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _firebaseService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully signed in!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _firebaseService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword ? obscureText : false,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        prefixIcon: Icon(icon, color: const Color(0xFFFF8A3D)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFFFF8A3D),
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1A1C24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF272A34),
            width: 1.3,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF272A34),
            width: 1.3,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFFF8A3D),
            width: 2.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: Stack(
        children: [
          // Dark gradient background for depth without glass
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B0C12),
                  Color(0xFF151824),
                ],
              ),
            ),
          ),
          // SafeArea with scrollable content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App branding with big text
                    const Text(
                      'Squash',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Color(0xFFFF8A3D),
                        fontFamily: 'Helvetica',
                      ),
                    ),
                    const SizedBox(height: 48),
                  
                  // Welcome Text with proper typography hierarchy
                  Text(
                    _isSignUp ? 'Create Account' : 'Welcome Back',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      fontFamily: 'Helvetica',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSignUp 
                        ? 'Sign up to start your coding journey'
                        : 'Sign in to continue your progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Dark card container (no glass)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF11131B),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_isSignUp) ...[
                            _buildInputField(
                              controller: _usernameController,
                              label: 'Username',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a username';
                                }
                                if (value.trim().length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildInputField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (_isSignUp && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 12),
                        
                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Color(0xFFFF8A3D)),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        BounceButton(
                          onPressed: () {
                            if (_isLoading) return;
                            _handleEmailPasswordAuth();
                          },
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFA14A),
                                  Color(0xFFB347FF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF8A3D).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSignUp ? 'Sign Up' : 'Sign In',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        shadows: [Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2))],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 18),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp
                                  ? 'Already have an account?'
                                  : "Don't have an account?",
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                  _formKey.currentState?.reset();
                                });
                              },
                              child: Text(
                                _isSignUp ? 'Sign In' : 'Sign Up',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8A3D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ],
                      ),
                    ),
                    ),
                    
                    const SizedBox(height: 28),
                  
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Color(0x33FFFFFF),
                            thickness: 1.2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: Color(0x33FFFFFF),
                            thickness: 1.2,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 28),
                  
                    // Google sign-in with bounce animation
                    BounceButton(
                      onPressed: _isLoading ? () {} : _handleGoogleSignIn,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2E313D), width: 1.2),
                          color: const Color(0xFF181A22),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              '_img/google_logo.png',
                              height: 22,
                              width: 22,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.login, size: 22, color: Color(0xFFFF8A3D));
                              },
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
