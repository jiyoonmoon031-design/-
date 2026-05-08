import 'package:flutter/material.dart';
import '../services/farm_service.dart';
import 'zone_create_screen.dart';
import 'zone_edit_screen.dart';

class ZoneListScreen extends StatefulWidget {
  final int farmId;
  final String farmName;

  const ZoneListScreen({
    super.key,
    required this.farmId,
    required this.farmName,
  });

  @override
  State<ZoneListScreen> createState() => _ZoneListScreenState();
}

class _ZoneListScreenState extends State<ZoneListScreen> {
  List<Map<String, dynamic>> zones = [];
  bool isLoading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadZones();
  }

  Future<void> loadZones() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final result = await FarmService.getZones(widget.farmId);

    if (!mounted) return;

    setState(() {
      isLoading = false;

      if (result['success'] == true) {
        zones = List<Map<String, dynamic>>.from(result['data'] ?? []);
      } else {
        zones = [];
        message = result['message'] ?? '구역 목록을 불러오지 못했습니다.';
      }
    });
  }

  Future<void> moveToCreateZone() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneCreateScreen(farmId: widget.farmId),
      ),
    );

    if (created == true) {
      await loadZones();
    }
  }

  Future<void> moveToEditZone(Map<String, dynamic> zone) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneEditScreen(zone: zone),
      ),
    );

    if (updated == true) {
      await loadZones();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message.isNotEmpty ? message : '등록된 구역이 없습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: moveToCreateZone,
              child: const Text('구역 추가'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropIcon(String cropName) {
    final icon = switch (cropName) {
      '옥수수' => '🌽',
      '포도' => '🍇',
      '사과' => '🍎',
      '고추' => '🌶️',
      '딸기' => '🍓',
      '토마토' => '🍅',
      _ => '🌱',
    };

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 27)),
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final zoneName = zone['zone_name_or_code'] ?? '이름 없는 구역';
    final cropName = zone['crop_name'] ?? '';
    final zoneDescription = zone['zone_description'] ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => moveToEditZone(zone),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildCropIcon(cropName.toString()),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cropName.toString().isNotEmpty
                        ? '$zoneName | $cropName'
                        : zoneName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (zoneDescription.toString().isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      '설명: $zoneDescription',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: '수정',
              onPressed: () => moveToEditZone(zone),
              icon: const Icon(Icons.edit_outlined),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
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
        title: Text(widget.farmName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6FAF7D),
        onPressed: moveToCreateZone,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadZones,
              child: zones.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: _buildEmptyState(),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        Text(
                          widget.farmName,
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '구역을 선택하거나 새로운 구역을 추가하세요.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ...zones.map(_buildZoneCard),
                      ],
                    ),
            ),
    );
  }
}