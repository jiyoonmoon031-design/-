import 'package:flutter/material.dart';
import 'treatment_alert_setting_screen.dart';
class DiagnosisResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const DiagnosisResultScreen({
    super.key,
    required this.resultData,
  });

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

  String _formatConfidence(dynamic value) {
    if (value is num) {
      return '${(value * 100).toStringAsFixed(1)}%';
    }
    return '-';
  }

  Widget _buildWarningBox({
    required Color bgColor,
    required Color textColor,
    required String text,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
            width: 88,
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
    final severity = resultData['severity_level']?.toString();
    final hasDisease = resultData['has_disease'];
    final confidence = resultData['confidence_score'];

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
    final detections = (resultData['detections'] as List?) ?? [];

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

  @override
  Widget build(BuildContext context) {
    final bool lowConfidenceFlag = resultData['low_confidence_flag'] ?? false;
    final bool retakeRecommendedFlag =
        resultData['retake_recommended_flag'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('진단 결과'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (retakeRecommendedFlag)
              _buildWarningBox(
                bgColor: Colors.red.shade50,
                textColor: Colors.red,
                icon: Icons.warning_amber_rounded,
                text: '신뢰도가 낮아 결과 활용을 권장하지 않습니다. 사진을 다시 촬영해주세요.',
              ),
            if (!retakeRecommendedFlag && lowConfidenceFlag)
              _buildWarningBox(
                bgColor: Colors.orange.shade50,
                textColor: Colors.orange.shade800,
                icon: Icons.info_outline,
                text: '신뢰도가 다소 낮습니다. 결과는 참고용으로 확인해주세요.',
              ),
            if (retakeRecommendedFlag || lowConfidenceFlag)
              const SizedBox(height: 16),

            _buildSummaryCard(),
            const SizedBox(height: 20),

            _buildSectionTitle('기본 정보'),
            const SizedBox(height: 12),
            _buildInfoTile(
              label: '작물',
              value: '${resultData['crop_name'] ?? '-'}',
            ),
            _buildInfoTile(
              label: '부위',
              value: '${resultData['part_name'] ?? '-'}',
            ),
            _buildInfoTile(
              label: '병해명',
              value: '${resultData['disease_name'] ?? '-'}',
            ),
            _buildInfoTile(
              label: '클래스명',
              value: '${resultData['class_name'] ?? '-'}',
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
                '${resultData['recommendation_text'] ?? '추천 조치 정보가 없습니다.'}',
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
                '${resultData['gradcam_path'] ?? '없음'}',
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

            const SizedBox(height: 24),

            if (resultData['has_disease'] == true)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final diagnosisId = resultData['diagnosis_id'];

                    if (diagnosisId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('진단 ID가 없어 알림을 설정할 수 없습니다.'),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TreatmentAlertSettingScreen(
                          diagnosisId: diagnosisId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text(
                    '알림 설정',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FAF7D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}