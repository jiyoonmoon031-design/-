import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  Map<String, dynamic>? userInfo;
  bool isLoading = true;
  bool isLoggingOut = false;
  bool isChangingRole = false;
  String message = '';

  final Color mainGreen = const Color(0xFF6FAF7D);

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await AuthService.getMyInfo();

      if (!mounted) return;

      setState(() {
        userInfo = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        userInfo = null;
        isLoading = false;
        message = '사용자 정보를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> changeRole() async {
    final currentRole = userInfo?['user_role']?.toString();

    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('역할 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('일반 사용자'),
                subtitle: const Text('개인 진단 기록을 관리합니다.'),
                value: 'GENERAL_USER',
                groupValue: currentRole,
                activeColor: mainGreen,
                onChanged: (value) => Navigator.pop(context, value),
              ),
              RadioListTile<String>(
                title: const Text('농장 관리자'),
                subtitle: const Text('농장과 구역을 관리합니다.'),
                value: 'FARM_MANAGER',
                groupValue: currentRole,
                activeColor: mainGreen,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );

    if (selectedRole == null || selectedRole == currentRole) return;

    setState(() {
      isChangingRole = true;
    });

    try {
      final result = await AuthService.updateMyRole(selectedRole);
    
      if (!mounted) return;

      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('역할이 변경되었습니다. 다시 로그인해주세요.'),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '역할 변경에 실패했습니다.'),
          ),
        );

        setState(() {
          isChangingRole = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('역할 변경 중 오류가 발생했습니다.'),
        ),
      );

      setState(() {
        isChangingRole = false;
      });
    }
  }

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그아웃 중 오류가 발생했습니다.'),
        ),
      );

      setState(() {
        isLoggingOut = false;
      });
    }
  }

  String roleLabel(String? value) {
    switch (value) {
      case 'GENERAL_USER':
        return '일반 사용자';
      case 'FARM_MANAGER':
        return '농장 관리자';
      default:
        return value ?? '-';
    }
  }

  String statusLabel(String? value) {
    switch (value) {
      case 'ACTIVE':
        return '활성';
      case 'INACTIVE':
        return '비활성';
      default:
        return value ?? '-';
    }
  }

  Widget _buildGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.person_outline,
            color: mainGreen,
            size: 30,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '내 계정 정보와 역할을 확인하고 변경할 수 있어요.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: mainGreen),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message.isNotEmpty ? message : '사용자 정보를 불러올 수 없습니다.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('마이페이지'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: mainGreen),
        ),
      );
    }

    if (userInfo == null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: mainGreen,
        onRefresh: loadUserInfo,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildGuideCard(),
            const SizedBox(height: 18),

            _buildInfoTile(
              label: '이메일',
              value: '${userInfo!['email'] ?? '-'}',
              icon: Icons.email_outlined,
            ),
            _buildInfoTile(
              label: '이름',
              value: '${userInfo!['name'] ?? '-'}',
              icon: Icons.badge_outlined,
            ),
            _buildInfoTile(
              label: '역할',
              value: roleLabel(userInfo!['user_role']?.toString()),
              icon: Icons.admin_panel_settings_outlined,
            ),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isChangingRole ? null : changeRole,
                icon: isChangingRole
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: mainGreen,
                        ),
                      )
                    : Icon(Icons.swap_horiz, color: mainGreen),
                label: Text(
                  isChangingRole ? '역할 변경 중...' : '역할 변경',
                  style: TextStyle(
                    color: mainGreen,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: mainGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 14),

            _buildInfoTile(
              label: '상태',
              value: statusLabel(userInfo!['account_status']?.toString()),
              icon: Icons.verified_user_outlined,
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isLoggingOut ? null : logout,
                icon: isLoggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  isLoggingOut ? '로그아웃 중...' : '로그아웃',
                  style: const TextStyle(fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}