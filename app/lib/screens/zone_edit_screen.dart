import 'package:flutter/material.dart';
import '../services/farm_service.dart';

class ZoneEditScreen extends StatefulWidget {
  final Map<String, dynamic> zone;

  const ZoneEditScreen({
    super.key,
    required this.zone,
  });

  @override
  State<ZoneEditScreen> createState() => _ZoneEditScreenState();
}

class _ZoneEditScreenState extends State<ZoneEditScreen> {
  late TextEditingController zoneNameController;
  late TextEditingController cropNameController;
  late TextEditingController descriptionController;

  bool isSaving = false;
  String message = '';

  @override
  void initState() {
    super.initState();

    zoneNameController = TextEditingController(
      text: widget.zone['zone_name_or_code'] ?? '',
    );
    cropNameController = TextEditingController(
      text: widget.zone['crop_name'] ?? '',
    );
    descriptionController = TextEditingController(
      text: widget.zone['zone_description'] ?? '',
    );
  }

  @override
  void dispose() {
    zoneNameController.dispose();
    cropNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> updateZone() async {
    if (zoneNameController.text.trim().isEmpty) {
      setState(() {
        message = '구역명 또는 코드는 필수입니다.';
      });
      return;
    }

    setState(() {
      isSaving = true;
      message = '';
    });

    final result = await FarmService.updateZone(
      zoneId: widget.zone['zone_id'],
      zoneNameOrCode: zoneNameController.text.trim(),
      cropName: cropNameController.text.trim(),
      zoneDescription: descriptionController.text.trim(),
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

  Future<void> deleteZone() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('구역 삭제'),
          content: const Text('이 구역을 삭제하시겠습니까?'),
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

    final result = await FarmService.deleteZone(widget.zone['zone_id']);

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
        title: const Text('구역 수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isSaving ? null : deleteZone,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
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
              onPressed: isSaving ? null : updateZone,
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