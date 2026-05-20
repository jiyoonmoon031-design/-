import 'package:flutter/material.dart';
import '../services/diagnosis_history_service.dart';

class DiagnosisDetailScreen extends StatefulWidget {
  final int diagnosisId;

  const DiagnosisDetailScreen({
    super.key,
    required this.diagnosisId,
  });

  @override
  State<DiagnosisDetailScreen> createState() => _DiagnosisDetailScreenState();
}

class _DiagnosisDetailScreenState extends State<DiagnosisDetailScreen> {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const Color mainGreen = Color(0xFF6FAF7D);

  Map<String, dynamic>? detailData;
  bool isLoading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await DiagnosisHistoryService.getDiagnosisDetail(
        widget.diagnosisId,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        if (result['success'] == true) {
          detailData = result['data'];
        } else {
          detailData = null;
          message = result['message'] ?? '상세 정보를 불러올 수 없습니다.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        detailData = null;
        message = '상세 정보를 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  String _severityLabel(String? value) {
    switch (value) {
      case 'HEALTHY':
      case '정상':
        return '정상';

      case 'MILD':
      case '경미':
        return '경미';

      case 'MODERATE':
      case '중간':
        return '중간';

      case 'SEVERE':
      case '심각':
        return '심각';

      default:
        return value ?? '-';
    }
  }

  Color _severityColor(String? value) {
    switch (value) {
      case 'HEALTHY':
      case '정상':
        return Colors.green;

      case 'MILD':
      case '경미':
        return Colors.yellow.shade700;

      case 'MODERATE':
      case '중간':
        return const Color(0xFFFF9800);

      case 'SEVERE':
      case '심각':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  String _hasDiseaseLabel(dynamic value) {
    if (value == true) return '병해 있음';
    if (value == false) return '병해 없음';
    return '-';
  }

  String _actionStatusLabel(String? value) {
    switch (value) {
      case 'PENDING':
        return '미조치';
      case 'COMPLETED':
        return '조치 완료';
      case 'HOLD':
        return '보류';
      case 'REMIND_LATER':
        return '나중에 알림';
      default:
        return value ?? '-';
    }
  }

  Color _actionStatusColor(String? value) {
    switch (value) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'HOLD':
        return Colors.blueGrey;
      case 'REMIND_LATER':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatConfidence(dynamic value) {
    if (value is num) {
      return '${(value).toStringAsFixed(1)}%';
    }
    return '-';
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';

    try {
      final date = DateTime.parse(rawDate).toLocal();
      final yy = date.year.toString();
      final mm = date.month.toString().padLeft(2, '0');
      final dd = date.day.toString().padLeft(2, '0');
      final hh = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '$yy-$mm-$dd $hh:$min';
    } catch (_) {
      return rawDate;
    }
  }
  String? _overlayImageUrl() {
    final path = detailData?['overlay_path'] ?? detailData?['overlay_url'];

    if (path == null) return null;

    final pathText = path.toString().replaceAll('\\', '/');

    if (pathText.startsWith('http')) {
      return pathText;
    }

    return '$baseUrl/$pathText';
  }

  String? _gradcamImageUrl() {
    final path =
        detailData?['gradcam_path'] ??
        detailData?['gradcam_url'] ??
        detailData?['gradcamUrl'];

    if (path == null) return null;

    final pathText = path.toString().replaceAll('\\', '/');

    if (pathText.startsWith('http')) {
      return pathText;
    }

    return '$baseUrl/$pathText';
  }
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: mainGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: mainGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final severity = detailData?['severity_level']?.toString();
    final hasDisease = detailData?['has_disease'];
    final confidence = detailData?['confidence_score'];
    final actionStatus = detailData?['action_status']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: mainGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: mainGreen,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '진단 상세 요약',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildChip(
                text: _hasDiseaseLabel(hasDisease),
                color: Colors.blueGrey,
              ),
              _buildChip(
                text: '심각도: ${_severityLabel(severity)}',
                color: _severityColor(severity),
              ),
              _buildChip(
                text: '상태: ${_actionStatusLabel(actionStatus)}',
                color: _actionStatusColor(actionStatus),
              ),
              _buildChip(
                text: '신뢰도: ${_formatConfidence(confidence)}',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String? imageUrl) {
    if (imageUrl == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Text(
          '이미지 경로가 없습니다.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 260,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 220,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: const Text(
              '이미지를 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        '${detailData?['recommendation_text'] ?? '추천 조치 정보가 없습니다.'}',
        style: const TextStyle(
          fontSize: 14,
          height: 1.55,
          color: Colors.black87,
        ),
      ),
    );
  }



  Widget _buildErrorState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: _cardDecoration(),
            child: Text(
              message.isNotEmpty ? message : '상세 정보를 불러올 수 없습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('진단 상세'),
        centerTitle: true,
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: const Center(
        child: CircularProgressIndicator(
          color: mainGreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (detailData == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('진단 상세'),
          centerTitle: true,
          backgroundColor: Colors.grey.shade100,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: _buildErrorState(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('진단 상세'),
        centerTitle: true,
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDetail,
          color: mainGreen,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '기본 정보',
                icon: Icons.description_outlined,
                child: Column(
                  children: [
                    _buildInfoTile(
                      label: '작물',
                      value: '${detailData!['crop_name'] ?? '-'}',
                    ),
                    _buildInfoTile(
                      label: '부위',
                      value: '${detailData!['part_name'] ?? '-'}',
                    ),
                    _buildInfoTile(
                      label: '병해명',
                      value: '${detailData!['disease_name'] ?? '-'}',
                    ),
                    _buildInfoTile(
                      label: '진단 시각',
                      value: _formatDate(
                        detailData!['diagnosed_at']?.toString(),
                      ),
                    ),
                    if (detailData!['farm_name'] != null)
                      _buildInfoTile(
                        label: '농장',
                        value: '${detailData!['farm_name']}',
                      ),
                    if (detailData!['zone_name'] != null)
                      _buildInfoTile(
                        label: '구역',
                        value: '${detailData!['zone_name']}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: '병변 탐지 결과',
                icon: Icons.crop_free_outlined,
                child: _buildImageCard(_overlayImageUrl()),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: 'Grad-CAM 분석',
                icon: Icons.local_fire_department_outlined,
                child: _buildImageCard(_gradcamImageUrl()),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: '추천 조치',
                icon: Icons.medical_services_outlined,
                child: _buildRecommendationText(),
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }
}