import 'package:flutter/material.dart';
import '../services/calendar_service.dart';

class TreatmentAlertSettingScreen extends StatefulWidget {
  final int diagnosisId;

  const TreatmentAlertSettingScreen({
    super.key,
    required this.diagnosisId,
  });

  @override
  State<TreatmentAlertSettingScreen> createState() =>
      _TreatmentAlertSettingScreenState();
}

class _TreatmentAlertSettingScreenState
    extends State<TreatmentAlertSettingScreen> {
  bool isLoading = false;

  String selectedPeriod = 'AM';
  int selectedHour = 9;
  int selectedMinute = 0;

  DateTime get tomorrow {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  Future<void> saveAlert() async {
    setState(() {
      isLoading = true;
    });

    final hour24 = selectedPeriod == 'AM'
        ? selectedHour
        : selectedHour == 12
            ? 12
            : selectedHour + 12;

    final scheduledDateTime = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      hour24,
      selectedMinute,
    );

    final result = await CalendarService.createTreatmentAlert(
      diagnosisId: widget.diagnosisId,
      scheduledAt: scheduledDateTime.toIso8601String(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림이 설정되었습니다.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '알림 설정에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = '${tomorrow.year}년 ${tomorrow.month}월 ${tomorrow.day}일';

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  '$dateText에 조치 알림을 설정합니다.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                '오전 / 오후',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('오전')),
                      selected: selectedPeriod == 'AM',
                      onSelected: (_) {
                        setState(() {
                          selectedPeriod = 'AM';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('오후')),
                      selected: selectedPeriod == 'PM',
                      onSelected: (_) {
                        setState(() {
                          selectedPeriod = 'PM';
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                '시간 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedHour,
                      decoration: InputDecoration(
                        labelText: '시',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: List.generate(12, (index) {
                        final hour = index + 1;
                        return DropdownMenuItem(
                          value: hour,
                          child: Text('$hour시'),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedHour = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedMinute,
                      decoration: InputDecoration(
                        labelText: '분',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: [0, 10, 20, 30, 40, 50].map((minute) {
                        return DropdownMenuItem(
                          value: minute,
                          child: Text('${minute.toString().padLeft(2, '0')}분'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedMinute = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : saveAlert,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notifications_active_outlined),
                  label: Text(isLoading ? '설정 중...' : '알림 설정하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FAF7D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}