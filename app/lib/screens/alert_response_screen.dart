import 'package:flutter/material.dart';
import '../services/alert_service.dart';

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
  bool isDetailLoading = true;
  String message = '';

  Map<String, dynamic>? alertInfo;

  String currentResponse = '';
  String currentStatus = '';
  String selectedResponse = '';

  bool showRemindLaterBox = false;

  DateTime? currentScheduledAt;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  int selectedDay = DateTime.now().add(const Duration(days: 1)).day;
  int selectedHour = 9;
  int selectedMinute = 0;

  final Color mainGreen = const Color(0xFF6FAF7D);

  @override
  void initState() {
    super.initState();
    loadAlertDetail();
  }

  List<int> get days {
    final lastDay = DateTime(selectedYear, selectedMonth + 1, 0).day;
    return List.generate(lastDay, (index) => index + 1);
  }

  DateTime makeScheduledDateTime() {
    return DateTime(
      selectedYear,
      selectedMonth,
      selectedDay,
      selectedHour,
      selectedMinute,
    );
  }

  Future<void> loadAlertDetail() async {
    setState(() {
      isDetailLoading = true;
      message = '';
    });

    final result = await AlertService.getAlertDetail(widget.alertId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];

      DateTime? scheduledAt;
      if (data['scheduled_at'] != null) {
        scheduledAt = DateTime.parse(data['scheduled_at']).toLocal();
      }

      final loadedResponse = data['alert_response'] ?? '';

      setState(() {
        alertInfo = data;
        currentResponse = loadedResponse;
        currentStatus = data['alert_status'] ?? '';
        selectedResponse = loadedResponse;
        showRemindLaterBox = loadedResponse == 'REMIND_LATER';
        currentScheduledAt = scheduledAt;

        if (scheduledAt != null) {
          selectedYear = scheduledAt.year;
          selectedMonth = scheduledAt.month;
          selectedDay = scheduledAt.day;
          selectedHour = scheduledAt.hour;
          selectedMinute = scheduledAt.minute;
        }

        isDetailLoading = false;
      });
    } else {
      setState(() {
        isDetailLoading = false;
        message = result['message'] ?? '알림 정보를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> respond(
    String responseValue, {
    DateTime? nextScheduledAt,
  }) async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final result = await AlertService.respondTreatmentAlert(
      alertId: widget.alertId,
      alertResponse: responseValue,
      nextScheduledAt: nextScheduledAt,
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

  Future<void> respondRemindLater() async {
    final scheduledAt = makeScheduledDateTime();

    if (scheduledAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 시간 이후로 설정해주세요.')),
      );
      return;
    }

    await respond(
      'REMIND_LATER',
      nextScheduledAt: scheduledAt,
    );
  }

  void selectResponse(String response) {
    setState(() {
      selectedResponse = response;
      showRemindLaterBox = response == 'REMIND_LATER';
    });
  }

  Widget buildStatusButton({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final bool selected = selectedResponse == value;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              selectResponse(value);

              if (value == 'COMPLETED') {
                respond('COMPLETED');
              } else if (value == 'HOLD') {
                respond('HOLD');
              }
            },
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: selected ? mainGreen : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? mainGreen : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: selected
                  ? Colors.white.withOpacity(0.18)
                  : const Color(0xFFF1F5F9),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 28,
              ),
          ],
        ),
      ),
    );
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
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: mainGreen, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text('$item'),
        );
      }).toList(),
      onChanged: isLoading
          ? null
          : (value) {
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('알림 응답'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: isDetailLoading
            ? Center(
                child: CircularProgressIndicator(color: mainGreen),
              )
            : SingleChildScrollView(
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
                      child: const Text(
                        '방제 알림에 대한 응답을 선택해주세요.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      '조치 상태 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    buildStatusButton(
                      label: '조치 완료',
                      value: 'COMPLETED',
                      icon: Icons.check_circle_outline,
                    ),

                    const SizedBox(height: 12),

                    buildStatusButton(
                      label: '보류',
                      value: 'HOLD',
                      icon: Icons.pause_circle_outline,
                    ),

                    const SizedBox(height: 12),

                    buildStatusButton(
                      label: '나중에 알림',
                      value: 'REMIND_LATER',
                      icon: Icons.notifications_active_outlined,
                    ),

                    if (showRemindLaterBox) ...[
                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '$selectedDateText에 다시 알림을 설정합니다.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 22),

                            const Text(
                              '날짜 선택',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

                                        final lastDay = DateTime(
                                          selectedYear,
                                          selectedMonth + 1,
                                          0,
                                        ).day;

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

                                        final lastDay = DateTime(
                                          selectedYear,
                                          selectedMonth + 1,
                                          0,
                                        ).day;

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

                            const SizedBox(height: 24),

                            const Text(
                              '시간 선택',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

                            const SizedBox(height: 28),

                            SizedBox(
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed:
                                    isLoading ? null : respondRemindLater,
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.notifications_active_outlined,
                                      ),
                                label: Text(
                                  isLoading ? '처리 중...' : '나중에 알림 설정',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mainGreen,
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
                    ],

                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}