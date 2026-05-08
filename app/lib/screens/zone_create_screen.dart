import 'package:flutter/material.dart';
import '../services/farm_service.dart';

class ZoneCreateScreen extends StatefulWidget {
  final int farmId;

  const ZoneCreateScreen({super.key, required this.farmId});

  @override
  State<ZoneCreateScreen> createState() => _ZoneCreateScreenState();
}

class _ZoneCreateScreenState extends State<ZoneCreateScreen> {
  final TextEditingController zoneNameController = TextEditingController();
  final TextEditingController cropNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isLoading = false;
  String message = '';

  Future<void> createZone() async {
    FocusScope.of(context).unfocus();

    final zoneName = zoneNameController.text.trim();
    final cropName = cropNameController.text.trim();
    final description = descriptionController.text.trim();

    if (zoneName.isEmpty) {
      setState(() {
        message = '구역명 또는 코드는 필수입니다.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await FarmService.createZone(
        farmId: widget.farmId,
        zoneNameOrCode: zoneName,
        cropName: cropName.isEmpty ? null : cropName,
        zoneDescription: description.isEmpty ? null : description,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        message = result['message'] ?? '';
      });

      if (result['success'] == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        message = '서버 오류가 발생했습니다.';
      });
    }
  }

  @override
  void dispose() {
    zoneNameController.dispose();
    cropNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('구역 등록'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildTextField(
            controller: zoneNameController,
            label: '구역명 또는 코드 *',
          ),
          _buildTextField(
            controller: cropNameController,
            label: '작물명',
          ),
          _buildTextField(
            controller: descriptionController,
            label: '구역 설명',
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : createZone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FAF7D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '등록 완료',
                      style: TextStyle(fontSize: 17),
                    ),
            ),
          ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}