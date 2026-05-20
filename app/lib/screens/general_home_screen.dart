import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'mypage_screen.dart';
import 'diagnosis_screen.dart';
import 'diagnosis_history_screen.dart';
import 'dashboard_screen.dart';
import 'alert_response_screen.dart';
import 'alert_list_screen.dart';
import '../services/alert_service.dart';

class GeneralHomeScreen extends StatefulWidget {
  const GeneralHomeScreen({super.key});

  @override
  State<GeneralHomeScreen> createState() => _GeneralHomeScreenState();
}

class _GeneralHomeScreenState extends State<GeneralHomeScreen> {
  int _currentIndex = 0;

  int _historyRefreshKey = 0;
  int _dashboardRefreshKey = 0;

  int _unreadAlertCount = 0;
  
  final List<String> _titles = const [
    '진단하기',
    '기록',
    '대시보드',
    '마이페이지',
  ];

  @override
  void initState() {
    super.initState();
    _setupFcmListeners();
    _loadUnreadAlert();
  }

  Future<void> _setupFcmListeners() async {
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleTreatmentAlert(initialMessage);
      _loadUnreadAlert();
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _loadUnreadAlert();
    });

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        _handleTreatmentAlert(message);
        _loadUnreadAlert();
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
  Future<void> _loadUnreadAlert() async {
    try {
      final count = await AlertService.getUnreadAlertCount();

      if (!mounted) return;

      setState(() {
        _unreadAlertCount = count;
      });
    } catch (e) {
      debugPrint('읽지 않은 알림 조회 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,

        backgroundColor: const Color(0xFFF4FAF5),
        foregroundColor: const Color(0xFF2F4F34),

        elevation: 0,
        surfaceTintColor: Colors.transparent,

        titleTextStyle: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2F4F34),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _openAlertList();

              if (!mounted) return;

              await _loadUnreadAlert();
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none),

                if (_unreadAlertCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _unreadAlertCount > 99
                            ? '99+'
                            : '$_unreadAlertCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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

        backgroundColor: Colors.white,

        selectedItemColor: const Color(0xFF6FAF7D),
        unselectedItemColor: Colors.blueGrey.shade300,

        selectedFontSize: 12,
        unselectedFontSize: 12,

        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
        ),

        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
        ),

        showUnselectedLabels: true,

        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: '진단',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: '대시보드',
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