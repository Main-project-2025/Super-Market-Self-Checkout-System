import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'premium_home_screen.dart';

/// Premium Login Screen with modern design aesthetics
/// Features: Glassmorphism, vibrant gradients, social login, dark mode support
class PremiumLoginScreen extends StatefulWidget {
  const PremiumLoginScreen({super.key});

  @override
  State<PremiumLoginScreen> createState() => _PremiumLoginScreenState();
}

class _PremiumLoginScreenState extends State<PremiumLoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingAuth() async {
    try {
      await ApiService.initialize();
      final result = await ApiService.verifyToken();
      if (result['valid'] == true && mounted) {
        _navigateBasedOnRole();
      }
    } catch (e) {
      // User not logged in, continue to login screen
    }
  }

  void _navigateBasedOnRole() {
    // Navigate to appropriate screen based on user role
    if (ApiService.isAdmin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PremiumHomeScreen()),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please enter email and password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        _showSnackBar('Login successful!');
        _navigateBasedOnRole();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Login failed: ${e.toString()}', isError: true);
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

  void _handleSocialLogin(String provider) {
    _showSnackBar('$provider login coming soon!');
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
                      child: _buildLoginCard(),
                    ),
                  ),
                ),
              ),
            ),
            // Dark mode toggle
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() => _isDarkMode = !_isDarkMode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    final cardColor = _isDarkMode ? const Color(0xFF1a2c2a) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF0c1d1b);
    final subtitleColor =
        _isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final inputBgColor =
        _isDarkMode ? const Color(0xFF122321) : Colors.grey[50];

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
                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009485).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_cart_checkout,
                    size: 40,
                    color: Color(0xFF009485),
                  ),
                ),
                const SizedBox(height: 24),
                // Welcome Text
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to start your scan-and-go experience',
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
                // Email Input
                _buildInputField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'hello@example.com',
                  icon: Icons.mail_outline,
                  inputBgColor: inputBgColor,
                  textColor: textColor,
                  labelColor: subtitleColor,
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
                ),
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _showSnackBar('Forgot password coming soon!');
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF009485),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Login Button
                _buildLoginButton(),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Social Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        label: 'Apple',
                        onTap: () => _handleSocialLogin('Apple'),
                        child: const Icon(Icons.apple, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSocialButton(
                        label: 'Google',
                        onTap: () => _handleSocialLogin('Google'),
                        child: Image.asset(
                          'assets/google_logo.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.g_mobiledata, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
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
                  "Don't have an account? ",
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to sign up screen
                    _showSnackBar('Sign up coming soon!');
                  },
                  child: const Text(
                    'Sign Up',
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
            obscureText: isPassword && _obscurePassword,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
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

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                    'Login',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required VoidCallback onTap,
    required Widget child,
  }) {
    final buttonBgColor =
        _isDarkMode ? const Color(0xFF122321) : Colors.white;
    final buttonBorderColor =
        _isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final buttonTextColor = _isDarkMode ? Colors.white : Colors.grey[800];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: buttonBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: buttonBorderColor!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: buttonTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
