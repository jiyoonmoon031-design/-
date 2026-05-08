import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/diagnosis_service.dart';
import '../services/farm_service.dart';
import 'diagnosis_result_screen.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final ImagePicker picker = ImagePicker();

  File? selectedImage;
  bool isLoading = false;
  bool isInitLoading = true;
  String message = '';

  String userRole = '';

  List<dynamic> farms = [];
  List<dynamic> zones = [];

  int? selectedFarmId;
  int? selectedZoneId;

  @override
  void initState() {
    super.initState();
    initScreen();
  }

  Future<void> initScreen() async {
    setState(() {
      isInitLoading = true;
      message = '';
      farms = [];
      zones = [];
      selectedFarmId = null;
      selectedZoneId = null;
    });

    try {
      final userInfo = await AuthService.getMyInfo();

      if (!mounted) return;

      final role = userInfo?['user_role'] ?? '';

      setState(() {
        userRole = role;
      });

      if (role == 'FARM_MANAGER') {
        await loadFarms();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = '사용자 정보를 불러오지 못했습니다.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isInitLoading = false;
      });
    }
  }

  Future<void> loadFarms() async {
    final result = await FarmService.getFarms();

    if (!mounted) return;

    if (result['success'] == true) {
      final farmList = result['data'] ?? [];

      setState(() {
        farms = farmList;
      });

      if (farmList.isNotEmpty) {
        final firstFarmId = farmList.first['farm_id'] as int;

        setState(() {
          selectedFarmId = firstFarmId;
        });

        await loadZones(firstFarmId);
      }
    } else {
      setState(() {
        message = result['message'] ?? '농장 목록을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> loadZones(int farmId) async {
    final result = await FarmService.getZones(farmId);

    if (!mounted) return;

    if (result['success'] == true) {
      final zoneList = result['data'] ?? [];

      setState(() {
        zones = zoneList;
        selectedZoneId =
            zoneList.isNotEmpty ? zoneList.first['zone_id'] as int : null;
      });
    } else {
      setState(() {
        zones = [];
        selectedZoneId = null;
        message = result['message'] ?? '구역 목록을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> pickImageFromGallery() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        message = '';
      });
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
        message = '';
      });
    }
  }

  Future<void> diagnoseImage() async {
    FocusScope.of(context).unfocus();

    if (selectedImage == null) {
      setState(() {
        message = '이미지를 먼저 선택해주세요.';
      });
      return;
    }

    if (userRole == 'FARM_MANAGER') {
      if (selectedFarmId == null) {
        setState(() {
          message = '농장을 선택해주세요.';
        });
        return;
      }

      if (selectedZoneId == null) {
        setState(() {
          message = '구역을 선택해주세요.';
        });
        return;
      }
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await DiagnosisService.uploadDiagnosis(
        selectedImage!,
        zoneId: userRole == 'FARM_MANAGER' ? selectedZoneId : null,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiagnosisResultScreen(
              resultData: result['data'],
            ),
          ),
        );
      } else {
        setState(() {
          message = result['message'] ?? '진단 요청에 실패했습니다.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = '진단 요청 중 오류가 발생했습니다.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF6FAF7D).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.local_florist_outlined,
              color: Color(0xFF6FAF7D),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              userRole == 'FARM_MANAGER'
                  ? '농장과 구역을 선택한 뒤 작물 사진을 업로드해 진단할 수 있어요.'
                  : '작물 사진을 업로드해 병해 여부와 심각도를 확인해보세요.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerSelectors() {
    if (userRole != 'FARM_MANAGER') {
      return const SizedBox.shrink();
    }

    if (farms.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          '등록된 농장이 없습니다. 먼저 농장과 구역을 등록해주세요.',
          style: TextStyle(fontSize: 14),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '농장 / 구역 선택',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: '농장/구역 새로고침',
                onPressed: isLoading ? null : initScreen,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: selectedFarmId,
            decoration: _dropdownDecoration(
              '농장 선택',
              Icons.agriculture_outlined,
            ),
            items: farms.map<DropdownMenuItem<int>>((farm) {
              return DropdownMenuItem<int>(
                value: farm['farm_id'] as int,
                child: Text(farm['farm_name'] ?? '이름 없는 농장'),
              );
            }).toList(),
            onChanged: (value) async {
              if (value == null) return;

              setState(() {
                selectedFarmId = value;
                zones = [];
                selectedZoneId = null;
                message = '';
              });

              await loadZones(value);
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            value: selectedZoneId,
            decoration: _dropdownDecoration(
              '구역 선택',
              Icons.grid_view_outlined,
            ),
            items: zones.map<DropdownMenuItem<int>>((zone) {
              return DropdownMenuItem<int>(
                value: zone['zone_id'] as int,
                child: Text(zone['zone_name_or_code'] ?? '이름 없는 구역'),
              );
            }).toList(),
            onChanged: zones.isEmpty
                ? null
                : (value) {
                    setState(() {
                      selectedZoneId = value;
                      message = '';
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: selectedImage != null
          ? Image.file(
              selectedImage!,
              fit: BoxFit.cover,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    size: 44,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '선택된 이미지가 없습니다.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : pickImageFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('갤러리'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6FAF7D),
                  side: const BorderSide(color: Color(0xFF6FAF7D)),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : pickImageFromCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('카메라'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6FAF7D),
                  side: const BorderSide(color: Color(0xFF6FAF7D)),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : diagnoseImage,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search),
            label: Text(
              isLoading ? '진단 요청 중...' : '진단 요청',
              style: const TextStyle(fontSize: 17),
            ),
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
    );
  }

  Widget _buildMessageBox() {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isInitLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      color: Colors.grey.shade100,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: initScreen,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _buildGuideCard(),
              const SizedBox(height: 16),
              _buildManagerSelectors(),
              if (userRole == 'FARM_MANAGER') const SizedBox(height: 16),
              _buildImagePreview(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 14),
              _buildMessageBox(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}