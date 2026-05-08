import 'package:flutter/material.dart';
import '../services/farm_service.dart';

class NearbyFarmDetailScreen extends StatefulWidget {
  final int farmId;
  final int baseFarmId;

  const NearbyFarmDetailScreen({
    super.key,
    required this.farmId,
    required this.baseFarmId,
  });

  @override
  State<NearbyFarmDetailScreen> createState() =>
      _NearbyFarmDetailScreenState();
}

class _NearbyFarmDetailScreenState extends State<NearbyFarmDetailScreen> {
  bool isLoading = true;
  String message = '';

  Map<String, dynamic>? farm;
  List<dynamic> zones = [];

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    final result = await FarmService.getNearbyFarmRiskDetail(
      farmId: widget.farmId,
      baseFarmId: widget.baseFarmId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];

      setState(() {
        farm = data['farm'];
        zones = data['zones'] ?? [];
        isLoading = false;
      });
    } else {
      setState(() {
        message = result['message'] ?? '상세 정보를 불러오지 못했습니다.';
        isLoading = false;
      });
    }
  }

  Color _alertColor(String? level) {
    switch (level) {
      case 'WARNING':
        return Colors.red;
      case 'CAUTION':
        return Colors.deepOrange;
      case 'WATCH':
        return Colors.orange;
      case 'SAFE':
        return Colors.green;
      case 'DATA_INSUFFICIENT':
      default:
        return Colors.blueGrey;
    }
  }

  IconData _alertIcon(String? level) {
    switch (level) {
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'CAUTION':
        return Icons.error_outline;
      case 'WATCH':
        return Icons.visibility_outlined;
      case 'SAFE':
        return Icons.shield_outlined;
      case 'DATA_INSUFFICIENT':
      default:
        return Icons.help_outline;
    }
  }

  String _dataStatusLabel(String? status) {
    switch (status) {
      case 'NO_DATA':
        return '데이터 부족';
      case 'REFERENCE_ONLY':
        return '참고용';
      case 'ENOUGH_DATA':
        return '정상 집계';
      default:
        return '-';
    }
  }

  Widget _buildFarmHeader() {
    if (farm == null) return const SizedBox.shrink();

    final cropSet = zones
        .map((z) => z['crop_name'])
        .where((name) => name != null && name.toString().isNotEmpty)
        .toSet()
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFE8F5EC),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF6FAF7D),
              size: 36,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm!['farm_name'] ?? '-',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${farm!['public_region_label'] ?? '-'} · ${farm!['distance_km'] ?? '-'}km',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    cropSet.isEmpty
                        ? '대표 작물: 정보 없음'
                        : '대표 작물: ${cropSet.join(", ")}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneMiniMap() {
    if (zones.isEmpty) {
      return const Text(
        '공개된 구역 정보가 없습니다.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '구역 미니맵',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '공개 가능한 구역 위험 정보를 확인하세요',
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: zones.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final zone = (zones[index] as Map).cast<String, dynamic>();
              return _buildZoneMiniCard(zone);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildZoneMiniCard(Map<String, dynamic> zone) {
    final preventionAlert =
        (zone['prevention_alert'] as Map?)?.cast<String, dynamic>() ?? {};

    final alertLevel = preventionAlert['alert_level'];
    final alertLabel = preventionAlert['alert_label'] ?? '-';
    final color = _alertColor(alertLevel);

    final topDisease = (zone['top_disease'] as Map?)?.cast<String, dynamic>();
    final diseaseText = topDisease == null
        ? '병해 없음'
        : topDisease['disease_name'] ?? '병해 정보 없음';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showZoneDetailBottomSheet(zone),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              zone['zone_name_or_code'] ?? '구역',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _alertIcon(alertLevel),
                  color: color,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    alertLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              diseaseText,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showZoneDetailBottomSheet(Map<String, dynamic> zone) {
    final preventionAlert =
        (zone['prevention_alert'] as Map?)?.cast<String, dynamic>() ?? {};
    final recent7days =
        (zone['recent_7days'] as Map?)?.cast<String, dynamic>() ?? {};
    final topDisease =
        (zone['top_disease'] as Map?)?.cast<String, dynamic>();
    final otherDiseases = (zone['other_diseases'] as List?) ?? [];

    final alertLevel = preventionAlert['alert_level'];
    final alertLabel = preventionAlert['alert_label'] ?? '-';
    final score = preventionAlert['score'] ?? 0;
    final dataStatus = preventionAlert['data_status'];

    final color = _alertColor(alertLevel);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '구역 상세 정보',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: color.withOpacity(0.14),
                      child: Icon(
                        Icons.grass,
                        color: color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${zone['zone_name_or_code'] ?? '구역'} | ${zone['crop_name'] ?? '작물 정보 없음'}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(_alertIcon(alertLevel), color: color),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        alertLabel,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionBox(
                  child: Text(
                    '최근 7일 진단 수 총 ${recent7days['total_diagnosis_count'] ?? 0}건',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 14),
                _sectionBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '예방 경보 점수',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (score as num).toDouble().clamp(0, 1),
                        minHeight: 9,
                        borderRadius: BorderRadius.circular(20),
                        color: color,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 8),
                      Text('점수: $score'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '주요 병해',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        topDisease == null
                            ? '최근 중간 이상 병해 없음'
                            : '${topDisease['disease_name']} · ${topDisease['count']}건',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '최근 중간 이상 발생일 ${zone['last_moderate_or_severe_date'] ?? '-'}',
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '기타 주의 병해',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (otherDiseases.isEmpty)
                        const Text(
                          '기타 병해 정보가 없습니다.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...otherDiseases.map((item) {
                          final disease =
                              (item as Map).cast<String, dynamic>();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${disease['disease_name']} · ${disease['count']}건',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                disease['last_occurred_date'] ?? '-',
                                style: const TextStyle(
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const Divider(height: 24),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _DetailRow(
                  label: '중간 이상',
                  value:
                      '${recent7days['moderate_or_severe_count'] ?? 0}건',
                ),
                _DetailRow(
                  label: '심각',
                  value: '${recent7days['severe_count'] ?? 0}건',
                ),
                _DetailRow(
                  label: '데이터 상태',
                  value: _dataStatusLabel(dataStatus),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          '농장 위험 정보',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (message.isNotEmpty)
            Text(
              message,
              style: const TextStyle(color: Colors.red),
            )
          else ...[
            _buildFarmHeader(),
            const SizedBox(height: 22),
            _buildZoneMiniMap(),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}