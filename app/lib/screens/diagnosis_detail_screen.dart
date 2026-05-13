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
        return '정상';
      case 'MILD':
        return '경미';
      case 'MODERATE':
        return '중간';
      case 'SEVERE':
        return '심각';
      default:
        return value ?? '-';
    }
  }

  Color _severityColor(String? value) {
    switch (value) {
      case 'HEALTHY':
        return Colors.green;
      case 'MILD':
        return Colors.orange;
      case 'MODERATE':
        return Colors.deepOrange;
      case 'SEVERE':
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
      default:
        return Colors.grey;
    }
  }

  String _formatConfidence(dynamic value) {
    if (value is num) {
      return '${(value * 100).toStringAsFixed(1)}%';
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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

  Widget _buildSummaryCard() {
    final severity = detailData?['severity_level']?.toString();
    final hasDisease = detailData?['has_disease'];
    final confidence = detailData?['confidence_score'];
    final actionStatus = detailData?['action_status']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '진단 요약',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _hasDiseaseLabel(hasDisease),
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _severityColor(severity).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '심각도: ${_severityLabel(severity)}',
                  style: TextStyle(
                    color: _severityColor(severity),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _actionStatusColor(actionStatus).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '상태: ${_actionStatusLabel(actionStatus)}',
                  style: TextStyle(
                    color: _actionStatusColor(actionStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '신뢰도: ${_formatConfidence(confidence)}',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionSection() {
    final detections = (detailData?['detections'] as List?) ?? [];

    if (detections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          '검출된 Bounding Box 정보가 없습니다.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      );
    }

    return Column(
      children: detections.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final det = entry.value;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            '영역 $index: (${det['bbox_xmin']}, ${det['bbox_ymin']}) ~ (${det['bbox_xmax']}, ${det['bbox_ymax']})',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message.isNotEmpty ? message : '상세 정보를 불러올 수 없습니다.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('진단 상세'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (detailData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('진단 상세'),
          centerTitle: true,
        ),
        body: _buildErrorState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('진단 상세'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDetail,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 20),

              _buildSectionTitle('기본 정보'),
              const SizedBox(height: 12),
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
                label: '클래스명',
                value: '${detailData!['class_name'] ?? '-'}',
              ),
              _buildInfoTile(
                label: '진단 시각',
                value: _formatDate(detailData!['diagnosed_at']?.toString()),
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

              const SizedBox(height: 10),
              _buildSectionTitle('추천 조치'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '${detailData!['recommendation_text'] ?? '추천 조치 정보가 없습니다.'}',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Grad-CAM 경로'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '${detailData!['gradcam_path'] ?? '없음'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Bounding Box 목록'),
              const SizedBox(height: 12),
              _buildDetectionSection(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}