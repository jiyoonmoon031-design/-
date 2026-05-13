import 'package:flutter/material.dart';
import '../services/farm_service.dart';
import 'farm_create_screen.dart';
import 'farm_edit_screen.dart';
import 'zone_list_screen.dart';

class FarmListScreen extends StatefulWidget {
  const FarmListScreen({super.key});

  @override
  State<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends State<FarmListScreen> {
  List<Map<String, dynamic>> farms = [];
  bool isLoading = true;
  String message = '';

  @override
  void initState() {
    super.initState();
    loadFarms();
  }

  Future<void> loadFarms() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final result = await FarmService.getFarms();

    if (!mounted) return;

    setState(() {
      isLoading = false;
      if (result['success'] == true) {
        farms = List<Map<String, dynamic>>.from(result['data'] ?? []);
      } else {
        farms = [];
        message = result['message'] ?? '농장 목록을 불러오지 못했습니다.';
      }
    });
  }

  Future<void> moveToCreateFarm() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FarmCreateScreen()),
    );

    if (created == true) {
      await loadFarms();
    }
  }

  Future<void> moveToEditFarm(Map<String, dynamic> farm) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FarmEditScreen(farm: farm),
      ),
    );

    if (updated == true) {
      await loadFarms();
    }
  }

  Future<void> moveToZoneList(Map<String, dynamic> farm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneListScreen(
          farmId: farm['farm_id'],
          farmName: farm['farm_name'] ?? '이름 없는 농장',
        ),
      ),
    );

    await loadFarms();
  }

  String? _farmImageUrl(Map<String, dynamic> farm) {
    final imagePath = farm['farm_image_path']?.toString();

    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    return '${FarmService.baseUrl}/$imagePath';
  }

  Widget _buildFarmImage(Map<String, dynamic> farm) {
    final imageUrl = _farmImageUrl(farm);

    if (imageUrl == null) {
      return const CircleAvatar(
        radius: 28,
        backgroundColor: Color(0xFFEAF6EE),
        child: Text('🌱', style: TextStyle(fontSize: 26)),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFEAF6EE),
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, __) {},
      child: null,
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: message.isNotEmpty
          ? Text(message)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('등록된 농장이 없습니다.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: moveToCreateFarm,
                  child: const Text('농장 추가'),
                ),
              ],
            ),
    );
  }

  Widget _buildFarmCard(Map<String, dynamic> farm) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => moveToZoneList(farm),
        child: Row(
          children: [
            _buildFarmImage(farm),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm['farm_name'] ?? '이름 없는 농장',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    farm['farm_location'] ?? '',
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    farm['farm_description'] ?? '',
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => moveToEditFarm(farm),
              icon: const Icon(Icons.edit),
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
        title: const Text('농장 등록'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6FAF7D),
        onPressed: moveToCreateFarm,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: loadFarms,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : farms.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: _buildEmptyView(),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 18, bottom: 24),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          '등록된 농장을 확인하고 새 농장을 추가하세요.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...farms.map(_buildFarmCard),
                    ],
                  ),
      ),
    );
  }
}