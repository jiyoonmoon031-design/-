import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/farm_service.dart';
import 'nearby_farm_detail_screen.dart';

class NearbyFarmScreen extends StatefulWidget {
  const NearbyFarmScreen({super.key});

  @override
  State<NearbyFarmScreen> createState() => _NearbyFarmScreenState();
}

class _NearbyFarmScreenState extends State<NearbyFarmScreen> {
  List<dynamic> myFarms = [];
  List<dynamic> nearbyFarms = [];

  Map<String, dynamic>? selectedBaseFarm;

  bool isLoading = true;
  bool isNearbyLoading = false;

  String sortBy = 'distance';
  String message = '';

  @override
  void initState() {
    super.initState();
    loadMyFarms();
  }

  Future<void> loadMyFarms() async {
    final result = await FarmService.getFarms();

    if (!mounted) return;

    if (result['success'] == true) {
      final farms = result['data'] ?? [];

      setState(() {
        myFarms = farms;
        selectedBaseFarm = farms.isNotEmpty ? farms.first : null;
        isLoading = false;
      });

      if (selectedBaseFarm != null) {
        await loadNearbyFarms();
      }
    } else {
      setState(() {
        isLoading = false;
        message = result['message'] ?? '농장 목록을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> loadNearbyFarms() async {
    if (selectedBaseFarm == null) return;

    setState(() {
      isNearbyLoading = true;
      message = '';
    });

    final result = await FarmService.getNearbyFarms(
      baseFarmId: selectedBaseFarm!['farm_id'],
      radiusKm: 30,
      sortBy: sortBy,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];

      setState(() {
        nearbyFarms = data['farms'] ?? [];
        selectedBaseFarm = {
          ...selectedBaseFarm!,
          ...data['base_farm'],
        };
        isNearbyLoading = false;
      });
    } else {
      setState(() {
        nearbyFarms = [];
        isNearbyLoading = false;
        message = result['message'] ?? '인근 농장 조회 실패';
      });
    }
  }

  LatLng? get baseLatLng {
    if (selectedBaseFarm == null) return null;

    final lat = selectedBaseFarm!['latitude'];
    final lng = selectedBaseFarm!['longitude'];

    if (lat == null || lng == null) return null;

    return LatLng(
        (lat as num).toDouble(),
        (lng as num).toDouble(),
    );
    }

  List<Marker> buildMarkers() {
  final markers = <Marker>[];

  final base = baseLatLng;

  // 내 농장 위치 마커
  if (base != null) {
    markers.add(
      Marker(
        point: base,
        width: 120,
        height: 90,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF6FAF7D),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                '내 농장 · ${selectedBaseFarm?['farm_name'] ?? ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            const Icon(
              Icons.my_location,
              size: 42,
              color: Color(0xFF6FAF7D),
            ),
          ],
        ),
      ),
    );
  }

  // 인근 농장 위치 마커
  for (final farm in nearbyFarms) {
    final lat = farm['latitude'];
    final lng = farm['longitude'];

    if (lat == null || lng == null) continue;

    markers.add(
      Marker(
        point: LatLng(
          (lat as num).toDouble(),
          (lng as num).toDouble(),
        ),
        width: 150,
        height: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Text(
                '${farm['farm_name']} · ${farm['distance_km']}km',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            const Icon(
              Icons.location_on,
              color: Color(0xFF6FAF7D),
              size: 34,
            ),
          ],
        ),
      ),
    );
  }

  return markers;
}

  void changeSort(String value) async {
    setState(() {
      sortBy = value;
    });

    await loadNearbyFarms();
  }

  @override
  Widget build(BuildContext context) {
    final center = baseLatLng ?? const LatLng(37.5665, 126.9780);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          '인근 농장 조회',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            '주변 농장의 공개 정보를 확인하세요.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 16),

          if (myFarms.isEmpty)
            const Text(
              '등록된 농장이 없습니다. 먼저 농장을 등록해주세요.',
              style: TextStyle(color: Colors.grey),
            )
          else
            DropdownButtonFormField<int>(
              value: selectedBaseFarm?['farm_id'],
              decoration: InputDecoration(
                labelText: '기준 농장 선택',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: myFarms.map<DropdownMenuItem<int>>((farm) {
                return DropdownMenuItem<int>(
                  value: farm['farm_id'],
                  child: Text(farm['farm_name']),
                );
              }).toList(),
              onChanged: (farmId) async {
                if (farmId == null) return;

                final farm = myFarms.firstWhere(
                  (item) => item['farm_id'] == farmId,
                );

                setState(() {
                  selectedBaseFarm = farm;
                });

                await loadNearbyFarms();
              },
            ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 280,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 10,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.cropcare',
                  ),
                  MarkerLayer(
                    markers: buildMarkers(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              ChoiceChip(
                label: const Text('가까운 순'),
                selected: sortBy == 'distance',
                selectedColor: const Color(0xFF6FAF7D),
                labelStyle: TextStyle(
                  color: sortBy == 'distance' ? Colors.white : Colors.black,
                ),
                onSelected: (_) => changeSort('distance'),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('가나다순'),
                selected: sortBy == 'name',
                selectedColor: const Color(0xFF6FAF7D),
                labelStyle: TextStyle(
                  color: sortBy == 'name' ? Colors.white : Colors.black,
                ),
                onSelected: (_) => changeSort('name'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (isNearbyLoading)
            const Center(child: CircularProgressIndicator())
          else if (message.isNotEmpty)
            Text(
              message,
              style: const TextStyle(color: Colors.red),
            )
          else if (nearbyFarms.isEmpty)
            const Text(
              '반경 30km 이내에 공유된 인근 농장이 없습니다.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Column(
              children: nearbyFarms.map((farm) {
                return GestureDetector(
                  onTap: () {
                    if (selectedBaseFarm == null) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NearbyFarmDetailScreen(
                          farmId: farm['farm_id'],
                          baseFarmId: selectedBaseFarm!['farm_id'],
                        ),
                      ),
                    );
                  },
                  child: _NearbyFarmCard(farm: farm),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _NearbyFarmCard extends StatelessWidget {
  final Map<String, dynamic> farm;

  const _NearbyFarmCard({
    required this.farm,
  });

  @override
  Widget build(BuildContext context) {
    final cropNames = (farm['crop_names'] as List?) ?? [];
    final diseaseNames = (farm['disease_names'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
            radius: 30,
            backgroundColor: const Color(0xFFE8F5EC),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF6FAF7D),
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm['farm_name'] ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${farm['public_region_label'] ?? '-'} · ${cropNames.isEmpty ? '작물 정보 없음' : cropNames.join(", ")}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diseaseNames.isEmpty
                      ? '최근 병해 정보 없음'
                      : '병해: ${diseaseNames.join(", ")}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${farm['distance_km']}km',
            style: const TextStyle(
              color: Color(0xFF6FAF7D),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}