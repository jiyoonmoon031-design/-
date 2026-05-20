import 'package:flutter/material.dart';

import 'diagnosis_detail_screen.dart';

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

      if (raw == null || raw.isEmpty) {
        return '-';
      }

      final date = DateTime.parse(raw).toLocal();

      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');

      final period = hour < 12 ? '오전' : '오후';

      final displayHour =
          hour == 0
              ? 12
              : hour > 12
              ? hour - 12
              : hour;

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
        return '경미';

      case 'MODERATE':
        return '중간';

      case 'SEVERE':
        return '심각';

      default:
        return value;
    }
  }

  Color severityColor(String value) {
    switch (value) {
      case 'HEALTHY':
      case '정상':
        return Colors.green;

      case 'MILD':
      case '경미':
      case '낮음':
        return Colors.yellow.shade700;

      case 'MODERATE':
      case '중간':
        return const Color(0xFFFFB74D);

      case 'SEVERE':
      case '심각':
      case '높음':
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
            ...diagnosisList.map(
              (item) => _buildHistoryCard(context, item),
            ),
        ],
      ),
    );
  }
}