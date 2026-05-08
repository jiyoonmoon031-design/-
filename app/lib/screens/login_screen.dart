import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'general_home_screen.dart';
import 'manager_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String errorMessage = '';

  final Color mainGreen = const Color(0xFF6FAF7D);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = '이메일과 비밀번호를 모두 입력해주세요.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await AuthService.login(email, password);

      if (!mounted) return;

      if (result['success'] == true) {
        final userRole = result['user']['user_role'];

        if (userRole == 'GENERAL_USER') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GeneralHomeScreen()),
          );
        } else if (userRole == 'FARM_MANAGER') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ManagerHomeScreen()),
          );
        } else {
          setState(() {
            errorMessage = '알 수 없는 사용자 권한입니다.';
          });
        }
      } else {
        setState(() {
          errorMessage = result['message'] ?? '로그인에 실패했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '로그인 중 오류가 발생했습니다.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: mainGreen),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: mainGreen, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.eco,
                    size: 72,
                    color: mainGreen,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'CropCare',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    '작물 진단과 관리를 더 간편하게',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 32),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: buildInputDecoration(
                      label: '이메일',
                      icon: Icons.email_outlined,
                    ),
                    onChanged: (_) {
                      if (errorMessage.isNotEmpty) {
                        setState(() {
                          errorMessage = '';
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    decoration: buildInputDecoration(
                      label: '비밀번호',
                      icon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!isLoading) {
                        login();
                      }
                    },
                    onChanged: (_) {
                      if (errorMessage.isNotEmpty) {
                        setState(() {
                          errorMessage = '';
                        });
                      }
                    },
                  ),

                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 18),

                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              '로그인',
                              style: TextStyle(fontSize: 17),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                );
                              },
                        child: Text(
                          '회원가입',
                          style: TextStyle(color: mainGreen),
                        ),
                      ),
                      const Text('|', style: TextStyle(color: Colors.black38)),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                // TODO: 아이디 찾기 화면/기능 연결 예정
                              },
                        child: Text(
                          '아이디 찾기',
                          style: TextStyle(color: mainGreen),
                        ),
                      ),
                      const Text('|', style: TextStyle(color: Colors.black38)),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                // TODO: 비밀번호 찾기 화면/기능 연결 예정
                              },
                        child: Text(
                          '비밀번호 찾기',
                          style: TextStyle(color: mainGreen),
                        ),
                      ),
                    ],
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