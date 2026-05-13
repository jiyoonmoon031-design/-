import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/calendar_service.dart';
import '../services/auth_service.dart';
import '../services/farm_service.dart';
import 'diagnosis_detail_screen.dart';
import 'farm_manager_screen.dart';

class DiagnosisHistoryScreen extends StatefulWidget {
  const DiagnosisHistoryScreen({super.key});

  @override
  State<DiagnosisHistoryScreen> createState() => _DiagnosisHistoryScreenState();
}

class _DiagnosisHistoryScreenState extends State<DiagnosisHistoryScreen> {
  List diagnosisList = [];
  bool isLoading = true;
  String message = '';

  int selectedTopTab = 0;

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  String userRole = '';

  String selectedCrop = '전체';
  String selectedSeverity = '';

  List<Map<String, dynamic>> farms = [];
  List<Map<String, dynamic>> zones = [];

  int? selectedFarmId;
  int? selectedZoneId;

  final Map<String, String> cropIcons = const {
    '옥수수': '🌽',
    '토마토': '🍅',
    '사과': '🍎',
    '포도': '🍇',
    '고추': '🌶️',
    '딸기': '🍓',
  };

  final List<String> cropFilters = ['전체', '옥수수', '포도', '사과', '고추', '딸기'];

  @override
  void initState() {
    super.initState();
    initScreen();
  }

  Future<void> initScreen() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final userInfo = await AuthService.getMyInfo();
      if (!mounted) return;

      final role = userInfo?['user_role'] ?? '';

      setState(() {
        userRole = role;
      });

      if (role == 'FARM_MANAGER') {
        await loadFarms();
      }

