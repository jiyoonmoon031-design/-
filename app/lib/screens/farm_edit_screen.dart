import 'package:flutter/material.dart';
import '../services/farm_service.dart';

class FarmEditScreen extends StatefulWidget {
  final Map<String, dynamic> farm;

  const FarmEditScreen({
    super.key,
    required this.farm,
  });

  @override
  State<FarmEditScreen> createState() => _FarmEditScreenState();
}

class _FarmEditScreenState extends State<FarmEditScreen> {
  late TextEditingController farmNameController;
  late TextEditingController farmLocationController;
  late TextEditingController farmDescriptionController;

  bool isSaving = false;
  String message = '';

  @override
  void initState() {
    super.initState();

    farmNameController = TextEditingController(
      text: widget.farm['farm_name'] ?? '',
    );
    farmLocationController = TextEditingController(
      text: widget.farm['farm_location'] ?? '',
    );
    farmDescriptionController = TextEditingController(
      text: widget.farm['farm_description'] ?? '',
    );
  }

  @override
  void dispose() {
    farmNameController.dispose();
    farmLocationController.dispose();
    farmDescriptionController.dispose();
    super.dispose();
  }

  Future<void> updateFarm() async {
    FocusScope.of(context).unfocus();

    final farmName = farmNameController.text.trim();
    final farmLocation = farmLocationController.text.trim();
    final farmDescription = farmDescriptionController.text.trim();

    if (farmName.isEmpty) {
      setState(() {
        message = '농장 이름은 필수입니다.';
      });
      return;
    }

    if (farmLocation.isEmpty) {
      setState(() {
        message = '농장 위치 주소는 필수입니다.';
      });
      return;
    }

    setState(() {
      isSaving = true;
      message = '';
    });

    final result = await FarmService.updateFarm(
      farmId: widget.farm['farm_id'],
      farmName: farmName,
      farmLocation: farmLocation,
      farmDescription: farmDescription.isEmpty ? null : farmDescription,
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
      message = result['message'] ?? '';
    });

    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> deleteFarm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('농장 삭제'),
          content: const Text('이 농장을 삭제하시겠습니까?\n연결된 구역도 함께 삭제될 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      isSaving = true;
      message = '';
    });

    final result = await FarmService.deleteFarm(widget.farm['farm_id']);

    if (!mounted) return;

    setState(() {
      isSaving = false;
      message = result['message'] ?? '';
    });

    if (result['success'] == true) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '주소를 수정하면 서버에서 다시 위도·경도로 변환되어 저장됩니다.',
          style: TextStyle(
            color: Color(0xFF2F6B3F),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildGeoInfoBox() {
    final latitude = widget.farm['latitude'];
    final longitude = widget.farm['longitude'];
    final publicRegionLabel = widget.farm['public_region_label'];

    if (latitude == null && longitude == null && publicRegionLabel == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          border: Border.all(color: Colors.blueGrey.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '현재 저장된 위치 정보\n'
          '위도: ${latitude ?? "-"}\n'
          '경도: ${longitude ?? "-"}\n'
          '공개 지역명: ${publicRegionLabel ?? "-"}',
          style: const TextStyle(
            color: Colors.blueGrey,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBox() {
    if (message.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        message,
        style: TextStyle(
          color: message.contains('성공') ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('농장 수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isSaving ? null : deleteFarm,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildTextField(
            controller: farmNameController,
            label: '농장 이름 *',
          ),
          _buildTextField(
            controller: farmLocationController,
            label: '농장 위치 주소 *',
            hintText: '예: 서울특별시 강남구 테헤란로 123',
            icon: Icons.location_on_outlined,
          ),
          _buildInfoBox(),
          _buildGeoInfoBox(),
          _buildTextField(
            controller: farmDescriptionController,
            label: '농장 설명',
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSaving ? null : updateFarm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FAF7D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '수정 완료',
                      style: TextStyle(fontSize: 17),
                    ),
            ),
          ),
          _buildMessageBox(),
        ],
      ),
    );
  }
}