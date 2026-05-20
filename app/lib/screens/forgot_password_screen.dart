import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String message = '';

  final Color mainGreen = const Color(0xFF6FAF7D);

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: mainGreen),
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
    );
  }

  Future<void> sendResetCode() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await AuthService.sendResetCode(
        emailController.text.trim(),
      );

      setState(() {
        message = result['message'] ?? result['detail'] ?? '인증번호가 발송되었습니다.';
      });
    } catch (e) {
      setState(() {
        message = '인증번호 발송 실패';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> resetPassword() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await AuthService.resetPassword(
        email: emailController.text.trim(),
        code: codeController.text.trim(),
        newPassword: passwordController.text.trim(),
      );

      if (result['success'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비밀번호가 변경되었습니다. 다시 로그인해주세요.'),
          ),
        );

        Navigator.pop(context);
      } else {
        setState(() {
          message = result['detail'] ?? result['message'] ?? '비밀번호 변경 실패';
        });
      }
    } catch (e) {
      setState(() {
        message = '비밀번호 변경 실패';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        backgroundColor: mainGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: buildInputDecoration(
                  label: '이메일',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : sendResetCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('인증번호 받기'),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: buildInputDecoration(
                  label: '인증번호',
                  icon: Icons.verified_user_outlined,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: buildInputDecoration(
                  label: '새 비밀번호',
                  icon: Icons.lock_outline,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('비밀번호 변경'),
                ),
              ),
              const SizedBox(height: 18),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(
                    color: message.contains('실패') ||
                            message.contains('올바르지') ||
                            message.contains('만료')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}