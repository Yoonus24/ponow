import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      _isLoading.value = true;

      await Future.delayed(const Duration(seconds: 1));

      _isLoading.value = false;

      final username = _usernameController.text;
      final password = _passwordController.text;

      if (username.isEmpty && password.isEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Invalid username or password',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _isLoading.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blueAccent,
              Colors.blue.shade200,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 20.0 : 40.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 24.0 : 40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 100,
                        child: Image.asset(
                          'assets/bestmummy.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Purchase Order',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),

                      const SizedBox(height: 30),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade100,
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  labelStyle: TextStyle(
                                    color: Colors.blue.shade700,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: Colors.blue.shade700,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 20,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade100,
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
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(
                                        color: Colors.blue.shade700,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: Colors.blue.shade700,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: _togglePasswordVisibility,
                                        icon: Icon(
                                          obscure
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 20,
                                          ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue.shade900,
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 30),

                            Container(
                              width: 220,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade700,
                                    Colors.blueAccent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _isLoading,
                                builder: (context, loading, _) {
                                  return loading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Material(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: _login,
                                            child: const Center(
                                              child: Text(
                                                'Log In',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                },
                              ),
                            ),
                          ],
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
    );
  }
}
