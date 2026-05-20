import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_manage_screen.dart';

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
  bool isSavingNotification = false;
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

  Future<void> editName() async {
    final controller = TextEditingController(
      text: userInfo?['name']?.toString() ?? '',
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
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.isEmpty) return;

    try {
      final result = await AuthService.updateMyInfo(newName);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이름이 수정되었습니다.')),
        );
        await loadUserInfo();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '이름 수정에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름 수정 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '현재 비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: mainGreen),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('변경'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final currentPassword = currentController.text.trim();
    final newPassword = newController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 모두 입력해주세요.')),
      );
      return;
    }

    try {
      final result = await AuthService.updateMyPassword(
        currentPassword,
        newPassword,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '비밀번호 변경에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 변경 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> updateNotification(bool value) async {
    setState(() {
      isSavingNotification = true;
    });

    try {
      final result = await AuthService.updateNotificationSetting(value);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          userInfo?['notification_enabled'] = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '알림이 켜졌습니다.' : '알림이 꺼졌습니다.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '알림 설정 변경에 실패했습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림 설정 변경 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingNotification = false;
        });
      }
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
          const SnackBar(content: Text('역할이 변경되었습니다. 다시 로그인해주세요.')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '역할 변경에 실패했습니다.')),
        );

        setState(() {
          isChangingRole = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('역할 변경 중 오류가 발생했습니다.')),
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
        const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')),
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
      decoration: _boxDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_outline, color: mainGreen, size: 30),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '내 계정 정보와 설정을 확인하고 변경할 수 있어요.',
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

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    IconData? icon,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              color: Colors.black54,
              tooltip: '수정',
            ),
        ],
      ),
    );
  }
  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    String? subtitle,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _boxDecoration(),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? mainGreen),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
  Widget _buildProfileCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileManageScreen(
              userInfo: userInfo!,
            ),
          ),
        );

        await loadUserInfo();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: mainGreen,
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 46,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${userInfo!['name'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '${userInfo!['email'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildRoleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '현재 역할',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: mainGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: mainGreen),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    roleLabel(userInfo!['user_role']?.toString()),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: mainGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel(userInfo!['account_status']?.toString()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isChangingRole ? null : changeRole,
              icon: Icon(Icons.swap_horiz, color: mainGreen),
              label: Text(
                isChangingRole ? '역할 변경 중...' : '역할 변경',
                style: TextStyle(
                  color: mainGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: mainGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildNotificationTile() {
    final enabled = userInfo?['notification_enabled'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _boxDecoration(),
      child: SwitchListTile(
        secondary: Icon(
          Icons.notifications_active_outlined,
          color: mainGreen,
        ),
        title: const Text(
          '알림 받기',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isSavingNotification
              ? '알림 설정을 변경하는 중입니다.'
              : '조치 알림과 인근 병해 알림을 수신합니다.',
          style: const TextStyle(fontSize: 12),
        ),
        value: enabled,
        activeColor: mainGreen,
        onChanged: isSavingNotification ? null : updateNotification,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
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
            _buildProfileCard(),
            const SizedBox(height: 22),

            _buildRoleCard(),
            const SizedBox(height: 22),

            _buildSectionTitle('알림 설정'),
            _buildNotificationTile(),

            const SizedBox(height: 14),

            _buildSectionTitle('로그아웃'),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }
}