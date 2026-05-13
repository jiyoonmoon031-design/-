import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/farm_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  bool isChartLoading = false;
  String message = '';

  String userRole = '';

  Map<String, dynamic> overallData = {};
  List<Map<String, dynamic>> groupKpis = [];
  List<Map<String, dynamic>> farms = [];
  Map<String, dynamic> chartData = {};

  int selectedGroupIndex = -1;
  int? selectedFarmId;

  final Color mainGreen = const Color(0xFF6FAF7D);

  final Map<String, String> cropIcons = {
    '옥수수': '🌽',
    '토마토': '🍅',
    '사과': '🍎',
    '포도': '🍇',
    '고추': '🌶️',
    '딸기': '🍓',
  };

  final List<Color> chartColors = const [
    Color(0xFF1E88E5),
    Color(0xFFE53935),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFFDD835),
    Color(0xFF6D4C41),
    Color(0xFFD81B60),
    Color(0xFF3949AB),
  ];

  List<Map<String, dynamic>> get visibleGroupKpis {
    if (userRole != 'FARM_MANAGER') return groupKpis;
    if (selectedFarmId == null) return [];

    return groupKpis.where((g) {
      return g['farm_id'] == selectedFarmId;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
      message = '';
      chartData = {};
    });

    try {
      final userInfo = await AuthService.getMyInfo();
      final role = userInfo?['user_role'] ?? '';

      Map<String, dynamic>? farmResult;

      if (role == 'FARM_MANAGER') {
        farmResult = await FarmService.getFarms();
      }

      final farmList = role == 'FARM_MANAGER'
          ? List<Map<String, dynamic>>.from(farmResult?['data'] ?? [])
          : <Map<String, dynamic>>[];

      int? firstFarmId;

      if (role == 'FARM_MANAGER' && farmList.isNotEmpty) {
        firstFarmId = farmList.first['farm_id'] as int?;
      }

      final overallResult = await DashboardService.getDashboard(
        farmId: firstFarmId,
      );

      final groupResult = await DashboardService.getGroupKpi();

      if (!mounted) return;

      if (overallResult['success'] == true && groupResult['success'] == true) {
        final groups =
            List<Map<String, dynamic>>.from(groupResult['data'] ?? []);

        int firstGroupIndex = -1;

        if (role == 'FARM_MANAGER') {
          if (firstFarmId != null) {
            firstGroupIndex = groups.indexWhere(
              (g) => g['farm_id'] == firstFarmId,
            );
          }
        } else {
          firstGroupIndex = groups.isNotEmpty ? 0 : -1;
        }

        setState(() {
          userRole = role;
          overallData = overallResult['data'] ?? {};
          groupKpis = groups;
          farms = farmList;
          selectedFarmId = firstFarmId;
          selectedGroupIndex = firstGroupIndex;
          isLoading = false;
        });

        if (firstGroupIndex != -1) {
          await loadChart(groups[firstGroupIndex]);
        }
      } else {
        setState(() {
          message = overallResult['message'] ??
              groupResult['message'] ??
              '대시보드를 불러오지 못했습니다.';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = '대시보드를 불러오는 중 오류가 발생했습니다.';
        isLoading = false;
      });
    }
  }

  Future<void> loadChart(Map<String, dynamic> group) async {
    setState(() {
      isChartLoading = true;
      message = '';
    });

    final result = await DashboardService.getGroupCharts(
      cropName: userRole == 'GENERAL_USER' ? group['crop_name'] : null,
      farmId: userRole == 'FARM_MANAGER' ? group['farm_id'] : null,
      zoneId: userRole == 'FARM_MANAGER' ? group['zone_id'] : null,
    );

    if (!mounted) return;

    setState(() {
      if (result['success'] == true) {
        chartData = result['data'] ?? {};
      } else {
        chartData = {};
        message = result['message'] ?? '그래프 데이터를 불러오지 못했습니다.';
      }
      isChartLoading = false;
    });
  }

  String _percentFromSeverity(dynamic value) {
    if (value is num) {
      return '${((value / 3) * 100).round()}%';
    }
    return '0%';
  }

  String _rate(dynamic value) {
    if (value is num) {
      return '${(value * 100).round()}%';
    }
    return '0%';
  }

  Color _severityColor(dynamic value) {
    final percent = value is num ? ((value / 3) * 100).round() : 0;
    if (percent >= 75) return Colors.red;
    if (percent >= 60) return Colors.deepOrange;
    return mainGreen;
  }

  String _selectedTitle() {
    if (selectedGroupIndex < 0 || selectedGroupIndex >= groupKpis.length) {
      return '';
    }

    final group = groupKpis[selectedGroupIndex];

    if (userRole == 'FARM_MANAGER') {
      return group['zone_name'] ??
          group['zone_name_or_code'] ??
          '구역 ${group['zone_id']}';
    }

    return group['crop_name'] ?? '';
  }

  Widget _sectionTitle(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (trailing != null && trailing.isNotEmpty)
            Flexible(
              child: Text(
                trailing,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: mainGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({bool selected = false}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: selected
          ? Border.all(color: mainGreen, width: 2)
          : Border.all(color: Colors.grey.shade200),
    );
  }

  Widget _buildFarmSelector() {
    if (userRole != 'FARM_MANAGER') {
      return const SizedBox.shrink();
    }

    if (farms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const Text('등록된 농장이 없습니다.'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '농장 선택',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: selectedFarmId,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
            items: farms.map((farm) {
              return DropdownMenuItem<int>(
                value: farm['farm_id'] as int,
                child: Text(farm['farm_name'] ?? '이름 없는 농장'),
              );
            }).toList(),
            onChanged: (value) async {
              if (value == null) return;

              final farmGroups =
                  groupKpis.where((g) => g['farm_id'] == value).toList();

              final nextIndex = farmGroups.isNotEmpty
                  ? groupKpis.indexOf(farmGroups.first)
                  : -1;

              setState(() {
                selectedFarmId = value;
                selectedGroupIndex = nextIndex;
                chartData = {};
                message = '';
                isChartLoading = true;
              });

              final overallResult = await DashboardService.getDashboard(
                farmId: value,
              );

              if (!mounted) return;

              setState(() {
                if (overallResult['success'] == true) {
                  overallData = overallResult['data'] ?? {};
                } else {
                  message = overallResult['message'] ?? '전체 KPI 조회 실패';
                }
              });

              if (nextIndex != -1) {
                await loadChart(groupKpis[nextIndex]);
              } else {
                setState(() {
                  isChartLoading = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverallSummary() {
    final kpi = overallData['kpi'] ?? {};

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userRole == 'FARM_MANAGER' ? '선택 농장 요약' : '전체 KPI',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _summaryItem(
                _percentFromSeverity(kpi['average_severity']),
                '평균 심각도',
                Colors.indigo.shade900,
              ),
              _summaryItem(
                _rate(kpi['completion_rate']),
                '조치 완료율',
                mainGreen,
              ),
              _summaryItem(
                '${kpi['disease_count'] ?? 0}건',
                '병해 발생',
                Colors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupKpiGrid() {
    final list = visibleGroupKpis;

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const Center(
          child: Text('선택한 농장에 표시할 구역 KPI 데이터가 없습니다.'),
        ),
      );
    }

    return GridView.builder(
      itemCount: list.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final item = list[index];
        final realIndex = groupKpis.indexOf(item);
        final selected = selectedGroupIndex == realIndex;

        final cropName = item['crop_name'] ?? '-';

        final farmName = item['farm_name'] ??
            '농장 ${item['farm_id']}';

        final zoneName = item['zone_name'] ??
            item['zone_name_or_code'] ??
            '구역 ${item['zone_id']}';

        final zoneCropName = item['zone_crop_name'] ??
            item['crop_name'] ??
            '-';

        final title = userRole == 'FARM_MANAGER'
            ? '$farmName\n$zoneName · $zoneCropName'
            : cropName;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            setState(() {
              selectedGroupIndex = realIndex;
            });
            await loadChart(item);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(selected: selected),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          cropIcons[userRole == 'FARM_MANAGER' ? zoneCropName : cropName] ?? '🌱',
                          style: const TextStyle(fontSize: 21),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '최근 30일',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
                const SizedBox(height: 8),
                _kpiRow(
                  '평균 심각도',
                  _percentFromSeverity(item['average_severity']),
                  _severityColor(item['average_severity']),
                ),
                _kpiRow(
                  '조치 완료율',
                  _rate(item['completion_rate']),
                  mainGreen,
                ),
                _kpiRow(
                  '병해 발생',
                  '${item['disease_count'] ?? 0}건',
                  Colors.black,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kpiRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    if (selectedGroupIndex < 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          userRole == 'FARM_MANAGER' ? '구역 상세 분석' : '작물 상세 분석',
          trailing:
              '선택 ${userRole == 'FARM_MANAGER' ? '구역' : '작물'}: ${_selectedTitle()}',
        ),
        if (isChartLoading)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: mainGreen),
            ),
          )
        else ...[
          _chartCard('일별 평균 심각도', _dailySeverityChart()),
          _chartCard('병해별 발생 빈도', _diseaseBarChart()),
          _chartCard('병해 분포', _diseasePieChart()),
        ],
      ],
    );
  }

  Widget _chartCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildLegend(List<Map<String, dynamic>> data) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(data.length, (index) {
        final diseaseName =
            data[index]['disease_name']?.toString() ?? '알 수 없음';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: chartColors[index % chartColors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              diseaseName,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }),
    );
  }

  Widget _dailySeverityChart() {
    final data = List<Map<String, dynamic>>.from(
      chartData['daily_severity_by_disease'] ?? [],
    );

    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('일별 심각도 데이터가 없습니다.')),
      );
    }

    final allDates = <String>{};

    for (final disease in data) {
      final daily = List<Map<String, dynamic>>.from(disease['data'] ?? []);
      for (final item in daily) {
        final date = item['date']?.toString();
        if (date != null && date.isNotEmpty) {
          allDates.add(date);
        }
      }
    }

    final dateList = allDates.toList()..sort();

    if (dateList.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('일별 심각도 데이터가 없습니다.')),
      );
    }

    final lines = <LineChartBarData>[];

    for (int i = 0; i < data.length; i++) {
      final disease = data[i];
      final daily = List<Map<String, dynamic>>.from(disease['data'] ?? []);
      final spots = <FlSpot>[];

      for (int j = 0; j < daily.length; j++) {
        final date = daily[j]['date']?.toString() ?? '';
        final dateIndex = dateList.indexOf(date);

        if (dateIndex == -1) continue;

        final score = daily[j]['average_severity'] ?? 0;

        spots.add(
          FlSpot(
            dateIndex.toDouble(),
            ((score as num) * 10).toDouble(),
          ),
        );
      }

      if (spots.isEmpty) continue;

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          color: chartColors[i % chartColors.length],
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4.5,
                color: barData.color ?? Colors.black,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(data),
        const SizedBox(height: 18),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (dateList.length - 1).toDouble(),
              minY: 0,
              maxY: 30,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= dateList.length) {
                        return const SizedBox.shrink();
                      }

                      final isLast = index == dateList.length - 1;

                      if (index % 7 != 0 && !isLast) {
                        return const SizedBox.shrink();
                      }

                      final date = dateList[index];
                      final label =
                          date.length >= 10 ? date.substring(5) : date;

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: lines,
            ),
          ),
        ),
      ],
    );
  }

  Widget _diseaseBarChart() {
    final data =
        List<Map<String, dynamic>>.from(chartData['disease_frequency'] ?? []);

    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('병해 발생 데이터가 없습니다.')),
      );
    }

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index]['disease_name']?.toString() ?? '',
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(data.length, (index) {
            final count = data[index]['count'] ?? 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (count as num).toDouble(),
                  width: 34,
                  color: chartColors[index % chartColors.length],
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _diseasePieChart() {
    final data = List<Map<String, dynamic>>.from(
      chartData['disease_distribution'] ?? [],
    );

    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('병해 분포 데이터가 없습니다.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(data),
        const SizedBox(height: 18),
        SizedBox(
          height: 280,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 58,
              sections: List.generate(data.length, (index) {
                final ratio = data[index]['ratio'] ?? 0;
                final percent = (ratio as num) * 100;

                return PieChartSectionData(
                  value: percent.toDouble(),
                  title: '${percent.toStringAsFixed(0)}%',
                  color: chartColors[index % chartColors.length],
                  radius: 72,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('대시보드'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: mainGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('대시보드'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: mainGreen,
          onRefresh: loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (userRole == 'FARM_MANAGER') ...[
                _buildFarmSelector(),
                const SizedBox(height: 18),
              ],
              _buildOverallSummary(),
              _sectionTitle(
                userRole == 'FARM_MANAGER' ? '구역별 KPI 비교' : '작물별 KPI 비교',
              ),
              _buildGroupKpiGrid(),
              _buildCharts(),
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}