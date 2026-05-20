import 'package:flutter/material.dart';
import 'treatment_alert_setting_screen.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const DiagnosisResultScreen({
    super.key,
    required this.resultData,
  });

  static const String baseUrl = 'http://10.0.2.2:8000';
  static const Color mainGreen = Color(0xFF6FAF7D);

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

  String _formatConfidence(dynamic value) {
    if (value is num) {
      return '${(value).toStringAsFixed(1)}%';
    }
    return '-';
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

  String? _overlayImageUrl() {
    final path =
        resultData['overlay_path'] ??
        resultData['overlay_url']??
        resultData['overlayUrl'];

    if (path == null) return null;

    final pathText = path.toString().replaceAll('\\', '/');

    if (pathText.startsWith('http')) {
      return pathText;
    }

    return '$baseUrl/$pathText';
  }

  String? _gradcamImageUrl() {
    final path =
        resultData['gradcam_path'] ??
        resultData['gradcam_url'] ??
        resultData['gradcamUrl'];

    if (path == null) return null;

    final pathText = path.toString().replaceAll('\\', '/');

    if (pathText.startsWith('http')) {
      return pathText;
    }

    return '$baseUrl/$pathText';
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

  Widget _buildWarningBox({
    required Color bgColor,
    required Color textColor,
    required String text,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
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

  Widget _buildSummaryCard() {
    final severity =
    resultData['severity_level']?.toString() ??
    resultData['severityLabel']?.toString();
    final hasDisease =
        resultData['has_disease'] ??
        !(resultData['isHealthy'] ?? false);
    final confidence =
        resultData['confidence_score'] ??
        resultData['confidence'];
    final severityScore = resultData['severity_score'];
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
                  '진단 결과 요약',
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
                text: '신뢰도: ${_formatConfidence(confidence)}',
                color: Colors.purple,
              ),
              
            ],
          ),
        ],
      ),
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
            width: 82,
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
          print('이미지 로딩 실패: $error');

          return Container(
            height: 220,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: Text(
              '이미지를 불러오지 못했습니다.\n$error',
              textAlign: TextAlign.center,
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
        '${resultData['recommendation_text'] ?? resultData['recommendationText'] ?? '추천 조치 정보가 없습니다.'}',
        style: const TextStyle(
          fontSize: 14,
          height: 1.55,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAlertButton(BuildContext context) {
    if (resultData['has_disease'] != true) {
      return const SizedBox.shrink();
    }

    return SizedBox(
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
          backgroundColor: mainGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool lowConfidenceFlag = resultData['low_confidence_flag'] ?? false;
    final bool retakeRecommendedFlag =
        resultData['retake_recommended_flag'] ?? false;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('진단 결과'),
        centerTitle: true,
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '기본 정보',
              icon: Icons.description_outlined,
              child: Column(
                children: [
                  _buildInfoTile(
                    label: '작물',
                    value: '${resultData['crop_name'] ?? resultData['cropType'] ?? '-'}',
                  ),
                  _buildInfoTile(
                    label: '부위',
                    value: '${resultData['part_name'] ?? resultData['affectedPart'] ?? '-'}',
                  ),
                  _buildInfoTile(
                    label: '병해명',
                    value: '${resultData['disease_name'] ?? resultData['diseaseName'] ?? '-'}',
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

            _buildAlertButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}