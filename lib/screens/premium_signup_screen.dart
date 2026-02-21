import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'premium_login_screen.dart';

/// Premium Sign-Up Screen with modern design aesthetics
/// Features: Glassmorphism, vibrant gradients, form validation
class PremiumSignupScreen extends StatefulWidget {
  const PremiumSignupScreen({super.key});

  @override
  State<PremiumSignupScreen> createState() => _PremiumSignupScreenState();
}

class _PremiumSignupScreenState extends State<PremiumSignupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  String? _validateForm() {
    if (_firstNameController.text.trim().isEmpty) {
      return 'Please enter your first name';
    }
    if (_lastNameController.text.trim().isEmpty) {
      return 'Please enter your last name';
    }
    if (_emailController.text.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!_validateEmail(_emailController.text.trim())) {
      return 'Please enter a valid email address';
    }
    if (_passwordController.text.isEmpty) {
      return 'Please enter a password';
    }
    if (_passwordController.text.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (_confirmPasswordController.text.isEmpty) {
      return 'Please confirm your password';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    final validationError = _validateForm();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

      await ApiService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: fullName,
      );

      // Clear the token so user must login manually
      await ApiService.clearToken();

      if (mounted) {
        _showSnackBar('Account created successfully! Please login.');
        // Navigate back to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PremiumLoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Sign up failed: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF009485),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkMode
                ? [const Color(0xFF0f2321), const Color(0xFF004d40)]
                : [const Color(0xFF009688), const Color(0xFF64FFDA)],
          ),
        ),
        child: Stack(
          children: [
            // Abstract background decorations
            Positioned(
              top: -MediaQuery.of(context).size.height * 0.2,
              left: -MediaQuery.of(context).size.width * 0.1,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: -MediaQuery.of(context).size.width * 0.1,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: BoxDecoration(
                  color: const Color(0xFF004d40).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildSignupCard(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupCard() {
    final cardColor = _isDarkMode ? const Color(0xFF1a2c2a) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF0c1d1b);
    final subtitleColor = _isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final inputBgColor = _isDarkMode
        ? const Color(0xFF122321)
        : Colors.grey[50];

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
            child: Column(
              children: [
                // Back Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF009485),
                      tooltip: 'Back to Login',
                    ),
                  ],
                ),
                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009485).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    size: 40,
                    color: Color(0xFF009485),
                  ),
                ),
                const SizedBox(height: 24),
                // Welcome Text
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Form
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
            child: Column(
              children: [
                // First Name Input
                _buildInputField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'John',
                  icon: Icons.person_outline,
                  inputBgColor: inputBgColor,
                  textColor: textColor,
                  labelColor: subtitleColor,
                ),
                const SizedBox(height: 20),
                // Last Name Input
                _buildInputField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Doe',
                  icon: Icons.person_outline,
                  inputBgColor: inputBgColor,
                  textColor: textColor,
                  labelColor: subtitleColor,
                ),
                const SizedBox(height: 20),
                // Email Input
                _buildInputField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'hello@example.com',
                  icon: Icons.mail_outline,
                  inputBgColor: inputBgColor,
                  textColor: textColor,
                  labelColor: subtitleColor,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                // Password Input
                _buildInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  inputBgColor: inputBgColor,
                  textColor: textColor,
                  labelColor: subtitleColor,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                const SizedBox(height: 20),
                // Confirm Password Input
                _buildInputField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  inputBgColor: inputBgColor,
                  textColor: textColor,
                  labelColor: subtitleColor,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Sign Up Button
                _buildSignupButton(),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF122321).withValues(alpha: 0.5)
                  : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(fontSize: 13, color: subtitleColor),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF009485),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color? inputBgColor,
    required Color textColor,
    required Color? labelColor,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: inputBgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscureText,
            keyboardType: keyboardType,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009485),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: const Color(0xFF009485).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}
