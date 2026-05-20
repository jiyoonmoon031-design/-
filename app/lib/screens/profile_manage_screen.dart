import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

class ProfileManageScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const ProfileManageScreen({
    super.key,
    required this.userInfo,
  });

  @override
  State<ProfileManageScreen> createState() => _ProfileManageScreenState();
}

class _ProfileManageScreenState extends State<ProfileManageScreen> {
  late Map<String, dynamic> userInfo;

  final Color mainGreen = const Color(0xFF6FAF7D);

  @override
  void initState() {
    super.initState();
    userInfo = Map<String, dynamic>.from(widget.userInfo);
  }

  Future<void> editName() async {
    final controller = TextEditingController(
      text: userInfo['name']?.toString() ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이름 수정'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: mainGreen),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    final result = await AuthService.updateMyInfo(newName);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        userInfo['name'] = newName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름이 수정되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '이름 수정에 실패했습니다.')),
      );
    }
  }

  Future<void> changePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
      builder: (_) => const ChangePasswordScreen(),
      ),
    );
  }

  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계정 삭제'),
          content: const Text('계정을 삭제하면 복구할 수 없습니다. 정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final result = await AuthService.deleteMyAccount();

    if (!mounted) return;

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '계정 삭제에 실패했습니다.')),
      );
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: mainGreen),
        title: Text(label),
        subtitle: Text(value),
        trailing: onTap == null ? null : const Icon(Icons.edit),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? mainGreen),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('계정 관리'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            '계정 정보',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoTile(
            icon: Icons.badge_outlined,
            label: '이름',
            value: '${userInfo['name'] ?? '-'}',
            onTap: editName,
          ),
          _buildInfoTile(
            icon: Icons.email_outlined,
            label: '이메일',
            value: '${userInfo['email'] ?? '-'}',
          ),

          const SizedBox(height: 20),

          const Text(
            '보안',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildMenuTile(
            icon: Icons.lock_outline,
            title: '비밀번호 변경',
            onTap: changePassword,
          ),

          const SizedBox(height: 20),

          const Text(
            '계정',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildMenuTile(
            icon: Icons.delete_outline,
            title: '계정 삭제',
            color: Colors.red,
            onTap: deleteAccount,
          ),
        ],
      ),
    );
  }
}