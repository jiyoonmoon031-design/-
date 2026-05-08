import 'package:flutter/material.dart';
import 'mypage_screen.dart';
import 'diagnosis_screen.dart';
import 'diagnosis_history_screen.dart';
import 'dashboard_screen.dart';

class GeneralHomeScreen extends StatefulWidget {
  const GeneralHomeScreen({super.key});

  @override
  State<GeneralHomeScreen> createState() => _GeneralHomeScreenState();
}

class _GeneralHomeScreenState extends State<GeneralHomeScreen> {
  int _currentIndex = 0;

  int _historyRefreshKey = 0;
  int _dashboardRefreshKey = 0;

  final List<String> _titles = const [
    '진단하기',
    '기록',
    '대시보드',
    '마이페이지',
  ];

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

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
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