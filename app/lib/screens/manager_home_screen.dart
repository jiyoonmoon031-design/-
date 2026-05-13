import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'mypage_screen.dart';
import 'diagnosis_screen.dart';
import 'diagnosis_history_screen.dart';
import 'dashboard_screen.dart';
import 'farm_list_screen.dart';
import 'share_consent_screen.dart';
import 'nearby_farm_screen.dart';
import 'alert_response_screen.dart';
import 'alert_list_screen.dart';

class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _currentIndex = 0;

  int _historyRefreshKey = 0;
  int _dashboardRefreshKey = 0;

  final List<String> _titles = const [
    '진단하기',
    '진단 이력',
    '대시보드',
    '농장 관리',
    '마이페이지',
  ];

  @override
  void initState() {
    super.initState();
    _setupFcmListeners();
  }

  Future<void> _setupFcmListeners() async {
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleTreatmentAlert(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        _handleTreatmentAlert(message);
      },
    );
  }

  void _handleTreatmentAlert(RemoteMessage message) {
    final data = message.data;

    if (data['type'] == 'TREATMENT_ALERT') {
      final alertId = int.tryParse(data['alert_id'] ?? '');

      if (alertId == null) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertResponseScreen(
            alertId: alertId,
          ),
        ),
      );
    }
  }

  List<Widget> _buildScreens() {
    return [
      const DiagnosisScreen(),
      DiagnosisHistoryScreen(key: ValueKey('history_$_historyRefreshKey')),
      DashboardScreen(key: ValueKey('dashboard_$_dashboardRefreshKey')),
      const ManagerFarmMenuScreen(),
      const MyPageScreen(),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;

      if (index == 1) {
        _historyRefreshKey++;
      } else if (index == 2) {
        _dashboardRefreshKey++;
      }
    });
  }

  Future<void> _openAlertList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AlertListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: _openAlertList,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: '진단',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: '이력',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: '대시보드',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture_outlined),
            activeIcon: Icon(Icons.agriculture),
            label: '농장관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}

class ManagerFarmMenuScreen extends StatelessWidget {
  const ManagerFarmMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.grey.shade100,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          children: [
            const Text(
              '농장과 구역 정보를 관리하고 주변 농장 위험에 대비하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: Colors.blueGrey,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _FarmMenuCard(
              icon: Icons.business_outlined,
              title: '농장 등록',
              subtitle: '관리하는 농장을 등록하세요',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FarmListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            _FarmMenuCard(
              icon: Icons.share_outlined,
              title: '공유 동의',
              subtitle: '농장 및 구역 공유 범위를 설정하세요',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShareConsentScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            _FarmMenuCard(
              icon: Icons.location_on_outlined,
              title: '인근 농장 조회',
              subtitle: '주변 농장의 병해 정보를 확인하세요',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NearbyFarmScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FarmMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 42,
                  color: const Color(0xFF6FAF7D),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.blueGrey,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}