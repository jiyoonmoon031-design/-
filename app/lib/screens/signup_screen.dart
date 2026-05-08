import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String selectedRole = 'GENERAL_USER';
  String message = '';
  bool isLoading = false;
  bool obscurePassword = true;

  final Color mainGreen = const Color(0xFF6FAF7D);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() {
        message = '이메일, 비밀번호, 이름을 모두 입력해주세요.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    final result = await AuthService.signup(
      email: email,
      password: password,
      name: name,
      userRole: selectedRole,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
      message = result['message'] ?? '';
    });

    if (result['success'] == true) {
      Navigator.pop(context);
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

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRole,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: mainGreen),
          items: const [
            DropdownMenuItem(
              value: 'GENERAL_USER',
              child: Text('일반 사용자'),
            ),
            DropdownMenuItem(
              value: 'FARM_MANAGER',
              child: Text('농장 관리자'),
            ),
          ],
          onChanged: isLoading
              ? null
              : (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.eco,
                size: 64,
                color: mainGreen,
              ),
              const SizedBox(height: 14),

              const Text(
                'CropCare 시작하기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                '계정을 만들고 작물 진단 관리를 시작해보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: buildInputDecoration(
                  label: '이메일',
                  icon: Icons.email_outlined,
                ),
                onChanged: (_) {
                  if (message.isNotEmpty) {
                    setState(() {
                      message = '';
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
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
                onChanged: (_) {
                  if (message.isNotEmpty) {
                    setState(() {
                      message = '';
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              TextField(
                controller: nameController,
                textInputAction: TextInputAction.done,
                decoration: buildInputDecoration(
                  label: '이름',
                  icon: Icons.badge_outlined,
                ),
                onChanged: (_) {
                  if (message.isNotEmpty) {
                    setState(() {
                      message = '';
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              _buildRoleDropdown(),

              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: message.contains('완료') || message.contains('성공')
                          ? mainGreen
                          : Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '회원가입 완료',
                          style: TextStyle(fontSize: 17),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}