import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosisService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> uploadDiagnosis(
    File imageFile, {
    int? zoneId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {
          'success': false,
          'message': '토큰이 없습니다.',
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/diagnoses/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      if (zoneId != null) {
        request.fields['zone_id'] = zoneId.toString();
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '진단 요청 실패',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '서버 연결 실패: $e',
      };
    }
  }
}