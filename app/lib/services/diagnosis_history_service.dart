import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosisHistoryService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> getDiagnosisHistory({
    String? cropName,
    String? severityLevel,
    String? actionStatus,
    String? diseaseName,
    int? farmId,
    int? zoneId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final queryParams = <String, String>{};

      if (cropName != null && cropName.isNotEmpty) {
        queryParams['crop_name'] = cropName;
      }
      if (severityLevel != null && severityLevel.isNotEmpty) {
        queryParams['severity_level'] = severityLevel;
      }
      if (actionStatus != null && actionStatus.isNotEmpty) {
        queryParams['action_status'] = actionStatus;
      }
      if (diseaseName != null && diseaseName.isNotEmpty) {
        queryParams['disease_name'] = diseaseName;
      }
      if (farmId != null) {
        queryParams['farm_id'] = farmId.toString();
      }
      if (zoneId != null) {
        queryParams['zone_id'] = zoneId.toString();
      }

      final uri = Uri.parse('$baseUrl/diagnoses/history')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '이력 조회 실패',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '서버 연결 실패: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getDiagnosisDetail(int diagnosisId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/diagnoses/$diagnosisId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '상세 조회 실패',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '서버 연결 실패: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateActionStatus({
    required int diagnosisId,
    required String actionStatus,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/diagnoses/$diagnosisId/action-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'action_status': actionStatus,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '조치 상태 변경 실패',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '서버 연결 실패: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': '토큰이 없습니다.'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? '대시보드 조회 실패',
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