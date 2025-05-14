import 'package:flutter/material.dart';
import 'package:smart_track/services/auth-services.dart';
import 'package:smart_track/widgets/loading-overlay.dart';
import 'package:smart_track/utils/colors.dart';
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
      // fillColor: Color.fromARGB(255, 255, 255, 255),
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
    // if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
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

// class LogInPage extends StatefulWidget {
//   const LogInPage({super.key});

//   @override
//   State<LogInPage> createState() => _LogInPageState();
// }

// class _LogInPageState extends State<LogInPage>
//     with SingleTickerProviderStateMixin, WidgetsBindingObserver {
//   //---------------   [ 🍀 State Variables]  -----------------//

//   final _formKey = GlobalKey<FormState>();
//   bool isShowLoading = false;
//   bool isPasswordVisible = false;
//   bool isKeyboardVisible = false;
//   final TextEditingController _email = TextEditingController();
//   final TextEditingController _password = TextEditingController();
//   final FocusNode _emailFocusNode = FocusNode();
//   final FocusNode _passwordFocusNode = FocusNode();

//   // Animation controllers - initialized in initState
//   late final AnimationController _animationController;
//   late final Animation<double> _imageSizeAnimation;
//   late final Animation<Alignment> _imageAlignmentAnimation;

//   @override
//   void initState() {
//     super.initState();
//     setupSystemUI();
//     WidgetsBinding.instance.addObserver(this);
//     // Proper initialization order
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _imageSizeAnimation = Tween<double>(begin: 200, end: 100).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _imageAlignmentAnimation = Tween<Alignment>(
//       begin: Alignment.center,
//       end: Alignment.topLeft,
//     ).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
//     );

//     _setupKeyboardListeners();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     // Proper disposal order
//     _animationController.dispose();
//     _email.dispose();
//     _password.dispose();
//     _emailFocusNode.dispose();
//     _passwordFocusNode.dispose();
//     super.dispose();
//   }

//   // Add this new method to handle keyboard visibility changes
//   // Fixed keyboard visibility handler
//   @override
//   void didChangeMetrics() {
//     final newKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
//     if (newKeyboardVisible != isKeyboardVisible) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted) {
//           setState(() => isKeyboardVisible = newKeyboardVisible);
//           if (newKeyboardVisible) {
//             _animationController.forward();
//           } else {
//             _animationController.reverse();
//           }
//         }
//       });
//     }
//   }

//   //-----------------[Keyboard Handling]---------------//
//   void _setupKeyboardListeners() {
//     _emailFocusNode.addListener(_handleFocusChange);
//     _passwordFocusNode.addListener(_handleFocusChange);
//   }

//   // Modified focus handler
//   void _handleFocusChange() {
//     final hasFocus = _emailFocusNode.hasFocus || _passwordFocusNode.hasFocus;
//     // isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

//     if (hasFocus && !isKeyboardVisible) {
//       if (!isKeyboardVisible) {
//         setState(() => isKeyboardVisible = true);
//         _animationController.forward();
//       }
//     } else if (!hasFocus && isKeyboardVisible) {
//       if (isKeyboardVisible) {
//         setState(() => isKeyboardVisible = false);
//         _animationController.reverse();
//       }
//     }
//   }

//   //-----------------    [🍀 Auth Function ]    -------------------//

//   Future<void> loginUser(String email, String password) async {
//     if (!_formKey.currentState!.validate()) return;
//     FocusScope.of(context).unfocus();
//     await AuthService.loginUser(
//       context: context,
//       email: email,
//       password: password,
//       setLoading: (isLoading) {
//         if (mounted) setState(() => isShowLoading = isLoading);
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14.0,
//                     vertical: 8.0,
//                   ),
//                   child: ConstrainedBox(
//                     constraints: BoxConstraints(
//                       minHeight:
//                           MediaQuery.of(context).size.height -
//                           MediaQuery.of(context).padding.top -
//                           MediaQuery.of(context).padding.bottom,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Animated Logo Section
//                         Align(
//                           // duration: const Duration(milliseconds: 300),
//                           alignment: _imageAlignmentAnimation.value,
//                           child: Container(
//                             // duration: const Duration(milliseconds: 300),
//                             padding: EdgeInsets.only(
//                               top: isKeyboardVisible ? 20 : 40,
//                             ),
//                             child: Image.asset(
//                               'assets/images/sign.png',
//                               fit: BoxFit.cover,
//                               height: _imageSizeAnimation.value,
//                             ),
//                           ),
//                         ),

//                         // Form Section
//                         Center(
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               if (!isKeyboardVisible) ...[
//                                 Text(
//                                   "Login",
//                                   style: TextStyle(
//                                     fontSize: 40,
//                                     fontWeight: FontWeight.w500,
//                                     fontFamily: 'Roboto',
//                                     height: 0,
//                                     letterSpacing: -0.33,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   'Sign in with your credential',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     letterSpacing: -0.5,
//                                     fontWeight: FontWeight.w300,
//                                     fontFamily: 'Roboto',
//                                     color: Colors.grey[500],
//                                   ),
//                                 ),
//                               ],

//                               Form(
//                                 key: _formKey,
//                                 child: Column(
//                                   children: [
//                                     const SizedBox(height: 30),
//                                     _buildEmailField(),
//                                     const SizedBox(height: 20),
//                                     _buildPasswordField(),
//                                     const SizedBox(height: 30),
//                                     _buildSignInButton(),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//             if (isShowLoading) BuildLoadingOverlay(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmailField() {
//     return Container(
//       height: 60,
//       decoration: BoxDecoration(
//         color: Colors.white54,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: Colors.black),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: Row(
//         children: [
//           const Icon(Icons.email, color: Color(0xFF80A7D5)),
//           const SizedBox(width: 10),
//           Expanded(
//             child: TextFormField(
//               controller: _email,
//               focusNode: _emailFocusNode,
//               keyboardType: TextInputType.emailAddress,
//               autofillHints: const [AutofillHints.email],
//               textInputAction: TextInputAction.next,
//               decoration: InputDecoration(
//                 hintText: 'Email address',
//                 border: InputBorder.none,
//                 isDense: true,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 15),
//                 hintStyle: const TextStyle(
//                   color: Colors.grey,
//                   fontSize: 16,
//                   fontFamily: 'Inter',
//                   fontWeight: FontWeight.w300,
//                 ),
//                 floatingLabelBehavior: FloatingLabelBehavior.never,
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   SnackbarHelper.showError(context, 'Please enter your email');
//                   return '';
//                 }
//                 if (!RegExp(
//                   r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
//                 ).hasMatch(value)) {
//                   SnackbarHelper.showError(
//                     context,
//                     'Please enter a valid email',
//                   );
//                   return '';
//                 }
//                 return null;
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPasswordField() {
//     return Container(
//       height: 60,
//       decoration: BoxDecoration(
//         color: Colors.white54,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: Colors.black),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: Row(
//         children: [
//           const Icon(Icons.lock, color: Color(0xFF80A7D5)),
//           const SizedBox(width: 10),
//           Expanded(
//             child: TextFormField(
//               controller: _password,
//               obscureText: !isPasswordVisible,
//               focusNode: _passwordFocusNode,
//               autofillHints: const [AutofillHints.password],
//               textInputAction: TextInputAction.done,
//               onEditingComplete: () => TextInput.finishAutofillContext(),
//               decoration: InputDecoration(
//                 hintText: 'Password',
//                 border: InputBorder.none,
//                 isDense: true,
//                 contentPadding: const EdgeInsets.symmetric(vertical: 15),
//                 hintStyle: const TextStyle(
//                   color: Colors.grey,
//                   fontSize: 16,
//                   fontFamily: 'Inter',
//                   fontWeight: FontWeight.w300,
//                 ),
//                 floatingLabelBehavior: FloatingLabelBehavior.never,
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//                     color: const Color(0xFF80A7D5),
//                   ),
//                   onPressed: togglePasswordVisibility,
//                 ),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   SnackbarHelper.showError(
//                     context,
//                     'Please enter your password',
//                   );
//                   return '';
//                 }
//                 return null;
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSignInButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: () {
//           if (_formKey.currentState!.validate()) {
//             loginUser(_email.text, _password.text);
//           }
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: ColorStyle.BlueStatic,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(24.0),
//           ),
//           padding: const EdgeInsets.symmetric(vertical: 20),
//         ),
//         child: Text(
//           isShowLoading ? 'Loading' : 'Sign In',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontFamily: 'Inter',
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//     );
//   }

//   void togglePasswordVisibility() {
//     setState(() => isPasswordVisible = !isPasswordVisible);
//   }
// }
