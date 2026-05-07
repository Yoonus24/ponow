// ignore_for_file: sized_box_for_whitespace, deprecated_member_use, avoid_print, use_build_context_synchronously


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchaseorders2/providers/permission_provider.dart';
import 'package:purchaseorders2/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:purchaseorders2/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);
  final ValueNotifier<bool> _formSubmitted = ValueNotifier(false);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    _formSubmitted.value = true;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    _isLoading.value = true;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    final uuid = const Uuid();

    /// Get or create browser_session_id
    String? browserSessionId = prefs.getString('browser_session_id');

    if (browserSessionId == null) {
      browserSessionId = uuid.v4();
      await prefs.setString('browser_session_id', browserSessionId);
    }

    try {
      /// LOGIN API CALL
      final result = await AuthService.login(
        username: username,
        password: password,
        browserSessionId: browserSessionId,
      );
      _isLoading.value = false;

      if (result != null) {
        // Start session
        SessionService.start();
        // Load into Provider
        try {
          final permissionProvider = Provider.of<PermissionProvider>(
            context,
            listen: false,
          );

          await permissionProvider.loadPermissions();

          print(permissionProvider.permissions);
        } catch (e) {
          print("⚠️ Provider not loaded: $e");
        }

        // Autofill complete
        TextInput.finishAutofillContext();

        // Navigate
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {"loginSuccess": true},
        );
      }
    } catch (e) {
      _isLoading.value = false;

      print("❌ LOGIN ERROR:");
      print(e);

      String message = "Something went wrong";

      if (e.toString().contains("SESSION_EXISTS")) {
        message = "Already logged in another device";
      } else if (e.toString().contains("INVALID_CREDENTIALS")) {
        message = "Invalid username or password";
      } else if (e.toString().contains("LOGIN_FAILED")) {
        message = "Login failed. Please try again";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }

  void _clearValidation() {
    if (_formSubmitted.value) {
      _formSubmitted.value = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _isLoading.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
    _formSubmitted.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    // Only validate if form has been submitted
    if (!_formSubmitted.value) return null;

    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    // Only validate if form has been submitted
    if (!_formSubmitted.value) return null;

    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 4) {
      return 'Password must be at least 4 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blueAccent,
              Colors.blueAccent.shade400,
              Colors.blueAccent.shade700,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 24.0 : 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated logo
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  height: 100,
                                  child: Image.asset(
                                    'assets/bestmummy.jpg',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.shopping_cart,
                                        size: 80,
                                        color: Colors.blueAccent,
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Purchase Order',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Sign in to continue',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ✅ Wrap form fields in AutofillGroup
                          AutofillGroup(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Username field - validation only on login click
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(
                                            0.1,
                                          ),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: _usernameController,
                                      validator: _validateUsername,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      onChanged: (value) {
                                        _clearValidation();
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Username',
                                        labelStyle: TextStyle(
                                          color: Colors.blueAccent,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: Colors.blueAccent,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 18,
                                              horizontal: 20,
                                            ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.blueAccent,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blueAccent.shade700,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Password field - validation only on login click
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(
                                            0.1,
                                          ),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable: _obscurePassword,
                                      builder: (context, obscure, _) {
                                        return TextFormField(
                                          controller: _passwordController,
                                          obscureText: obscure,
                                          validator: _validatePassword,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          onChanged: (value) {
                                            _clearValidation();
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            labelStyle: TextStyle(
                                              color: Colors.blueAccent,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock_outline,
                                              color: Colors.blueAccent,
                                            ),
                                            suffixIcon: IconButton(
                                              onPressed:
                                                  _togglePasswordVisibility,
                                              icon: Icon(
                                                obscure
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 18,
                                                  horizontal: 20,
                                                ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.blueAccent,
                                                width: 2,
                                              ),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.redAccent,
                                                width: 1,
                                              ),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                    color: Colors.redAccent,
                                                    width: 2,
                                                  ),
                                                ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.blueAccent.shade700,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // Login button
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blueAccent,
                                          Colors.blueAccent.shade700,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blueAccent.withOpacity(
                                            0.5,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          if (!_isLoading.value) {
                                            _login();
                                          }
                                        },
                                        child: ValueListenableBuilder<bool>(
                                          valueListenable: _isLoading,
                                          builder: (context, loading, _) {
                                            if (loading) {
                                              return const Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                ),
                                              );
                                            }

                                            return const Center(
                                              child: Text(
                                                'Log In',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
