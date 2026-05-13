import 'package:flutter/material.dart';
import 'alert_response_screen.dart';
import '../services/auth_service.dart';
import '../services/alert_service.dart';
import '../services/farm_service.dart';

class FarmManagerScreen extends StatefulWidget {
  const FarmManagerScreen({super.key});

  @override
  State<FarmManagerScreen> createState() => _FarmManagerScreenState();
}

class _FarmManagerScreenState extends State<FarmManagerScreen> {
  bool isLoading = true;
  String message = '';

  String userRole = '';

  List<Map<String, dynamic>> alerts = [];
  Map<String, dynamic> summary = {
    'completed': 0,
    'hold': 0,
    'remind_later': 0,
  };

  String selectedCrop = '전체';
  String selectedSeverity = '';

  List<Map<String, dynamic>> farms = [];
  List<Map<String, dynamic>> zones = [];

  int? selectedFarmId;
  int? selectedZoneId;

  final cropFilters = ['전체', '옥수수', '포도', '사과', '고추', '딸기'];

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

      await loadAlerts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        message = '화면 정보를 불러오지 못했습니다.';
      });
    }
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

  Future<void> loadAlerts() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final result = await AlertService.getTreatmentAlerts(
      cropName: userRole == 'GENERAL_USER' ? selectedCrop : '',
      severityLevel: selectedSeverity,
      farmId: userRole == 'FARM_MANAGER' ? selectedFarmId : null,
      zoneId: userRole == 'FARM_MANAGER' ? selectedZoneId : null,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        summary = result['data']['summary'] ?? {
          'completed': 0,
          'hold': 0,
          'remind_later': 0,
        };
        alerts = List<Map<String, dynamic>>.from(
          result['data']['alerts'] ?? [],
        );
        isLoading = false;
      });
    } else {
      setState(() {
        summary = {
          'completed': 0,
          'hold': 0,
          'remind_later': 0,
        };
        message = result['message'] ?? '조치 목록을 불러오지 못했습니다.';
        alerts = [];
        isLoading = false;
      });
    }
  }

  String severityLabel(String value) {
    switch (value) {
      case 'SEVERE':
        return '높음';
      case 'MODERATE':
        return '중간';
      case 'MILD':
        return '낮음';
      case 'HEALTHY':
        return '정상';
      default:
        return value;
    }
  }

  Color severityColor(String value) {
    switch (value) {
      case 'SEVERE':
        return Colors.red;
      case 'MODERATE':
        return Colors.deepOrange;
      case 'MILD':
        return Colors.orange;
      case 'HEALTHY':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      final y = date.year.toString();
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '$y.$m.$d';
    } catch (_) {
      return '-';
    }
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      padding: const EdgeInsets.symmetric(vertical: 22),
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
      child: Row(
        children: [
          _buildSummaryItem('${summary['completed'] ?? 0}', '조치 완료', Colors.green),
          _buildSummaryItem('${summary['hold'] ?? 0}', '보류 중', Colors.blueGrey),
          _buildSummaryItem('${summary['remind_later'] ?? 0}', '나중에 알림', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String count, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    if (userRole == 'FARM_MANAGER') {
      return _buildManagerFilters();
    }

    return _buildGeneralUserFilters();
  }

  Widget _buildGeneralUserFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('작물별', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: cropFilters.map((crop) {
                return _buildChip(
                  label: crop,
                  selected: selectedCrop == crop,
                  onTap: () {
                    setState(() {
                      selectedCrop = crop;
                    });
                    loadAlerts();
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
          _buildSeverityFilter(),
        ],
      ),
    );
  }

  Widget _buildManagerFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('농장', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: selectedFarmId,
            decoration: InputDecoration(
              labelText: '농장 선택',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
                    await loadAlerts();
                  },
          ),
          const SizedBox(height: 18),
          const Text('구역', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            value: selectedZoneId,
            decoration: InputDecoration(
              labelText: '구역 선택',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
              loadAlerts();
            },
          ),
          const SizedBox(height: 22),
          _buildSeverityFilter(),
        ],
      ),
    );
  }

  Widget _buildSeverityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('심각도', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChip(
                label: '전체',
                selected: selectedSeverity == '',
                onTap: () {
                  setState(() => selectedSeverity = '');
                  loadAlerts();
                },
              ),
              _buildChip(
                label: '심각도 높음',
                selected: selectedSeverity == 'SEVERE',
                onTap: () {
                  setState(() => selectedSeverity = 'SEVERE');
                  loadAlerts();
                },
              ),
              _buildChip(
                label: '심각도 중간',
                selected: selectedSeverity == 'MODERATE',
                onTap: () {
                  setState(() => selectedSeverity = 'MODERATE');
                  loadAlerts();
                },
              ),
              _buildChip(
                label: '심각도 낮음',
                selected: selectedSeverity == 'MILD',
                onTap: () {
                  setState(() => selectedSeverity = 'MILD');
                  loadAlerts();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
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
          color: selected ? Colors.white : Colors.blueGrey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> item) {
    final cropName = item['crop_name'] ?? '-';
    final diseaseName = item['disease_name'] ?? '-';
    final severity = item['severity_level'] ?? '-';
    final confidence = item['confidence_score'] ?? 0;
    final diagnosedAt = formatDate(item['diagnosed_at']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.all(18),
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.yellow.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.grain, color: Colors.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cropName | $diseaseName',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$diagnosedAt / 신뢰도 ${((confidence as num) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlertResponseScreen(
                      alertId: item['alert_id'],
                    ),
                  ),
                );

                if (changed == true) {
                  await loadAlerts();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: const Color(0xFF6FAF7D),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('상태 변경', style: TextStyle(fontSize: 17)),
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: RefreshIndicator(
        onRefresh: loadAlerts,
        child: ListView(
          children: [
            _buildSummaryCard(),
            _buildFilters(),
            const SizedBox(height: 24),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Text(
                    message.isNotEmpty ? message : '알림 설정된 진단 내역이 없습니다.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              ...alerts.map(_buildAlertCard),
          ],
        ),
      ),
    );
  }
}