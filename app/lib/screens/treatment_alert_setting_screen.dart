import 'package:flutter/material.dart';
import '../services/alert_service.dart';

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

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  int selectedDay = DateTime.now().add(const Duration(days: 1)).day;
  int selectedHour = 9;
  int selectedMinute = 0;

  Future<void> saveAlert() async {
    final scheduledDateTime = DateTime(
      selectedYear,
      selectedMonth,
      selectedDay,
      selectedHour,
      selectedMinute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 시간 이후로 알림 시간을 설정해주세요.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await AlertService.createTreatmentAlert(
      diagnosisId: widget.diagnosisId,
      scheduledAt: scheduledDateTime.toIso8601String(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('나중에 알림이 설정되었습니다.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '알림 설정에 실패했습니다.')),
      );
    }
  }

  List<int> get days {
    final lastDay = DateTime(selectedYear, selectedMonth + 1, 0).day;
    return List.generate(lastDay, (index) => index + 1);
  }

  Widget buildDropdown({
    required String label,
    required int value,
    required List<int> items,
    required void Function(int value) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text('$item'),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateText =
        '$selectedYear년 $selectedMonth월 $selectedDay일 '
        '${selectedHour.toString().padLeft(2, '0')}:'
        '${selectedMinute.toString().padLeft(2, '0')}';

    final now = DateTime.now();

    final yearItems = List.generate(3, (index) => now.year + index);
    final monthItems = List.generate(12, (index) => index + 1);
    final dayItems = days;
    final hourItems = List.generate(24, (index) => index);
    final minuteItems = List.generate(60, (index) => index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  '$selectedDateText에 조치 알림을 설정합니다.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                '날짜 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: buildDropdown(
                      label: '년',
                      value: selectedYear,
                      items: yearItems,
                      onChanged: (value) {
                        setState(() {
                          selectedYear = value;

                          final lastDay =
                              DateTime(selectedYear, selectedMonth + 1, 0).day;
                          if (selectedDay > lastDay) {
                            selectedDay = lastDay;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildDropdown(
                      label: '월',
                      value: selectedMonth,
                      items: monthItems,
                      onChanged: (value) {
                        setState(() {
                          selectedMonth = value;

                          final lastDay =
                              DateTime(selectedYear, selectedMonth + 1, 0).day;
                          if (selectedDay > lastDay) {
                            selectedDay = lastDay;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildDropdown(
                      label: '일',
                      value: selectedDay,
                      items: dayItems,
                      onChanged: (value) {
                        setState(() {
                          selectedDay = value;
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
                    child: buildDropdown(
                      label: '시',
                      value: selectedHour,
                      items: hourItems,
                      onChanged: (value) {
                        setState(() {
                          selectedHour = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: buildDropdown(
                      label: '분',
                      value: selectedMinute,
                      items: minuteItems,
                      onChanged: (value) {
                        setState(() {
                          selectedMinute = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

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