      await loadHistory();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        message = '화면 정보를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> loadHistory() async {
    await loadMonthlyEvents(focusedDay);
  }

  Future<void> loadFarms() async {
    final result = await FarmService.getFarms();

    if (!mounted) return;

    if (result['success'] == true) {
      final farmList = List<Map<String, dynamic>>.from(result['data'] ?? []);

      setState(() {
        farms = farmList;
      });

      if (farmList.isNotEmpty) {
        selectedFarmId = farmList.first['farm_id'];
        await loadZones(selectedFarmId!);
      }
    } else {
      setState(() {
        farms = [];
        zones = [];
        selectedFarmId = null;
        selectedZoneId = null;
        message = result['message'] ?? '농장 목록을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> loadZones(int farmId) async {
    final result = await FarmService.getZones(farmId);

    if (!mounted) return;

    if (result['success'] == true) {
      final zoneList = List<Map<String, dynamic>>.from(result['data'] ?? []);

      setState(() {
        zones = zoneList;
        selectedZoneId = null;
      });
    } else {
      setState(() {
        zones = [];
        selectedZoneId = null;
        message = result['message'] ?? '구역 목록을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> loadMonthlyEvents(DateTime month) async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final result = await CalendarService.getCalendarEvents(
      startDate: start.toIso8601String(),
      endDate: end.toIso8601String(),
      farmId: userRole == 'FARM_MANAGER' ? selectedFarmId : null,
      zoneId: userRole == 'FARM_MANAGER' ? selectedZoneId : null,
      cropName: userRole == 'FARM_MANAGER' ? '' : selectedCrop,
      severityLevel: selectedSeverity,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;

      if (result['success'] == true) {
        diagnosisList = result['data'] ?? [];
      } else {
        diagnosisList = [];
        message = result['message'] ?? '캘린더 기록을 불러오지 못했습니다.';
      }
    });
  }

  DateTime? parseDiagnosisDate(dynamic item) {
    try {
      final raw = item['event_date']?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  List get selectedDayDiagnosisList {
    return diagnosisList.where((item) {
      final date = parseDiagnosisDate(item);
      if (date == null) return false;
      return isSameDay(date, selectedDay);
    }).toList();
  }

  List getEventsForDay(DateTime day) {
    return diagnosisList.where((item) {
      final date = parseDiagnosisDate(item);
      if (date == null) return false;
      return isSameDay(date, day);
    }).toList();
  }

  String severityLabel(String value) {
    switch (value) {
      case 'HEALTHY':
        return '정상';
      case 'MILD':
        return '낮음';
      case 'MODERATE':
        return '중간';
      case 'SEVERE':
        return '높음';
      default:
        return value;
    }
  }

  Color severityColor(String value) {
    switch (value) {
      case 'HEALTHY':
        return Colors.green;
      case 'MILD':
        return Colors.amber;
      case 'MODERATE':
        return Colors.deepOrange;
      case 'SEVERE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  Widget _buildTopSwitch() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTopSwitchButton(
                title: '팜캘린더',
                selected: selectedTopTab == 0,
                onTap: () {
                  setState(() {
                    selectedTopTab = 0;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTopSwitchButton(
                title: '팜매니저',
                selected: selectedTopTab == 1,
                onTap: () {
                  setState(() {
                    selectedTopTab = 1;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSwitchButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              selected ? const Color(0xFF6FAF7D) : Colors.transparent,
          foregroundColor: selected ? Colors.white : Colors.blueGrey.shade700,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFilterTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildChipFilter({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF6FAF7D),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.blueGrey.shade700,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: selected ? const Color(0xFF6FAF7D) : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _buildFilters() {
    if (userRole == 'FARM_MANAGER') {
      return _buildManagerFilters();
    }
    return _buildGeneralUserFilters();
  }

  Widget _filterCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGeneralUserFilters() {
    return _filterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterTitle('작물별'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cropFilters.map((crop) {
                return _buildChipFilter(
                  label: crop,
                  selected: selectedCrop == crop,
                  onTap: () {
                    setState(() {
                      selectedCrop = crop;
                    });
                    loadHistory();
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
          _buildSeverityFilters(),
        ],
      ),
    );
  }

  Widget _buildManagerFilters() {
    return _filterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterTitle('농장'),
          DropdownButtonFormField<int>(
            value: selectedFarmId,
            decoration: _dropdownDecoration('농장 선택'),
            items: farms.map((farm) {
              return DropdownMenuItem<int>(
                value: farm['farm_id'],
                child: Text(farm['farm_name'] ?? '이름 없는 농장'),
              );
            }).toList(),
            onChanged: farms.isEmpty
                ? null
                : (value) async {
                    if (value == null) return;

                    setState(() {
                      selectedFarmId = value;
                      selectedZoneId = null;
                      zones = [];
                    });

                    await loadZones(value);
                    await loadHistory();
                  },
          ),
          const SizedBox(height: 18),
          _buildFilterTitle('구역'),
          DropdownButtonFormField<int?>(
            value: selectedZoneId,
            decoration: _dropdownDecoration('구역 선택'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('전체 구역'),
              ),
              ...zones.map((zone) {
                return DropdownMenuItem<int?>(
                  value: zone['zone_id'],
                  child: Text(zone['zone_name_or_code'] ?? '이름 없는 구역'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                selectedZoneId = value;
              });
              loadHistory();
            },
          ),
          const SizedBox(height: 22),
          _buildSeverityFilters(),
        ],
      ),
    );
  }

  Widget _buildSeverityFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterTitle('심각도'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChipFilter(
                label: '전체',
                selected: selectedSeverity == '',
                onTap: () {
                  setState(() {
                    selectedSeverity = '';
                  });
                  loadHistory();
                },
              ),
              _buildChipFilter(
                label: '심각도 높음',
                selected: selectedSeverity == 'SEVERE',
                onTap: () {
                  setState(() {
                    selectedSeverity = 'SEVERE';
                  });
                  loadHistory();
                },
              ),
              _buildChipFilter(
                label: '심각도 중간',
                selected: selectedSeverity == 'MODERATE',
                onTap: () {
                  setState(() {
                    selectedSeverity = 'MODERATE';
                  });
                  loadHistory();
                },
              ),
              _buildChipFilter(
                label: '심각도 낮음',
                selected: selectedSeverity == 'MILD',
                onTap: () {
                  setState(() {
                    selectedSeverity = 'MILD';
                  });
                  loadHistory();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        locale: 'ko_KR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        eventLoader: getEventsForDay,
        rowHeight: 58,
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, size: 30),
          rightChevronIcon: Icon(Icons.chevron_right, size: 30),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.blueGrey),
          weekendStyle: TextStyle(color: Colors.blueGrey),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: Colors.black87),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF6FAF7D),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        onDaySelected: (newSelectedDay, newFocusedDay) {
          setState(() {
            selectedDay = newSelectedDay;
            focusedDay = newFocusedDay;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CalendarDayHistoryScreen(
                selectedDate: newSelectedDay,
                diagnosisList: selectedDayDiagnosisList,
              ),
            ),
          );
        },
        onPageChanged: (newFocusedDay) {
          focusedDay = newFocusedDay;
          loadMonthlyEvents(newFocusedDay);
        },
      ),
    );
  }

  Widget _buildFarmCalendar() {
    if (isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Expanded(
      child: Container(
        color: Colors.grey.shade100,
        child: RefreshIndicator(
          onRefresh: loadHistory,
          child: ListView(
            children: [
              _buildFilters(),
              _buildCalendar(),
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmManager() {
    return const Expanded(
      child: FarmManagerScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        children: [
          _buildTopSwitch(),
          if (selectedTopTab == 0) _buildFarmCalendar(),
          if (selectedTopTab == 1) _buildFarmManager(),
        ],
      ),
    );
  }
}

class CalendarDayHistoryScreen extends StatelessWidget {
  final DateTime selectedDate;
  final List diagnosisList;
  final Map<String, String> cropIcons = const {
    '옥수수': '🌽',
    '토마토': '🍅',
    '사과': '🍎',
    '포도': '🍇',
    '고추': '🌶️',
    '딸기': '🍓',
  };
  const CalendarDayHistoryScreen({
    super.key,
    required this.selectedDate,
    required this.diagnosisList,
  });

  String formatSelectedDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String formatTime(dynamic item) {
    try {
      final raw = item['event_date']?.toString();
      if (raw == null || raw.isEmpty) return '-';

      final date = DateTime.parse(raw).toLocal();
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? '오전' : '오후';
      final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;

      return '$period $displayHour:$minute';
    } catch (_) {
      return '-';
    }
  }

  String severityLabel(String value) {
    switch (value) {
      case 'HEALTHY':
        return '정상';
      case 'MILD':
        return '낮음';
      case 'MODERATE':
        return '중간';
      case 'SEVERE':
        return '높음';
      default:
        return value;
    }
  }

  Color severityColor(String value) {
    switch (value) {
      case 'HEALTHY':
        return Colors.green;
      case 'MILD':
        return Colors.amber;
      case 'MODERATE':
        return Colors.deepOrange;
      case 'SEVERE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHistoryCard(BuildContext context, dynamic item) {
    final cropName = item['crop_name'] ?? '-';
    final diseaseName = item['disease_name'] ?? '-';
    final severity = item['severity_level'] ?? '-';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    cropIcons[cropName] ?? '🌱',
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cropName,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      diseaseName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatTime(item),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: severityColor(severity),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  severityLabel(severity),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                final diagnosisId = item['diagnosis_id'];

                if (diagnosisId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('진단 상세 정보를 찾을 수 없습니다.'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiagnosisDetailScreen(
                      diagnosisId: diagnosisId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FAF7D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '상세보기',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countText = '총 ${diagnosisList.length}건의 진단 기록';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('팜캘린더'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatSelectedDate(selectedDate),
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  countText,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (diagnosisList.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Text(
                  '해당 날짜의 진단 기록이 없습니다.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...diagnosisList.map((item) => _buildHistoryCard(context, item)),
        ],
      ),
    );
  }
}