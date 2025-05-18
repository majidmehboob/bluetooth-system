import 'package:flutter/material.dart';
import 'package:smart_track/services/auth-services.dart';
import 'package:smart_track/widgets/loading-overlay.dart';
import 'package:smart_track/utils/colors.dart';
import 'package:smart_track/widgets/snackbar-helper.dart';
import 'package:smart_track/widgets/system-ui.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LogInPage>
    with SingleTickerProviderStateMixin {
  // Text controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Scroll controller and field keys
  final ScrollController _scrollCtrl = ScrollController();
  final _emailKey = GlobalKey();
  final _passKey = GlobalKey();

  // Error messages
  String? _emailError;
  String? _passwordError;

  // Loading and visibility
  bool _isLoading = false;
  bool _obscure = true;

  bool isStudent = false;
  bool isTeacher = false;

  @override
  void initState() {
    super.initState();
    setupSystemUI();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Scroll helper
  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
  }

  // Input decoration with error support
  InputDecoration _dec(
    String label,
    IconData icon, {
    Widget? suffix,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: ColorStyle.BlueStatic),
      suffixIcon: suffix,
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: ColorStyle.BlueStatic),
      ),
    );
  }

  //-----------------    [🍀 Auth Function ]    -------------------//
  Future<void> loginUser(String email, String password) async {
    FocusScope.of(context).unfocus();
    if (email.isEmpty || password.isEmpty) {
      String errorMessage = '';
      if (email.isEmpty && password.isEmpty) {
        errorMessage = 'Please enter both email and password';
      } else if (email.isEmpty) {
        errorMessage = 'Please enter your email';
      } else {
        errorMessage = 'Please enter your password';
      }
      SnackbarHelper.showError(context, errorMessage);

      return;
    }

    await AuthService.loginUser(
      context: context,
      email: email,
      password: password,
      setLoading: (isLoading) {
        if (mounted) setState(() => _isLoading = isLoading);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Center(
                    child: Image.asset(
                      'assets/images/sign.png',
                      height: h * 0.5,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Login',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  Container(
                    key: _emailKey,
                    child: TextField(
                      controller: _emailCtrl,
                      decoration: _dec(
                        'Email',
                        Icons.email,
                        errorText: _emailError,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  Container(
                    key: _passKey,
                    child: TextField(
                      controller: _passwordCtrl,
                      decoration: _dec(
                        'Password',
                        Icons.lock,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: ColorStyle.BlueStatic,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        errorText: _passwordError,
                      ),
                      obscureText: _obscure,
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        loginUser(_emailCtrl.text, _passwordCtrl.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorStyle.BlueStatic,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (_isLoading) BuildLoadingOverlay(),
        ],
      ),
    );
  }
}
