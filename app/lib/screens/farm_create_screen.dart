import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/farm_service.dart';

class FarmCreateScreen extends StatefulWidget {
  const FarmCreateScreen({super.key});

  @override
  State<FarmCreateScreen> createState() => _FarmCreateScreenState();
}

class _FarmCreateScreenState extends State<FarmCreateScreen> {
  final TextEditingController farmNameController = TextEditingController();
  final TextEditingController farmLocationController = TextEditingController();
  final TextEditingController farmDescriptionController =
      TextEditingController();

  File? selectedImage;

  bool isLoading = false;
  String message = '';

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
    });
  }

  Future<void> createFarm() async {
    FocusScope.of(context).unfocus();

    final farmName = farmNameController.text.trim();
    final farmLocation = farmLocationController.text.trim();
    final farmDescription = farmDescriptionController.text.trim();

    if (farmName.isEmpty) {
      setState(() {
        message = '농장 이름을 입력해주세요.';
      });
      return;
    }

    if (farmLocation.isEmpty) {
      setState(() {
        message = '농장 위치 주소를 입력해주세요.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await FarmService.createFarm(
        farmName: farmName,
        farmLocation: farmLocation,
        farmDescription: farmDescription.isEmpty
            ? null
            : farmDescription,
        farmImagePath: selectedImage?.path,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          message = result['message'] ?? '농장 등록에 실패했습니다.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = '서버 오류가 발생했습니다.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    farmNameController.dispose();
    farmLocationController.dispose();
    farmDescriptionController.dispose();

    super.dispose();
  }

  Widget _buildMessageBox() {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '입력한 주소는 서버에서 위도·경도로 변환되어 저장됩니다.\n예: 서울특별시 강남구 테헤란로 123',
        style: TextStyle(
          color: Color(0xFF2F6B3F),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: isLoading ? null : pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 46,
                    color: Color(0xFF6FAF7D),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '농장 이미지 선택',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            selectedImage = null;
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
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
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildImagePicker(),

          const SizedBox(height: 18),

          TextField(
            controller: farmNameController,
            decoration: InputDecoration(
              labelText: '농장 이름 *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: farmLocationController,
            decoration: InputDecoration(
              labelText: '농장 위치 주소 *',
              hintText: '예: 서울특별시 강남구 테헤란로 123',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          _buildInfoBox(),

          const SizedBox(height: 14),

          TextField(
            controller: farmDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '농장 설명',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : createFarm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FAF7D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
                      '등록',
                      style: TextStyle(fontSize: 17),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          _buildMessageBox(),
        ],
      ),
    );
  }
}