import 'package:flutter/material.dart';
import '../services/farm_service.dart';

class ShareConsentScreen extends StatefulWidget {
  const ShareConsentScreen({super.key});

  @override
  State<ShareConsentScreen> createState() => _ShareConsentScreenState();
}

class _ShareConsentScreenState extends State<ShareConsentScreen> {
  List<dynamic> farms = [];
  List<dynamic> zones = [];

  int? selectedFarmId;
  String selectedLevel = "PARTIAL_PUBLIC";
  Set<int> selectedZoneIds = {};

  bool isLoading = true;
  bool isZoneLoading = false;

  @override
  void initState() {
    super.initState();
    loadFarms();
  }

  Future<void> loadFarms() async {
    try {
      final result = await FarmService.getFarms();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          farms = result['data'] ?? [];
          isLoading = false;
        });

        if (farms.isNotEmpty) {
          selectedFarmId = farms.first["farm_id"];
          await loadZones(selectedFarmId!);
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showMessage(result['message'] ?? "농장 목록을 불러오지 못했습니다.");
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage("농장 목록을 불러오지 못했습니다.");
    }
  }

  Future<void> loadZones(int farmId) async {
    setState(() {
      isZoneLoading = true;
      zones = [];
      selectedZoneIds.clear();
    });

    try {
      final result = await FarmService.getZones(farmId);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          zones = result['data'] ?? [];
          isZoneLoading = false;

          if (selectedLevel == "FULL_PUBLIC") {
            selectedZoneIds = zones
                .map<int>((zone) => zone["zone_id"] as int)
                .toSet();
          }
        });
      } else {
        setState(() {
          isZoneLoading = false;
        });
        showMessage(result['message'] ?? "구역 목록을 불러오지 못했습니다.");
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isZoneLoading = false;
      });

      showMessage("구역 목록을 불러오지 못했습니다.");
    }
  }

  Future<void> saveShareConsent() async {
    if (selectedFarmId == null) {
      showMessage("농장을 선택해주세요.");
      return;
    }

    if (selectedLevel == "PARTIAL_PUBLIC" && selectedZoneIds.isEmpty) {
      showMessage("부분 공개는 공개할 구역을 1개 이상 선택해야 합니다.");
      return;
    }

    try {
      await FarmService().updateShareConsent(
        farmId: selectedFarmId!,
        shareConsentLevel: selectedLevel,
        sharedZoneIds: selectedZoneIds.toList(),
      );

      showMessage("공유 동의 설정이 저장되었습니다.");
    } catch (e) {
      showMessage("공유 동의 설정 저장에 실패했습니다.");
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void selectLevel(String level) {
    setState(() {
      selectedLevel = level;

      if (level == "FULL_PUBLIC") {
        selectedZoneIds = zones
            .map<int>((zone) => zone["zone_id"] as int)
            .toSet();
      } else {
        selectedZoneIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          "공유 동의",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "내 농장과 구역의 공유 범위를 선택하세요.",
              style: TextStyle(fontSize: 16, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 24),

            _levelCard(
              title: "전체 공개",
              description: "CropCare 사용자가 나의 농장과 구역 상태를 볼 수 있어요.",
              icon: Icons.language,
              level: "FULL_PUBLIC",
            ),
            const SizedBox(height: 14),

            _levelCard(
              title: "부분 공개",
              description: "공유하고 싶은 일부 구역만 선택해요.",
              icon: Icons.group_outlined,
              level: "PARTIAL_PUBLIC",
            ),
            const SizedBox(height: 14),

            _levelCard(
              title: "비공개",
              description: "CropCare 사용자가 나의 농장과 구역 상태를 볼 수 없어요.",
              icon: Icons.lock_outline,
              level: "PRIVATE",
            ),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "공유할 농장 및 구역 선택",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (farms.isEmpty)
                    const Text(
                      "등록된 농장이 없습니다.",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: selectedFarmId,
                      decoration: InputDecoration(
                        labelText: "농장 선택",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: farms.map<DropdownMenuItem<int>>((farm) {
                        return DropdownMenuItem<int>(
                          value: farm["farm_id"],
                          child: Text(farm["farm_name"]),
                        );
                      }).toList(),
                      onChanged: selectedLevel == "PRIVATE"
                          ? null
                          : (farmId) async {
                              if (farmId == null) return;

                              setState(() {
                                selectedFarmId = farmId;
                              });

                              await loadZones(farmId);
                            },
                    ),

                  const SizedBox(height: 20),

                  if (selectedLevel == "PRIVATE")
                    const Text(
                      "비공개 상태에서는 구역을 선택할 수 없습니다.",
                      style: TextStyle(color: Colors.grey),
                    )
                  else if (selectedLevel == "FULL_PUBLIC")
                    const Text(
                      "전체 공개 상태입니다. 모든 구역이 자동으로 공유됩니다.",
                      style: TextStyle(color: Colors.grey),
                    )
                  else if (isZoneLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (zones.isEmpty)
                    const Text(
                      "등록된 구역이 없습니다.",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Column(
                      children: zones.map((zone) {
                        final int zoneId = zone["zone_id"];
                        final bool checked = selectedZoneIds.contains(zoneId);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: checked,
                                activeColor: const Color(0xFF6BAF7B),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedZoneIds.add(zoneId);
                                    } else {
                                      selectedZoneIds.remove(zoneId);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                zone["zone_name_or_code"],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: farms.isEmpty ? null : saveShareConsent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6BAF7B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "저장하기",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelCard({
    required String title,
    required String description,
    required IconData icon,
    required String level,
  }) {
    final bool selected = selectedLevel == level;

    return GestureDetector(
      onTap: () => selectLevel(level),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF6BAF7B) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: selected
                  ? const Color(0xFFE8F5EC)
                  : const Color(0xFFF1F5F9),
              child: Icon(
                icon,
                color: selected ? const Color(0xFF6BAF7B) : Colors.grey,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check,
                          color: Color(0xFF6BAF7B),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}