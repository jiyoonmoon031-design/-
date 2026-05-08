import 'package:flutter/material.dart';
import '../services/calendar_service.dart';

class AlertResponseScreen extends StatefulWidget {
  final int alertId;

  const AlertResponseScreen({
    super.key,
    required this.alertId,
  });

  @override
  State<AlertResponseScreen> createState() => _AlertResponseScreenState();
}

class _AlertResponseScreenState extends State<AlertResponseScreen> {
  bool isLoading = false;
  String message = '';

  Future<void> respond(String responseValue) async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final result = await CalendarService.respondAlert(
      alertId: widget.alertId,
      alertResponse: responseValue,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
      message = result['message'] ?? '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? '처리 완료')),
    );

    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 응답'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '방제 알림에 대한 응답을 선택해주세요.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : () => respond('COMPLETED'),
              child: const Text('COMPLETED'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : () => respond('HOLD'),
              child: const Text('HOLD'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : () => respond('REMIND_LATER'),
              child: const Text('REMIND_LATER'),
            ),
            const SizedBox(height: 24),
            if (isLoading) const CircularProgressIndicator(),
            if (message.isNotEmpty) Text(message),
          ],
        ),
      ),
    );
  }
}