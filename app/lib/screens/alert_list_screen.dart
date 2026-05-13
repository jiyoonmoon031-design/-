import 'package:flutter/material.dart';
import '../services/alert_service.dart';
import 'alert_response_screen.dart';

class AlertListScreen extends StatefulWidget {
  const AlertListScreen({super.key});

  @override
  State<AlertListScreen> createState() => _AlertListScreenState();
}

class _AlertListScreenState extends State<AlertListScreen> {
  bool isLoading = true;
  String message = '';
  List<Map<String, dynamic>> alerts = [];

  @override
  void initState() {
    super.initState();
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final result = await AlertService.getTreatmentAlerts(
        alertStatus: 'SENT',
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        alerts = List<Map<String, dynamic>>.from(
          result['data']['alerts'] ?? [],
        );
        isLoading = false;
      });
    } else {
      setState(() {
        message = result['message'] ?? '알림 목록을 불러오지 못했습니다.';
        alerts = [];
        isLoading = false;
      });
    }
  }

  int? parseAlertId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';

    try {
      final date = DateTime.parse(raw).toLocal();
      final y = date.year;
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      final h = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');

      return '$y.$m.$d $h:$min';
    } catch (_) {
      return '-';
    }
  }

  String statusLabel(String value) {
    switch (value) {
      case 'SCHEDULED':
        return '예약됨';
      case 'SENT':
        return '알림 도착';
      case 'CLOSED':
        return '종료';
      case 'RESPONDED':
        return '응답 완료';
      default:
        return value;
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

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final alertId = parseAlertId(alert['alert_id']);
    final cropName = alert['crop_name'] ?? '-';
    final diseaseName = alert['disease_name'] ?? '-';
    final severity = alert['severity_level'] ?? '-';
    final alertStatus = alert['alert_status'] ?? '-';
    final scheduledAt = formatDate(alert['scheduled_at']?.toString());

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        if (alertId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 ID를 찾을 수 없습니다.')),
          );
          return;
        }

        final changed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlertResponseScreen(
              alertId: alertId,
            ),
          ),
        );

        if (changed == true) {
          loadAlerts();
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF6FAF7D),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$cropName | $diseaseName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '알림 시간: $scheduledAt',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '상태: ${statusLabel(alertStatus)}',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: severityColor(severity),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                severityLabel(severity),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('알림 목록'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadAlerts,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : alerts.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          message.isNotEmpty ? message : '도착한 알림이 없습니다.',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 18, bottom: 24),
                    children: alerts.map(_buildAlertCard).toList(),
                  ),
      ),
    );
  }
}